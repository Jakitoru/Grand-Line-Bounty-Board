# 🏴‍☠️ Grand Line Bounty Board - Hệ Thống Truy Nã Hải Tặc One Piece

Dự án web theo dõi tiền truy nã, thông tin chi tiết và tạo lệnh truy nã hải tặc cho riêng bạn, được xây dựng bằng **Next.js (App Router)**, **TypeScript**, **Tailwind CSS v4** và bọc kết nối cơ sở dữ liệu **Supabase**.

---

## ✨ Các Tính Năng Nổi Bật

1. **Hiển Thị Lệnh Truy Nã (Wanted Posters) Cực Đẹp:**
   - Các thẻ nhân vật được thiết kế theo phong cách lệnh truy nã cổ điển của hải quân (Wanted Posters), sử dụng hiệu ứng giấy da cổ, viền gỗ dày, phông chữ có chân `Cinzel` sang trọng, và bộ lọc màu sepia đặc sắc.
   - Hiệu ứng lia bóng sáng (Shine animation) khi rê chuột qua thẻ và lật nhẹ tạo cảm giác cực kỳ cao cấp.

2. **Tìm Kiếm & Bộ Lọc Nâng Cao:**
   - Tìm kiếm tức thì theo Tên, Biệt danh, hoặc Trái ác quỷ.
   - Lọc nhanh theo thế lực chính: *Băng Mũ Rơm, Băng Tóc Đỏ, Băng Râu Trắng, Băng Râu Đen, Cross Guild, Quân Cách Mạng, Hải Quân*.
   - Sắp xếp thông minh theo: Tiền truy nã (Cao → Thấp, Thấp → Cao), Tuổi tác, hoặc Chiều cao.

3. **Xem Chi Tiết Hải Tặc (Pirate Scroll Modal):**
   - Bấm vào một tấm lệnh truy nã bất kỳ để mở cuộn thư cổ hiển thị đầy đủ thông số: Chức vụ, Trái ác quỷ sở hữu, Hệ trái ác quỷ, Tuổi, Chiều cao, Quê quán, Trạng thái hoạt động (Còn sống/Đã mất) và hồ sơ tiểu sử phạm tội chi tiết.

4. **Tạo Mới & Phát Hành Lệnh Truy Nã Riêng:**
   - Cho phép người dùng tự thiết kế lệnh truy nã với đầy đủ các thuộc tính tùy chỉnh.
   - Hỗ trợ chọn nhanh các mẫu ảnh chân dung đẹp từ Unsplash.

5. **Kết Nối Thông Minh Hai Chế Độ (Supabase & Local Fallback):**
   - **Chế độ Ngoại tuyến (Local Fallback):** Nếu chưa cấu hình Supabase, hệ thống hoạt động mượt mà thông qua bộ dữ liệu mẫu mặc định kết hợp lưu trữ trong `localStorage` cho các nhân vật tự tạo mới.
   - **Chế độ Trực tuyến (Supabase DB):** Chỉ cần điền cấu hình API, hệ thống sẽ tự động đồng bộ hóa đọc/ghi/xóa trực tuyến hai chiều tới cơ sở dữ liệu Supabase đám mây của bạn!

---

## 🛠️ Công Nghệ Sử Dụng

- **Framework**: Next.js 16 (App Router, Turbopack)
- **Ngôn ngữ**: TypeScript
- **Styling**: Tailwind CSS v4, kết hợp Vanilla CSS cho hiệu ứng giấy da cổ điển & kính mờ (Glassmorphism)
- **Cơ sở dữ liệu**: Supabase (PostgreSQL Client)
- **Icons**: Lucide React

---

## 🚀 Hướng Dẫn Bắt Đầu Nhanh

### 1. Khởi động môi trường phát triển (Dev Server)

Di chuyển vào thư mục dự án và chạy các lệnh sau:

```bash
cd one-piece-app
npm run dev
```

Mở trình duyệt truy cập: [http://localhost:3000](http://localhost:3000) để trải nghiệm ứng dụng ngay lập tức!

### 2. Thiết lập cơ sở dữ liệu Supabase (Tùy chọn)

Để đồng bộ dữ liệu lên cơ sở dữ liệu đám mây Supabase:

1. Đăng nhập vào [Supabase Console](https://supabase.com) và tạo một Project mới.
2. Truy cập vào phần **SQL Editor** trong bảng quản trị Supabase của bạn, sao chép toàn bộ mã SQL trong file:
   👉 [**`supabase-schema.sql`**](./supabase-schema.sql) nằm ở thư mục gốc của dự án này, dán vào và nhấn **Run** để khởi tạo bảng và dữ liệu mẫu hải tặc huyền thoại.
3. Nhân bản tệp [**.env.local.example**](./.env.local.example) thành `.env.local`:
   ```bash
   cp .env.local.example .env.local
   ```
4. Mở tệp `.env.local` lên và thay thế bằng các thông số thực tế lấy từ **Project Settings → API** trên Supabase:
   ```env
   NEXT_PUBLIC_SUPABASE_URL=đường_dẫn_supabase_của_bạn
   NEXT_PUBLIC_SUPABASE_ANON_KEY=mã_anon_key_của_bạn
   ```
5. Khởi động lại Dev Server (`npm run dev`) để hoàn thành kết nối trực tiếp!

---

## 📂 Sơ Đồ Cấu Trúc Dự Án

```text
one-piece-app/
├── public/                 # Các tài nguyên tĩnh
├── src/
│   ├── app/
│   │   ├── globals.css     # Định nghĩa thiết kế, font chữ & animation tùy chỉnh
│   │   ├── layout.tsx      # Bố cục trang chung & SEO tối ưu
│   │   └── page.tsx        # Giao diện điều khiển chính & Quản lý logic
│   └── lib/
│       ├── data.ts         # Dataset gốc & Định nghĩa kiểu dữ liệu hải tặc
│       └── supabase.ts     # Trình xử lý kết nối bọc Supabase & Local Fallback
├── .env.local.example      # Tệp cấu hình mẫu API Supabase
├── supabase-schema.sql     # Schema SQL xây dựng cơ sở dữ liệu trên Supabase
├── package.json            # Quản lý các thư viện cài đặt
└── tsconfig.json           # Cấu hình TypeScript
```

Chúc bạn có một chuyến hải trình vĩ đại tìm kiếm kho báu One Piece cùng hệ thống **Grand Line Bounty Board**! 🏴‍☠️🍖⚓
