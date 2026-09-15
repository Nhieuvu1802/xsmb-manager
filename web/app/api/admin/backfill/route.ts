import { NextResponse } from "next/server";
import { listStoredDraws } from "@/lib/server/draw-repository";
import { syncDrawsToBackup } from "@/lib/server/backup-api";
import type { Region } from "@/lib/lottery-domain";

const REGIONS: Record<string, Region> = { XSMB: "Miền Bắc", XSMT: "Miền Trung", XSMN: "Miền Nam" };

export async function POST(request: Request) {
  const expected = process.env.ADMIN_API_KEY?.trim();
  const supplied = request.headers.get("authorization")?.replace(/^Bearer\s+/i, "");
  if (!expected || supplied !== expected) return NextResponse.json({ success: false, error: "Unauthorized" }, { status: 401 });
  const body = await request.json().catch(() => null) as { from?: string; to?: string; region?: string; province?: string } | null;
  const region = body?.region ? REGIONS[body.region] : undefined;
  if (!body?.from || !body.to || !region || !/^\d{4}-\d{2}-\d{2}$/.test(body.from) || !/^\d{4}-\d{2}-\d{2}$/.test(body.to)) return NextResponse.json({ success: false, error: "from, to and region are required" }, { status: 422 });
  const days = Math.floor((Date.parse(`${body.to}T00:00:00Z`) - Date.parse(`${body.from}T00:00:00Z`)) / 86_400_000) + 1;
  if (days < 1 || days > 31) return NextResponse.json({ success: false, error: "Range must be 1-31 days" }, { status: 422 });
  try {
    const stored = await listStoredDraws({ region, station: body.province, from: body.from, to: body.to, limit: 50 });
    const result = stored?.draws.length ? await syncDrawsToBackup(stored.draws) : { inserted: 0, updated: 0, unchanged: 0 };
    return NextResponse.json({ success: true, range: { from: body.from, to: body.to, days }, found: stored?.draws.length ?? 0, result });
  } catch (error) {
    return NextResponse.json({ success: false, error: error instanceof Error ? error.message : "Backfill failed" }, { status: 503 });
  }
}
