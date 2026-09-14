/**
 * Trend-optimized database queries.
 * Uses SQL aggregation + NumberTrend pre-computed table for fast analytics.
 */
import type { Region as DatabaseRegion } from "@prisma/client";
import type { NumberStat, Region } from "../lottery-domain";
import { ALL_NUMBERS, lastTwoDigits } from "../statistics";
import { getPrisma } from "./prisma";

const REGION_TO_DB: Record<Region, DatabaseRegion> = {
  "Miền Bắc": "NORTH",
  "Miền Trung": "CENTRAL",
  "Miền Nam": "SOUTH",
};

/* ------------------------------------------------------------------ */
/*  NumberTrend: refresh from raw PrizeResult data                     */
/* ------------------------------------------------------------------ */

/**
 * Rebuild number_trends for draws in a given date range.
 * Called by cron after new draws are imported.
 */
export async function refreshNumberTrends(from: string, to: string) {
  const prisma = getPrisma();
  if (!prisma) return 0;

  const BATCH = 500;
  let offset = 0;
  let totalRows = 0;

  while (true) {
    const draws = await prisma.lotteryDraw.findMany({
      where: {
        drawnAt: {
          gte: new Date(`${from}T00:00:00+07:00`),
          lte: new Date(`${to}T23:59:59+07:00`),
        },
      },
      include: { results: true },
      orderBy: [{ drawnAt: "asc" }, { id: "asc" }],
      take: BATCH,
      skip: offset,
    });

    if (!draws.length) break;

    const trendData: Array<{
      drawId: string;
      drawDate: Date;
      region: DatabaseRegion;
      number: string;
      hitCount: number;
    }> = [];

    for (const draw of draws) {
      const numberCounts = new Map<string, number>();
      for (const result of draw.results) {
        const num = result.lastTwo || lastTwoDigits(result.value);
        numberCounts.set(num, (numberCounts.get(num) ?? 0) + 1);
      }
      // Chỉ lưu các số thực sự xuất hiện. Các số còn lại được suy ra là 0 khi
      // truy vấn, giúp bảng xu hướng nhỏ hơn nhiều trên gói database miễn phí.
      for (const [num, hitCount] of numberCounts) {
        trendData.push({
          drawId: draw.id,
          drawDate: new Date(`${draw.drawnAt.toISOString().slice(0, 10)}T00:00:00Z`),
          region: draw.region,
          number: num,
          hitCount,
        });
      }
    }

    // Một lần xóa + tạo theo lô nhanh hơn hàng chục nghìn câu lệnh upsert.
    // Việc xử lý theo drawId vẫn bảo đảm đồng bộ đúng nếu kết quả được sửa.
    await prisma.numberTrend.deleteMany({
      where: { drawId: { in: draws.map((draw) => draw.id) } },
    });

    for (let i = 0; i < trendData.length; i += 1000) {
      const chunk = trendData.slice(i, i + 1000);
      await prisma.numberTrend.createMany({ data: chunk, skipDuplicates: true });
    }

    totalRows += trendData.length;
    offset += BATCH;
  }

  return totalRows;
}

/**
 * Bulk refresh: rebuild ALL number_trends from scratch.
 * Used on first run or after schema migration.
 */
export async function fullRefreshNumberTrends() {
  const prisma = getPrisma();
  if (!prisma) return 0;

  const first = await prisma.lotteryDraw.findFirst({
    orderBy: [{ drawnAt: "asc" }, { id: "asc" }],
    select: { drawnAt: true },
  });
  const last = await prisma.lotteryDraw.findFirst({
    orderBy: { drawnAt: "desc" },
    select: { drawnAt: true },
  });

  if (!first || !last) return 0;

  const from = first.drawnAt.toISOString().slice(0, 10);
  const to = last.drawnAt.toISOString().slice(0, 10);

  // Clear existing data first
  await prisma.numberTrend.deleteMany();

  return refreshNumberTrends(from, to);
}

/* ------------------------------------------------------------------ */
/*  SQL-aggregated number frequency stats                               */
/* ------------------------------------------------------------------ */

/**
 * Get per-number frequency statistics using SQL aggregation.
 * Much faster than loading all draws into JS.
 */
export async function getNumberFrequencies(
  region: Region,
  from?: string,
  to?: string,
): Promise<{ number: string; count: number; drawHits: number }[]> {
  const prisma = getPrisma();
  if (!prisma) return [];

  const dbRegion = REGION_TO_DB[region];

  // Try NumberTrend table first (fastest path)
  const trendCount = await prisma.numberTrend.count({
    where: { region: dbRegion },
  });

  if (trendCount > 0) {
    const dateFilter: Record<string, Date> = {};
    if (from) dateFilter.gte = new Date(`${from}T00:00:00Z`);
    if (to) dateFilter.lte = new Date(`${to}T23:59:59Z`);

    const rows = await prisma.numberTrend.groupBy({
      by: ["number"],
      where: {
        region: dbRegion,
        ...(Object.keys(dateFilter).length ? { drawDate: dateFilter } : {}),
        hitCount: { gt: 0 },
      },
      _sum: { hitCount: true },
      _count: { id: true },
    });

    return ALL_NUMBERS.map((num) => {
      const match = rows.find((r) => r.number === num);
      return {
        number: num,
        count: Number(match?._sum.hitCount ?? 0),
        drawHits: Number(match?._count.id ?? 0),
      };
    });
  }

  // Fallback: aggregate from raw tables
  type FreqRow = { number: string; count: bigint; draw_hits: bigint };
  const params: unknown[] = [dbRegion];
  const dateClauses: string[] = [];
  let idx = 2;

  if (from) {
    dateClauses.push(`ld.drawn_at >= $${idx}::timestamptz`);
    params.push(new Date(`${from}T00:00:00+07:00`));
    idx++;
  }
  if (to) {
    dateClauses.push(`ld.drawn_at <= $${idx}::timestamptz`);
    params.push(new Date(`${to}T23:59:59+07:00`));
    idx++;
  }

  const dateWhere = dateClauses.length ? `AND ${dateClauses.join(" AND ")}` : "";
  const sql = `
    SELECT pr.last_two AS number, COUNT(*) AS count,
           COUNT(DISTINCT pr.draw_id) AS draw_hits
    FROM prize_results pr
    JOIN lottery_draws ld ON ld.id = pr.draw_id
    WHERE ld.region = $1::"Region" ${dateWhere}
    GROUP BY pr.last_two
  `;

  const results = await prisma.$queryRawUnsafe<FreqRow[]>(sql, ...params);

  return ALL_NUMBERS.map((num) => {
    const match = results.find((r) => r.number === num);
    return {
      number: num,
      count: Number(match?.count ?? 0),
      drawHits: Number(match?.draw_hits ?? 0),
    };
  });
}

function buildDateFilterObject(from?: string, to?: string) {
  const filter: Record<string, unknown> = {};
  if (from || to) {
    const drawnAt: Record<string, Date> = {};
    if (from) drawnAt.gte = new Date(`${from}T00:00:00+07:00`);
    if (to) drawnAt.lte = new Date(`${to}T23:59:59+07:00`);
    filter.drawnAt = drawnAt;
  }
  return filter;
}

/**
 * Full NumberStat[] using SQL for frequency + gap/streak in JS.
 */
export async function getNumberStatsFromDb(
  region: Region,
  from?: string,
  to?: string,
): Promise<NumberStat[] | null> {
  const prisma = getPrisma();
  if (!prisma) return null;

  const frequencies = await getNumberFrequencies(region, from, to);
  if (!frequencies.length) return null;

  const totalSlots = frequencies.reduce((sum, f) => sum + f.count, 0);
  const dbRegion = REGION_TO_DB[region];

  // Ordered draw dates
  const drawDates = await prisma.lotteryDraw.findMany({
    where: { region: dbRegion, ...buildDateFilterObject(from, to) },
    select: { id: true, drawnAt: true },
    orderBy: { drawnAt: "asc" },
  });

  const drawCount = drawDates.length;
  if (!drawCount) return null;

  // Dùng drawId thay vì ngày: miền Nam/Trung có thể có nhiều đài cùng ngày.
  const drawIndexMap = new Map<string, number>();
  drawDates.forEach((draw, index) => drawIndexMap.set(draw.id, index));

  // Get hit draw dates per number
  const numbersWithHits = frequencies.filter((f) => f.drawHits > 0).map((f) => f.number);
  const hitsByNumber = new Map<string, number[]>();

  if (numbersWithHits.length > 0) {
    const trendCount = await prisma.numberTrend.count({ where: { region: dbRegion } });

    if (trendCount > 0) {
      const dateFilter: Record<string, Date> = {};
      if (from) dateFilter.gte = new Date(`${from}T00:00:00Z`);
      if (to) dateFilter.lte = new Date(`${to}T23:59:59Z`);

      const trendRows = await prisma.numberTrend.findMany({
        where: {
          region: dbRegion,
          number: { in: numbersWithHits },
          hitCount: { gt: 0 },
          ...(Object.keys(dateFilter).length ? { drawDate: dateFilter } : {}),
        },
        select: { number: true, drawId: true },
        orderBy: { drawDate: "asc" },
      });

      for (const r of trendRows) {
        const idx = drawIndexMap.get(r.drawId);
        if (idx !== undefined) {
          if (!hitsByNumber.has(r.number)) hitsByNumber.set(r.number, []);
          hitsByNumber.get(r.number)!.push(idx);
        }
      }
      hitsByNumber.forEach((indexes) => indexes.sort((left, right) => left - right));
    }
  }

  return ALL_NUMBERS.map((num) => {
    const freq = frequencies.find((f) => f.number === num)!;
    const hitIndexes = hitsByNumber.get(num) ?? [];
    const expected = totalSlots * 0.01;
    const deviation = Math.sqrt(totalSlots * 0.01 * 0.99);
    const gaps = hitIndexes.slice(1).map((value, index) => value - hitIndexes[index]);

    let currentStreak = 0;
    for (let i = drawCount - 1; i >= 0; i -= 1) {
      if (hitIndexes.includes(i)) {
        if (i === drawCount - 1 || hitIndexes.includes(i + 1)) {
          currentStreak += 1;
        } else { break; }
      } else { break; }
    }

    let longestStreak = 0;
    let tempStreak = 0;
    for (let i = 0; i < hitIndexes.length; i += 1) {
      tempStreak = 1;
      for (let j = i + 1; j < hitIndexes.length; j += 1) {
        if (hitIndexes[j] === hitIndexes[j - 1] + 1) { tempStreak += 1; } else { break; }
      }
      longestStreak = Math.max(longestStreak, tempStreak);
    }

    return {
      number: num,
      count: freq.count,
      drawHits: freq.drawHits,
      rate: totalSlots ? freq.count / totalSlots : 0,
      drawRate: drawCount ? freq.drawHits / drawCount : 0,
      gap: hitIndexes.length ? drawCount - 1 - hitIndexes.at(-1)! : null,
      averageGap: gaps.length ? gaps.reduce((a, b) => a + b, 0) / gaps.length : null,
      zScore: deviation ? (freq.count - expected) / deviation : 0,
      currentStreak,
      longestStreak,
    };
  });
}

/* ------------------------------------------------------------------ */
/*  Trend timeline data (for chart)                                     */
/* ------------------------------------------------------------------ */

export type TrendPoint = {
  date: string;
  label: string;
  hits: number;
};

/**
 * Get trend timeline data for specific numbers over the last N draws.
 * Uses NumberTrend for O(N) query.
 */
export async function getTrendTimeline(
  region: Region,
  trackedNumbers: string[],
  limit = 30,
): Promise<TrendPoint[]> {
  const prisma = getPrisma();
  if (!prisma) return [];

  const dbRegion = REGION_TO_DB[region];

  const draws = await prisma.lotteryDraw.findMany({
    where: { region: dbRegion },
    select: { id: true, drawnAt: true },
    orderBy: { drawnAt: "desc" },
    take: limit,
  });

  if (!draws.length) return [];

  const drawIds = draws.map((d) => d.id);

  const trends = await prisma.numberTrend.findMany({
    where: {
      drawId: { in: drawIds },
      hitCount: { gt: 0 },
      ...(trackedNumbers.length ? { number: { in: trackedNumbers } } : {}),
    },
    select: { drawId: true, hitCount: true },
  });

  const hitsByDraw = new Map<string, number>();
  for (const t of trends) {
    hitsByDraw.set(t.drawId, (hitsByDraw.get(t.drawId) ?? 0) + t.hitCount);
  }

  return draws.reverse().map((draw) => ({
    date: draw.drawnAt.toISOString().slice(0, 10),
    label: new Intl.DateTimeFormat("vi-VN", { day: "2-digit", month: "2-digit" }).format(draw.drawnAt),
    hits: hitsByDraw.get(draw.id) ?? 0,
  }));
}
