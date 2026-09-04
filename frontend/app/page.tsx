"use client";

import { FormEvent, useCallback, useEffect, useMemo, useState } from "react";
import { getResults, login, LotteryResult, syncMb } from "@/lib/api";

const today = new Date().toISOString().slice(0, 10);
const weekAgo = new Date(Date.now() - 6 * 86400000).toISOString().slice(0, 10);
const prizeOrder = ["Đặc biệt", "Giải nhất", "Giải nhì", "Giải ba", "Giải tư", "Giải năm", "Giải sáu", "Giải bảy"];
const apiUrl = (process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000").replace(/\/$/, "");

function formatDate(value: string) {
  return new Intl.DateTimeFormat("vi-VN", { weekday: "long", day: "2-digit", month: "2-digit", year: "numeric" }).format(new Date(`${value}T00:00:00`));
}

export default function Dashboard() {
  const [start, setStart] = useState(weekAgo);
  const [end, setEnd] = useState(today);
  const [results, setResults] = useState<LotteryResult[]>([]);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [online, setOnline] = useState(() => typeof navigator === "undefined" || navigator.onLine);
  const [token, setToken] = useState("");
  const [showLogin, setShowLogin] = useState(false);
  const [syncing, setSyncing] = useState(false);

  const load = useCallback(async () => {
    setLoading(true); setError("");
    try {
      const data = await getResults(start, end);
      setResults(data);
      localStorage.setItem("xsmb:last-results", JSON.stringify(data));
    } catch (reason) {
      const cached = localStorage.getItem("xsmb:last-results");
      if (cached) {
        setResults(JSON.parse(cached));
        setMessage("Đang hiển thị dữ liệu gần nhất đã lưu trên thiết bị.");
      } else setError(reason instanceof Error ? reason.message : "Không thể tải dữ liệu");
    } finally { setLoading(false); }
  }, [start, end]);

  useEffect(() => {
    const timer = window.setTimeout(() => void load(), 0);
    return () => window.clearTimeout(timer);
  }, [load]);
  useEffect(() => {
    const update = () => setOnline(navigator.onLine);
    window.addEventListener("online", update); window.addEventListener("offline", update);
    return () => { window.removeEventListener("online", update); window.removeEventListener("offline", update); };
  }, []);

  const drawDates = useMemo(() => [...new Set(results.map((item) => item.draw_date))].sort().reverse(), [results]);
  const selectedDate = drawDates[0];
  const board = useMemo(() => results.filter((item) => item.draw_date === selectedDate), [results, selectedDate]);
  const frequent = useMemo(() => {
    const counts = new Map<string, number>();
    results.forEach((item) => counts.set(item.loto2, (counts.get(item.loto2) ?? 0) + 1));
    return [...counts].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0])).slice(0, 6);
  }, [results]);

  async function submitLogin(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); setError("");
    const data = new FormData(event.currentTarget);
    try {
      const auth = await login(String(data.get("username")), String(data.get("password")));
      setToken(auth.access_token); setShowLogin(false); setMessage("Đã đăng nhập quản trị trong phiên này.");
    } catch (reason) { setError(reason instanceof Error ? reason.message : "Đăng nhập thất bại"); }
  }

  async function synchronize() {
    if (!token) { setShowLogin(true); return; }
    setSyncing(true); setError("");
    try {
      const response = await syncMb(start, end, token);
      setMessage(`Đã đồng bộ ${response.saved} kỳ${response.errors.length ? `, ${response.errors.length} lỗi` : ""}.`);
      await load();
    } catch (reason) { setError(reason instanceof Error ? reason.message : "Đồng bộ thất bại"); }
    finally { setSyncing(false); }
  }

  return (
    <main>
      <header className="topbar">
        <a className="brand" href="#top" aria-label="Xổ số 24/7 — Trang chủ"><span className="brandMark">24/7</span><span>XỔ SỐ <b>THỐNG KÊ</b></span></a>
        <nav aria-label="Điều hướng chính"><a className="active" href="#ket-qua">Kết quả</a><a href="#thong-ke">Thống kê</a><a href={`${apiUrl}/docs`} target="_blank" rel="noreferrer">API</a></nav>
        <button className="accountButton" onClick={() => token ? setToken("") : setShowLogin(true)}>{token ? "Đăng xuất" : "Quản trị"}</button>
      </header>

      <section className="hero" id="top">
        <div><p className="eyebrow">DỮ LIỆU MINH BẠCH · CẬP NHẬT LIÊN TỤC</p><h1>Kết quả rõ ràng.<br/><em>Thống kê có chiều sâu.</em></h1><p className="lede">Tra cứu XSMB nhanh, theo dõi tần suất lô tô và mang dữ liệu theo bạn ngay cả khi mất mạng.</p></div>
        <div className={`connection ${online ? "online" : "offline"}`}><span />{online ? "Đang trực tuyến" : "Chế độ ngoại tuyến"}</div>
      </section>

      <section className="controlPanel" aria-label="Bộ lọc kết quả">
        <label>Từ ngày<input type="date" value={start} max={end} onChange={(e) => setStart(e.target.value)} /></label>
        <label>Đến ngày<input type="date" value={end} min={start} max={today} onChange={(e) => setEnd(e.target.value)} /></label>
        <button className="primary" onClick={load} disabled={loading}>{loading ? "Đang tải…" : "Tra cứu"}</button>
        <button className="secondary" onClick={synchronize} disabled={syncing}>{syncing ? "Đang đồng bộ…" : "Đồng bộ dữ liệu"}</button>
      </section>

      {(message || error) && <div className={`notice ${error ? "error" : ""}`} role="status">{error || message}</div>}

      <section className="dashboard" id="ket-qua">
        <article className="resultCard">
          <div className="sectionHead"><div><p className="kicker">XỔ SỐ MIỀN BẮC</p><h2>{selectedDate ? formatDate(selectedDate) : "Chưa có dữ liệu"}</h2></div><span className="drawCount">{drawDates.length} kỳ</span></div>
          {loading ? <div className="skeleton">Đang tải kết quả…</div> : board.length ? (
            <div className="prizeBoard">
              {prizeOrder.map((prize) => {
                const values = board.filter((item) => item.prize === prize).sort((a, b) => a.position - b.position);
                if (!values.length) return null;
                return <div className={`prizeRow ${prize === "Đặc biệt" ? "special" : ""}`} key={prize}><span>{prize}</span><div>{values.map((item) => <b key={`${item.prize}-${item.position}`}>{item.full_number}</b>)}</div></div>;
              })}
            </div>
          ) : <div className="empty"><b>Không có kết quả trong khoảng này</b><span>Hãy chọn khoảng ngày khác hoặc đăng nhập để đồng bộ.</span></div>}
        </article>

        <aside className="insights" id="thong-ke">
          <div className="sectionHead"><div><p className="kicker">NHỊP DỮ LIỆU</p><h2>Lô tô nổi bật</h2></div></div>
          <div className="numberGrid">{frequent.length ? frequent.map(([number, count], index) => <div className="numberTile" key={number}><span>#{index + 1}</span><b>{number}</b><small>{count} lần</small></div>) : <p>Chưa đủ dữ liệu thống kê.</p>}</div>
          <div className="insightNote"><b>Góc nhìn dữ liệu</b><p>Tần suất chỉ phản ánh lịch sử trong khoảng đã chọn, không đảm bảo kết quả tương lai.</p></div>
        </aside>
      </section>

      <footer><span>© 2026 Xổ số 24/7</span><span>Dữ liệu dành cho mục đích tham khảo</span></footer>

      {showLogin && <div className="modalBackdrop" onMouseDown={() => setShowLogin(false)}><form className="loginCard" onSubmit={submitLogin} onMouseDown={(e) => e.stopPropagation()}><button type="button" className="close" onClick={() => setShowLogin(false)} aria-label="Đóng">×</button><p className="kicker">KHU VỰC QUẢN TRỊ</p><h2>Đăng nhập để đồng bộ</h2><label>Tên đăng nhập<input name="username" autoComplete="username" required /></label><label>Mật khẩu<input name="password" type="password" autoComplete="current-password" required /></label><button className="primary" type="submit">Đăng nhập</button><small>JWT chỉ được giữ trong bộ nhớ và bị xoá khi đóng trang.</small></form></div>}
    </main>
  );
}
