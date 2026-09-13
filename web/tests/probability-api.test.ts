import { describe, expect, it } from "vitest";
import { GET } from "../app/api/probability/route";

describe("GET /api/probability", () => {
  it("trả kết quả hợp lệ", async () => {
    const response = await GET(new Request("http://localhost/api/probability?digits=2&selections=1&slots=27"));
    const body = await response.json();
    expect(response.status).toBe(200);
    expect(body.outcomes).toBe(100);
    expect(body.atLeastOne).toBeCloseTo(1 - 0.99 ** 27, 12);
  });

  it("từ chối tham số ngoài phạm vi", async () => {
    const response = await GET(new Request("http://localhost/api/probability?digits=9"));
    expect(response.status).toBe(422);
  });
});

