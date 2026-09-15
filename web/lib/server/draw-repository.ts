import type { LotteryType, Prisma, Region as DatabaseRegion, VerificationStatus } from "@prisma/client";
import type { LotteryDraw, Region } from "../lottery-domain";
import { getPrisma } from "./prisma";

const REGION_TO_DATABASE: Record<Region, DatabaseRegion> = {
  "Miền Bắc": "NORTH",
  "Miền Trung": "CENTRAL",
  "Miền Nam": "SOUTH",
};

const DATABASE_TO_REGION: Record<DatabaseRegion, Region> = {
  NORTH: "Miền Bắc",
  CENTRAL: "Miền Trung",
  SOUTH: "Miền Nam",
};

export type DrawFilters = {
  region?: Region;
  lotteryType?: LotteryDraw["lotteryType"];
  station?: string;
  from?: string;
  to?: string;
  limit?: number;
  offset?: number;
};

function toDomainDraw(draw: Prisma.LotteryDrawGetPayload<{ include: { results: true } }>): LotteryDraw {
  return {
    id: draw.id,
    drawCode: draw.drawCode,
    lotteryType: draw.lotteryType,
    date: draw.drawnAt.toISOString().slice(0, 10),
    drawnAt: draw.drawnAt.toISOString(),
    region: DATABASE_TO_REGION[draw.region],
    station: draw.station,
    source: draw.sourceUrl,
    collectedAt: draw.collectedAt.toISOString(),
    verification: draw.verification,
    results: draw.results
      .sort((left, right) => left.position - right.position)
      .map((result) => ({ prize: result.prize, position: result.position, value: result.value })),
  };
}

export async function listStoredDraws(filters: DrawFilters) {
  const prisma = getPrisma();
  if (!prisma) return null;

  const where: Prisma.LotteryDrawWhereInput = {};
  if (filters.region) where.region = REGION_TO_DATABASE[filters.region];
  if (filters.lotteryType) where.lotteryType = filters.lotteryType;
  if (filters.station) where.station = { contains: filters.station, mode: "insensitive" };
  if (filters.from || filters.to) {
    where.drawnAt = {
      ...(filters.from ? { gte: new Date(`${filters.from}T00:00:00+07:00`) } : {}),
      ...(filters.to ? { lte: new Date(`${filters.to}T23:59:59+07:00`) } : {}),
    };
  }

  const [rows, total] = await prisma.$transaction([
    prisma.lotteryDraw.findMany({
      where,
      include: { results: true },
      orderBy: [{ drawnAt: "desc" }, { station: "asc" }],
      take: Math.min(Math.max(filters.limit ?? 100, 1), 5000),
      skip: Math.max(filters.offset ?? 0, 0),
    }),
    prisma.lotteryDraw.count({ where }),
  ]);

  return { draws: rows.map(toDomainDraw), total };
}

function createDrawData(draw: LotteryDraw) {
  return {
    drawCode: draw.drawCode,
    lotteryType: draw.lotteryType as LotteryType,
    region: REGION_TO_DATABASE[draw.region],
    station: draw.station,
    drawnAt: new Date(draw.drawnAt),
    sourceUrl: draw.source,
    collectedAt: new Date(draw.collectedAt),
    verification: draw.verification as VerificationStatus,
  };
}

export async function upsertDraws(draws: LotteryDraw[]) {
  const prisma = getPrisma();
  if (!prisma) throw new Error("DATABASE_URL chưa được cấu hình.");

  let processed = 0;
  for (let offset = 0; offset < draws.length; offset += 40) {
    const chunk = draws.slice(offset, offset + 40);
    await prisma.$transaction(
      chunk.map((draw) =>
        prisma.lotteryDraw.upsert({
          where: { drawCode: draw.drawCode },
          create: {
            ...createDrawData(draw),
            results: {
              create: draw.results.map((result) => ({
                ...result,
                lastTwo: result.value.slice(-2).padStart(2, "0"),
              })),
            },
          },
          update: {
            ...createDrawData(draw),
            results: {
              deleteMany: {},
              create: draw.results.map((result) => ({
                ...result,
                lastTwo: result.value.slice(-2).padStart(2, "0"),
              })),
            },
          },
        }),
      ),
    );
    processed += chunk.length;
  }
  return processed;
}

export async function insertMissingDraws(draws: LotteryDraw[]) {
  const prisma = getPrisma();
  if (!prisma) throw new Error("DATABASE_URL chưa được cấu hình.");

  let inserted = 0;
  for (let offset = 0; offset < draws.length; offset += 150) {
    const chunk = draws.slice(offset, offset + 150);
    const created = await prisma.lotteryDraw.createMany({
      data: chunk.map(createDrawData),
      skipDuplicates: true,
    });
    inserted += created.count;

    const identifiers = await prisma.lotteryDraw.findMany({
      where: { drawCode: { in: chunk.map((draw) => draw.drawCode) } },
      select: { id: true, drawCode: true },
    });
    const idByCode = new Map(identifiers.map((draw) => [draw.drawCode, draw.id]));
    await prisma.prizeResult.createMany({
      data: chunk.flatMap((draw) => {
        const drawId = idByCode.get(draw.drawCode);
        if (!drawId) return [];
        return draw.results.map((result) => ({
          drawId,
          prize: result.prize,
          position: result.position,
          value: result.value,
          lastTwo: result.value.slice(-2).padStart(2, "0"),
        }));
      }),
      skipDuplicates: true,
    });
  }
  return inserted;
}

export async function pruneOldDraws(retentionDays = 370) {
  const prisma = getPrisma();
  if (!prisma) throw new Error("DATABASE_URL chưa được cấu hình.");
  const threshold = new Date();
  threshold.setUTCDate(threshold.getUTCDate() - retentionDays);
  return prisma.lotteryDraw.deleteMany({ where: { drawnAt: { lt: threshold } } });
}

export async function databaseStatus() {
  const prisma = getPrisma();
  if (!prisma) return null;
  const [drawCount, newest, oldest] = await prisma.$transaction([
    prisma.lotteryDraw.count(),
    prisma.lotteryDraw.findFirst({ orderBy: { drawnAt: "desc" }, select: { drawnAt: true, collectedAt: true } }),
    prisma.lotteryDraw.findFirst({ orderBy: { drawnAt: "asc" }, select: { drawnAt: true } }),
  ]);
  return { drawCount, newest, oldest };
}

export async function logDataImport(input: {
  source: string;
  acceptedRows: number;
  duplicateRows: number;
  rejectedRows: number;
  report: Prisma.InputJsonValue;
}) {
  const prisma = getPrisma();
  if (!prisma) return null;
  return prisma.dataImport.create({ data: input });
}

export async function logAudit(input: {
  action: string;
  entity: string;
  entityId?: string;
  details?: Prisma.InputJsonValue;
  ipAddress?: string;
}) {
  const prisma = getPrisma();
  if (!prisma) return null;
  try {
    return await prisma.auditLog.create({ data: input });
  } catch (error) {
    // Auditing must never turn an already successful import/maintenance action
    // into a failed HTTP response. Sentry/server logs still retain the failure.
    console.error("Không thể ghi audit log.", error);
    return null;
  }
}
