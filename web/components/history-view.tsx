"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { CalendarDays, X } from "lucide-react";
import type { LotteryDraw } from "@/lib/lottery-domain";
import { lastTwoDigits } from "@/lib/statistics";

function formatDate(date: string, long = false) {
  return new Intl.DateTimeFormat("vi-VN", {
    weekday: long ? "long" : undefined,
    day: "2-digit",
    month: "2-digit",
    year: long ? "numeric" : undefined,
  }).format(new Date(`${date}T00:00:00`));
}

function PanelHeader({ icon, eyebrow, title }: { icon: React.ReactNode; eyebrow: string; title: string }) {
  return (
    <header className="panel-header">
      <div className="panel-title-icon">{icon}</div>
      <div className="panel-title"><span>{eyebrow}</span><h2>{title}</h2></div>
    </header>
  );
}

function NumberPill({ number, tone = "neutral" }: { number: string; tone?: "hot" | "cold" | "gold" | "neutral" }) {
  return <span className={`number-pill ${tone}`}>{number}</span>;
}

function PrizeBoard({ draw }: { draw: LotteryDraw }) {
  const groups = draw.results.reduce<Record<string, string[]>>((acc, r) => {
    (acc[r.prize] ??= []).push(r.value);
    return acc;
  }, {});
  return (
    <div className="prize-board">
      {Object.entries(groups).map(([prize, values]) => (
        <div className={`prize-line ${prize === "Đặc biệt" ? "special" : ""}`} key={prize}>
          <span>{prize}</span>
          <div>{values.map((v, i) => <strong key={`${v}-${i}`}>{v}</strong>)}</div>
        </div>
      ))}
    </div>
  );
}

function PageHeading({ eyebrow, title, description }: { eyebrow: string; title: string; description: string }) {
  return (
    <section className="page-heading">
      <div><span>{eyebrow}</span><h1>{title}</h1><p>{description}</p></div>
    </section>
  );
}

export function HistoryView({ draws }: { draws: LotteryDraw[] }) {
  const [visibleCount, setVisibleCount] = useState(20);
  const [fromDate, setFromDate] = useState("");
  const [toDate, setToDate] = useState("");
  const [stationFilter, setStationFilter] = useState("");
  const [typeFilter, setTypeFilter] = useState<"" | LotteryDraw["lotteryType"]>("");
  const [selectedDraw, setSelectedDraw] = useState<LotteryDraw | null>(null);
  const sentinelRef = useRef<HTMLDivElement>(null);

  const stations = useMemo(() => [...new Set(draws.map((d) => d.station))].sort(), [draws]);

  const filtered = useMemo(() => {
    let result = [...draws].sort((a, b) => b.date.localeCompare(a.date));
    if (fromDate) result = result.filter((d) => d.date >= fromDate);
    if (toDate) result = result.filter((d) => d.date <= toDate);
    if (stationFilter) result = result.filter((d) => d.station === stationFilter);
    if (typeFilter) result = result.filter((d) => d.lotteryType === typeFilter);
    return result;
  }, [draws, fromDate, toDate, stationFilter, typeFilter]);

  const visible = filtered.slice(0, visibleCount);

  useEffect(() => {
    const sentinel = sentinelRef.current;
    if (!sentinel || visibleCount >= filtered.length) return;
    const observer = new IntersectionObserver((entries) => {
      if (entries[0]?.isIntersecting) {
        setVisibleCount((count) => Math.min(count + 20, filtered.length));
      }
    }, { rootMargin: "240px" });
    observer.observe(sentinel);
    return () => observer.disconnect();
  }, [filtered.length, visibleCount]);

  return (
    <>
      <PageHeading eyebrow="LỊCH SỬ" title="Kỳ quay gần nhất" description={`${filtered.length} kỳ quay phù hợp bộ lọc`} />
      <section className="panel history-filters">
        <PanelHeader icon={<CalendarDays />} eyebrow="BỘ LỌC" title="Lọc kỳ quay" />
        <div className="filter-row">
          <label><span>Từ ngày</span><input type="date" value={fromDate} onChange={(event) => { setFromDate(event.target.value); setVisibleCount(20); }} /></label>
          <label><span>Đến ngày</span><input type="date" value={toDate} onChange={(event) => { setToDate(event.target.value); setVisibleCount(20); }} /></label>
          <label><span>Đài</span><select value={stationFilter} onChange={(event) => { setStationFilter(event.target.value); setVisibleCount(20); }}><option value="">Tất cả</option>{stations.map((station) => <option key={station} value={station}>{station}</option>)}</select></label>
          <label><span>Loại</span><select value={typeFilter} onChange={(event) => { setTypeFilter(event.target.value as "" | LotteryDraw["lotteryType"]); setVisibleCount(20); }}><option value="">Tất cả</option><option value="TRADITIONAL">Truyền thống</option><option value="COMBINATION">Tổ hợp</option></select></label>
        </div>
      </section>
      <section className="panel draw-table-panel">
        <table className="draw-table">
          <thead><tr><th>Ngày</th><th>Đài</th><th>Miền</th><th>Mã kỳ</th><th>Kết quả</th></tr></thead>
          <tbody>
            {visible.map((draw) => (
              <tr key={draw.id} className="clickable" onClick={() => setSelectedDraw(draw)}>
                <td>{formatDate(draw.date)}</td>
                <td>{draw.station}</td>
                <td>{draw.region}</td>
                <td><code>{draw.drawCode}</code></td>
                <td>{draw.results.length} giải</td>
              </tr>
            ))}
          </tbody>
        </table>
        {visibleCount < filtered.length && <div ref={sentinelRef} className="history-sentinel">Đang tải thêm kỳ quay…</div>}
      </section>
      {selectedDraw && (
        <div className="modal-overlay" onClick={() => setSelectedDraw(null)} role="dialog" aria-label="Chi tiết kỳ quay">
          <div className="modal-panel" onClick={(e) => e.stopPropagation()}>
            <header className="modal-header">
              <h3>Kỳ quay {formatDate(selectedDraw.date, true)}</h3>
              <button onClick={() => setSelectedDraw(null)} aria-label="Đóng"><X /></button>
            </header>
            <div className="modal-body">
              <p>{selectedDraw.station} · {selectedDraw.region} · {selectedDraw.drawCode}</p>
              <PrizeBoard draw={selectedDraw} />
              <div className="modal-numbers">
                <strong>2 chữ số cuối:</strong>
                <div className="number-pills">{[...new Set(selectedDraw.results.map((r) => lastTwoDigits(r.value)))].map((n) => <NumberPill key={n} number={n} />)}</div>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
