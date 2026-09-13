"use client";

import { useMemo } from "react";
import { BarChart3, CircleGauge, Target } from "lucide-react";
import { Bar, BarChart, CartesianGrid, Cell, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import type { LotteryDraw, NumberStat } from "@/lib/lottery-domain";
import { calculateStructure } from "@/lib/statistics";

function PanelHeader({ icon, eyebrow, title }: { icon: React.ReactNode; eyebrow: string; title: string }) {
  return (<header className="panel-header"><div className="panel-title-icon">{icon}</div><div className="panel-title"><span>{eyebrow}</span><h2>{title}</h2></div></header>);
}

function PageHeading({ eyebrow, title, description }: { eyebrow: string; title: string; description: string }) {
  return (<section className="page-heading"><div><span>{eyebrow}</span><h1>{title}</h1><p>{description}</p></div></section>);
}

export function StatsView({ draws, stats }: { draws: LotteryDraw[]; stats: NumberStat[] }) {
  const structure = useMemo(() => calculateStructure(draws), [draws]);
  const sortedByStreak = useMemo(() => [...stats].filter((s) => s.longestStreak > 0).sort((a, b) => b.longestStreak - a.longestStreak), [stats]);
  const total = stats.reduce((sum, s) => sum + s.count, 0);

  return (
    <>
      <PageHeading eyebrow="THỐNG KÊ" title="Phân tích chi tiết" description={`${draws.length} kỳ · ${total.toLocaleString("vi-VN")} kết quả`} />
      <section className="panel">
        <PanelHeader icon={<BarChart3 />} eyebrow="TẦN SUẤT" title="Chữ số 0–9" />
        <ResponsiveContainer width="100%" height={190}>
          <BarChart data={structure.digitCounts} margin={{ top: 8, right: 5, left: -22, bottom: 0 }}>
            <CartesianGrid vertical={false} stroke="#273044" strokeDasharray="3 5" />
            <XAxis dataKey="digit" axisLine={false} tickLine={false} tick={{ fill: "#8c96a8", fontSize: 10 }} />
            <YAxis axisLine={false} tickLine={false} tick={{ fill: "#8c96a8", fontSize: 9 }} />
            <Tooltip cursor={{ fill: "rgba(255,255,255,.03)" }} contentStyle={{ background: "#151c2b", border: "1px solid #2c3548", borderRadius: 10 }} />
            <Bar isAnimationActive={false} dataKey="count" name="Lượt" radius={[4, 4, 0, 0]}>
              {structure.digitCounts.map((entry) => <Cell key={entry.digit} fill={Number(entry.digit) % 2 === 0 ? "#efbd5b" : "#69768d"} />)}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </section>
      <section className="panel">
        <PanelHeader icon={<CircleGauge />} eyebrow="ĐẦU–ĐUÔI" title="Heatmap 10×10" />
        <div className="head-tail-wrap">
          <div className="head-tail-grid"><i />
            {structure.tails.map((item) => <b key={`t-${item.digit}`}>{item.digit}</b>)}
            {structure.heads.flatMap((head) => [<b key={`h-${head.digit}`}>{head.digit}</b>, ...structure.tails.map((tail) => {
              const key = `${head.digit}${tail.digit}`;
              const s = stats[Number(key)];
              const max = Math.max(...stats.map((item) => item.count), 1);
              const intensity = s ? s.count / max : 0;
              return <span key={key} style={{ background: `rgba(239,189,91,${0.05 + intensity * 0.55})`, borderRadius: 4, padding: "2px 4px", fontSize: 9, color: "#f5f2ea", textAlign: "center" as const }}>{s?.count ?? 0}</span>;
            })])}
          </div>
        </div>
      </section>
      <section className="panel">
        <PanelHeader icon={<Target />} eyebrow="STREAK" title="Chuỗi xuất hiện liên tiếp" />
        <div className="streak-list">
          {sortedByStreak.slice(0, 10).map((s) => (<div key={s.number} className="streak-row">
            <span className={`number-pill ${s.currentStreak >= 3 ? "hot" : "neutral"}`}>{s.number}</span>
            <span>Dài nhất: <strong>{s.longestStreak}</strong> kỳ</span>
            <span>Đang: <strong>{s.currentStreak}</strong> kỳ</span>
          </div>))}
          {sortedByStreak.length === 0 && <div className="empty-state"><p>Chưa đủ dữ liệu streak.</p></div>}
        </div>
      </section>
    </>
  );
}
