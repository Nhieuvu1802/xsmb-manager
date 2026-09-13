#!/usr/bin/env node
/**
 * Kiểm tra dataset trước khi build/deploy (chạy bằng `npm run build`).
 *
 * Worker bundle trực tiếp `public-data/*.json`, nên nếu snapshot thiếu, sai
 * JSON hoặc sai cấu trúc giải thì deploy sẽ phục vụ dữ liệu lỗi. Script này
 * dừng sớm với thông báo rõ ràng. Không đọc/ghi bất kỳ credential nào.
 */

import { existsSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = dirname(fileURLToPath(import.meta.url));
const publicDataDir = resolve(scriptDir, "..", "..", "public-data");

const REQUIRED_FILES = [
  "config.json",
  "manifest.json",
  "status.json",
  "xsmb/latest.json",
  "xsmn/latest.json",
  "xsmb/history.json",
  "xsmn/history.json",
];

const problems = [];

function readJson(relativePath) {
  const absolute = resolve(publicDataDir, relativePath);
  if (!existsSync(absolute)) {
    problems.push(`Thiếu file public-data/${relativePath}`);
    return null;
  }
  try {
    return JSON.parse(readFileSync(absolute, "utf8"));
  } catch (error) {
    problems.push(`JSON không hợp lệ ở public-data/${relativePath}: ${error.message}`);
    return null;
  }
}

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

function checkSnapshot(label, snapshot, expectedPrizes, singleDate = true) {
  if (!snapshot) return null;
  if (!ISO_DATE.test(snapshot.date ?? "")) {
    problems.push(`${label}: date không đúng ISO (nhận "${snapshot.date}")`);
  }
  if (!Array.isArray(snapshot.draws) || snapshot.draws.length === 0) {
    problems.push(`${label}: không có kỳ quay nào trong snapshot`);
    return snapshot;
  }
  if (snapshot.count !== snapshot.draws.length) {
    problems.push(
      `${label}: count=${snapshot.count} không khớp draws=${snapshot.draws.length}`,
    );
  }
  for (const draw of snapshot.draws) {
    if (singleDate && draw.date !== snapshot.date) {
      problems.push(`${label}: kỳ ${draw.draw_code ?? draw.station} lệch ngày snapshot`);
    }
    if (!Array.isArray(draw.results) || draw.results.length !== expectedPrizes) {
      problems.push(
        `${label}: ${draw.station} có ${draw.results?.length ?? 0} giải, cần ${expectedPrizes}`,
      );
      continue;
    }
    const seen = new Set();
    for (const result of draw.results) {
      const key = `${result.prize}#${result.position}`;
      if (seen.has(key)) problems.push(`${label}: ${draw.station} trùng vị trí ${key}`);
      seen.add(key);
      if (!/^\d+$/.test(String(result.value ?? ""))) {
        problems.push(
          `${label}: ${draw.station} ${key} có giá trị không phải số ("${result.value}")`,
        );
      }
    }
  }
  if (!singleDate) {
    const dates = snapshot.draws.map((draw) => draw.date).sort();
    const latest = dates[dates.length - 1];
    if (snapshot.date !== latest) {
      problems.push(
        `${label}: date=${snapshot.date} không phải kỳ mới nhất ${latest}`,
      );
    }
    if (snapshot.firstDate !== dates[0]) {
      problems.push(
        `${label}: firstDate=${snapshot.firstDate} không phải kỳ cũ nhất ${dates[0]}`,
      );
    }
    if (!(Number.isInteger(snapshot.days) && snapshot.days >= 1)) {
      problems.push(`${label}: days=${snapshot.days} không hợp lệ`);
    }
  }
  return snapshot;
}

for (const file of REQUIRED_FILES) readJson(file);

const status = readJson("status.json");
const manifest = readJson("manifest.json");
readJson("config.json");

if (status && manifest && status.datasetVersion !== manifest.datasetVersion) {
  problems.push(
    `datasetVersion lệch nhau: status.json=${status.datasetVersion} manifest.json=${manifest.datasetVersion}`,
  );
}

const xsmb = checkSnapshot("xsmb/latest.json", readJson("xsmb/latest.json"), 27);
const xsmn = checkSnapshot("xsmn/latest.json", readJson("xsmn/latest.json"), 18);
const xsmbHistory = checkSnapshot(
  "xsmb/history.json",
  readJson("xsmb/history.json"),
  27,
  false,
);
const xsmnHistory = checkSnapshot(
  "xsmn/history.json",
  readJson("xsmn/history.json"),
  18,
  false,
);

if (problems.length > 0) {
  console.error("❌ Dataset chưa sẵn sàng để deploy:");
  for (const problem of problems) console.error(`   - ${problem}`);
  process.exit(1);
}

console.log("✅ public-data hợp lệ");
console.log(`   datasetVersion : ${status.datasetVersion}`);
console.log(`   datasetDate    : ${status.datasetDate}`);
console.log(`   xsmb           : ${xsmb.draws.length} kỳ × 27 giải (${xsmb.date})`);
console.log(
  `   xsmn           : ${xsmn.draws.length} đài × 18 giải (${xsmn.date}) - ${xsmn.draws
    .map((draw) => draw.station)
    .join(", ")}`,
);
console.log(
  `   xsmb history   : ${xsmbHistory.draws.length} kỳ × 27 giải trong cửa sổ ${xsmbHistory.days} ngày (${xsmbHistory.firstDate} → ${xsmbHistory.date})`,
);
console.log(
  `   xsmn history   : ${xsmnHistory.draws.length} đài trong cửa sổ ${xsmnHistory.days} ngày (${xsmnHistory.firstDate} → ${xsmnHistory.date})`,
);
