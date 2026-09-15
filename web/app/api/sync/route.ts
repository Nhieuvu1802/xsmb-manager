import { NextResponse } from "next/server";
import { listStoredDraws } from "@/lib/server/draw-repository";
import { syncDrawsToBackup } from "@/lib/server/backup-api";
import type { Region } from "@/lib/lottery-domain";

const REGIONS: Record<string, Region> = { XSMB: "Miền Bắc", XSMT: "Miền Trung", XSMN: "Miền Nam" };

export async function POST(request: Request) {
  const configuredKey = process.env.ADMIN_API_KEY?.trim();
  const suppliedKey = request.headers.get("authorization")?.replace(/^Bearer\s+/i, "");
  if (!configuredKey || suppliedKey !== configuredKey) return NextResponse.json({ success: false, error: "Unauthorized" }, { status: 401 });
  const body = await request.json().catch(() => ({})) as { from?: string; to?: string; region?: string; province?: string; limit?: number };
  if ((body.from && !/^\d{4}-\d{2}-\d{2}$/.test(body.from)) || (body.to && !/^\d{4}-\d{2}-\d{2}$/.test(body.to))) return NextResponse.json({ success: false, error: "Invalid date" }, { status: 422 });
  const limit = Math.min(Math.max(body.limit ?? 30, 1), 50);
  try {
    const stored = await listStoredDraws({ region: body.region ? REGIONS[body.region] : undefined, station: body.province, from: body.from, to: body.to, limit });
    if (!stored?.draws.length) return NextResponse.json({ success: true, inserted: 0, updated: 0, unchanged: 0, message: "No matching draws" });
    return NextResponse.json(await syncDrawsToBackup(stored.draws));
  } catch (error) {
    return NextResponse.json({ success: false, error: error instanceof Error ? error.message : "Sync unavailable" }, { status: 503 });
  }
}
