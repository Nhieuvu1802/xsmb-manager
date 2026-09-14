"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { CalendarDays, Dices, Info, RefreshCw, ShieldCheck, Sparkles } from "lucide-react";
import type { LotteryDraw, Region } from "@/lib/lottery-domain";
import { calculateSetProbability, rankHistoricalCandidates, secureRandomNumbers } from "@/lib/statistics";

function vietnamToday() {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Ho_Chi_Minh",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(new Date());
  const part = (type: Intl.DateTimeFormatPartTypes) => parts.find((item) => item.type === type)?.value ?? "";
  return `${part("year")}-${part("month")}-${part("day")}`;
}

function formatPercent(value: number) {
  return new Intl.NumberFormat("vi-VN", { style: "percent", minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(value);
}

export function SimulatorView({ draws, region, station }: { draws: LotteryDraw[]; region: Region; station: string }) {
  const [targetDate, setTargetDate] = useState(vietnamToday);
  const [displayNumber, setDisplayNumber] = useState("24");
  const [history, setHistory] = useState<string[]>([]);
  const [spinning, setSpinning] = useState(false);
  const intervalRef = useRef<number | null>(null);

  useEffect(() => () => {
    if (intervalRef.current !== null) window.clearInterval(intervalRef.current);
  }, []);

  const candidates = useMemo(() => rankHistoricalCandidates(draws, targetDate, 12), [draws, targetDate]);
  const averageSlots = draws.length
    ? Math.max(1, Math.round(draws.reduce((sum, draw) => sum + draw.results.length, 0) / draws.length))
    : region === "Miền Bắc" ? 27 : 18;
  const theoreticalChance = calculateSetProbability(1, averageSlots);
  const targetWeekday = new Intl.DateTimeFormat("vi-VN", { weekday: "long" }).format(new Date(`${targetDate}T12:00:00`));

  function spin() {
    if (spinning) return;
    setSpinning(true);
    let ticks = 0;
    intervalRef.current = window.setInterval(() => {
      setDisplayNumber(secureRandomNumbers(1)[0]);
      ticks += 1;
      if (ticks < 14) return;
      if (intervalRef.current !== null) window.clearInterval(intervalRef.current);
      intervalRef.current = null;
      const finalNumber = secureRandomNumbers(1)[0];
      setDisplayNumber(finalNumber);
      setHistory((current) => [finalNumber, ...current].slice(0, 8));
      setSpinning(false);
    }, 70);
  }

  return (
    <>
      <section className="page-heading simulator-heading">
        <div><span>PHÒNG MÔ PHỎNG MINH BẠCH</span><h1>Quay thử & xếp hạng lịch sử</h1><p>Mô phỏng ngẫu nhiên bằng Web Crypto; bảng số bên cạnh chỉ mô tả dữ liệu trước ngày đã chọn.</p></div>
      </section>

      <section className="simulator-layout">
        <article className="panel draw-machine-panel">
          <header className="panel-header">
            <div className="panel-title-icon"><Dices /></div>
            <div className="panel-title"><span>LỒNG CẦU MÔ PHỎNG</span><h2>Một kết quả 00–99</h2></div>
            <div className="panel-meta"><span className="quality-badge good"><ShieldCheck />Web Crypto</span></div>
          </header>
          <div className={`draw-machine ${spinning ? "is-spinning" : ""}`} aria-live="polite" aria-label={`Kết quả mô phỏng ${displayNumber}`}>
            <div className="machine-ring"><span>{displayNumber[0]}</span><span>{displayNumber[1]}</span></div>
            <small>Mỗi số 00–99 có xác suất bằng nhau trong mô phỏng này</small>
          </div>
          <button className="gold-button simulator-button" onClick={spin} disabled={spinning}>
            {spinning ? <RefreshCw className="spin-icon" /> : <Sparkles />}{spinning ? "Đang trộn ngẫu nhiên" : "Quay thử một lượt"}
          </button>
          <div className="spin-history"><span>Lịch sử trên thiết bị</span><div>{history.length ? history.map((number, index) => <b key={`${number}-${index}`}>{number}</b>) : <small>Chưa có lượt quay</small>}</div></div>
          <p className="machine-note"><Info />Kết quả chỉ được tạo trên thiết bị và không liên quan đến kỳ quay thật.</p>
        </article>

        <article className="panel candidate-panel">
          <header className="panel-header">
            <div className="panel-title-icon south"><CalendarDays /></div>
            <div className="panel-title"><span>ĐIỂM NỔI BẬT LỊCH SỬ</span><h2>{region}{station ? ` · ${station}` : " · Tất cả đài"}</h2></div>
            <div className="panel-meta"><span className="quality-badge warning">Không phải dự đoán</span></div>
          </header>
          <div className="candidate-toolbar">
            <label><span>Ngày tham khảo</span><input type="date" value={targetDate} onChange={(event) => setTargetDate(event.target.value)} /></label>
            <div><span>Ngày trong tuần</span><strong>{targetWeekday}</strong></div>
            <div><span>Mẫu quá khứ</span><strong>{candidates[0]?.sampleDraws.toLocaleString("vi-VN") ?? 0} kỳ</strong></div>
          </div>
          <div className="candidate-grid">
            {candidates.map((candidate, index) => (
              <article key={candidate.number}>
                <span className="candidate-rank">#{index + 1}</span>
                <b>{candidate.number}</b>
                <div><strong>{candidate.score.toFixed(1)} điểm</strong><small>Toàn kỳ {candidate.overallHits} · 30 ngày {candidate.recentHits} · cùng thứ {candidate.weekdayHits}</small></div>
              </article>
            ))}
          </div>
          {!candidates.length && <div className="candidate-empty">Chưa đủ dữ liệu trước ngày đã chọn.</div>}
          <div className="candidate-disclaimer">
            <ShieldCheck />
            <p><strong>Xác suất lý thuyết không thay đổi: {formatPercent(theoreticalChance)} mỗi số trong một kỳ {averageSlots} kết quả.</strong> Điểm xếp hạng kết hợp tần suất toàn mẫu, 30 ngày gần nhất và cùng thứ trong tuần; điểm cao không có nghĩa số đó dễ trúng hơn.</p>
          </div>
        </article>
      </section>
    </>
  );
}
