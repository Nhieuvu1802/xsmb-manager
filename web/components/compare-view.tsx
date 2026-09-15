"use client";

import { useMemo } from "react";
import { CartesianGrid, Legend, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import type { LotteryDraw } from "@/lib/lottery-domain";
import { ALL_NUMBERS, calculateNumberStats, compareWindows } from "@/lib/statistics";

const SERIES_COLORS = ["#efbd5b", "#d96c75", "#72a7e8", "#78c6a3", "#9d8ee8"];

function PageHeading({ eyebrow, title, description }: { eyebrow: string; title: string; description: string }) {
  return (<section className="page-heading"><div><span>{eyebrow}</span><h1>{title}</h1><p>{description}</p></div></section>);
}

function ResponsibleNotice() {
  return (
    <section className="responsibility-notice">
      <div><span>18+ · CHƠI CÓ TRÁCH NHIỆM</span><p>Dữ liệu lịch sử không thể bảo đảm kết quả tương lai. Mỗi kỳ quay hợp lệ được xem là một sự kiện ngẫu nhiên độc lập. Công cụ này chỉ phục vụ mục đích thống kê và giáo dục.</p></div>
    </section>
  );
}

export function CompareView({ draws }: { draws: LotteryDraw[] }) {
  const windows = useMemo(() => compareWindows(draws), [draws]);
  const overlay = useMemo(() => {
    const ordered = [...draws].sort(
      (left, right) => right.date.localeCompare(left.date) || left.station.localeCompare(right.station),
    );
    const series = windows.map((window) => ({
      period: window.period,
      stats: calculateNumberStats(ordered.slice(0, window.period)),
    }));
    return ALL_NUMBERS.map((number, index) => ({
      number,
      ...Object.fromEntries(series.map(({ period, stats }) => [`p${period}`, Number((stats[index].rate * 100).toFixed(3))])),
    }));
  }, [draws, windows]);

  return (
    <>
      <PageHeading eyebrow="SO SÁNH" title="So sánh dữ liệu" description="Đối chiếu thống kê qua nhiều khoảng thời gian" />
      <section className="panel compare-table-panel">
        <table className="compare-table">
          <thead><tr><th>Chỉ số</th>{windows.map((w) => <th key={w.period}>{w.period} kỳ</th>)}</tr></thead>
          <tbody>
            <tr><td>Số kỳ</td>{windows.map((w) => <td key={w.period}>{w.draws}</td>)}</tr>
            <tr><td>Tổng vị trí</td>{windows.map((w) => <td key={w.period}>{w.slots.toLocaleString("vi-VN")}</td>)}</tr>
            <tr><td>Distinct</td>{windows.map((w) => <td key={w.period}>{w.distinct}/100</td>)}</tr>
            <tr><td title="Chi bình phương so với phân phối đều, df=99">χ²</td>{windows.map((w) => <td key={w.period}>{w.chiSquare.toFixed(1)}</td>)}</tr>
            <tr><td>Top 3</td>{windows.map((w) => <td key={w.period}>{w.top.map((t) => t.number).join(", ")}</td>)}</tr>
            <tr><td>Đáy 3</td>{windows.map((w) => <td key={w.period}>{w.bottom.map((b) => b.number).join(", ")}</td>)}</tr>
            <tr><td>Gan dài nhất</td>{windows.map((w) => <td key={w.period}>{w.longestGap} kỳ</td>)}</tr>
          </tbody>
        </table>
      </section>
      <section className="panel compare-overlay-panel">
        <h2>Overlay tần suất 00–99</h2>
        <p>Tỷ lệ trên tổng vị trí quan sát giúp các cửa sổ khác kích thước vẫn so sánh được.</p>
        <ResponsiveContainer width="100%" height={320}>
          <LineChart data={overlay} margin={{ top: 16, right: 18, left: -8, bottom: 4 }}>
            <CartesianGrid vertical={false} stroke="#273044" strokeDasharray="3 5" />
            <XAxis dataKey="number" interval={9} axisLine={false} tickLine={false} tick={{ fill: "#8c96a8", fontSize: 10 }} />
            <YAxis unit="%" axisLine={false} tickLine={false} tick={{ fill: "#8c96a8", fontSize: 10 }} />
            <Tooltip contentStyle={{ background: "#151c2b", border: "1px solid #2c3548", borderRadius: 10 }} />
            <Legend />
            {windows.map((window, index) => (
              <Line
                key={window.period}
                type="monotone"
                dataKey={`p${window.period}`}
                name={`${window.period} kỳ`}
                stroke={SERIES_COLORS[index]}
                strokeWidth={window.period === 30 ? 2.5 : 1.5}
                dot={false}
                isAnimationActive={false}
              />
            ))}
          </LineChart>
        </ResponsiveContainer>
      </section>
      <ResponsibleNotice />
    </>
  );
}
