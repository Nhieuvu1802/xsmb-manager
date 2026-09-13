import type { LotteryDraw, PrizeResult } from "./lottery-domain";

const PRIZES: Array<[string, number, number]> = [
  ["Đặc biệt", 1, 5],
  ["Giải nhất", 1, 5],
  ["Giải nhì", 2, 5],
  ["Giải ba", 6, 5],
  ["Giải tư", 4, 4],
  ["Giải năm", 6, 4],
  ["Giải sáu", 3, 3],
  ["Giải bảy", 4, 2],
];

function mulberry32(seed: number) {
  return () => {
    seed |= 0;
    seed = (seed + 0x6d2b79f5) | 0;
    let value = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    value = (value + Math.imul(value ^ (value >>> 7), 61 | value)) ^ value;
    return ((value ^ (value >>> 14)) >>> 0) / 4294967296;
  };
}

function formatDate(date: Date) {
  return date.toISOString().slice(0, 10);
}

function makeResults(seed: number): PrizeResult[] {
  const random = mulberry32(seed);
  return PRIZES.flatMap(([prize, count, digits]) =>
    Array.from({ length: count }, (_, index) => ({
      prize,
      position: index + 1,
      value: Math.floor(random() * 10 ** digits)
        .toString()
        .padStart(digits, "0"),
    })),
  );
}

export function createSampleDraws(days = 122): LotteryDraw[] {
  const end = new Date("2026-09-12T00:00:00.000Z");

  return Array.from({ length: days }, (_, index) => {
    const date = new Date(end);
    date.setUTCDate(end.getUTCDate() - index);
    const dateString = formatDate(date);
    return {
      id: `mb-${dateString}`,
      drawCode: `MB-${dateString.replaceAll("-", "")}`,
      lotteryType: "TRADITIONAL" as const,
      date: dateString,
      drawnAt: `${dateString}T18:15:00+07:00`,
      region: "Miền Bắc" as const,
      station: "Hội đồng XSKT miền Bắc",
      source: "Dữ liệu mô phỏng có seed cố định",
      collectedAt: `${dateString}T20:10:00+07:00`,
      verification: "SAMPLE" as const,
      results: makeResults(20260912 - index * 7919),
    };
  });
}

export const SAMPLE_DRAWS = createSampleDraws(365);
