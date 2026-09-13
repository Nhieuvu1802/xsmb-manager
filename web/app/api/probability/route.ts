import { NextResponse } from "next/server";
import { z } from "zod";

const querySchema = z.object({
  digits: z.coerce.number().int().min(2).max(6).default(2),
  selections: z.coerce.number().int().min(1).max(1000).default(1),
  slots: z.coerce.number().int().min(1).max(1000).default(1),
});

export function calculateProbability(input: z.infer<typeof querySchema>) {
  const outcomes = 10 ** input.digits;
  const selections = Math.min(input.selections, outcomes);
  const singleSlot = selections / outcomes;
  return {
    inputs: { ...input, selections },
    outcomes,
    singleSlot,
    atLeastOne: 1 - (1 - singleSlot) ** input.slots,
    assumptions: [
      "Các kết quả trong không gian mẫu đồng khả năng.",
      "Các vị trí được xem là độc lập trong phép tính xấp xỉ nhiều vị trí.",
    ],
  };
}

export async function GET(request: Request) {
  const params = Object.fromEntries(new URL(request.url).searchParams);
  const parsed = querySchema.safeParse(params);
  if (!parsed.success) {
    return NextResponse.json({ error: "Tham số không hợp lệ", details: z.flattenError(parsed.error) }, { status: 422 });
  }
  return NextResponse.json(calculateProbability(parsed.data), {
    headers: { "Cache-Control": "public, max-age=3600" },
  });
}

