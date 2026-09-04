import type { Metadata, Viewport } from "next";
import { Manrope, Roboto_Mono } from "next/font/google";
import { PwaRegister } from "@/components/pwa-register";
import "./globals.css";

const sans = Manrope({ subsets: ["latin", "vietnamese"], variable: "--font-sans" });
const mono = Roboto_Mono({ subsets: ["latin", "vietnamese"], variable: "--font-mono" });

export const metadata: Metadata = {
  title: "Xổ số 24/7 — Tra cứu & thống kê",
  description: "Tra cứu kết quả XSMB, thống kê lô tô và đồng bộ dữ liệu trên mọi thiết bị.",
  applicationName: "Xổ số 24/7",
  manifest: "/manifest.webmanifest",
  appleWebApp: { capable: true, statusBarStyle: "black-translucent", title: "Xổ số 24/7" }
};

export const viewport: Viewport = { themeColor: "#9f1d20", colorScheme: "light" };

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="vi">
      <body className={`${sans.variable} ${mono.variable}`}>
        {children}
        <PwaRegister />
      </body>
    </html>
  );
}
