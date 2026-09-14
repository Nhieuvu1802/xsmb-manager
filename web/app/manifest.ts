import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Thống Kê 24 — Phân tích xác suất xổ số",
    short_name: "Thống Kê 24",
    description: "Công cụ tra cứu và thống kê xổ số minh bạch cho mục đích học tập, giải trí.",
    id: "/",
    start_url: "/",
    scope: "/",
    lang: "vi",
    display: "standalone",
    background_color: "#070b12",
    theme_color: "#0b101b",
    orientation: "portrait-primary",
    categories: ["utilities", "education"],
    icons: [
      { src: "/icon-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
      { src: "/icon-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
      { src: "/icon-512.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
    ],
    shortcuts: [
      { name: "Mở ứng dụng", short_name: "Mở", url: "/", icons: [{ src: "/icon-192.png", sizes: "192x192", type: "image/png" }] },
    ]
  };
}
