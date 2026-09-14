/**
 * Cloudflare Worker API v1 cho xsmb-manager.
 *
 * Endpoint chính:
 *   GET /v1/health
 *   GET /v1/xsmb/latest?days=7
 *   GET /v1/xsmn/latest?days=7&province=Long%20An
 *
 * Endpoint tương thích thêm cho app Flutter (dùng cùng hợp đồng với FastAPI):
 *   GET /v1/xsmb/{YYYY-MM-DD}, GET /v1/xsmb/history?start=&end=
 *   GET /v1/xsmn/{YYYY-MM-DD}, GET /v1/xsmn/history?start=&end=
 *   GET /v1/config, GET /v1/manifest, GET /
 *
 * Worker không có secret, không binding, không gọi mạng ngoài: dữ liệu là
 * snapshot đã kiểm định được bundle từ `public-data/`.
 */

import {
  MANIFEST,
  PUBLIC_CONFIG,
  REGIONS,
  allDraws,
  datasetDate,
  datasetHealthy,
  datasetVersion,
  drawsForDate,
  drawsInRange,
  historyRange,
  isRegionKey,
  latestDraws,
  prizeCount,
  regionDate,
  type DrawSelection,
} from "./dataset";
import { CACHE, errorResponse, jsonResponse, preflight } from "./response";
import { calculateStatistics, generateTop4 } from "./statistics";
import {
  checkBudget, parseLimits, activateCircuitBreaker, deactivateCircuitBreaker,
  DEFAULT_LIMITS,
} from "./r2-budget";
import type { Env, RegionKey } from "./types";

const API_VERSION = "v1";
const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;
const DEFAULT_DAYS = 7;
const MAX_DAYS = 90;

/** Lỗi có chủ đích, được router chuyển thành JSON với mã HTTP rõ ràng. */
class ApiProblem extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
    readonly extra: Record<string, unknown> = {},
  ) {
    super(message);
    this.name = "ApiProblem";
  }
}

function version(env: Env): string {
  return env.API_VERSION || API_VERSION;
}

/** ETag ổn định theo phiên bản dataset + endpoint, giúp app tiết kiệm băng thông. */
function etag(env: Env, scope: string): string {
  return `W/"${version(env)}-${datasetVersion()}-${scope}"`;
}

function parseDays(url: URL): number {
  const raw = url.searchParams.get("days");
  if (raw === null || raw.trim() === "") return DEFAULT_DAYS;
  const value = Number(raw);
  if (!Number.isInteger(value) || value < 1 || value > MAX_DAYS) {
    throw new ApiProblem(
      400,
      "invalid_query",
      `days phải là số nguyên từ 1 đến ${MAX_DAYS}.`,
      { parameter: "days", received: raw },
    );
  }
  return value;
}

function parseDateParam(url: URL, name: string): string | null {
  const raw = url.searchParams.get(name);
  if (raw === null || raw.trim() === "") return null;
  const value = raw.trim();
  if (!ISO_DATE.test(value)) {
    throw new ApiProblem(
      400,
      "invalid_query",
      `${name} phải theo định dạng YYYY-MM-DD.`,
      { parameter: name, received: raw },
    );
  }
  return value;
}

function stationParam(url: URL): string | null {
  const raw = url.searchParams.get("province") ?? url.searchParams.get("station");
  const value = (raw ?? "").trim();
  return value === "" ? null : value;
}

/** Payload dạng DrawListResponse của FastAPI, kèm metadata của dataset. */
function listPayload(
  env: Env,
  region: RegionKey,
  selection: DrawSelection,
  extra: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    region: REGIONS[region].code,
    count: selection.draws.length,
    draws: selection.draws,
    success: true,
    apiVersion: version(env),
    regionName: REGIONS[region].name,
    regionLabel: REGIONS[region].label,
    date: selection.date,
    datasetDate: datasetDate(),
    datasetVersion: datasetVersion(),
    generatedAt: MANIFEST.generatedAt,
    source: "vvn-public-data",
    stations: selection.stations,
    ...extra,
  };
}

/* -------------------------------------------------------------------------- */
/* Handlers                                                                    */
/* -------------------------------------------------------------------------- */

function healthHandler(request: Request, env: Env): Response {
  const healthy = datasetHealthy();
  return jsonResponse(
    {
      status: healthy ? "ok" : "degraded",
      apiVersion: version(env),
      datasetDate: datasetDate(),
      datasetVersion: datasetVersion(),
      generatedAt: MANIFEST.generatedAt,
      database: env.LOTTERY_DATA ? "r2+snapshot" : "snapshot",
      time: new Date().toISOString(),
      lastDataUpdate: datasetDate(),
      environment: env.ENVIRONMENT ?? "production",
      r2: { available: !!env.LOTTERY_DATA },
      cron: { enabled: true },
      providers: ["cloudflare-worker", "public-data"],
      historyDays: MANIFEST.historyDays ?? null,
      history: {
        xsmb: historyRange("xsmb"),
        xsmn: historyRange("xsmn"),
      },
      regions: {
        xsmb: {
          date: regionDate("xsmb"),
          draws: allDraws("xsmb").length,
          prizesPerDraw: prizeCount("xsmb"),
        },
        xsmn: {
          date: regionDate("xsmn"),
          draws: allDraws("xsmn").length,
          prizesPerDraw: prizeCount("xsmn"),
          stations: [
            ...new Set(allDraws("xsmn").map((draw) => draw.station)),
          ].sort(),
        },
      },
    },
    request,
    env,
    200,
    { cacheControl: CACHE.health, etag: etag(env, "health") },
  );
}

function configHandler(request: Request, env: Env): Response {
  return jsonResponse(
    { ...PUBLIC_CONFIG, apiVersion: version(env) },
    request,
    env,
    200,
    { cacheControl: CACHE.meta, etag: etag(env, "config") },
  );
}

function manifestHandler(request: Request, env: Env): Response {
  return jsonResponse(
    {
      ...MANIFEST,
      apiVersion: version(env),
      servedBy: "cloudflare-worker",
      regions: {
        xsmb: { date: regionDate("xsmb"), draws: allDraws("xsmb").length },
        xsmn: { date: regionDate("xsmn"), draws: allDraws("xsmn").length },
      },
    },
    request,
    env,
    200,
    { cacheControl: CACHE.meta, etag: etag(env, "manifest") },
  );
}

function indexDocument(request: Request, env: Env): Response {
  const base = new URL(request.url).origin;
  return jsonResponse(
    {
      status: datasetHealthy() ? "ok" : "degraded",
      apiVersion: version(env),
      service: "xsmb-manager-api",
      datasetDate: datasetDate(),
      datasetVersion: datasetVersion(),
      historyDays: MANIFEST.historyDays ?? null,
      environment: env.ENVIRONMENT ?? "production",
      endpoints: [
        `${base}/v1/health`,
        `${base}/v1/xsmb/latest`,
        `${base}/v1/xsmn/latest`,
        `${base}/v1/xsmb/{YYYY-MM-DD}`,
        `${base}/v1/xsmn/{YYYY-MM-DD}`,
        `${base}/v1/xsmb/history?start=&end=`,
        `${base}/v1/xsmn/history?start=&end=`,
        `${base}/v1/statistics/00-99`,
        `${base}/v1/xsmb/statistics`,
        `${base}/v1/xsmn/statistics`,
        `${base}/v1/predictions/top4`,
        `${base}/v1/config`,
        `${base}/v1/manifest`,
      ],
      regions: [REGIONS.xsmb.label, REGIONS.xsmn.label],
      note: "Miền Trung chưa có dữ liệu trong dataset.",
    },
    request,
    env,
    200,
    { cacheControl: CACHE.meta, etag: etag(env, "index") },
  );
}

function latestHandler(
  request: Request,
  env: Env,
  url: URL,
  region: RegionKey,
): Response {
  const selection = latestDraws(region, parseDays(url), stationParam(url));
  return jsonResponse(
    listPayload(env, region, selection, {
      availableDates: [...new Set(allDraws(region).map((draw) => draw.date))].sort(
        (a, b) => (a < b ? 1 : -1),
      ),
    }),
    request,
    env,
    200,
    { cacheControl: CACHE.data, etag: etag(env, `${region}-latest`) },
  );
}

function historyHandler(
  request: Request,
  env: Env,
  url: URL,
  region: RegionKey,
): Response {
  const start = parseDateParam(url, "start");
  const end = parseDateParam(url, "end");
  if (start !== null && end !== null && start > end) {
    throw new ApiProblem(400, "invalid_query", "start phải nhỏ hơn hoặc bằng end.");
  }
  const selection = drawsInRange(region, start, end, stationParam(url));
  return jsonResponse(
    listPayload(env, region, selection, { start, end }),
    request,
    env,
    200,
    { cacheControl: CACHE.data, etag: etag(env, `${region}-history`) },
  );
}

function dateHandler(
  request: Request,
  env: Env,
  url: URL,
  region: RegionKey,
  date: string,
): Response {
  const selection = drawsForDate(region, date, stationParam(url));
  if (selection.draws.length === 0) {
    throw new ApiProblem(
      404,
      "not_found",
      `Chưa có dữ liệu ${REGIONS[region].label} cho ngày ${date}.`,
      { region: REGIONS[region].code, date, availableDates: [...new Set(allDraws(region).map((draw) => draw.date))].sort((a, b) => (a < b ? 1 : -1)) },
    );
  }
  return jsonResponse(
    listPayload(env, region, selection, { date }),
    request,
    env,
    200,
    { cacheControl: CACHE.data, etag: etag(env, `${region}-${date}`) },
  );
}

/* -------------------------------------------------------------------------- */
/* Statistics & Predictions handlers                                           */
/* -------------------------------------------------------------------------- */

function statisticsHandler(request: Request, env: Env, region: string): Response {
  const regionKey = region === "xsmb" ? "xsmb" : "xsmn";
  const draws = allDraws(regionKey);
  const stats = calculateStatistics(draws, regionKey);
  stats.datasetVersion = datasetVersion();
  return jsonResponse(
    stats,
    request,
    env,
    200,
    { cacheControl: CACHE.meta, etag: etag(env, `${regionKey}-statistics`) },
  );
}

function predictionsHandler(request: Request, env: Env): Response {
  // Compute stats for xsmb (most data, 27 results per draw)
  const draws = allDraws("xsmb");
  const stats = calculateStatistics(draws, "xsmb");
  const top4 = generateTop4(
    stats.numbers,
    regionDate("xsmb") ?? new Date().toISOString().slice(0, 10),
    datasetVersion(),
    "top4-v1",
  );
  return jsonResponse(
    top4,
    request,
    env,
    200,
    { cacheControl: CACHE.health, etag: etag(env, "predictions-top4") },
  );
}

/* -------------------------------------------------------------------------- */
/* R2 Budget handlers                                                          */
/* -------------------------------------------------------------------------- */

function r2BudgetHandler(request: Request, env: Env): Response | Promise<Response> {
  if (!env.LOTTERY_DATA) {
    return jsonResponse(
      { r2: false, message: "R2 not configured" },
      request, env, 200, { cacheControl: CACHE.health },
    );
  }
  const limits = parseLimits(env as unknown as Record<string, string | undefined>);
  return checkBudget(env.LOTTERY_DATA, "read", 0, limits).then((result) =>
    jsonResponse({
      r2: true,
      circuitBreaker: result.meta.circuitBreaker,
      blockedReason: result.meta.blockedReason ?? null,
      status: result.severity,
      message: result.message,
      limits: {
        maxStorageGB: round4(limits.maxStorageBytes / 1024 ** 3),
        maxWritesPerMonth: limits.maxWritesPerMonth,
        softLimitPercent: limits.softLimitPercent,
        hardLimitPercent: limits.hardLimitPercent,
      },
      usage: result.usage,
      lastUpdated: result.meta.lastUpdated,
    }, request, env, 200, { cacheControl: "private, max-age=0" }),
  );
}

async function r2BudgetSubHandler(
  request: Request, env: Env, sub: string | undefined,
): Promise<Response> {
  if (!sub) {
    return r2BudgetHandler(request, env) as Promise<Response>;
  }
  if (sub === "budget") return r2BudgetHandler(request, env) as Promise<Response>;

  if (sub === "circuit-breaker") {
    if (!env.LOTTERY_DATA) {
      return errorResponse(request, env, 503, "r2_not_configured", "R2 not configured.");
    }
    if (request.method === "POST") {
      // Check admin secret
      const authHeader = request.headers.get("Authorization");
      const token = authHeader?.replace("Bearer ", "") ?? "";
      if (!env.ADMIN_SECRET || token !== env.ADMIN_SECRET) {
        return errorResponse(request, env, 401, "unauthorized", "Admin secret required.");
      }
      const body = await request.json<{ action: "on" | "off"; reason?: string }>();
      if (body.action === "on") {
        await activateCircuitBreaker(env.LOTTERY_DATA, body.reason ?? "manual activation");
        return jsonResponse({ circuitBreaker: true, message: "Circuit breaker activated" },
          request, env, 200);
      }
      if (body.action === "off") {
        await deactivateCircuitBreaker(env.LOTTERY_DATA);
        return jsonResponse({ circuitBreaker: false, message: "Circuit breaker deactivated" },
          request, env, 200);
      }
      return errorResponse(request, env, 400, "invalid_action", "Action must be 'on' or 'off'.");
    }
    return errorResponse(request, env, 405, "method_not_allowed", "Use POST with {action, reason}.");
  }

  return errorResponse(request, env, 404, "not_found", `/v1/r2/${sub} không tồn tại.`);
}

function round4(n: number): number {
  return Math.round(n * 10000) / 10000;
}

/* -------------------------------------------------------------------------- */
/* Router                                                                      */
/* -------------------------------------------------------------------------- */

const worker = {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    try {
      if (request.method === "OPTIONS") return preflight(request, env);
      // Allow POST only for R2 circuit-breaker admin endpoint
      const isCircuitBreakerPost =
        request.method === "POST" &&
        url.pathname === `/${API_VERSION}/r2/circuit-breaker`;
      if (request.method !== "GET" && request.method !== "HEAD" && !isCircuitBreakerPost) {
        return errorResponse(
          request,
          env,
          405,
          "method_not_allowed",
          `Phương thức ${request.method} không được hỗ trợ, chỉ dùng GET.`,
        );
      }

      const segments = url.pathname.split("/").filter((value) => value !== "");
      if (segments.length === 0) return indexDocument(request, env);

      const [prefix, first, second, ...rest] = segments;
      if (prefix !== API_VERSION) {
        return errorResponse(
          request,
          env,
          404,
          "not_found",
          `Đường dẫn ${url.pathname} không tồn tại. API dùng tiền tố /${API_VERSION}/.`,
        );
      }
      if (first === undefined) return indexDocument(request, env);
      if (rest.length > 0) {
        return errorResponse(
          request,
          env,
          404,
          "not_found",
          `Đường dẫn ${url.pathname} không tồn tại.`,
        );
      }

      if (second === undefined) {
        switch (first) {
          case "health":
            return healthHandler(request, env);
          case "config":
            return configHandler(request, env);
          case "manifest":
            return manifestHandler(request, env);
          case "statistics":
            return statisticsHandler(request, env, "xsmb");
          case "predictions":
            return predictionsHandler(request, env);
          case "r2":
            return r2BudgetHandler(request, env);
          case "xsmb":
          case "xsmn":
            return errorResponse(
              request,
              env,
              400,
              "missing_endpoint",
              `Thiếu endpoint cho /${API_VERSION}/${first}: dùng /latest, /history hoặc /{YYYY-MM-DD}.`,
            );
          default:
            return errorResponse(
              request,
              env,
              404,
              "not_found",
              `Endpoint /${API_VERSION}/${first} không tồn tại.`,
            );
        }
      }

      // ── Tham số室.pathname routes (trước region check) ──
      if (first === "predictions" && second === "top4") {
        return predictionsHandler(request, env);
      }
      if (first === "statistics" && second === "00-99") {
        return statisticsHandler(request, env, "00-99");
      }

      // R2 admin routes: /v1/r2/budget, /v1/r2/circuit-breaker
      if (first === "r2") {
        return r2BudgetSubHandler(request, env, second);
      }

      if (!isRegionKey(first)) {
        return errorResponse(
          request,
          env,
          404,
          "not_found",
          `Vùng "${first}" không hỗ trợ. Chỉ có xsmb và xsmn.`,
        );
      }

      if (second === "latest") return latestHandler(request, env, url, first);
      if (second === "history") return historyHandler(request, env, url, first);
      if (second === "statistics") return statisticsHandler(request, env, first);
      if (ISO_DATE.test(second)) {
        return dateHandler(request, env, url, first, second);
      }
      return errorResponse(
        request,
        env,
        404,
        "not_found",
        `Endpoint /${API_VERSION}/${first}/${second} không tồn tại.`,
      );
    } catch (error) {
      if (error instanceof ApiProblem) {
        return errorResponse(
          request,
          env,
          error.status,
          error.code,
          error.message,
          error.extra,
        );
      }
      console.error("unhandled_error", {
        path: url.pathname,
        message: error instanceof Error ? error.message : String(error),
      });
      return errorResponse(
        request,
        env,
        500,
        "internal_error",
        "Worker gặp lỗi không mong đợi, vui lòng thử lại sau.",
      );
    }
  },
};

export default worker;

/* -------------------------------------------------------------------------- */
/* Scheduled handler (Cloudflare Cron)                                         */
/* -------------------------------------------------------------------------- */

/**
 * Cloudflare Cron gọi scheduled() theo crons đã cấu hình trong wrangler.jsonc.
 * Hiện tại Worker chỉ đọc snapshot tĩnh — scheduled() log thông tin dataset
 * để khi collector được thêm vào, handler này đã sẵn sàng gọi collector.
 *
 * Cron schedule (UTC):
 *   - 15,30 9 * * *  → XSMN collection window (09:15, 09:30)
 *   - 0 10 * * *     → XSMN final check (10:00)
 *   - 15,30 11 * * * → XSMB collection window (11:15, 11:30)
 *   - 0 12 * * *     → XSMB final check (12:00)
 */
export async function scheduled(
  _event: ScheduledEvent,
  env: Env,
  _ctx: ExecutionContext,
): Promise<void> {
  const now = new Date().toISOString();
  console.log(JSON.stringify({
    event: "cron_tick",
    timestamp: now,
    datasetVersion: datasetVersion(),
    datasetDate: datasetDate(),
    environment: env.ENVIRONMENT ?? "production",
  }));

  // ── R2 Budget Guard: kiểm tra trước khi collector ghi dữ liệu ──
  if (env.LOTTERY_DATA) {
    const limits = parseLimits(env as unknown as Record<string, string | undefined>);
    const budget = await checkBudget(env.LOTTERY_DATA, "write", 0, limits);
    console.log(JSON.stringify({
      event: "cron_r2_budget_check",
      severity: budget.severity,
      message: budget.message,
      usage: budget.usage,
    }));

    if (!budget.allowed) {
      console.error(JSON.stringify({
        event: "cron_r2_budget_blocked",
        message: budget.message,
        usage: budget.usage,
        action: "skipping_collection",
      }));
      // KHÔNG collect — tránh chi phí ngoài dự kiến.
      // Budget meta đã được ghi trong checkBudget.
      return;
    }

    if (budget.severity === "soft") {
      console.warn(JSON.stringify({
        event: "cron_r2_budget_warning",
        message: budget.message,
        usage: budget.usage,
        action: "proceeding_with_collection",
      }));
    }
  }

  // When R2 is available, this is where collector logic runs:
  // 1. Determine which region to collect based on current time
  // 2. Fetch from providers (primary → secondary → fallback)
  // 3. Validate and normalize
  // 4. Store to R2 (using guardedPut for budget tracking)
  // 5. Update manifest
  // 6. Generate updated statistics
  // For now, the bundled snapshot is the source of truth.
}
