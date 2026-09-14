import { NextResponse } from "next/server";
import type { Region } from "@/lib/lottery-domain";
import { getNumberFrequencies, getTrendTimeline } from "@/lib/server/trend-repository";

const VALID_REGIONS: Region[] = ["Miền Bắc", "Miền Trung", "Miền Nam"];

/**
 * GET /api/stats/trend?region=Miền+Bắc&limit=30&numbers=07,13,24
 * Returns:
 *  - frequencies: per-number hit counts (all 00-99)
 *  - timeline: last N draws with hit counts (for chart)
 */
export async function GET(request: Request) {
  const params = Object.fromEntries(new URL(request.url).searchParams);
  const region = (params.region as Region) || "Miền Bắc";

  if (!VALID_REGIONS.includes(region)) {
    return NextResponse.json({ error: "Miền không hợp lệ." }, { status: 422 });
  }

  const limit = Math.min(Math.max(Number(params.limit) || 30, 5), 365);
  const trackedNumbers = params.numbers
    ? params.numbers.split(",").map((n) => n.trim().padStart(2, "0")).filter((n) => /^\d{2}$/.test(n))
    : [];

  const [frequencies, timeline] = await Promise.all([
    getNumberFrequencies(region),
    getTrendTimeline(region, trackedNumbers, limit),
  ]);

  return NextResponse.json(
    { region, frequencies, timeline, limit, trackedNumbers },
    { headers: { "Cache-Control": "public, max-age=300" } },
  );
}
