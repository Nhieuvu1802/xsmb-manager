"use client";

import { useMemo, useState } from "react";
import { CalendarDays, Columns2, Info } from "lucide-react";
import type { LotteryDraw } from "@/lib/lottery-domain";
import { stationMatches, stationsForRegion } from "@/lib/stations";

const PRIZE_ORDER = ["Đặc biệt", "Giải nhất", "Giải nhì", "Giải ba", "Giải tư", "Giải năm", "Giải sáu", "Giải bảy", "Giải tám"];

function formatDate(date?: string) {
  if (!date) return "Chưa có dữ liệu";
  return new Intl.DateTimeFormat("vi-VN", { day: "2-digit", month: "2-digit", year: "numeric" })
    .format(new Date(`${date}T12:00:00`));
}

function valuesByPrize(draw?: LotteryDraw) {
  const groups = new Map<string, string[]>();
  draw?.results.forEach((result) => groups.set(result.prize, [...(groups.get(result.prize) ?? []), result.value]));
  return groups;
}

export function SouthernDualView({ draws }: { draws: LotteryDraw[] }) {
  const available = useMemo(() => {
    const stationsWithData = new Set(draws.map((draw) => draw.station));
    return stationsForRegion("Miền Nam").filter((station) =>
      [...stationsWithData].some((name) => stationMatches(name, station.name)),
    );
  }, [draws]);
  const [selectedFirstStation, setFirstStation] = useState("TP. Hồ Chí Minh");
  const [selectedSecondStation, setSecondStation] = useState("Đồng Tháp");
  const firstStation = available.some((station) => stationMatches(station.name, selectedFirstStation))
    ? selectedFirstStation
    : available[0]?.name ?? "";
  const secondStation = available.some((station) =>
    stationMatches(station.name, selectedSecondStation) && !stationMatches(station.name, firstStation),
  )
    ? selectedSecondStation
    : available.find((station) => !stationMatches(station.name, firstStation))?.name ?? "";

  const firstDraw = draws.find((draw) => stationMatches(draw.station, firstStation));
  const secondDraw = draws.find((draw) => stationMatches(draw.station, secondStation));
  const firstPrizes = valuesByPrize(firstDraw);
  const secondPrizes = valuesByPrize(secondDraw);
  const prizes = PRIZE_ORDER.filter((prize) => firstPrizes.has(prize) || secondPrizes.has(prize));

  if (available.length < 2) return null;

  return (
    <section className="panel southern-dual-panel">
      <header className="panel-header">
        <div className="panel-title-icon south"><Columns2 /></div>
        <div className="panel-title"><span>MIỀN NAM · XEM SONG SONG</span><h2>Hai đài trên cùng một bảng giải</h2></div>
        <div className="panel-meta"><span className="source-chip"><span />Dữ liệu mới nhất mỗi đài</span></div>
      </header>

      <div className="dual-station-controls">
        <label>
          <span>Đài thứ nhất</span>
          <select value={firstStation} onChange={(event) => setFirstStation(event.target.value)}>
            {available.map((station) => <option key={station.code} value={station.name} disabled={station.name === secondStation}>{station.name}</option>)}
          </select>
        </label>
        <div className="dual-divider" aria-hidden="true"><Columns2 /></div>
        <label>
          <span>Đài thứ hai</span>
          <select value={secondStation} onChange={(event) => setSecondStation(event.target.value)}>
            {available.map((station) => <option key={station.code} value={station.name} disabled={station.name === firstStation}>{station.name}</option>)}
          </select>
        </label>
      </div>

      <div className="dual-table-wrap">
        <table className="dual-station-table">
          <thead>
            <tr>
              <th>Giải</th>
              <th><strong>{firstStation}</strong><small><CalendarDays />{formatDate(firstDraw?.date)}</small></th>
              <th><strong>{secondStation}</strong><small><CalendarDays />{formatDate(secondDraw?.date)}</small></th>
            </tr>
          </thead>
          <tbody>
            {prizes.map((prize) => (
              <tr key={prize} className={prize === "Đặc biệt" ? "special" : ""}>
                <th>{prize}</th>
                <td>{firstPrizes.get(prize)?.map((value) => <b key={`${prize}-${value}`}>{value}</b>) ?? <i>—</i>}</td>
                <td>{secondPrizes.get(prize)?.map((value) => <b key={`${prize}-${value}`}>{value}</b>) ?? <i>—</i>}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p className="dual-station-note"><Info />Hai cột có thể thuộc hai ngày quay khác nhau; ngày của từng đài luôn được ghi ngay dưới tên.</p>
    </section>
  );
}
