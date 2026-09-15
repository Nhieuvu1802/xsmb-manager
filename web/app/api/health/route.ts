import { NextResponse } from "next/server";
import { SAMPLE_DRAWS } from "@/lib/sample-data";
import { databaseStatus } from "@/lib/server/draw-repository";
import { checkWorkerHealth } from "@/lib/worker-api-client";
import { getPrisma } from "@/lib/server/prisma";
import { checkBackupHealth } from "@/lib/server/backup-api";
import { buildProviderChain } from "@/lib/server/providers";

export async function GET() {
  let database = null;
  try {
    database = await databaseStatus();
  } catch (error) {
    console.error("Không kiểm tra được PostgreSQL.", error);
  }

  // Count NumberTrend rows for trend optimization status
  let numberTrendCount = 0;
  try {
    const prisma = getPrisma();
    if (prisma) {
      numberTrendCount = await prisma.numberTrend.count();
    }
  } catch (error) {
    console.error("Không kiểm tra được NumberTrends.", error);
  }

  const worker = await checkWorkerHealth();
  let backup: Record<string, unknown> | null = null;
  try { backup = await checkBackupHealth(); } catch { /* optional backup */ }
  const latestSample = SAMPLE_DRAWS[0];

  const storage: "postgres" | "worker" | "sample" = database?.drawCount
    ? "postgres"
    : worker.reachable
      ? "worker"
      : "sample";
  const providerHealth = buildProviderChain().getHealthScores();


  return NextResponse.json({
    status: "online",
    database: database ? "online" : "offline",
    last_sync: database?.newest?.collectedAt.toISOString() ?? null,
    last_data: database?.newest?.drawnAt.toISOString() ?? null,
    version: "3.3.0",
    storage,
    drawCount: database?.drawCount || (worker.reachable ? (worker.xsmbDraws ?? 0) + (worker.xsmnDraws ?? 0) : SAMPLE_DRAWS.length),
    lastUpdate: database?.newest?.collectedAt.toISOString() ?? latestSample?.collectedAt ?? null,
    oldestDraw: database?.oldest?.drawnAt.toISOString() ?? SAMPLE_DRAWS.at(-1)?.drawnAt ?? null,
    worker: {
      reachable: worker.reachable,
      xsmbDraws: worker.xsmbDraws ?? null,
      xsmnDraws: worker.xsmnDraws ?? null,
    },
    backup: { reachable: backup?.status === "online", ...backup },
    providers: providerHealth.map((h) => ({
      code: h.code,
      name: h.name,
      score: h.score,
      healthy: h.healthy,
      successCount: h.successCount,
      failureCount: h.failureCount,
      averageResponseTime: Math.round(h.averageResponseTimeMs),
    })),
    trend: {
      numberTrendRows: numberTrendCount,
      ready: numberTrendCount > 0,
    },
    timestamp: new Date().toISOString(),
  });
}
