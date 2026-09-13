import { NextResponse } from "next/server";
import { SAMPLE_DRAWS } from "@/lib/sample-data";
import { compareWindows } from "@/lib/statistics";
import type { Region } from "@/lib/lottery-domain";

const VALID_REGIONS: Region[] = ["Miền Bắc", "Miền Trung", "Miền Nam"];

export async function GET(request: Request) {
  const params = Object.fromEntries(new URL(request.url).searchParams);
  const region = (params.region as Region) || "Miền Bắc";

  if (!VALID_REGIONS.includes(region)) {
    return NextResponse.json({ error: "Miền không hợp lệ." }, { status: 422 });
  }

  const draws = SAMPLE_DRAWS.filter((d) => d.region === region);
  const windows = compareWindows(draws);

  return NextResponse.json(
    { region, windows },
    { headers: { "Cache-Control": "public, max-age=600" } }
  );
}
