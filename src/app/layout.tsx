import type { Metadata } from "next";
import { Playfair_Display, Montserrat } from "next/font/google";
import "./globals.css";

const playfair = Playfair_Display({ 
  subsets: ["latin", "vietnamese"],
  variable: "--font-serif",
  display: "swap",
});

const montserrat = Montserrat({ 
  subsets: ["latin", "vietnamese"],
  variable: "--font-sans",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Grand Line Bounty Board - Hệ Thống Truy Nã Hải Tặc One Piece",
  description: "Trang web theo dõi tiền truy nã, thông tin chi tiết và tạo lệnh truy nã hải tặc cho riêng bạn bằng Next.js và Supabase.",
  referrer: "no-referrer",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="vi" className={`h-full antialiased scroll-smooth ${playfair.variable} ${montserrat.variable}`}>
      <body className="min-h-full flex flex-col bg-[#020617] text-slate-100 font-sans">
        {children}
      </body>
    </html>
  );
}
