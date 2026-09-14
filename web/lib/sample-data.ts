import type { LotteryDraw, PrizeResult, Region } from "./lottery-domain";
import { stationsForDrawDate } from "./stations";

const NORTHERN_PRIZES: Array<[string, number, number]> = [
  ["Đặc biệt", 1, 5],
  ["Giải nhất", 1, 5],
  ["Giải nhì", 2, 5],
  ["Giải ba", 6, 5],
  ["Giải tư", 4, 4],
  ["Giải năm", 6, 4],
  ["Giải sáu", 3, 3],
  ["Giải bảy", 4, 2],
];

const CENTRAL_SOUTHERN_PRIZES: Array<[string, number, number]> = [
  ["Đặc biệt", 1, 6],
  ["Giải nhất", 1, 5],
  ["Giải nhì", 1, 5],
  ["Giải ba", 2, 5],
  ["Giải tư", 7, 5],
  ["Giải năm", 1, 4],
  ["Giải sáu", 3, 4],
  ["Giải bảy", 1, 3],
  ["Giải tám", 1, 2],
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

function hashSeed(value: string) {
  let hash = 2166136261;
  for (let index = 0; index < value.length; index += 1) {
    hash ^= value.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

function makeResults(seed: number, region: Region): PrizeResult[] {
  const random = mulberry32(seed);
  const prizes = region === "Miền Bắc" ? NORTHERN_PRIZES : CENTRAL_SOUTHERN_PRIZES;
  return prizes.flatMap(([prize, count, digits]) =>
    Array.from({ length: count }, (_, index) => ({
      prize,
      position: index + 1,
      value: Math.floor(random() * 10 ** digits)
        .toString()
        .padStart(digits, "0"),
    })),
  );
}

function makeDraw(date: Date, region: Region, station: string, stationCode: string): LotteryDraw {
  const dateString = formatDate(date);
  const regionCode = region === "Miền Bắc" ? "MB" : region === "Miền Trung" ? "MT" : "MN";
  const drawTime = region === "Miền Bắc" ? "18:15" : region === "Miền Trung" ? "17:15" : "16:15";
  const drawCode = `${regionCode}-${stationCode}-${dateString.replaceAll("-", "")}`;

  return {
    id: drawCode.toLowerCase(),
    drawCode,
    lotteryType: "TRADITIONAL",
    date: dateString,
    drawnAt: `${dateString}T${drawTime}:00+07:00`,
    region,
    station,
    source: "Dữ liệu mô phỏng minh bạch · seed theo ngày và đài",
    collectedAt: `${dateString}T20:10:00+07:00`,
    verification: "SAMPLE",
    results: makeResults(hashSeed(drawCode), region),
  };
}

function yesterdayUtc() {
  const date = new Date();
  date.setUTCHours(0, 0, 0, 0);
  date.setUTCDate(date.getUTCDate() - 1);
  return date;
}

export function createSampleDraws(days = 365, regions: Region[] = ["Miền Bắc", "Miền Trung", "Miền Nam"]): LotteryDraw[] {
  const end = yesterdayUtc();
  const draws: LotteryDraw[] = [];

  for (let dayOffset = 0; dayOffset < days; dayOffset += 1) {
    const date = new Date(end);
    date.setUTCDate(end.getUTCDate() - dayOffset);

    for (const region of regions) {
      for (const station of stationsForDrawDate(region, date)) {
        draws.push(makeDraw(date, region, station.name, station.code));
      }
    }
  }

  return draws.sort((left, right) =>
    right.date.localeCompare(left.date) || left.region.localeCompare(right.region) || left.station.localeCompare(right.station),
  );
}

export const SAMPLE_DRAWS = createSampleDraws(365);

// Keep first paint light; the client replaces this slice with API/PostgreSQL data after hydration.
export const CLIENT_SAMPLE_DRAWS = createSampleDraws(90, ["Miền Bắc"]);
