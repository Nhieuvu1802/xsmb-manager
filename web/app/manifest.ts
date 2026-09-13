import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Xổ số 24/7 — Tra cứu & thống kê",
    short_name: "Xổ số 24/7",
    description: "Tra cứu kết quả XSMB và thống kê lô tô.",
    id: "/",
    start_url: "/",
    scope: "/",
    lang: "vi",
    display: "standalone",
    background_color: "#f7f1e7",
    theme_color: "#9f1d20",
    orientation: "portrait-primary",
    categories: ["utilities", "finance"],
    icons: [
      { src: "/icon.svg", sizes: "any", type: "image/svg+xml", purpose: "any" },
      { src: "/icon.svg", sizes: "any", type: "image/svg+xml", purpose: "maskable" },
    ],
    shortcuts: [
      { name: "Kết quả", short_name: "Kết quả", url: "/#ket-qua", icons: [{ src: "/icon.svg", sizes: "any", type: "image/svg+xml" }] },
      { name: "Thống kê", short_name: "Thống kê", url: "/#thong-ke", icons: [{ src: "/icon.svg", sizes: "any", type: "image/svg+xml" }] }
    ]
  };
}
