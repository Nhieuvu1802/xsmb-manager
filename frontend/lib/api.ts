export type LotteryResult = {
  draw_date: string;
  prize: string;
  position: number;
  full_number: string;
  loto2: string;
};

export type SyncResponse = { saved: number; errors: string[] };

const API_URL = (process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000").replace(/\/$/, "");

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`${API_URL}${path}`, init);
  if (!response.ok) {
    const payload = await response.json().catch(() => null);
    throw new Error(payload?.detail ?? `API trả về lỗi ${response.status}`);
  }
  return response.json() as Promise<T>;
}

export function getResults(start?: string, end?: string) {
  const query = new URLSearchParams();
  if (start) query.set("start", start);
  if (end) query.set("end", end);
  return request<LotteryResult[]>(`/api/v1/draws/mb?${query}`);
}

export async function login(username: string, password: string) {
  const body = new URLSearchParams({ username, password });
  return request<{ access_token: string; token_type: string }>("/api/v1/auth/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body
  });
}

export function syncMb(start_date: string, end_date: string, token: string) {
  return request<SyncResponse>("/api/v1/sync/mb", {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
    body: JSON.stringify({ start_date, end_date })
  });
}
