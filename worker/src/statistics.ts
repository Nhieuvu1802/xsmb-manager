/**
 * Statistics Engine — thong ke 00-99 tu du lieu lottery draws.
 * Chay tren Worker runtime, khong phu thuoc Node.js APIs.
 * statisticalScore = 0-100, KHONG phai xac suat.
 */
import type { Draw, NumberStatistics } from "./types";

const ALL_NUMBERS = Array.from({ length: 100 }, (_, i) =>
  i.toString().padStart(2, "0"),
);

function lastTwo(value: string): string {
  return value.slice(-2).padStart(2, "0");
}

function median(values: number[]): number {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 !== 0 ? sorted[mid]! : (sorted[mid - 1]! + sorted[mid]!) / 2;
}

function stdDevCalc(values: number[], mean: number): number {
  if (values.length === 0) return 0;
  const variance = values.reduce((sum, v) => sum + (v - mean) ** 2, 0) / values.length;
  return Math.sqrt(variance);
}

function normalize(value: number, min: number, max: number): number {
  if (max === min) return 50;
  return Math.max(0, Math.min(100, ((value - min) / (max - min)) * 100));
}

export function calculateStatistics(draws: Draw[], region: string) {
  const totalDraws = draws.length;
  const drawHitMaps: Map<string, number>[] = draws.map((draw) => {
    const hits = new Map<string, number>();
    for (const result of draw.results) {
      const num = lastTwo(result.value);
      hits.set(num, (hits.get(num) ?? 0) + 1);
    }
    return hits;
  });
  const totalSlots = draws.reduce((sum, d) => sum + d.results.length, 0);

  const numberStats: NumberStatistics[] = ALL_NUMBERS.map((number) => {
    const hitIndexes: number[] = [];
    let totalHits = 0;
    for (let i = 0; i < drawHitMaps.length; i++) {
      const hits = drawHitMaps[i]!.get(number) ?? 0;
      if (hits > 0) { hitIndexes.push(i); totalHits += hits; }
    }
    const freq = (window: number) => {
      const subset = drawHitMaps.slice(0, Math.min(window, drawHitMaps.length));
      let count = 0;
      for (const map of subset) count += map.get(number) ?? 0;
      return count;
    };
    const gaps = hitIndexes.slice(1).map((v, i) => v - hitIndexes[i]!);
    const gapCurrent = hitIndexes.length > 0 ? hitIndexes[0]! : null;
    const gapAverage = gaps.length > 0 ? gaps.reduce((a, b) => a + b, 0) / gaps.length : null;
    const gapMedianVal = gaps.length > 0 ? median(gaps) : null;
    const gapStdDevVal = gaps.length > 0 && gapAverage !== null ? stdDevCalc(gaps, gapAverage) : null;
    const gapMax = gaps.length > 0 ? Math.max(...gaps) : null;
    const countIn = (subset: Map<string, number>[]) => subset.reduce((s, m) => s + (m.get(number) ?? 0), 0);
    const baseRate = totalDraws > 0 ? totalHits / totalDraws : 0.01;
    const shortTrend = countIn(drawHitMaps.slice(0, 20)) / Math.max(1, Math.min(20, totalDraws)) / baseRate;
    const mediumTrend = countIn(drawHitMaps.slice(0, 30)) / Math.max(1, Math.min(30, totalDraws)) / baseRate;
    const longTrend = countIn(drawHitMaps.slice(0, 90)) / Math.max(1, Math.min(90, totalDraws)) / baseRate;
    let recency = 0;
    for (let i = 0; i < Math.min(90, drawHitMaps.length); i++) {
      if (drawHitMaps[i]!.has(number)) recency += Math.exp(-i / 20);
    }
    return {
      number, appearanceCount: totalHits,
      drawOccurrenceRate: totalDraws > 0 ? hitIndexes.length / totalDraws : 0,
      frequency5: freq(5), frequency10: freq(10), frequency20: freq(20),
      frequency30: freq(30), frequency60: freq(60), frequency90: freq(90),
      gapCurrent, gapAverage, gapMedian: gapMedianVal, gapStdDev: gapStdDevVal, gapMax,
      recency, statisticalScore: 0, shortTrend, mediumTrend, longTrend,
    };
  });

  const maxFreq90 = Math.max(...numberStats.map((s) => s.frequency90), 1);
  const maxRecency = Math.max(...numberStats.map((s) => s.recency), 1);
  const maxGapCurrent = Math.max(...numberStats.map((s) => s.gapCurrent ?? 0), 1);
  for (const stat of numberStats) {
    const w = { frequency: 0.25, recency: 0.25, gap: 0.20, momentum: 0.15, stability: 0.15 };
    const score =
      w.frequency * normalize(stat.frequency90, 0, maxFreq90) +
      w.recency * normalize(stat.recency, 0, maxRecency) +
      w.gap * normalize(stat.gapCurrent ?? 0, 0, maxGapCurrent) +
      w.momentum * normalize(stat.shortTrend, 0, 2) +
      w.stability * normalize(stat.mediumTrend, 0, 2);
    stat.statisticalScore = Math.round(Math.max(0, Math.min(100, score)) * 10) / 10;
  }
  return {
    datasetVersion: "", statisticsVersion: `stats-${region}-${totalDraws}`,
    generatedAt: new Date().toISOString(), region, totalDraws, numbers: numberStats,
  };
}

export function generateTop4(
  stats: NumberStatistics[], drawDate: string, datasetVersion: string, modelVersion: string,
) {
  const top4 = [...stats]
    .sort((a, b) => b.statisticalScore - a.statisticalScore)
    .slice(0, 4)
    .map((s) => ({
      number: s.number, statisticalScore: s.statisticalScore,
      features: {
        frequency90: Math.round(s.frequency90 * 1000) / 1000,
        gapCurrent: s.gapCurrent,
        shortTrend: Math.round(s.shortTrend * 100) / 100,
      },
    }));
  return { drawDate, modelVersion, datasetVersion, generatedAt: new Date().toISOString(), numbers: top4 };
}
