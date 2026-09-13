import { cloudflareTest } from "@cloudflare/vitest-pool-workers";
import { defineConfig } from "vitest/config";

// vitest-pool-workers >= 0.22 dùng plugin `cloudflareTest` (thay cho
// `defineWorkersConfig` cũ). Test chạy trong chính runtime của Worker nên hợp
// đồng HTTP được kiểm tra đúng như production (SELF.fetch).
export default defineConfig({
  plugins: [
    cloudflareTest({
      wrangler: { configPath: "./wrangler.jsonc" },
    }),
  ],
  test: {
    include: ["test/**/*.test.ts"],
  },
});
