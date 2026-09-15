import { createHash } from "node:crypto";
import { z } from "zod";
import type { LotteryDraw, Region } from "../lottery-domain";

const REGION_CODES = ["XSMB", "XSMT", "XSMN"] as const;
const PRIZES = /^(DB|G[1-8]|GDB|SPECIAL)$/i;

export const normalizedResultSchema = z.object({
  prize: z.string().trim().regex(PRIZES).transform((value) => value.toUpperCase()),
  numbers: z.array(z.string().regex(/^\d{2,6}$/)).min(1).max(30),
});

export const normalizedDrawSchema = z.object({
  region: z.enum(REGION_CODES),
  province: z.string().trim().min(2).max(100).regex(/^[\p{L}\d -]+$/u),
  draw_date: z.iso.date(),
  results: z.array(normalizedResultSchema).min(1).max(12),
  source: z.string().trim().min(1).max(255),
  fetched_at: z.iso.datetime({ offset: true }),
  checksum: z.string().regex(/^[a-f0-9]{64}$/).optional(),
});

export type NormalizedDraw = z.infer<typeof normalizedDrawSchema> & { checksum: string };

function canonicalResults(results: z.infer<typeof normalizedResultSchema>[]) {
  return results
    .map((result) => ({ prize: result.prize.toUpperCase(), numbers: [...result.numbers] }))
    .sort((left, right) => left.prize.localeCompare(right.prize));
}

export function checksumDraw(input: Omit<NormalizedDraw, "checksum"> | z.input<typeof normalizedDrawSchema>) {
  const parsed = normalizedDrawSchema.omit({ checksum: true }).parse(input);
  return createHash("sha256")
    .update(JSON.stringify({
      region: parsed.region,
      province: parsed.province.toLowerCase(),
      draw_date: parsed.draw_date,
      results: canonicalResults(parsed.results),
    }))
    .digest("hex");
}

export function normalizeDraw(input: unknown): NormalizedDraw {
  const parsed = normalizedDrawSchema.parse(input);
  const checksum = checksumDraw(parsed);
  if (parsed.checksum && parsed.checksum !== checksum) throw new Error("Checksum dữ liệu không hợp lệ.");
  return { ...parsed, results: canonicalResults(parsed.results), checksum };
}

export const syncPayloadSchema = z.union([
  normalizedDrawSchema.transform((draw) => ({ draws: [draw] })),
  z.object({ draws: z.array(normalizedDrawSchema).min(1).max(50) }),
]);

const REGION_TO_CODE: Record<Region, (typeof REGION_CODES)[number]> = {
  "Miền Bắc": "XSMB",
  "Miền Trung": "XSMT",
  "Miền Nam": "XSMN",
};

const CODE_TO_REGION: Record<(typeof REGION_CODES)[number], Region> = {
  XSMB: "Miền Bắc",
  XSMT: "Miền Trung",
  XSMN: "Miền Nam",
};

export function domainToNormalized(draw: LotteryDraw): NormalizedDraw {
  const grouped = new Map<string, string[]>();
  for (const result of draw.results) grouped.set(result.prize, [...(grouped.get(result.prize) ?? []), result.value]);
  return normalizeDraw({
    region: REGION_TO_CODE[draw.region],
    province: draw.station,
    draw_date: draw.date,
    results: [...grouped].map(([prize, numbers]) => ({ prize, numbers })),
    source: draw.source,
    fetched_at: draw.collectedAt,
  });
}

export function normalizedToDomain(draw: NormalizedDraw): LotteryDraw {
  return {
    id: `backup-${draw.region}-${draw.province}-${draw.draw_date}`,
    drawCode: `${draw.region}-${draw.province}-${draw.draw_date}`,
    lotteryType: "TRADITIONAL",
    date: draw.draw_date,
    drawnAt: `${draw.draw_date}T${draw.region === "XSMB" ? "18:15" : draw.region === "XSMT" ? "17:15" : "16:15"}:00+07:00`,
    region: CODE_TO_REGION[draw.region],
    station: draw.province,
    source: draw.source,
    collectedAt: draw.fetched_at,
    verification: "VERIFIED",
    results: draw.results.flatMap((result) => result.numbers.map((value, index) => ({ prize: result.prize, position: index + 1, value }))),
  };
}
