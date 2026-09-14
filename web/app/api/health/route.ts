import { NextResponse } from "next/server";
import { SAMPLE_DRAWS } from "@/lib/sample-data";
import { databaseStatus } from "@/lib/server/draw-repository";
import { checkWorkerHealth } from "@/lib/worker-api-client";
import { getPrisma } from "@/lib/server/prisma";

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
  const latestSample = SAMPLE_DRAWS[0];

  const storage: "postgres" | "worker" | "sample" = database?.drawCount
    ? "postgres"
    : worker.reachable
      ? "worker"
      : "sample";

  return NextResponse.json({
    status: "healthy",
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
    trend: {
      numberTrendRows: numberTrendCount,
      ready: numberTrendCount > 0,
    },
    timestamp: new Date().toISOString(),
  });
}
