import { NextResponse } from "next/server";
import { createSampleDraws } from "@/lib/sample-data";
import {
  databaseStatus,
  insertMissingDraws,
  logAudit,
  logDataImport,
  pruneOldDraws,
  upsertDraws,
} from "@/lib/server/draw-repository";
import { refreshNumberTrends } from "@/lib/server/trend-repository";
import { fetchLegalProvider, providerRecordsToDraws } from "@/lib/server/provider";
import { fetchWorkerHistory } from "@/lib/worker-api-client";
import { scrapeRecent } from "@/lib/server/xoso-scraper";
import type { Region } from "@/lib/lottery-domain";
import { cacheInvalidate } from "@/lib/server/cache";
import { getClientIp } from "@/lib/server/request-context";

export const maxDuration = 300;

function dateOnly(date: Date) {
  return date.toISOString().slice(0, 10);
}

export async function GET(request: Request) {
  const secret = process.env.CRON_SECRET;
  if (!secret || request.headers.get("authorization") !== `Bearer ${secret}`) {
    return NextResponse.json({ error: "Cron không hợp lệ." }, { status: 401 });
  }

  const retentionDays = Math.min(Math.max(Number(process.env.DATA_RETENTION_DAYS) || 370, 365), 400);

  try {
    const before = await databaseStatus();
    const today = new Date();
    const requestedFullSync = new URL(request.url).searchParams.get("full") === "true";
    const fullSync = requestedFullSync || !before?.drawCount || today.getUTCDay() === 0;
    const from = new Date(today);
    from.setUTCDate(from.getUTCDate() - (fullSync ? 365 : 7));
    const payload = await fetchLegalProvider(dateOnly(from), dateOnly(today));

    let imported = 0;
    let source = "rolling-sample";
    if (payload) {
      imported = await upsertDraws(providerRecordsToDraws(payload.records));
      source = "legal-provider";
    } else {
      // Try web scraper (xoso.com.vn / xosodaiphat.com) — no env vars needed
      const scrapedDraws = await scrapeRecent(fullSync ? 7 : 3);
      if (scrapedDraws.length) {
        imported = before?.drawCount ? await upsertDraws(scrapedDraws) : await insertMissingDraws(scrapedDraws);
        source = "xoso-scraper";
      } else {
        const regions: Region[] = ["Miền Bắc", "Miền Trung", "Miền Nam"];
        const workerDraws = (await Promise.all(
          regions.map((region) => fetchWorkerHistory(region, dateOnly(from), dateOnly(today))),
        )).flat();
        if (workerDraws.length) {
          imported = before?.drawCount ? await upsertDraws(workerDraws) : await insertMissingDraws(workerDraws);
          source = "cloudflare-worker-api";
        } else {
          imported = await insertMissingDraws(createSampleDraws(before?.drawCount ? 3 : 365));
        }
      }
    }

    const removed = await pruneOldDraws(retentionDays);

    // Sync newly imported data to InfinityFree backup (best-effort, non-blocking)
    let syncResult: { inserted?: number; updated?: number; unchanged?: number } | null = null;
    if (imported > 0 && process.env.BACKUP_SYNC_URL) {
      try {
        const { listStoredDraws: listDraws } = await import("@/lib/server/draw-repository");
        const { syncDrawsToBackup } = await import("@/lib/server/backup-api");
        const recentDraws = await listDraws({ from: dateOnly(from), to: dateOnly(today), limit: 100 });
        if (recentDraws?.draws.length) {
          syncResult = await syncDrawsToBackup(recentDraws.draws);
        }
      } catch (syncError) {
        console.error("Đồng bộ backup thất bại (non-blocking).", syncError);
      }
    }

    // Refresh NumberTrend pre-aggregated table for fast trend queries
    let trendRows = 0;
    try {
      trendRows = await refreshNumberTrends(dateOnly(from), dateOnly(today));
    } catch (trendError) {
      console.error("Refresh NumberTrends thất bại.", trendError);
    }

    const after = await databaseStatus();
    await logDataImport({
      source,
      acceptedRows: imported,
      duplicateRows: 0,
      rejectedRows: 0,
      report: { from: dateOnly(from), to: dateOnly(today), fullSync, removed: removed.count, retentionDays, trendRows },
    });
    await cacheInvalidate("stats:");
    await logAudit({
      action: "MAINTAIN_DATASET",
      entity: "LotteryDraw",
      details: { source, fullSync, imported, removed: removed.count, retentionDays, trendRows },
      ipAddress: getClientIp(request),
    });

    return NextResponse.json({ status: "MAINTAINED", source, fullSync, imported, removed: removed.count, trendRows, backupSync: syncResult, database: after });
  } catch (error) {
    console.error("Cron duy trì dữ liệu thất bại.", error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : "Không thể duy trì dữ liệu." },
      { status: 500 },
    );
  }
}
