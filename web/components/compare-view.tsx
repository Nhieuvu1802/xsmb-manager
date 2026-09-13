"use client";

import { useMemo } from "react";
import type { LotteryDraw } from "@/lib/lottery-domain";
import { compareWindows } from "@/lib/statistics";

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
      <ResponsibleNotice />
    </>
  );
}
