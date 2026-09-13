/**
 * Bộ sinh vector đối chiếu (parity vectors) cho bản Flutter.
 *
 * File này KHÔNG được Flutter biên dịch — nó nằm ở đây để lưu lại đúng cách
 * fixture `test/fixtures/parity_vectors.json` được tạo ra.
 *
 * Cách chạy lại khi `web/lib/statistics.ts` thay đổi:
 *   1. Copy file này vào `web/tests/_vectors.test.ts`
 *   2. cd web && npx vitest run tests/_vectors.test.ts
 *   3. Xoá lại `web/tests/_vectors.test.ts` để bản web luôn sạch
 *   4. cd mobile && flutter test
 *
 * Nếu bước 4 báo lệch, sửa `lib/src/logic/statistics.dart` cho khớp rồi lặp lại.
 */
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { expect, it } from "vitest";

import { SAMPLE_DRAWS } from "../lib/sample-data";
import {
  buildTrend,
  calculateDayOfWeekStats,
  calculateNumberStats,
  calculatePairStats,
  calculateSetProbability,
  calculateStructure,
  chiSquareUniform,
  combinations,
  exactDigitProbability,
  expectedValue,
  lastTwoDigits,
  monteCarloAtLeastOne,
  parseCsvDraws,
  parseJsonDraws,
  parseNumberSet,
  validateCsv,
  wilsonInterval,
} from "../lib/statistics";

/** CWD khi vitest chạy là `web/`, nên đi lên một cấp là repo root. */
const OUTPUT = resolve(process.cwd(), "../mobile/test/fixtures/parity_vectors.json");

type Stats = ReturnType<typeof calculateNumberStats>;
type Draw = (typeof SAMPLE_DRAWS)[number];

const fixed = (value: number | null, digits = 10) =>
  value === null ? "null" : value.toFixed(digits);

const statLine = (stat: Stats[number]) =>
  [
    stat.number,
    stat.count,
    stat.drawHits,
    fixed(stat.rate),
    fixed(stat.drawRate),
    stat.gap === null ? "null" : String(stat.gap),
    fixed(stat.averageGap),
    fixed(stat.zScore),
  ].join("|");

const pick = (stats: Stats, numbers: string[]) =>
  numbers.map((number) => statLine(stats.find((item) => item.number === number)!)).join(";");

const drawLine = (draw: Draw) =>
  [
    draw.id,
    draw.drawCode,
    draw.lotteryType,
    draw.date,
    draw.drawnAt,
    draw.region,
    draw.station,
    draw.source,
    draw.collectedAt,
    draw.verification,
  ].join("|");

const resultLine = (draw: Draw) =>
  draw.results.map((item) => `${item.prize}|${item.position}|${item.value}`).join(",");

const parseError = (callback: () => unknown) => {
  try {
    callback();
    return "(no error)";
  } catch (error) {
    return error instanceof Error ? error.message : String(error);
  }
};

const csvInput = [
  "date,Giải đặc biệt,Giải nhất",
  "2026-09-10,12345,23456",
  '2026-09-11,"34567","45678"',
  "2026-09-11,99999,88888",
  "khong-phai-ngay,1,2",
  "2026-09-14,abc,",
  "2026-09-16,55555,66666",
].join("\n");

const jsonInput = JSON.stringify([
  {
    date: "2026-09-20",
    drawCode: "MB-TEST-1",
    results: [
      { prize: "Giải bảy", value: "34" },
      { number: "056", position: 2 },
    ],
  },
  {
    date: "2026-09-21T18:00:00Z",
    draw_code: "MB-TEST-2",
    region: "Miền Nam",
    lotteryType: "COMBINATION",
    station: "Đài test",
    source: "nguồn test",
    drawnAt: "2026-09-21T18:05:00+07:00",
    results: [{ prize: "Giải nhất", value: "12345" }],
  },
]);

it("writes parity vectors", () => {
  const stats30 = calculateNumberStats(SAMPLE_DRAWS.slice(0, 30));
  const stats365 = calculateNumberStats(SAMPLE_DRAWS);
  const structure = calculateStructure(SAMPLE_DRAWS);
  const pairs = calculatePairStats(SAMPLE_DRAWS);
  const trendTracked = ["00", "12", "42", "99"];
  const trend = buildTrend(SAMPLE_DRAWS, trendTracked);
  const csvValidation = validateCsv(csvInput);
  const csvDraws = parseCsvDraws(csvInput);
  const jsonDraws = parseJsonDraws(jsonInput, "Miền Bắc");

  const checks: Record<string, number | string> = {
    sampleDrawsLength: SAMPLE_DRAWS.length,
    firstDrawMeta: drawLine(SAMPLE_DRAWS[0]),
    firstDrawResults: resultLine(SAMPLE_DRAWS[0]),
    firstDrawResultCount: SAMPLE_DRAWS[0].results.length,
    secondDrawMeta: drawLine(SAMPLE_DRAWS[1]),
    secondDrawResults: resultLine(SAMPLE_DRAWS[1]),
    lastDrawMeta: drawLine(SAMPLE_DRAWS[SAMPLE_DRAWS.length - 1]),

    stats30TotalSlots: stats30.reduce((sum, item) => sum + item.count, 0),
    stats30Flagship: pick(stats30, ["00", "01", "42", "99"]),
    stats30ChiSquare: Number(chiSquareUniform(stats30).toFixed(9)),

    stats365TotalSlots: stats365.reduce((sum, item) => sum + item.count, 0),
    stats365Flagship: pick(stats365, ["00", "07", "42", "99"]),
    stats365ChiSquare: Number(chiSquareUniform(stats365).toFixed(9)),
    stats365Counts: stats365.map((item) => item.count).join(","),
    stats365DrawHits: stats365.map((item) => item.drawHits).join(","),

    structureDigitCounts: structure.digitCounts.map((item) => item.count).join(","),
    structureHeads: structure.heads.map((item) => item.count).join(","),
    structureTails: structure.tails.map((item) => item.count).join(","),
    structureSums: structure.sums.map((item) => item.count).join(","),
    structureParity: `${structure.parity.even}|${structure.parity.odd}`,
    structureRanges: structure.ranges.map((item) => item.count).join(","),
    structureSequences: structure.sequences.map(([key, count]) => `${key}:${count}`).join(";"),

    pairsTop10: pairs.slice(0, 10).map((item) => `${item.pair}:${item.count}`).join(";"),
    pairsLength: pairs.length,

    dayOfWeek: calculateDayOfWeekStats(SAMPLE_DRAWS)
      .map((item) => `${item.day}|${item.dayIndex}|${item.count}|${item.drawHits}`)
      .join(";"),

    trendTracked: trendTracked.join(","),
    trendLength: trend.length,
    trendLast30: trend.map((item) => `${item.date}|${item.hits}`).join(";"),

    probabilitySet5: Number(calculateSetProbability(5, 27).toFixed(12)),
    probabilitySet7Default: Number(calculateSetProbability(7).toFixed(12)),
    probabilitySet0: calculateSetProbability(0),
    probabilitySet200: Number(calculateSetProbability(200, 27).toFixed(12)),
    digitProbability: [1, 2, 4, 6, 12]
      .map((digits) => fixed(exactDigitProbability(digits)!))
      .join(";"),
    digitProbability13: exactDigitProbability(13) === null ? "null" : "unexpected",
    combos: [combinations(24, 4), combinations(6, 3), combinations(0, 0), combinations(5, 9)].join(
      ";",
    ),
    expectedValue: Number(expectedValue(10, 100, 0.02).toFixed(12)),
    wilson25of100: wilsonInterval(25, 100).map((value) => fixed(value, 12)).join(";"),
    wilson0of0: wilsonInterval(0, 0).map((value) => fixed(value, 12)).join(";"),
    wilson3of7: wilsonInterval(3, 7).map((value) => fixed(value, 12)).join(";"),
    monteCarlo100k: monteCarloAtLeastOne(5, 27, 100000, 2409),
    monteCarlo10k: monteCarloAtLeastOne(2, 27, 10000, 2409),

    lastTwoDigits: ["007", "07", "7", "12345", "00"].map(lastTwoDigits).join("|"),

    numberSetInput: "00 5, 07;99-100.1 abc 007 1e2 99 12 ",
    csvInput,
    jsonInput,
  };

  const numberSet = parseNumberSet(checks.numberSetInput as string);
  checks.numberSetNumbers = numberSet.numbers.join(",");
  checks.numberSetInvalid = numberSet.invalid.join(",");

  checks.csvValidRows = csvValidation.validRows;
  checks.csvDuplicateRows = csvValidation.duplicateRows;
  checks.csvIssues = csvValidation.issues
    .map((issue) => `${issue.row}|${issue.level}|${issue.message}`)
    .join(";");
  checks.csvDraws = csvDraws.map((draw) => `${drawLine(draw)}#${resultLine(draw)}`).join(";;");
  checks.csvDrawsLength = csvDraws.length;

  checks.jsonDraws = jsonDraws.map((draw) => `${drawLine(draw)}#${resultLine(draw)}`).join(";;");
  checks.jsonDrawsLength = jsonDraws.length;
  checks.jsonErrorEmpty = parseError(() => parseJsonDraws("{}", "Miền Bắc"));
  checks.jsonErrorBadDate = parseError(() =>
    parseJsonDraws('[{"date":"2026-13-01","results":[{"value":"12"}]}]', "Miền Bắc"),
  );
  checks.jsonErrorDuplicate = parseError(() =>
    parseJsonDraws(
      '[{"date":"2026-09-01","drawCode":"X","results":[{"value":"12"}]},{"date":"2026-09-02","drawCode":"X","results":[{"value":"13"}]}]',
      "Miền Bắc",
    ),
  );
  checks.jsonErrorOutOfRange = parseError(() =>
    parseJsonDraws('[{"date":"2026-09-01","results":[{"value":"1"}]}]', "Miền Bắc"),
  );
  checks.jsonErrorNoResults = parseError(() =>
    parseJsonDraws('[{"date":"2026-09-01","results":[]}]', "Miền Bắc"),
  );
  checks.jsonErrorNotObject = parseError(() => parseJsonDraws("[1]", "Miền Bắc"));

  mkdirSync(dirname(OUTPUT), { recursive: true });
  writeFileSync(OUTPUT, `${JSON.stringify(checks, null, 2)}\n`, "utf8");

  expect(Object.keys(checks).length).toBeGreaterThan(50);
});
