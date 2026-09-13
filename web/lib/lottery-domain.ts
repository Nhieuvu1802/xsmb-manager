export type Region = "Miền Bắc" | "Miền Trung" | "Miền Nam";

export type PrizeResult = {
  prize: string;
  position: number;
  value: string;
};

export type LotteryDraw = {
  id: string;
  drawCode: string;
  lotteryType: "TRADITIONAL" | "COMBINATION";
  date: string;
  drawnAt: string;
  region: Region;
  station: string;
  source: string;
  collectedAt: string;
  verification: "SAMPLE" | "PENDING" | "VERIFIED" | "REJECTED";
  results: PrizeResult[];
};

export type NumberStat = {
  number: string;
  count: number;
  drawHits: number;
  rate: number;
  drawRate: number;
  gap: number | null;
  averageGap: number | null;
  zScore: number;
  currentStreak: number;
  longestStreak: number;
};

export type WindowComparison = {
  period: number;
  draws: number;
  slots: number;
  distinct: number;
  chiSquare: number;
  top: Array<{ number: string; count: number }>;
  bottom: Array<{ number: string; count: number }>;
  longestGap: number;
};

export type DataIssue = {
  row: number;
  level: "error" | "warning";
  message: string;
};

export type CsvValidation = {
  validRows: number;
  duplicateRows: number;
  issues: DataIssue[];
};
