import { NextResponse } from "next/server";
import { SAMPLE_DRAWS } from "@/lib/sample-data";

export async function GET() {
  const lastDraw = SAMPLE_DRAWS[SAMPLE_DRAWS.length - 1];
  return NextResponse.json({
    status: "healthy",
    version: "1.0.0",
    drawCount: SAMPLE_DRAWS.length,
    lastUpdate: lastDraw?.date ?? null,
    dataSource: "sample",
    timestamp: new Date().toISOString(),
  });
}
