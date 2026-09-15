import type { LotteryDraw, Region } from "../lottery-domain";
import { domainToNormalized, normalizeDraw, normalizedToDomain } from "./normalized-lottery";

const TIMEOUT_MS = 5_000;

export class BackupApiError extends Error {
  constructor(message: string, readonly retryable: boolean, readonly status?: number) { super(message); }
}

function backupBaseUrl() {
  return process.env.BACKUP_API_URL?.trim().replace(/\/+$/, "") || null;
}

async function backupFetch(path: string, init?: RequestInit) {
  const base = backupBaseUrl();
  if (!base) throw new BackupApiError("BACKUP_API_URL chưa được cấu hình.", false);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const response = await fetch(`${base}${path}`, { ...init, signal: controller.signal, cache: "no-store" });
    if (!response.ok) throw new BackupApiError(`Backup API trả HTTP ${response.status}.`, response.status >= 500, response.status);
    return await response.json();
  } catch (error) {
    if (error instanceof BackupApiError) throw error;
    throw new BackupApiError(error instanceof Error ? error.message : "Backup API không khả dụng.", true);
  } finally { clearTimeout(timeout); }
}

export async function fetchBackupDraws(filters: { region?: Region; from?: string; to?: string; limit: number }) {
  const regionCode = filters.region === "Miền Bắc" ? "XSMB" : filters.region === "Miền Trung" ? "XSMT" : filters.region === "Miền Nam" ? "XSMN" : undefined;
  const params = new URLSearchParams({ limit: String(Math.min(filters.limit, 500)) });
  if (regionCode) params.set("region", regionCode);
  if (filters.from) params.set("from", filters.from);
  if (filters.to) params.set("to", filters.to);
  const body = await backupFetch(`/draws.php?${params}`) as { draws?: unknown[] };
  return (body.draws ?? []).map((draw) => normalizedToDomain(normalizeDraw(draw)));
}

export async function checkBackupHealth() {
  return backupFetch("/health.php") as Promise<Record<string, unknown>>;
}

export async function syncDrawsToBackup(draws: LotteryDraw[]) {
  const syncUrl = process.env.BACKUP_SYNC_URL?.trim();
  const key = process.env.BACKUP_SYNC_API_KEY?.trim();
  if (!syncUrl || !key) throw new BackupApiError("Thiếu cấu hình đồng bộ backup.", false);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10_000);
  try {
    const response = await fetch(syncUrl, {
      method: "POST",
      headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
      body: JSON.stringify({ draws: draws.map(domainToNormalized) }),
      signal: controller.signal,
      cache: "no-store",
    });
    const body = await response.json().catch(() => null);
    if (!response.ok || !body) throw new BackupApiError(`Đồng bộ backup thất bại (HTTP ${response.status}).`, response.status >= 500, response.status);
    return body;
  } finally { clearTimeout(timeout); }
}
