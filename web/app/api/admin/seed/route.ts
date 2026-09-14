import { NextResponse } from "next/server";
import { SAMPLE_DRAWS } from "@/lib/sample-data";
import { databaseStatus, insertMissingDraws, logDataImport } from "@/lib/server/draw-repository";

export const maxDuration = 300;

export async function POST(request: Request) {
  const configuredKey = process.env.ADMIN_API_KEY;
  const suppliedKey = request.headers.get("authorization")?.replace(/^Bearer\s+/i, "");
  if (!configuredKey || suppliedKey !== configuredKey) {
    return NextResponse.json({ error: "Không có quyền tạo dữ liệu mẫu." }, { status: 401 });
  }

  try {
    const inserted = await insertMissingDraws(SAMPLE_DRAWS);
    const status = await databaseStatus();
    await logDataImport({
      source: "sample-bootstrap",
      acceptedRows: inserted,
      duplicateRows: SAMPLE_DRAWS.length - inserted,
      rejectedRows: 0,
      report: { requested: SAMPLE_DRAWS.length, retainedDays: 370 },
    });
    return NextResponse.json({ status: "SEEDED", inserted, database: status });
  } catch (error) {
    return NextResponse.json(
      { error: error instanceof Error ? error.message : "Không thể tạo dữ liệu mẫu." },
      { status: 503 },
    );
  }
}
