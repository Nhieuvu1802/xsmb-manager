/**
 * Tiện ích HTTP: CORS, JSON response, ETag/304 và lỗi JSON thống nhất.
 *
 * Mọi endpoint đều trả JSON (kể cả lỗi) để app Flutter và website chỉ cần một
 * cách xử lý duy nhất.
 */

import type { Env } from "./types";

/** Gợi ý cache cho từng nhóm endpoint. */
export const CACHE = {
  /** Dữ liệu kết quả: thay đổi 1 lần/ngày, cho phép cache mạnh. */
  data: "public, max-age=300, s-maxage=3600, stale-while-revalidate=86400",
  /** Health: cần phản ánh trạng thái dataset nhanh hơn. */
  health: "public, max-age=60, s-maxage=300, stale-while-revalidate=600",
  /** Metadata ít đổi. */
  meta: "public, max-age=600, s-maxage=3600, stale-while-revalidate=86400",
  /** Lỗi: không cache. */
  none: "no-store",
} as const;

export function corsHeaders(env: Env, request: Request): Record<string, string> {
  const configured = (env.ALLOWED_ORIGINS ?? "*").trim();
  const origin = request.headers.get("Origin");
  const headers: Record<string, string> = {
    "access-control-allow-methods": "GET,HEAD,OPTIONS",
    "access-control-allow-headers": "Content-Type,Accept,Authorization,If-None-Match",
    "access-control-expose-headers": "ETag,X-API-Version,X-Dataset-Version,X-Dataset-Date",
    "access-control-max-age": "86400",
  };
  if (configured === "*" || configured === "") {
    headers["access-control-allow-origin"] = "*";
    return headers;
  }
  const allowed = configured.split(",").map((value) => value.trim());
  if (origin && allowed.includes(origin)) {
    headers["access-control-allow-origin"] = origin;
    headers["vary"] = "Origin";
  }
  return headers;
}

export interface ResponseMeta {
  /** ETag nội dung; client gửi lại `If-None-Match` sẽ nhận 304. */
  etag?: string;
  cacheControl?: string;
  extraHeaders?: Record<string, string>;
}

export function jsonResponse(
  body: unknown,
  request: Request,
  env: Env,
  status = 200,
  meta: ResponseMeta = {},
): Response {
  const headers: Record<string, string> = {
    "content-type": "application/json; charset=utf-8",
    "cache-control": meta.cacheControl ?? CACHE.data,
    "x-content-type-options": "nosniff",
    "referrer-policy": "no-referrer",
    "x-api-version": env.API_VERSION ?? "v1",
    ...corsHeaders(env, request),
    ...meta.extraHeaders,
  };
  if (meta.etag) {
    headers.etag = meta.etag;
    if (request.headers.get("if-none-match") === meta.etag) {
      return new Response(null, { status: 304, headers });
    }
  }
  if (request.method === "HEAD") {
    return new Response(null, { status, headers });
  }
  return new Response(JSON.stringify(body), { status, headers });
}

export function errorResponse(
  request: Request,
  env: Env,
  status: number,
  code: string,
  message: string,
  extra: Record<string, unknown> = {},
): Response {
  return jsonResponse(
    {
      status: "error",
      apiVersion: env.API_VERSION ?? "v1",
      code,
      message,
      // `detail` để tương thích với client đang đọc lỗi của FastAPI.
      detail: message,
      ...extra,
    },
    request,
    env,
    status,
    { cacheControl: CACHE.none },
  );
}

export function preflight(request: Request, env: Env): Response {
  return new Response(null, {
    status: 204,
    headers: {
      ...corsHeaders(env, request),
      "cache-control": CACHE.none,
      "x-api-version": env.API_VERSION ?? "v1",
    },
  });
}
