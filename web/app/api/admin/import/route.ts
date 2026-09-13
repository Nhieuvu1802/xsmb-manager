import { NextResponse } from "next/server";
import { z } from "zod";

const prizeSchema = z.object({
  prize: z.string().trim().min(1).max(80),
  position: z.number().int().positive(),
  value: z.string().regex(/^\d{2,6}$/),
});

const drawSchema = z.object({
  drawCode: z.string().trim().min(3).max(100),
  lotteryType: z.enum(["TRADITIONAL", "COMBINATION"]),
  region: z.enum(["Miền Bắc", "Miền Trung", "Miền Nam"]),
  station: z.string().trim().min(2).max(100),
  drawnAt: z.iso.datetime({ offset: true }),
  source: z.string().url(),
  prizes: z.array(prizeSchema).min(1).max(100),
});

const importSchema = z.object({ records: z.array(drawSchema).min(1).max(500) });

export async function POST(request: Request) {
  const configuredKey = process.env.ADMIN_API_KEY;
  const suppliedKey = request.headers.get("authorization")?.replace(/^Bearer\s+/i, "");
  if (!configuredKey || suppliedKey !== configuredKey) {
    return NextResponse.json({ error: "Không có quyền nhập dữ liệu." }, { status: 401 });
  }

  const body = await request.json().catch(() => null);
  const parsed = importSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: "Dữ liệu không hợp lệ", details: z.flattenError(parsed.error) }, { status: 422 });
  }

  const seen = new Set<string>();
  const duplicates: string[] = [];
  parsed.data.records.forEach((record) => {
    if (seen.has(record.drawCode)) duplicates.push(record.drawCode);
    seen.add(record.drawCode);
  });

  return NextResponse.json({
    accepted: parsed.data.records.length - duplicates.length,
    duplicates,
    status: "VALIDATED",
    note: "Endpoint MVP chỉ kiểm định. Bật PostgreSQL/Prisma để ghi bền vững.",
  });
}
