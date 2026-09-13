"use client";

import { useMemo, useState } from "react";
import { CalendarDays, ChevronLeft, ChevronRight, X } from "lucide-react";
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
  const [page, setPage] = useState(0);
  const [fromDate, setFromDate] = useState("");
  const [toDate, setToDate] = useState("");
  const [stationFilter, setStationFilter] = useState("");
  const [selectedDraw, setSelectedDraw] = useState<LotteryDraw | null>(null);
  const perPage = 20;

  const stations = useMemo(() => [...new Set(draws.map((d) => d.station))].sort(), [draws]);

  const filtered = useMemo(() => {
    let result = [...draws].sort((a, b) => b.date.localeCompare(a.date));
    if (fromDate) result = result.filter((d) => d.date >= fromDate);
    if (toDate) result = result.filter((d) => d.date <= toDate);
    if (stationFilter) result = result.filter((d) => d.station === stationFilter);
    return result;
  }, [draws, fromDate, toDate, stationFilter]);

  const totalPages = Math.ceil(filtered.length / perPage);
  const paged = filtered.slice(page * perPage, (page + 1) * perPage);

  return (
    <>
      <PageHeading eyebrow="LỊCH SỬ" title="Kỳ quay gần nhất" description={`${filtered.length} kỳ quay phù hợp bộ lọc`} />
      <section className="panel history-filters">
        <PanelHeader icon={<CalendarDays />} eyebrow="BỘ LỌC" title="Lọc kỳ quay" />
        <div className="filter-row">
          <label><span>Từ ngày</span><input type="date" value={fromDate} onChange={(e) => { setFromDate(e.target.value); setPage(0); }} /></label>
          <label><span>Đến ngày</span><input type="date" value={toDate} onChange={(e) => { setToDate(e.target.value); setPage(0); }} /></label>
          <label><span>Đài</span><select value={stationFilter} onChange={(e) => { setStationFilter(e.target.value); setPage(0); }}><option value="">Tất cả</option>{stations.map((s) => <option key={s} value={s}>{s}</option>)}</select></label>
        </div>
      </section>
      <section className="panel draw-table-panel">
        <table className="draw-table">
          <thead><tr><th>Ngày</th><th>Đài</th><th>Miền</th><th>Mã kỳ</th><th>Kết quả</th></tr></thead>
          <tbody>
            {paged.map((draw) => (
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
        {totalPages > 1 && (
          <div className="pagination">
            <button disabled={page === 0} onClick={() => setPage((p) => p - 1)}><ChevronLeft /></button>
            <span>{page + 1} / {totalPages}</span>
            <button disabled={page >= totalPages - 1} onClick={() => setPage((p) => p + 1)}><ChevronRight /></button>
          </div>
        )}
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
