/**
 * Kiểu dữ liệu công khai của Worker API v1.
 *
 * Toàn bộ tên trường ở đây khớp với `backend/xsmb_manager/api/schemas.py`
 * (DrawListResponse / DrawRead / PrizeRead / HealthResponse) để app Flutter và
 * website đọc được cùng một hợp đồng dù dữ liệu đến từ FastAPI hay Worker.
 */

/** Vùng dữ liệu có snapshot tĩnh (miền Trung chưa có dữ liệu). */
export type RegionKey = "xsmb" | "xsmn";

/** Biến môi trường công khai trong wrangler.jsonc (không chứa bí mật). */
export interface Env {
  /** Phiên bản API công bố trong mọi response, mặc định `v1`. */
  API_VERSION: string;
  /** `*` hoặc danh sách origin cách nhau bằng dấu phẩy. */
  ALLOWED_ORIGINS: string;
  /** Nhãn môi trường để đưa vào /v1/health. */
  ENVIRONMENT?: string;
}

/** Một giải trong kỳ quay (`PrizeRead`). */
export interface Prize {
  prize: string;
  position: number;
  value: string;
}

/** Một kỳ quay hoàn chỉnh của một đài (`DrawRead`). */
export interface Draw {
  region: string;
  date: string;
  station: string;
  source: string;
  verification?: string;
  collected_at?: string | null;
  draw_code?: string;
  results: Prize[];
}

/** Payload snapshot trong `public-data/xsmb/latest.json` và `.../xsmn/latest.json`. */
export interface LatestSnapshot {
  success: boolean;
  source: string;
  region: RegionKey;
  date: string | null;
  updatedAt: string;
  count: number;
  draws: Draw[];
}

/** `public-data/status.json` (và `status/health.json`). */
export interface DatasetStatus {
  status: string;
  datasetDate: string | null;
  datasetVersion: string;
  apiVersion: string;
  generatedAt: string;
}

/** `public-data/manifest.json`. */
export interface DatasetManifest {
  schemaVersion: number;
  generatedAt: string;
  xsmbLatestDate: string | null;
  xsmnLatestDate: string | null;
  datasetVersion: string;
  files: Record<string, { sha256: string; bytes: number }>;
}

/** `public-data/config.json`. */
export interface PublicConfig {
  apiBaseUrl: string;
  apiVersion: string;
  fallbackDataUrl: string;
  maintenance: boolean;
  minimumAppVersion: string;
  githubFallbackEnabled: boolean;
}
