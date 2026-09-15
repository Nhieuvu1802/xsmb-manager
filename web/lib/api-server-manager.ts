export type ApiResult<T> = { data: T; source: "primary" | "backup" | "cache"; stale: boolean };

export class ApiServerManager<T> {
  constructor(
    private readonly primaryUrl: string,
    private readonly backupUrl: string | undefined,
    private readonly readCache: () => T | null,
    private readonly writeCache: (value: T) => void,
    private readonly timeoutMs = 5_000,
    private readonly fetcher: typeof fetch = fetch,
  ) {}

  private async request(url: string): Promise<T> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);
    try {
      const response = await this.fetcher(url, { signal: controller.signal });
      if (!response.ok) {
        const error = new Error(`HTTP ${response.status}`) as Error & { failover?: boolean };
        error.failover = response.status >= 500;
        throw error;
      }
      return await response.json() as T;
    } finally { clearTimeout(timer); }
  }

  async get(path: string): Promise<ApiResult<T>> {
    try {
      const data = await this.request(`${this.primaryUrl.replace(/\/$/, "")}/${path.replace(/^\//, "")}`);
      this.writeCache(data); return { data, source: "primary", stale: false };
    } catch (error) {
      if ((error as Error & { failover?: boolean }).failover === false) throw error;
    }
    if (this.backupUrl) {
      try {
        const data = await this.request(`${this.backupUrl.replace(/\/$/, "")}/${path.replace(/^\//, "")}`);
        this.writeCache(data); return { data, source: "backup", stale: false };
      } catch (error) {
        if ((error as Error & { failover?: boolean }).failover === false) throw error;
      }
    }
    const cached = this.readCache();
    if (cached !== null) return { data: cached, source: "cache", stale: true };
    throw new Error("Primary, backup and local cache are unavailable.");
  }
}
