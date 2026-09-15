import { NextResponse } from "next/server";
import { z } from "zod";
import { logAudit, logDataImport, upsertDraws } from "@/lib/server/draw-repository";
import { cacheInvalidate } from "@/lib/server/cache";
import { getClientIp } from "@/lib/server/request-context";
import { providerPayloadSchema, providerRecordsToDraws } from "@/lib/server/provider";

export async function POST(request: Request) {
  const configuredKey = process.env.ADMIN_API_KEY;
  const suppliedKey = request.headers.get("authorization")?.replace(/^Bearer\s+/i, "");
  if (!configuredKey || suppliedKey !== configuredKey) {
    return NextResponse.json({ error: "Không có quyền nhập dữ liệu." }, { status: 401 });
  }

  const body = await request.json().catch(() => null);
  const parsed = providerPayloadSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: "Dữ liệu không hợp lệ", details: z.flattenError(parsed.error) }, { status: 422 });
  }

  const seen = new Set<string>();
  const duplicates: string[] = [];
  const uniqueRecords = parsed.data.records.filter((record) => {
    if (seen.has(record.drawCode)) {
      duplicates.push(record.drawCode);
      return false;
    }
    seen.add(record.drawCode);
    return true;
  });

  try {
    const accepted = await upsertDraws(providerRecordsToDraws(uniqueRecords));
    await logDataImport({
      source: "admin-api",
      acceptedRows: accepted,
      duplicateRows: duplicates.length,
      rejectedRows: 0,
      report: { duplicates },
    });
    await cacheInvalidate("stats:");
    await logAudit({
      action: "IMPORT_DRAWS",
      entity: "LotteryDraw",
      details: { accepted, duplicateRows: duplicates.length, source: "admin-api" },
      ipAddress: getClientIp(request),
    });
    return NextResponse.json({ accepted, duplicates, status: "IMPORTED" });
  } catch (error) {
    return NextResponse.json(
      { error: error instanceof Error ? error.message : "Không thể ghi PostgreSQL." },
      { status: 503 },
    );
  }
}
