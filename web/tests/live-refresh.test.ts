import { describe, expect, it } from "vitest";
import { liveRefreshInterval } from "../lib/live-refresh";

describe("adaptive live refresh", () => {
  it("polls every 45 seconds while draws are running", () => {
    expect(liveRefreshInterval(new Date("2026-09-15T10:30:00Z"))).toBe(45_000);
  });
  it("backs off to 30 minutes outside draw hours", () => {
    expect(liveRefreshInterval(new Date("2026-09-15T02:00:00Z"))).toBe(1_800_000);
  });
});
