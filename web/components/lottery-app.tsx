"use client";

import { ChangeEvent, useMemo, useRef, useState } from "react";
import {
  Activity,
  AlertCircle,
  ArrowDownRight,
  ArrowUpRight,
  BarChart3,
  BookOpen,
  CalendarDays,
  Check,
  ChevronDown,
  CircleGauge,
  Clock3,
  Cloud,
  Database,
  Dices,
  FileCheck2,
  FileUp,
  Flame,
  HelpCircle,
  History,
  Info,
  LayoutDashboard,
  Menu,
  MoonStar,
  Plus,
  RefreshCw,
  Search,
  ShieldCheck,
  Snowflake,
  Sparkles,
  Star,
  Target,
  TrendingUp,
  UploadCloud,
  X,
} from "lucide-react";
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { SAMPLE_DRAWS } from "@/lib/sample-data";
import type { LotteryDraw, NumberStat, Region } from "@/lib/lottery-domain";
import { HistoryView } from "@/components/history-view";
import { StatsView } from "@/components/stats-view";
import { CompareView } from "@/components/compare-view";
import {
  buildTrend,
  calculateStructure,
  calculateNumberStats,
  calculateSetProbability,
  calculatePairStats,
  calculateDayOfWeekStats,
  chiSquareUniform,
  combinations,
  exactDigitProbability,
  expectedValue,
  lastTwoDigits,
  parseCsvDraws,
  parseJsonDraws,
  parseNumberSet,
  secureRandomNumbers,
  validateCsv,
  wilsonInterval,
  monteCarloAtLeastOne,
} from "@/lib/statistics";

type View = "overview" | "analyzer" | "history" | "stats" | "compare" | "data" | "method";
type CompareSet = { id: number; label: string; numbers: string[] };
type Period = 7 | 30 | 90 | 180 | 365;

const NAV_ITEMS: Array<{ id: View; label: string; description: string; icon: typeof LayoutDashboard }> = [
  { id: "overview", label: "Tổng quan", description: "Nhịp dữ liệu", icon: LayoutDashboard },
  { id: "analyzer", label: "Phân tích", description: "Kiểm tra bộ số", icon: CircleGauge },
  { id: "history", label: "Lịch sử", description: "Kỳ quay gần nhất", icon: History },
  { id: "stats", label: "Thống kê", description: "Phân tích chi tiết", icon: BarChart3 },
  { id: "compare", label: "So sánh", description: "7–365 kỳ", icon: Activity },
  { id: "data", label: "Kho dữ liệu", description: "Nguồn & nhập liệu", icon: Database },
  { id: "method", label: "Phương pháp", description: "Công thức rõ ràng", icon: BookOpen },
];

const PERIOD_OPTIONS: Period[] = [7, 30, 90, 180, 365];

function formatDate(date: string, long = false) {
  return new Intl.DateTimeFormat("vi-VN", {
    weekday: long ? "long" : undefined,
    day: "2-digit",
    month: "2-digit",
    year: long ? "numeric" : undefined,
  }).format(new Date(`${date}T00:00:00`));
}

function percentage(value: number, digits = 1) {
  return new Intl.NumberFormat("vi-VN", {
    style: "percent",
    minimumFractionDigits: digits,
    maximumFractionDigits: digits,
  }).format(value);
}

function NumberPill({ number, tone = "neutral" }: { number: string; tone?: "hot" | "cold" | "gold" | "neutral" }) {
  return <span className={`number-pill ${tone}`}>{number}</span>;
}

function AppTooltip({ active, payload, label }: { active?: boolean; payload?: Array<{ value?: number }>; label?: string }) {
  if (!active || !payload?.length) return null;
  return (
    <div className="chart-tooltip">
      <span>{label}</span>
      <strong>{payload[0].value ?? 0} lượt xuất hiện</strong>
    </div>
  );
}

function EmptyState({ children }: { children: React.ReactNode }) {
  return (
    <div className="empty-state">
      <Search size={24} />
      <p>{children}</p>
    </div>
  );
}

export function LotteryApp() {
  const [view, setView] = useState<View>("overview");
  const [mobileMenu, setMobileMenu] = useState(false);
  const [period, setPeriod] = useState<Period>(90);
  const [region, setRegion] = useState<Region>("Miền Bắc");
  const [lotteryType, setLotteryType] = useState("Lô tô 2 số");
  const [draws, setDraws] = useState<LotteryDraw[]>(SAMPLE_DRAWS);
  const [toast, setToast] = useState("");
  const [theme, setTheme] = useState<"dark" | "light">(() =>
    typeof window !== "undefined" && localStorage.getItem("tk24:theme") === "light" ? "light" : "dark",
  );

  const filteredDraws = useMemo(
    () => draws.filter((draw) => draw.region === region).slice(0, period),
    [draws, period, region],
  );
  const stats = useMemo(() => calculateNumberStats(filteredDraws), [filteredDraws]);

  function navigate(next: View) {
    setView(next);
    setMobileMenu(false);
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  function importDraws(nextDraws: LotteryDraw[]) {
    const importedIds = new Set(nextDraws.map((draw) => `${draw.region}-${draw.date}`));
    setDraws((current) => [
      ...nextDraws,
      ...current.filter((draw) => !importedIds.has(`${draw.region}-${draw.date}`)),
    ].sort((a, b) => b.date.localeCompare(a.date)));
    setRegion(nextDraws[0]?.region ?? region);
    setToast(`Đã nhập ${nextDraws.length} kỳ hợp lệ vào phiên làm việc.`);
    window.setTimeout(() => setToast(""), 4200);
  }

  const pageTitle = NAV_ITEMS.find((item) => item.id === view)?.label ?? "Tổng quan";

  return (
    <div className="app-shell" data-theme={theme}>
      <aside className={`sidebar ${mobileMenu ? "open" : ""}`}>
        <div className="brand-block">
          <div className="brand-symbol" aria-hidden="true"><span>24</span></div>
          <div><strong>Thống Kê 24</strong><small>Dữ liệu minh bạch</small></div>
          <button className="icon-button sidebar-close" onClick={() => setMobileMenu(false)} aria-label="Đóng menu"><X /></button>
        </div>

        <div className="nav-caption">Không gian phân tích</div>
        <nav className="side-nav" aria-label="Điều hướng chính">
          {NAV_ITEMS.map((item) => {
            const Icon = item.icon;
            return (
              <button key={item.id} className={view === item.id ? "active" : ""} onClick={() => navigate(item.id)}>
                <span className="nav-icon"><Icon size={19} /></span>
                <span><strong>{item.label}</strong><small>{item.description}</small></span>
              </button>
            );
          })}
        </nav>

        <div className="sidebar-spacer" />
        <div className="responsible-card">
          <ShieldCheck size={21} />
          <div><strong>18+ · Có trách nhiệm</strong><p>Thống kê để tham khảo, không phải cam kết trúng thưởng.</p></div>
        </div>
        <div className="sidebar-meta"><span><span className="status-dot" />Dữ liệu mẫu</span><small>v3.0.0</small></div>
      </aside>

      {mobileMenu && <button className="sidebar-scrim" onClick={() => setMobileMenu(false)} aria-label="Đóng menu" />}

      <main className="workspace">
        <header className="topbar">
          <button className="icon-button menu-button" onClick={() => setMobileMenu(true)} aria-label="Mở menu"><Menu /></button>
          <div className="mobile-title"><small>Thống Kê 24</small><strong>{pageTitle}</strong></div>
          <div className="desktop-filters">
            <label><span>Khu vực</span><select value={region} onChange={(event) => setRegion(event.target.value as Region)}><option>Miền Bắc</option><option>Miền Trung</option><option>Miền Nam</option></select><ChevronDown size={14} /></label>
            <label><span>Loại phân tích</span><select value={lotteryType} onChange={(event) => setLotteryType(event.target.value)}><option>Lô tô 2 số</option><option>Giải đặc biệt</option><option>Vé 6/45</option></select><ChevronDown size={14} /></label>
            <label><span>Khoảng dữ liệu</span><select value={period} onChange={(event) => setPeriod(Number(event.target.value) as Period)}>{PERIOD_OPTIONS.map((value) => <option value={value} key={value}>{value} kỳ gần nhất</option>)}</select><ChevronDown size={14} /></label>
          </div>
          <button className="icon-button theme-button" onClick={() => setTheme((current) => {
            const next = current === "dark" ? "light" : "dark";
            localStorage.setItem("tk24:theme", next);
            return next;
          })} aria-label={theme === "dark" ? "Chuyển sang giao diện sáng" : "Chuyển sang giao diện tối"}><MoonStar size={19} /></button>
          <button className="profile-button" aria-label="Hồ sơ người dùng">AN</button>
        </header>

        <div className="mobile-filters">
          <label><select value={region} onChange={(event) => setRegion(event.target.value as Region)}><option>Miền Bắc</option><option>Miền Trung</option><option>Miền Nam</option></select><ChevronDown /></label>
          <label><select value={period} onChange={(event) => setPeriod(Number(event.target.value) as Period)}>{PERIOD_OPTIONS.map((value) => <option value={value} key={value}>{value} kỳ</option>)}</select><ChevronDown /></label>
          <label><select value={lotteryType} onChange={(event) => setLotteryType(event.target.value)}><option>Lô tô 2 số</option><option>Giải đặc biệt</option><option>Vé 6/45</option></select><ChevronDown /></label>
        </div>

        <div className="page-content">
          {view === "overview" && <Overview draws={filteredDraws} stats={stats} period={period} onNavigate={navigate} />}
          {view === "analyzer" && <Analyzer draws={filteredDraws} stats={stats} />}
          {view === "history" && <HistoryView draws={draws} />}
          {view === "stats" && <StatsView draws={filteredDraws} stats={stats} />}
          {view === "compare" && <CompareView draws={filteredDraws} />}
          {view === "data" && <DataCenter draws={draws} onImport={importDraws} />}
          {view === "method" && <Methodology draws={filteredDraws} stats={stats} />}
        </div>

        <footer className="app-footer">
          <span>© 2026 Thống Kê 24 · Công cụ học tập & giải trí</span>
          <span>Kết quả quá khứ không đảm bảo kết quả tương lai.</span>
        </footer>
      </main>

      <nav className="bottom-nav" aria-label="Điều hướng di động">
        {NAV_ITEMS.slice(0, 4).map((item) => {
          const Icon = item.icon;
          return <button key={item.id} className={view === item.id ? "active" : ""} onClick={() => navigate(item.id)}><Icon /><span>{item.label}</span></button>;
        })}
      </nav>

      {toast && <div className="toast" role="status"><Check size={18} />{toast}</div>}
    </div>
  );
}

function Overview({ draws, stats, period, onNavigate }: { draws: LotteryDraw[]; stats: NumberStat[]; period: Period; onNavigate: (view: View) => void }) {
  const [trendMode, setTrendMode] = useState<"Ngày" | "Tuần" | "Tháng">("Ngày");
  const latest = draws[0];
  const sortedHot = [...stats].sort((a, b) => b.count - a.count || a.number.localeCompare(b.number));
  const hot = sortedHot.slice(0, 5);
  const cold = [...stats].sort((a, b) => a.count - b.count || a.number.localeCompare(b.number)).slice(0, 5);
  const overdue = [...stats].filter((stat) => stat.gap !== null).sort((a, b) => (b.gap ?? 0) - (a.gap ?? 0)).slice(0, 5);
  const tracked = hot.slice(0, 3).map((stat) => stat.number);
  const trend = (() => {
    const rawTrend = buildTrend(draws, tracked);
    if (trendMode === "Ngày") return rawTrend.slice(-14);
    const bucketSize = trendMode === "Tuần" ? 7 : 30;
    const chunks: Array<{ date: string; hits: number }> = [];
    for (let index = 0; index < rawTrend.length; index += bucketSize) {
      const chunk = rawTrend.slice(index, index + bucketSize);
      if (chunk.length) chunks.push({ date: chunk.at(-1)?.date ?? "", hits: chunk.reduce((sum, item) => sum + item.hits, 0) });
    }
    return chunks;
  })();
  const totalResults = draws.reduce((sum, draw) => sum + draw.results.length, 0);
  const pairStats = useMemo(() => calculatePairStats(draws), [draws]);
  const dayStats = useMemo(() => calculateDayOfWeekStats(draws), [draws]);

  if (!draws.length) {
    return (
      <>
        <PageHeading eyebrow="TRUNG TÂM DỮ LIỆU" title="Tổng quan xác suất" description="Không có dữ liệu mẫu cho khu vực đã chọn." />
        <section className="panel"><EmptyState>Hãy chọn Miền Bắc hoặc nhập CSV cho khu vực này trong Kho dữ liệu.</EmptyState></section>
      </>
    );
  }

  return (
    <>
      <PageHeading
        eyebrow="TRUNG TÂM DỮ LIỆU"
        title="Tổng quan xác suất"
        description={`Góc nhìn thống kê trên ${period} kỳ gần nhất — dữ liệu mô phỏng, không phải dự đoán.`}
        action={<button className="primary-button" onClick={() => onNavigate("analyzer")}><Sparkles size={17} />Phân tích bộ số</button>}
      />

      <section className="metric-grid">
        <article className="metric-card featured">
          <div className="metric-icon"><Activity /></div>
          <div className="metric-copy"><span>Tổng kỳ phân tích</span><strong>{draws.length}</strong><small><ArrowUpRight /> {totalResults.toLocaleString("vi-VN")} kết quả riêng lẻ</small></div>
          <div className="mini-bars" aria-hidden="true">{[38, 61, 48, 77, 56, 90, 72, 100].map((height, index) => <i key={index} style={{ height: `${height}%` }} />)}</div>
        </article>
        <article className="metric-card">
          <div className="metric-icon hot"><Flame /></div>
          <div className="metric-copy"><span>Đang xuất hiện nhiều</span><strong>{hot[0]?.number}</strong><small className="warm"><ArrowUpRight /> {hot[0]?.count} lần · z = {hot[0]?.zScore.toFixed(2)}</small></div>
        </article>
        <article className="metric-card">
          <div className="metric-icon cold"><Snowflake /></div>
          <div className="metric-copy"><span>Đang xuất hiện ít</span><strong>{cold[0]?.number}</strong><small className="cool"><ArrowDownRight /> {cold[0]?.count} lần trong mẫu</small></div>
        </article>
        <article className="metric-card">
          <div className="metric-icon overdue"><Clock3 /></div>
          <div className="metric-copy"><span>Lâu chưa xuất hiện</span><strong>{overdue[0]?.number}</strong><small>{overdue[0]?.gap ?? 0} kỳ kể từ lần gần nhất</small></div>
        </article>
      </section>

      <section className="overview-grid top-row">
        <article className="panel draw-panel">
          <PanelHeader icon={<History />} eyebrow="KỲ QUAY MỚI NHẤT" title={formatDate(latest.date, true)} meta={<span className="source-chip"><span />Mẫu · seed cố định</span>} />
          <PrizeBoard draw={latest} />
          <div className="draw-footer"><span><Cloud size={15} />Nguồn: {latest.source}</span><span>Cập nhật: 20:10 · {formatDate(latest.date)}</span></div>
        </article>

        <article className="panel pulse-panel">
          <PanelHeader icon={<TrendingUp />} eyebrow="NHỊP SỐ" title="Nhóm nổi bật" meta={<button className="text-button" onClick={() => onNavigate("analyzer")}>Xem chi tiết</button>} />
          <div className="rank-list">
            {hot.map((item, index) => (
              <div className="rank-row" key={item.number}>
                <span className="rank-index">{index + 1}</span>
                <NumberPill number={item.number} tone={index < 2 ? "hot" : "neutral"} />
                <div className="rank-measure"><span><i style={{ width: `${Math.max(16, (item.count / (hot[0]?.count || 1)) * 100)}%` }} /></span><small>{item.count} lần</small></div>
                <span className={item.zScore >= 0 ? "delta up" : "delta down"}>{item.zScore >= 0 ? "+" : ""}{item.zScore.toFixed(1)}σ</span>
              </div>
            ))}
          </div>
          <div className="micro-note"><Info size={16} /><span>“Nhiều” chỉ mô tả mẫu đang xem, không làm tăng cơ hội ở kỳ kế tiếp.</span></div>
        </article>
      </section>

      <section className="overview-grid chart-row">
        <article className="panel trend-panel">
          <PanelHeader
            icon={<BarChart3 />}
            eyebrow="DIỄN BIẾN"
            title="Xu hướng nhóm số nổi bật"
            meta={<div className="segmented">{(["Ngày", "Tuần", "Tháng"] as const).map((mode) => <button key={mode} onClick={() => setTrendMode(mode)} className={trendMode === mode ? "active" : ""}>{mode}</button>)}</div>}
          />
          <div className="tracked-line"><span>Theo dõi</span>{tracked.map((number) => <NumberPill key={number} number={number} tone="gold" />)}</div>
          <div className="chart-wrap">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={trend} margin={{ top: 10, right: 8, left: -26, bottom: 0 }}>
                <defs><linearGradient id="goldArea" x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stopColor="#efbd5b" stopOpacity={0.35} /><stop offset="100%" stopColor="#efbd5b" stopOpacity={0} /></linearGradient></defs>
                <CartesianGrid vertical={false} stroke="#273044" strokeDasharray="3 5" />
                <XAxis dataKey="date" axisLine={false} tickLine={false} tick={{ fill: "#7d879a", fontSize: 11 }} interval="preserveStartEnd" />
                <YAxis axisLine={false} tickLine={false} allowDecimals={false} tick={{ fill: "#7d879a", fontSize: 11 }} />
                <Tooltip content={<AppTooltip />} cursor={{ stroke: "#efbd5b", strokeDasharray: "3 3" }} />
                <Area isAnimationActive={false} type="monotone" dataKey="hits" stroke="#efbd5b" strokeWidth={2.5} fill="url(#goldArea)" activeDot={{ r: 5, fill: "#efbd5b", stroke: "#111725", strokeWidth: 3 }} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </article>

        <article className="panel probability-panel">
          <PanelHeader icon={<Target />} eyebrow="XÁC SUẤT LÝ THUYẾT" title="Một số 2 chữ số" meta={<HelpCircle size={17} />} />
          <div className="probability-orbit">
            <div><strong>23,77%</strong><span>xuất hiện ≥ 1 lần<br />trong 27 kết quả*</span></div>
          </div>
          <div className="formula-line"><code>1 − (99/100)<sup>27</sup></code><span>≈ 0,2377</span></div>
          <p className="panel-caption">*Mô hình lý thuyết giả định 27 đuôi số độc lập và phân phối đều. Xác suất trúng riêng giải đặc biệt là 1%.</p>
        </article>
      </section>

      <section className="panel heatmap-panel">
        <PanelHeader icon={<CircleGauge />} eyebrow="BẢN ĐỒ 00–99" title="Mật độ xuất hiện" meta={<div className="heat-legend"><span>Ít</span><i /><i /><i /><i /><span>Nhiều</span></div>} />
        <div className="number-heatmap">
          {stats.map((item) => {
            const max = hot[0]?.count || 1;
            const intensity = item.count / max;
            return (
              <button key={item.number} title={`${item.number}: ${item.count} lần · ${item.gap ?? "—"} kỳ gan`} style={{ "--heat": intensity } as React.CSSProperties}>
                <strong>{item.number}</strong><small>{item.count}</small>
              </button>
            );
          })}
        </div>
        <div className="heatmap-summary">
          <div><Flame /><span><small>Nhóm xuất hiện nhiều</small><strong>{hot.map((item) => item.number).join(" · ")}</strong></span></div>
          <div><Snowflake /><span><small>Nhóm xuất hiện ít</small><strong>{cold.map((item) => item.number).join(" · ")}</strong></span></div>
          <div><Clock3 /><span><small>Nhóm lâu chưa xuất hiện</small><strong>{overdue.map((item) => item.number).join(" · ")}</strong></span></div>
        </div>
      </section>

      <section className="overview-grid stats-row">
        <article className="panel pair-panel">
          <PanelHeader icon={<Target />} eyebrow="CẶP SỐ" title="Cặp xuất hiện nhiều nhất" meta={<span className="source-chip"><span />{draws.length} kỳ</span>} />
          <div className="pair-list">
            {pairStats.length > 0 ? pairStats.slice(0, 12).map((item, index) => (
              <div key={item.pair} className="pair-row">
                <span className="pair-rank">#{index + 1}</span>
                <span className="pair-numbers">{item.pair}</span>
                <span className="pair-count">{item.count} lần</span>
                <div className="pair-bar"><div style={{ width: `${(item.count / (pairStats[0]?.count || 1)) * 100}%` }} /></div>
              </div>
            )) : <EmptyState>Chưa đủ dữ liệu.</EmptyState>}
          </div>
        </article>

        <article className="panel dow-panel">
          <PanelHeader icon={<CalendarDays />} eyebrow="NGÀY TRONG TUẦN" title="Phân bố theo ngày" meta={<span className="source-chip"><span />Trung bình</span>} />
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={dayStats.map((d) => ({ name: d.day, hits: d.drawHits, total: d.count }))} margin={{ top: 8, right: 5, left: -22, bottom: 0 }}>
              <CartesianGrid vertical={false} stroke="#273044" strokeDasharray="3 5" />
              <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: "#8c96a8", fontSize: 10 }} />
              <YAxis axisLine={false} tickLine={false} tick={{ fill: "#8c96a8", fontSize: 9 }} />
              <Tooltip cursor={{ fill: "rgba(255,255,255,.03)" }} contentStyle={{ background: "#151c2b", border: "1px solid #2c3548", borderRadius: 10 }} />
              <Bar dataKey="hits" name="Số kỳ quay" radius={[4, 4, 0, 0]}>
                {dayStats.map((entry, index) => (
                  <Cell key={entry.day} fill={index === 0 ? "#ef6f61" : "#efbd5b"} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
          <div className="dow-summary">
            {dayStats.map((d) => (
              <div key={d.day} className="dow-item">
                <strong>{d.day}</strong>
                <span>{d.drawHits} kỳ · {d.count.toLocaleString("vi-VN")} kết quả</span>
              </div>
            ))}
          </div>
        </article>
      </section>

      <ResponsibleNotice />
    </>
  );
}

function PageHeading({ eyebrow, title, description, action }: { eyebrow: string; title: string; description: string; action?: React.ReactNode }) {
  return (
    <section className="page-heading">
      <div><span>{eyebrow}</span><h1>{title}</h1><p>{description}</p></div>
      {action}
    </section>
  );
}

function PanelHeader({ icon, eyebrow, title, meta }: { icon: React.ReactNode; eyebrow: string; title: string; meta?: React.ReactNode }) {
  return (
    <header className="panel-header">
      <div className="panel-title-icon">{icon}</div>
      <div className="panel-title"><span>{eyebrow}</span><h2>{title}</h2></div>
      {meta && <div className="panel-meta">{meta}</div>}
    </header>
  );
}

function PrizeBoard({ draw }: { draw: LotteryDraw }) {
  const groups = draw.results.reduce<Record<string, string[]>>((accumulator, result) => {
    (accumulator[result.prize] ??= []).push(result.value);
    return accumulator;
  }, {});
  const preferredOrder = ["Đặc biệt", "Giải nhất", "Giải nhì", "Giải ba", "Giải tư", "Giải năm", "Giải sáu", "Giải bảy"];
  const entries = Object.entries(groups).sort(([a], [b]) => {
    const ai = preferredOrder.indexOf(a);
    const bi = preferredOrder.indexOf(b);
    return (ai < 0 ? 99 : ai) - (bi < 0 ? 99 : bi);
  });

  return (
    <div className="prize-board">
      {entries.map(([prize, values]) => (
        <div className={`prize-line ${prize === "Đặc biệt" ? "special" : ""}`} key={prize}>
          <span>{prize.replaceAll("_", " ")}</span>
          <div>{values.map((value, index) => <strong key={`${value}-${index}`}>{value}</strong>)}</div>
        </div>
      ))}
    </div>
  );
}

function Analyzer({ draws, stats }: { draws: LotteryDraw[]; stats: NumberStat[] }) {
  const [raw, setRaw] = useState("08, 23, 47, 62");
  const [sets, setSets] = useState<CompareSet[]>([
    { id: 1, label: "Bộ A", numbers: ["08", "23", "47", "62"] },
    { id: 2, label: "Bộ B", numbers: ["11", "36", "58", "90"] },
  ]);
  const [randomSize, setRandomSize] = useState(5);
  const [favoriteCount, setFavoriteCount] = useState(() => {
    if (typeof window === "undefined") return 0;
    return (JSON.parse(localStorage.getItem("tk24:favorites") ?? "[]") as string[][]).length;
  });
  const parsed = useMemo(() => parseNumberSet(raw), [raw]);
  const statMap = useMemo(() => new Map(stats.map((item) => [item.number, item])), [stats]);
  const selectedStats = parsed.numbers.map((number) => statMap.get(number)).filter((item): item is NumberStat => Boolean(item));
  const probability = calculateSetProbability(parsed.numbers.length);
  const structure = useMemo(() => calculateStructure(draws), [draws]);

  function generate() {
    const numbers = secureRandomNumbers(randomSize);
    setRaw(numbers.join(", "));
  }

  function addComparison() {
    if (!parsed.numbers.length) return;
    setSets((current) => [
      ...current.slice(-3),
      { id: Date.now(), label: `Bộ ${String.fromCharCode(65 + current.length)}`, numbers: parsed.numbers },
    ]);
  }

  function saveFavorite() {
    if (!parsed.numbers.length) return;
    const stored = JSON.parse(localStorage.getItem("tk24:favorites") ?? "[]") as string[][];
    const key = parsed.numbers.join("-");
    const unique = [...stored.filter((item) => item.join("-") !== key), parsed.numbers].slice(-12);
    localStorage.setItem("tk24:favorites", JSON.stringify(unique));
    setFavoriteCount(unique.length);
  }

  const comparison = sets.map((set) => {
    const hitDraws = draws.filter((draw) => {
      const values = draw.results.map((result) => lastTwoDigits(result.value));
      return set.numbers.some((number) => values.includes(number));
    }).length;
    return { ...set, theory: calculateSetProbability(set.numbers.length) * 100, history: draws.length ? (hitDraws / draws.length) * 100 : 0 };
  });

  return (
    <>
      <PageHeading eyebrow="PHÒNG PHÂN TÍCH" title="Kiểm tra bộ số" description="Đặt lịch sử cạnh xác suất lý thuyết để có một góc nhìn tỉnh táo hơn." />

      <section className="analyzer-layout">
        <article className="panel analyzer-input-panel">
          <PanelHeader icon={<CircleGauge />} eyebrow="BƯỚC 1" title="Nhập bộ số" meta={<span className="selection-count">{parsed.numbers.length}/20 số</span>} />
          <div className="analyzer-form">
            <label>Dãy số cần phân tích<textarea value={raw} onChange={(event) => setRaw(event.target.value)} placeholder="Ví dụ: 08, 23, 47, 62" /></label>
            <div className="input-help"><span>Tách số bằng dấu phẩy hoặc khoảng trắng.</span>{parsed.invalid.length > 0 && <strong>Sai định dạng: {parsed.invalid.join(", ")}</strong>}</div>
            <div className="selected-pills">{parsed.numbers.map((number) => <span key={number}>{number}</span>)}</div>
            <div className="form-actions"><button className="primary-button" onClick={addComparison}><Plus size={17} />Thêm vào so sánh</button><button className="secondary-button" onClick={saveFavorite}><Star size={16} />Lưu ({favoriteCount})</button><button className="secondary-button" onClick={() => setRaw("")}><X size={16} />Xóa</button></div>
          </div>
        </article>

        <article className="panel random-panel">
          <PanelHeader icon={<Dices />} eyebrow="BỘ TẠO MINH BẠCH" title="Chọn số ngẫu nhiên" />
          <div className="random-copy"><p>Dùng <strong>Web Crypto API</strong> và rejection sampling để tránh thiên lệch modulo. Không dùng lịch sử để “tối ưu” kết quả.</p></div>
          <label className="range-control"><span>Số lượng: <strong>{randomSize}</strong></span><input type="range" min="1" max="12" value={randomSize} onChange={(event) => setRandomSize(Number(event.target.value))} /></label>
          <button className="gold-button" onClick={generate}><RefreshCw size={17} />Tạo bộ số mới</button>
          <div className="algorithm-note"><ShieldCheck size={17} /><span>Có thể kiểm tra mã nguồn hàm sinh số trong <code>lib/statistics.ts</code>.</span></div>
        </article>
      </section>

      <section className="analysis-metrics">
        <article><span>Xác suất ≥ 1 số xuất hiện</span><strong>{percentage(probability, 2)}</strong><small>Lý thuyết · 27 kết quả</small></article>
        <article><span>Tổng lượt trong lịch sử</span><strong>{selectedStats.reduce((sum, item) => sum + item.count, 0)}</strong><small>Trên {draws.length} kỳ đã lọc</small></article>
        <article><span>Tỷ lệ quan sát trung bình</span><strong>{percentage(selectedStats.length ? selectedStats.reduce((sum, item) => sum + item.drawRate, 0) / selectedStats.length : 0)}</strong><small>Mỗi số · theo kỳ</small></article>
        <article><span>Độ lệch lớn nhất</span><strong>{selectedStats.length ? Math.max(...selectedStats.map((item) => Math.abs(item.zScore))).toFixed(2) : "0.00"}σ</strong><small>So với phân phối đều</small></article>
      </section>

      <section className="overview-grid analysis-row">
        <article className="panel stats-table-panel">
          <PanelHeader icon={<Activity />} eyebrow="LỊCH SỬ" title="Hồ sơ từng số" meta={<span className="source-chip"><span />{draws.length} kỳ</span>} />
          {selectedStats.length ? (
            <div className="table-scroll"><table><thead><tr><th>Số</th><th>Lượt</th><th>Tỷ lệ ô</th><th>Tỷ lệ kỳ</th><th>Khoảng gan</th><th>Độ lệch</th></tr></thead><tbody>{selectedStats.map((item) => <tr key={item.number}><td><NumberPill number={item.number} tone={item.zScore > 1 ? "hot" : item.zScore < -1 ? "cold" : "neutral"} /></td><td><strong>{item.count}</strong></td><td>{percentage(item.rate, 2)}</td><td>{percentage(item.drawRate)}</td><td>{item.gap ?? "—"} kỳ</td><td><span className={item.zScore >= 0 ? "delta up" : "delta down"}>{item.zScore >= 0 ? "+" : ""}{item.zScore.toFixed(2)}σ</span></td></tr>)}</tbody></table></div>
          ) : <EmptyState>Nhập ít nhất một số hợp lệ từ 00 đến 99.</EmptyState>}
        </article>

        <article className="panel independence-panel">
          <PanelHeader icon={<ShieldCheck />} eyebrow="ĐỌC ĐÚNG DỮ LIỆU" title="Các kỳ quay độc lập" />
          <div className="independence-visual"><span>P(A)</span><i /><span>P(B)</span><strong>=</strong><span>P(A) × P(B)</span></div>
          <p>Nếu quy trình quay là công bằng và các kỳ độc lập, việc một số đã lâu chưa xuất hiện <strong>không khiến nó “đến lượt”</strong> ở kỳ tiếp theo.</p>
          <div className="plain-warning"><AlertCircle size={18} /><span>Tần suất, độ lệch và khoảng gan chỉ mô tả dữ liệu quá khứ.</span></div>
        </article>
      </section>

      <section className="panel structure-panel">
        <PanelHeader icon={<CircleGauge />} eyebrow="CẤU TRÚC 2 CHỮ SỐ" title="Đầu, đuôi, tổng và khoảng số" meta={<span className="selection-count">{draws.length} kỳ</span>} />
        <div className="structure-content">
          <div className="structure-chart">
            <h3>Tần suất chữ số 0–9</h3>
            <ResponsiveContainer width="100%" height={190}><BarChart data={structure.digitCounts} margin={{ top: 8, right: 5, left: -22, bottom: 0 }}><CartesianGrid vertical={false} stroke="#273044" strokeDasharray="3 5" /><XAxis dataKey="digit" axisLine={false} tickLine={false} tick={{ fill: "#8c96a8", fontSize: 10 }} /><YAxis axisLine={false} tickLine={false} tick={{ fill: "#8c96a8", fontSize: 9 }} /><Tooltip cursor={{ fill: "rgba(255,255,255,.03)" }} contentStyle={{ background: "#151c2b", border: "1px solid #2c3548", borderRadius: 10 }} /><Bar isAnimationActive={false} dataKey="count" name="Lượt" radius={[4, 4, 0, 0]}>{structure.digitCounts.map((entry) => <Cell key={entry.digit} fill={Number(entry.digit) % 2 === 0 ? "#efbd5b" : "#69768d"} />)}</Bar></BarChart></ResponsiveContainer>
          </div>
          <div className="head-tail-wrap"><h3>Heatmap đầu–đuôi</h3><div className="head-tail-grid"><i />{structure.tails.map((item) => <b key={`tail-${item.digit}`}>{item.digit}</b>)}{structure.heads.flatMap((head) => [<b key={`head-${head.digit}`}>{head.digit}</b>, ...structure.tails.map((tail) => {
            const stat = stats[Number(`${head.digit}${tail.digit}`)];
            const max = Math.max(...stats.map((item) => item.count), 1);
            return <span key={`${head.digit}-${tail.digit}`} style={{ "--heat": stat.count / max } as React.CSSProperties} title={`${stat.number}: ${stat.count} lần`}>{stat.count}</span>;
          })])}</div></div>
          <div className="structure-summary">
            <div><span>Chẵn / lẻ</span><strong>{structure.parity.even.toLocaleString("vi-VN")} / {structure.parity.odd.toLocaleString("vi-VN")}</strong></div>
            <div><span>Tổng phổ biến</span><strong>{[...structure.sums].sort((a, b) => b.count - a.count)[0]?.sum ?? "—"}</strong></div>
            <div><span>Khoảng nổi bật</span><strong>{[...structure.ranges].sort((a, b) => b.count - a.count)[0]?.label ?? "—"}</strong></div>
            <div className="sequences"><span>Chuỗi cặp / bộ ba lặp lại</span><strong>{structure.sequences.slice(0, 4).map(([sequence, count]) => `${sequence} (${count})`).join(" · ") || "Chưa đủ dữ liệu"}</strong></div>
          </div>
        </div>
      </section>

      <section className="panel compare-panel">
        <PanelHeader icon={<BarChart3 />} eyebrow="SO SÁNH" title="Nhiều bộ số trên cùng màn hình" meta={<span className="selection-count">Tối đa 4 bộ</span>} />
        {comparison.length ? (
          <div className="compare-content">
            <div className="compare-chart"><ResponsiveContainer width="100%" height="100%"><BarChart data={comparison} barGap={4} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}><CartesianGrid vertical={false} stroke="#273044" strokeDasharray="3 5" /><XAxis dataKey="label" axisLine={false} tickLine={false} tick={{ fill: "#8c96a8", fontSize: 12 }} /><YAxis axisLine={false} tickLine={false} tick={{ fill: "#8c96a8", fontSize: 11 }} unit="%" /><Tooltip cursor={{ fill: "rgba(255,255,255,.03)" }} contentStyle={{ background: "#151c2b", border: "1px solid #2c3548", borderRadius: 10 }} /><Bar isAnimationActive={false} dataKey="theory" name="Lý thuyết" fill="#efbd5b" radius={[5, 5, 0, 0]} /><Bar isAnimationActive={false} dataKey="history" name="Lịch sử" fill="#58657a" radius={[5, 5, 0, 0]} /></BarChart></ResponsiveContainer></div>
            <div className="compare-list">{comparison.map((set, index) => <div key={set.id}><span className="compare-color" style={{ background: index === 0 ? "#efbd5b" : "#58657a" }} /><div><strong>{set.label}</strong><small>{set.numbers.join(" · ")}</small></div><span>{percentage(set.theory / 100)}</span><button onClick={() => setSets((current) => current.filter((item) => item.id !== set.id))} aria-label={`Xóa ${set.label}`}><X /></button></div>)}</div>
          </div>
        ) : <EmptyState>Thêm một bộ số để bắt đầu so sánh.</EmptyState>}
      </section>

      <ResponsibleNotice />
    </>
  );
}

function DataCenter({ draws, onImport }: { draws: LotteryDraw[]; onImport: (draws: LotteryDraw[]) => void }) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [fileName, setFileName] = useState("");
  const [csvText, setCsvText] = useState("");
  const [region, setRegion] = useState<Region>("Miền Bắc");
  const isJson = fileName.toLowerCase().endsWith(".json");
  const validation = useMemo(() => {
    if (!csvText) return null;
    if (!isJson) return validateCsv(csvText);
    try {
      return { validRows: parseJsonDraws(csvText, region).length, duplicateRows: 0, issues: [] };
    } catch (error) {
      return { validRows: 0, duplicateRows: 0, issues: [{ row: 0, level: "error" as const, message: error instanceof Error ? error.message : "JSON không hợp lệ." }] };
    }
  }, [csvText, isJson, region]);

  async function readFile(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (!file) return;
    setFileName(file.name);
    setCsvText(await file.text());
  }

  function confirmImport() {
    const imported = isJson ? parseJsonDraws(csvText, region) : parseCsvDraws(csvText, region);
    if (imported.length) onImport(imported);
  }

  const latestDate = [...draws].sort((a, b) => b.date.localeCompare(a.date))[0]?.date;

  return (
    <>
      <PageHeading eyebrow="QUẢN TRỊ DỮ LIỆU" title="Kho dữ liệu" description="Biết dữ liệu đến từ đâu, được kiểm tra thế nào và cập nhật khi nào." action={<button className="primary-button" onClick={() => inputRef.current?.click()}><FileUp size={17} />Chọn CSV / JSON</button>} />

      <section className="source-grid">
        <article className="panel source-card active-source"><div className="source-logo"><Database /></div><div><span>ĐANG SỬ DỤNG</span><h3>Dữ liệu mẫu cục bộ</h3><p>{draws.length} kỳ · sinh bằng seed cố định để chạy thử an toàn.</p></div><span className="verified"><Check />Sẵn sàng</span></article>
        <article className="panel source-card"><div className="source-logo api"><Cloud /></div><div><span>TÙY CHỌN</span><h3>API hợp pháp</h3><p>Ánh xạ endpoint của đơn vị được cấp quyền trong lớp dữ liệu.</p></div><button className="secondary-button" disabled>Kết nối sau</button></article>
      </section>

      <section className="data-layout">
        <article className="panel import-panel">
          <PanelHeader icon={<UploadCloud />} eyebrow="NHẬP DỮ LIỆU" title="Kiểm tra trước khi lưu" />
          <input ref={inputRef} className="sr-only" type="file" accept=".csv,.json,text/csv,application/json" onChange={readFile} />
          <button className="drop-zone" onClick={() => inputRef.current?.click()}>
            <span><FileUp /></span><strong>{fileName || "Chọn tệp CSV hoặc JSON"}</strong><small>{fileName ? "Chọn tệp khác" : "Bấm để chọn · tối đa 10 MB"}</small>
          </button>
          <div className="csv-format"><strong>Định dạng tối thiểu</strong><code>date,dac_biet,giai_nhat,giai_nhi<br />2026-09-12,12345,54321,&quot;11111 22222&quot;</code></div>
          <label className="field-label">Khu vực dữ liệu<select value={region} onChange={(event) => setRegion(event.target.value as Region)}><option>Miền Bắc</option><option>Miền Trung</option><option>Miền Nam</option></select></label>
        </article>

        <article className="panel validation-panel">
          <PanelHeader icon={<FileCheck2 />} eyebrow="KIỂM ĐỊNH" title="Báo cáo chất lượng" meta={validation && <span className={`quality-badge ${validation.issues.some((issue) => issue.level === "error") ? "warning" : "good"}`}>{validation.issues.some((issue) => issue.level === "error") ? "Cần xử lý" : "Đạt"}</span>} />
          {!validation ? <EmptyState>Chọn CSV hoặc JSON để xem lỗi định dạng, dòng trùng và kỳ có thể bị thiếu.</EmptyState> : (
            <div className="validation-content">
              <div className="validation-stats"><div><strong>{validation.validRows}</strong><span>Dòng hợp lệ</span></div><div><strong>{validation.duplicateRows}</strong><span>Dòng trùng</span></div><div><strong>{validation.issues.length}</strong><span>Cảnh báo</span></div></div>
              <div className="issue-list">{validation.issues.length ? validation.issues.slice(0, 7).map((issue, index) => <div key={`${issue.row}-${index}`} className={issue.level}><AlertCircle /><span><strong>{issue.row ? `Dòng ${issue.row}` : "Chuỗi ngày"}</strong>{issue.message}</span></div>) : <div className="all-good"><Check /><span><strong>Không phát hiện lỗi</strong>Tệp sẵn sàng để nhập.</span></div>}</div>
              <button className="primary-button full" onClick={confirmImport} disabled={!validation.validRows || validation.issues.some((issue) => issue.level === "error")}><Database size={17} />Nhập {validation.validRows} kỳ hợp lệ</button>
            </div>
          )}
        </article>
      </section>

      <section className="panel provenance-panel">
        <PanelHeader icon={<History />} eyebrow="DẤU VẾT DỮ LIỆU" title="Nguồn và lần cập nhật" />
        <div className="provenance-table"><div className="provenance-head"><span>Nguồn</span><span>Phạm vi</span><span>Cập nhật gần nhất</span><span>Trạng thái</span></div><div><span><Database />Mẫu cục bộ</span><span>Miền Bắc · {draws.length} kỳ</span><span>{latestDate ? `20:10 · ${formatDate(latestDate)}` : "—"}</span><span className="good-status"><Check />Đã kiểm tra</span></div></div>
      </section>
    </>
  );
}

function ProbabilityLab({ draws, stats }: { draws: LotteryDraw[]; stats: NumberStat[] }) {
  const [digits, setDigits] = useState(2);
  const [choices, setChoices] = useState(1);
  const [ticketPrice, setTicketPrice] = useState(10000);
  const [prize, setPrize] = useState(70000);
  const exact = exactDigitProbability(digits) ?? 0;
  const oneOfMany = Math.min(1, exact * choices);
  const ev = expectedValue(ticketPrice, prize, oneOfMany);
  const total = stats.reduce((sum, item) => sum + item.count, 0);
  const [low, high] = wilsonInterval(stats[0]?.count ?? 0, total);
  const chi = chiSquareUniform(stats);
  const simulation = monteCarloAtLeastOne(Math.min(choices, 100), 27, 10000, 2409);

  return (
    <section className="panel probability-lab">
      <PanelHeader icon={<Dices />} eyebrow="PHÒNG THỬ XÁC SUẤT" title="Tính và mô phỏng" meta={<span className="selection-count">Seed 2409 · 10.000 lượt</span>} />
      <div className="lab-grid">
        <div className="lab-controls">
          <label><span>Số chữ số</span><select value={digits} onChange={(event) => setDigits(Number(event.target.value))}>{[2,3,4,5,6].map((value) => <option key={value} value={value}>{value} chữ số</option>)}</select></label>
          <label><span>Số lựa chọn không trùng</span><input type="number" min="1" max={Math.min(100, 10 ** digits)} value={choices} onChange={(event) => setChoices(Math.max(1, Number(event.target.value)))} /></label>
          <label><span>Giá vé (₫)</span><input type="number" min="0" step="1000" value={ticketPrice} onChange={(event) => setTicketPrice(Math.max(0, Number(event.target.value)))} /></label>
          <label><span>Giải thưởng (₫)</span><input type="number" min="0" step="1000" value={prize} onChange={(event) => setPrize(Math.max(0, Number(event.target.value)))} /></label>
        </div>
        <div className="lab-results">
          <article><span>Xác suất 1 lựa chọn</span><strong>1 / {(1 / exact).toLocaleString("vi-VN")}</strong><small>{percentage(exact, Math.min(6, digits))}</small></article>
          <article><span>Một trong {choices} lựa chọn</span><strong>{percentage(oneOfMany, 4)}</strong><small>{choices} kết quả không trùng</small></article>
          <article><span>Số tổ hợp C(45,6)</span><strong>{combinations(45, 6).toLocaleString("vi-VN")}</strong><small>Ví dụ vé chọn 6 từ 45</small></article>
          <article className={ev >= 0 ? "positive" : "negative"}><span>Giá trị kỳ vọng / vé</span><strong>{ev.toLocaleString("vi-VN")} ₫</strong><small>P × giải thưởng − giá vé</small></article>
        </div>
      </div>
      <div className="test-strip">
        <div><span>Monte Carlo · bộ {Math.min(choices, 100)} số / 27 vị trí</span><strong>{percentage(simulation, 2)}</strong><small>Lý thuyết: {percentage(calculateSetProbability(Math.min(choices, 100)), 2)}</small></div>
        <div><span>Khoảng tin cậy Wilson 95% · số 00</span><strong>{percentage(low, 2)} – {percentage(high, 2)}</strong><small>{stats[0]?.count ?? 0}/{total} vị trí quan sát</small></div>
        <div><span>χ² so với phân phối đều</span><strong>{chi.toFixed(2)}</strong><small>df = 99 · mô tả trên {draws.length} kỳ</small></div>
      </div>
      <p className="lab-note"><Info />Kiểm định χ² cần được đọc cùng ngưỡng ý nghĩa và chất lượng dữ liệu. Một sai khác thống kê không chứng minh khả năng dự báo.</p>
    </section>
  );
}

function Methodology({ draws, stats }: { draws: LotteryDraw[]; stats: NumberStat[] }) {
  return (
    <>
      <PageHeading eyebrow="PHƯƠNG PHÁP MINH BẠCH" title="Công thức & giả định" description="Mỗi chỉ số đều có định nghĩa, giả định và giới hạn sử dụng rõ ràng." />
      <section className="method-grid">
        <article className="panel method-card"><span className="method-index">01</span><Target /><h2>Một số trong một kết quả</h2><code>P = 1 / 100 = 1%</code><p>Khi xét đúng hai chữ số cuối của một kết quả và giả định các số 00–99 đồng khả năng.</p></article>
        <article className="panel method-card"><span className="method-index">02</span><CircleGauge /><h2>Ít nhất một lần trong kỳ</h2><code>P = 1 − (99/100)<sup>n</sup></code><p>Với n = 27 kết quả, xác suất lý thuyết xấp xỉ 23,77% cho một số đã chọn.</p></article>
        <article className="panel method-card"><span className="method-index">03</span><Dices /><h2>Bộ k số trong một kỳ</h2><code>P = 1 − ((100−k)/100)<sup>n</sup></code><p>Xấp xỉ khi mỗi vị trí được coi là độc lập; k là số lượng số khác nhau đã chọn.</p></article>
        <article className="panel method-card"><span className="method-index">04</span><BarChart3 /><h2>Độ lệch chuẩn hóa</h2><code>z = (x − np) / √np(1−p)</code><p>So sánh số lần quan sát x với kỳ vọng np. Giá trị z lớn không phải tín hiệu dự đoán.</p></article>
        <article className="panel method-card"><span className="method-index">05</span><Activity /><h2>Tần suất quan sát</h2><code>f = số lần xuất hiện / tổng vị trí</code><p>Một thống kê mô tả phụ thuộc vào cửa sổ dữ liệu, không thay thế xác suất lý thuyết.</p></article>
        <article className="panel method-card"><span className="method-index">06</span><CalendarDays /><h2>Khoảng cách xuất hiện</h2><code>gap = kỳ hiện tại − kỳ gần nhất</code><p>“Gan” đo thời gian đã qua. Nó không có nghĩa một số sẽ sớm xuất hiện hơn.</p></article>
      </section>

      <ProbabilityLab draws={draws} stats={stats} />

      <section className="panel architecture-panel">
        <PanelHeader icon={<Database />} eyebrow="KIẾN TRÚC" title="Tách lớp để dễ kiểm tra" />
        <div className="architecture-flow"><div><Cloud /><strong>Nguồn dữ liệu</strong><span>CSV · API hợp pháp · mẫu</span></div><i>→</i><div><FileCheck2 /><strong>Kiểm định</strong><span>Trùng · thiếu · định dạng</span></div><i>→</i><div><CircleGauge /><strong>Thống kê thuần</strong><span>Tần suất · gap · z-score</span></div><i>→</i><div><LayoutDashboard /><strong>Trình bày</strong><span>Bộ lọc · biểu đồ · bảng</span></div></div>
      </section>

      <section className="panel limitations-panel"><div><AlertCircle /></div><div><span>GIỚI HẠN CẦN NHỚ</span><h2>Ngẫu nhiên không có trí nhớ</h2><p>Các mẫu ngắn hạn có thể trông rất thuyết phục chỉ do biến động ngẫu nhiên. Không có “cầu chắc thắng”, không có mô hình nào trong ứng dụng cam kết lợi nhuận hoặc kết quả tương lai.</p></div></section>
      <ResponsibleNotice />
    </>
  );
}

function ResponsibleNotice() {
  return (
    <section className="responsibility-notice">
      <div className="notice-icon"><ShieldCheck /></div>
      <div><span>18+ · CHƠI CÓ TRÁCH NHIỆM</span><h2>Hiểu xác suất. Giữ giới hạn.</h2><p>Công cụ này chỉ phục vụ học tập và giải trí; không phải tư vấn tài chính hay hệ thống dự đoán chắc chắn. Không vay tiền, không theo đuổi thua lỗ và hãy tuân thủ pháp luật nơi bạn sinh sống.</p></div>
      <a href="https://www.ncpgambling.org/help-treatment/about-the-national-problem-gambling-helpline/" target="_blank" rel="noreferrer">Tìm hiểu hỗ trợ<ArrowUpRight /></a>
    </section>
  );
}
