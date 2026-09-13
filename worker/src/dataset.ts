/**
 * Lớp dữ liệu của Worker.
 *
 * Nguồn dữ liệu là các snapshot công khai đã được collector kiểm định và ghi
 * trong `public-data/` (xsmb/latest.json, xsmn/latest.json, status.json,
 * manifest.json, config.json). Những file này được bundle vào Worker lúc build
 * nên runtime không cần binding, không gọi mạng ngoài và không cần credential.
 */

import configJson from "../../public-data/config.json";
import manifestJson from "../../public-data/manifest.json";
import statusJson from "../../public-data/status.json";
import xsmbLatestJson from "../../public-data/xsmb/latest.json";
import xsmnLatestJson from "../../public-data/xsmn/latest.json";
import type {
  DatasetManifest,
  DatasetStatus,
  Draw,
  LatestSnapshot,
  PublicConfig,
  RegionKey,
} from "./types";

const snapshots: Record<RegionKey, LatestSnapshot> = {
  xsmb: xsmbLatestJson as LatestSnapshot,
  xsmn: xsmnLatestJson as LatestSnapshot,
};

export const PUBLIC_CONFIG = configJson as PublicConfig;
export const MANIFEST = manifestJson as DatasetManifest;
export const STATUS = statusJson as DatasetStatus;

/** Thông tin vùng miền dùng chung cho URL, response và tài liệu. */
export const REGIONS: Record<
  RegionKey,
  { code: string; name: RegionKey; label: string; stationLabel: string }
> = {
  xsmb: {
    code: "mb",
    name: "xsmb",
    label: "Miền Bắc",
    stationLabel: "Hội đồng XSKT miền Bắc",
  },
  xsmn: {
    code: "mn",
    name: "xsmn",
    label: "Miền Nam",
    stationLabel: "Nhiều đài",
  },
};

export function isRegionKey(value: string): value is RegionKey {
  return value === "xsmb" || value === "xsmn";
}

/** Bỏ dấu tiếng Việt để tìm đài không phân biệt hoa/thường và dấu. */
export function normalizeText(value: string): string {
  return value
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .replace(/đ/giu, "d")
    .replace(/\s+/g, " ")
    .trim()
    .toLowerCase();
}

function compareDraws(a: Draw, b: Draw): number {
  if (a.date !== b.date) return a.date < b.date ? 1 : -1;
  return a.station.localeCompare(b.station);
}

/** Toàn bộ kỳ quay của một vùng, mới nhất trước. */
export function allDraws(region: RegionKey): Draw[] {
  return [...snapshots[region].draws].sort(compareDraws);
}

/** Mọi ngày có dữ liệu của một vùng, mới nhất trước. */
export function availableDates(region: RegionKey): string[] {
  const dates = new Set<string>();
  for (const draw of snapshots[region].draws) dates.add(draw.date);
  return [...dates].sort((a, b) => (a < b ? 1 : -1));
}

function filterByStation(draws: Draw[], station: string | null): Draw[] {
  if (!station) return draws;
  const wanted = normalizeText(station);
  return draws.filter((draw) => normalizeText(draw.station) === wanted);
}

export interface DrawSelection {
  /** Ngày mới nhất trong tập kết quả (null nếu không có kỳ nào khớp). */
  date: string | null;
  draws: Draw[];
  /** Danh sách đài hiện có, dùng cho tham số `station`/`province`. */
  stations: string[];
}

/**
 * Các kỳ gần nhất của một vùng, giới hạn theo số ngày (`days`) và tuỳ chọn
 * lọc theo đài.
 */
export function latestDraws(
  region: RegionKey,
  days: number,
  station: string | null = null,
): DrawSelection {
  const ordered = allDraws(region);
  const wanted = new Set(availableDates(region).slice(0, days));
  const selected = filterByStation(
    ordered.filter((draw) => wanted.has(draw.date)),
    station,
  );
  return {
    date: selected.length > 0 ? selected[0]!.date : null,
    draws: selected,
    stations: [...new Set(ordered.map((draw) => draw.station))].sort(),
  };
}

/** Kỳ quay của đúng một ngày. */
export function drawsForDate(
  region: RegionKey,
  date: string,
  station: string | null = null,
): DrawSelection {
  const ordered = allDraws(region);
  const selected = filterByStation(
    ordered.filter((draw) => draw.date === date),
    station,
  );
  return {
    date: selected.length > 0 ? date : null,
    draws: selected,
    stations: [...new Set(ordered.map((draw) => draw.station))].sort(),
  };
}

/** Kỳ quay trong khoảng ngày (bao gồm hai đầu, cho phép bỏ trống một đầu). */
export function drawsInRange(
  region: RegionKey,
  start: string | null,
  end: string | null,
  station: string | null = null,
): DrawSelection {
  const ordered = allDraws(region);
  const selected = filterByStation(
    ordered.filter(
      (draw) =>
        (start === null || draw.date >= start) &&
        (end === null || draw.date <= end),
    ),
    station,
  );
  return {
    date: selected.length > 0 ? selected[0]!.date : null,
    draws: selected,
    stations: [...new Set(ordered.map((draw) => draw.station))].sort(),
  };
}

/* -------------------------------------------------------------------------- */
/* Metadata                                                                    */
/* -------------------------------------------------------------------------- */

export function regionDate(region: RegionKey): string | null {
  const dates = availableDates(region);
  return dates.length > 0 ? dates[0]! : null;
}

/** Ngày mới nhất trong toàn bộ dataset (đối chiếu lại với status.json). */
export function datasetDate(): string | null {
  const computed = [regionDate("xsmb"), regionDate("xsmn")]
    .filter((value): value is string => value !== null)
    .sort()
    .pop();
  return computed ?? STATUS.datasetDate ?? null;
}

export function datasetVersion(): string {
  return STATUS.datasetVersion || MANIFEST.datasetVersion;
}

/** Số giải của mỗi kỳ quay (XSMB 27, mỗi đài XSMN 18). */
export function prizeCount(region: RegionKey): number {
  const first = allDraws(region)[0];
  return first ? first.results.length : 0;
}

/** Snapshot có đủ dữ liệu để phục vụ production hay không. */
export function datasetHealthy(): boolean {
  return (
    regionDate("xsmb") !== null &&
    regionDate("xsmn") !== null &&
    snapshots.xsmb.draws.length > 0 &&
    snapshots.xsmn.draws.length > 0
  );
}
