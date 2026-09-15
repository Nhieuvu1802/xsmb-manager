/**
 * Lightweight HTML scraper for XSMB/XSMN from xoso.com.vn (primary)
 * and xosodaiphat.com (backup). Server-side only — runs in cron/Node.
 */
import type { LotteryDraw, PrizeResult, Region } from "../lottery-domain";
import { canonicalStationName } from "../stations";

const TIMEOUT_MS = 8_000;
const UA = "Mozilla/5.0 (compatible; XSMB-Manager/3.4)";

const MB_PRIZE_NAMES: Record<string, string> = {
  DB: "Đặc biệt", ĐB: "Đặc biệt",
  "1": "Giải nhất", "2": "Giải nhì", "3": "Giải ba",
  "4": "Giải tư", "5": "Giải năm", "6": "Giải sáu", "7": "Giải bảy",
};

const MB_EXPECTED: Record<string, number> = {
  "Đặc biệt": 1, "Giải nhất": 1, "Giải nhì": 2, "Giải ba": 6,
  "Giải tư": 4, "Giải năm": 6, "Giải sáu": 3, "Giải bảy": 4,
};

const MB_PRIZE_LEN: Record<string, number> = {
  "Đặc biệt": 5, "Giải nhất": 5, "Giải nhì": 5, "Giải ba": 5,
  "Giải tư": 4, "Giải năm": 4, "Giải sáu": 3, "Giải bảy": 2,
};

const MN_CODE_TO_PRIZE: Record<string, string> = {
  "8": "Giải tám", "7": "Giải bảy", "6": "Giải sáu", "5": "Giải năm",
  "4": "Giải tư", "3": "Giải ba", "2": "Giải nhì", "1": "Giải nhất",
  ĐB: "Đặc biệt",
};

const MN_EXPECTED: Record<string, number> = {
  "Giải tám": 1, "Giải bảy": 1, "Giải sáu": 3, "Giải năm": 1,
  "Giải tư": 7, "Giải ba": 2, "Giải nhì": 1, "Giải nhất": 1, "Đặc biệt": 1,
};

const MN_PRIZE_LEN: Record<string, number> = {
  "Giải tám": 2, "Giải bảy": 3, "Giải sáu": 4, "Giải năm": 4,
  "Giải tư": 5, "Giải ba": 5, "Giải nhì": 5, "Giải nhất": 5, "Đặc biệt": 6,
};

async function fetchHtml(url: string): Promise<string | null> {
  try {
    const res = await fetch(url, {
      signal: AbortSignal.timeout(TIMEOUT_MS),
      headers: { "User-Agent": UA },
      cache: "no-store",
    });
    if (!res.ok) return null;
    return res.text();
  } catch {
    return null;
  }
}

function ddmm(dateStr: string) {
  const [y, m, d] = dateStr.split("-");
  return `${d}-${m}-${y}`;
}

// ── XSMB parsing ────────────────────────────────────────────────────

function parseXSMB(html: string): Record<string, string[]> | null {
  const found: Record<string, string[]> = {};

  // Strategy 1: ID-based (xoso.com.vn) — mb_prize{code}_item{n}
  for (const code of Object.keys(MB_PRIZE_NAMES)) {
    const re = new RegExp(
      `id="mb_prize${code}_item(\\d+)"[^>]*>([^<]*(?:<[^/][^>]*>)*[^<]*)\\s*(\\d{${MB_PRIZE_LEN[MB_PRIZE_NAMES[code]]}})`,
      "gi",
    );
    let m: RegExpExecArray | null;
    const items: [number, string][] = [];
    while ((m = re.exec(html))) {
      items.push([parseInt(m[1]), m[3]]);
    }
    if (items.length) {
      const prize = MB_PRIZE_NAMES[code];
      found[prize] = items.sort((a, b) => a[0] - b[0]).map(([, v]) => v);
    }
  }

  if (Object.values(found).reduce((s, a) => s + a.length, 0) >= 27) return found;

  // Strategy 2: table-row regex (xosodaiphat.com)
  for (const [code, prize] of Object.entries(MB_PRIZE_NAMES)) {
    if (found[prize]?.length === MB_EXPECTED[prize]) continue;
    const len = MB_PRIZE_LEN[prize];
    const escaped = code.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const re = new RegExp(
      `<tr[^>]*>\\s*<(?:th|td)[^>]*>\\s*(?:G(?:iải)?\\.?\\s*)?${escaped}\\s*((?:(?!<tr).)*)`,
      "gi",
    );
    const rowMatch = re.exec(html);
    if (rowMatch) {
      const nums = [...rowMatch[1].matchAll(new RegExp(`>\\s*(\\d{${len}})\\s*<`, "g"))].map((m) => m[1]);
      if (nums.length >= MB_EXPECTED[prize]) {
        found[prize] = nums.slice(0, MB_EXPECTED[prize]);
      }
    }
  }

  return Object.values(found).reduce((s, a) => s + a.length, 0) >= 27 ? found : null;
}

function mbToResults(found: Record<string, string[]>): PrizeResult[] {
  const results: PrizeResult[] = [];
  let pos = 1;
  for (const [prize, expected] of Object.entries(MB_EXPECTED)) {
    for (const n of (found[prize] ?? []).slice(0, expected)) {
      results.push({ prize, position: pos++, value: n });
    }
  }
  return results;
}

// ── XSMN / XSMT parsing ────────────────────────────────────────────

function parseXSMN(html: string): Record<string, Record<string, string[]>> | null {
  for (const tableMatch of html.matchAll(/<table[^>]*>([\s\S]*?)<\/table>/gi)) {
    const table = tableMatch[1];
    if (!/(?:G\.?\s*)?(?:8|ĐB)/i.test(table)) continue;

    let provinces = [...table.matchAll(/title="Xổ số\s+([^"]+)"/gi)].map((m) => m[1].trim());
    if (provinces.length < 2) {
      provinces = [...table.matchAll(/<h3[^>]*>\s*<a[^>]*>(.*?)<\/a>/gi)]
        .map((m) => m[1].replace(/<[^>]+>/g, "").trim())
        .filter((p) => p && p.length < 40);
    }
    provinces = [...new Set(provinces)];
    if (provinces.length < 2 || provinces.length > 4) continue;

    const result: Record<string, Record<string, string[]>> = {};
    for (const p of provinces) result[p] = {};

    for (const [code, prize] of Object.entries(MN_CODE_TO_PRIZE)) {
      const escaped = code.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      const re = new RegExp(
        `<tr[^>]*>\\s*<(?:th|td)[^>]*>\\s*(?:G\\.?\\s*)?${escaped}\\s*((?:(?!<tr).)*)`,
        "gi",
      );
      const rowMatch = re.exec(table);
      if (!rowMatch) continue;
      const cells = rowMatch[1].split(/<td[^>]*>/i).slice(1);
      const len = MN_PRIZE_LEN[prize];
      for (let i = 0; i < Math.min(cells.length, provinces.length); i++) {
        const nums = [...cells[i].matchAll(new RegExp(`>\\s*(\\d{${len}})\\s*<`, "g"))].map((m) => m[1]);
        result[provinces[i]][prize] = nums.slice(0, MN_EXPECTED[prize]);
      }
    }

    const hasData = Object.values(result).some((prizes) =>
      Object.values(prizes).some((v) => v.length > 0),
    );
    if (hasData) return result;
  }
  return null;
}

function smnToDraws(
  data: Record<string, Record<string, string[]>>,
  date: string,
  region: "Miền Nam" | "Miền Trung",
): LotteryDraw[] {
  const drawnAtTime = region === "Miền Trung" ? "17:15" : "16:15";
  const prefix = region === "Miền Nam" ? "MN" : "MT";
  return Object.entries(data).map(([province, prizes]) => {
    const results: PrizeResult[] = [];
    let pos = 1;
    for (const [prize, expected] of Object.entries(MN_EXPECTED)) {
      for (const n of (prizes[prize] ?? []).slice(0, expected)) {
        results.push({ prize, position: pos++, value: n });
      }
    }
    return {
      id: `${prefix.toLowerCase()}-${province.toLowerCase().replace(/[^a-z0-9]/g, "")}-${date}`,
      drawCode: `${prefix}-${province.replace(/[^a-zA-Z0-9]/g, "")}-${date}`,
      lotteryType: "TRADITIONAL" as const,
      date,
      drawnAt: `${date}T${drawnAtTime}:00+07:00`,
      region,
      station: canonicalStationName(province, region),
      source: "xoso.com.vn",
      collectedAt: new Date().toISOString(),
      verification: "PENDING" as const,
      results,
    };
  });
}

// ── Public API ──────────────────────────────────────────────────────

const XSMB_URLS = [
  (d: string) => `https://xoso.com.vn/xsmb-${ddmm(d)}.html`,
  (d: string) => `https://xosodaiphat.com/xsmb-${ddmm(d)}.html`,
];

const XSMN_URLS = [
  (d: string) => `https://xoso.com.vn/xsmn-${ddmm(d)}.html`,
  (d: string) => `https://xosodaiphat.com/xsmn-${ddmm(d)}.html`,
];

const XSMT_URLS = [
  (d: string) => `https://xoso.com.vn/xsmt-${ddmm(d)}.html`,
  (d: string) => `https://xosodaiphat.com/xsmt-${ddmm(d)}.html`,
];

export async function scrapeXSMB(date: string): Promise<LotteryDraw | null> {
  for (const urlFn of XSMB_URLS) {
    const html = await fetchHtml(urlFn(date));
    if (!html) continue;
    const found = parseXSMB(html);
    if (!found) continue;
    return {
      id: `mb-${date}`,
      drawCode: `MB-${date}`,
      lotteryType: "TRADITIONAL",
      date,
      drawnAt: `${date}T18:15:00+07:00`,
      region: "Miền Bắc",
      station: "Hội đồng XSKT miền Bắc",
      source: "xoso.com.vn",
      collectedAt: new Date().toISOString(),
      verification: "VERIFIED",
      results: mbToResults(found),
    };
  }
  return null;
}

async function scrapeXSMNDate(date: string): Promise<LotteryDraw[]> {
  for (const urlFn of XSMN_URLS) {
    const html = await fetchHtml(urlFn(date));
    if (!html) continue;
    const data = parseXSMN(html);
    if (!data) continue;
    return smnToDraws(data, date, "Miền Nam");
  }
  return [];
}

async function scrapeXSMTDate(date: string): Promise<LotteryDraw[]> {
  for (const urlFn of XSMT_URLS) {
    const html = await fetchHtml(urlFn(date));
    if (!html) continue;
    const data = parseXSMN(html);
    if (!data) continue;
    return smnToDraws(data, date, "Miền Trung");
  }
  return [];
}

/** Scrape recent days (1–7 back) across all regions. */
export async function scrapeRecent(daysBack: number = 3): Promise<LotteryDraw[]> {
  const now = new Date();
  const draws: LotteryDraw[] = [];

  for (let i = 0; i < daysBack; i++) {
    const d = new Date(now);
    d.setUTCDate(d.getUTCDate() - i);
    const dateStr = d.toISOString().slice(0, 10);

    const mb = await scrapeXSMB(dateStr);
    if (mb) draws.push(mb);
    draws.push(...(await scrapeXSMNDate(dateStr)));
    draws.push(...(await scrapeXSMTDate(dateStr)));
  }

  return draws;
}
