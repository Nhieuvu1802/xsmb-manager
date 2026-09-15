import { describe, expect, it } from "vitest";
import { checksumDraw, normalizeDraw } from "../lib/server/normalized-lottery";

const valid = { region: "XSMB" as const, province: "mien-bac", draw_date: "2026-09-15", results: [{ prize: "DB", numbers: ["12345"] }], source: "licensed-api", fetched_at: "2026-09-15T12:00:00Z" };

describe("normalized lottery schema", () => {
  it("creates a stable checksum", () => expect(checksumDraw(valid)).toBe(checksumDraw({ ...valid })));
  it("rejects invalid data and HTML", () => {
    expect(() => normalizeDraw({ ...valid, province: "<script>x</script>" })).toThrow();
    expect(() => normalizeDraw({ ...valid, results: [{ prize: "DB", numbers: ["bad"] }] })).toThrow();
  });
  it("rejects a mismatched checksum", () => expect(() => normalizeDraw({ ...valid, checksum: "0".repeat(64) })).toThrow(/Checksum/));
});
