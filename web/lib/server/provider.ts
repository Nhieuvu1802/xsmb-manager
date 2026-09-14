import { z } from "zod";
import type { LotteryDraw } from "../lottery-domain";
import { canonicalStationName } from "../stations";

export const prizeInputSchema = z.object({
  prize: z.string().trim().min(1).max(80),
  position: z.number().int().positive(),
  value: z.string().regex(/^\d{2,6}$/),
});

export const drawInputSchema = z.object({
  drawCode: z.string().trim().min(3).max(100),
  lotteryType: z.enum(["TRADITIONAL", "COMBINATION"]),
  region: z.enum(["Miền Bắc", "Miền Trung", "Miền Nam"]),
  station: z.string().trim().min(2).max(100),
  drawnAt: z.iso.datetime({ offset: true }),
  collectedAt: z.iso.datetime({ offset: true }).optional(),
  source: z.string().url(),
  verification: z.enum(["SAMPLE", "PENDING", "VERIFIED", "REJECTED"]).optional(),
  prizes: z.array(prizeInputSchema).min(1).max(100),
});

export const providerPayloadSchema = z.object({ records: z.array(drawInputSchema).min(1).max(10_000) });

export function providerRecordsToDraws(records: z.infer<typeof drawInputSchema>[]): LotteryDraw[] {
  return records.map((record) => ({
    id: record.drawCode.toLowerCase().replace(/[^a-z0-9-]/g, "-"),
    drawCode: record.drawCode,
    lotteryType: record.lotteryType,
    date: record.drawnAt.slice(0, 10),
    drawnAt: record.drawnAt,
    region: record.region,
    station: canonicalStationName(record.station, record.region),
    source: record.source,
    collectedAt: record.collectedAt ?? new Date().toISOString(),
    verification: record.verification ?? "PENDING",
    results: record.prizes,
  }));
}

export async function fetchLegalProvider(from: string, to: string) {
  const configuredUrl = process.env.LOTTERY_PROVIDER_URL?.trim();
  if (!configuredUrl) return null;

  const url = new URL(configuredUrl);
  url.searchParams.set("from", from);
  url.searchParams.set("to", to);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 25_000);

  try {
    const response = await fetch(url, {
      headers: process.env.LOTTERY_PROVIDER_TOKEN
        ? { Authorization: `Bearer ${process.env.LOTTERY_PROVIDER_TOKEN}` }
        : undefined,
      signal: controller.signal,
      cache: "no-store",
    });
    if (!response.ok) throw new Error(`Nguồn dữ liệu trả HTTP ${response.status}.`);
    return providerPayloadSchema.parse(await response.json());
  } finally {
    clearTimeout(timeout);
  }
}
