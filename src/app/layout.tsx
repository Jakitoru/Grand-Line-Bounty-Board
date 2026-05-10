import type { Metadata } from "next";
import "./globals.css";

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
    <html lang="vi" className="h-full antialiased scroll-smooth">
      <body className="min-h-full flex flex-col bg-[#020617] text-slate-100">
        {children}
      </body>
    </html>
  );
}
