import { NextResponse } from "next/server";
import { fullRefreshNumberTrends } from "@/lib/server/trend-repository";

/**
 * POST /api/admin/seed-trends
 * Rebuilds the NumberTrend table from raw lottery_draws + prize_results.
 * Run after first DB seed or schema migration.
 */
export async function POST(request: Request) {
  const secret = process.env.CRON_SECRET;
  if (!secret || request.headers.get("authorization") !== `Bearer ${secret}`) {
    return NextResponse.json({ error: "Không có quyền." }, { status: 401 });
  }

  try {
    const totalRows = await fullRefreshNumberTrends();
    return NextResponse.json({ status: "OK", totalRows });
  } catch (error) {
    console.error("Seed NumberTrends thất bại.", error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : "Seed thất bại." },
      { status: 500 },
    );
  }
}
