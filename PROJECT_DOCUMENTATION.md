# 🏴‍☠️ TÀI LIỆU DỰ ÁN: GRAND LINE BOUNTY BOARD

## 1. Tổng Quan Dự Án (Overview)

**Grand Line Bounty Board** là một ứng dụng Web hiện đại, được thiết kế nhằm mục đích quản lý và hiển thị các "Lệnh Truy Nã" (Wanted Posters) của thế giới Hải Tặc One Piece. Dự án được xây dựng trên nền tảng **Next.js** kết hợp với hệ quản trị cơ sở dữ liệu thời gian thực **Supabase**, mang lại trải nghiệm mượt mà, phản hồi nhanh và dữ liệu đồng nhất.

Về mặt thị giác, ứng dụng sở hữu ngôn ngữ thiết kế đậm chất cổ điển (Vintage Document / Scroll), kết hợp với xu hướng giao diện Glassmorphism hiện đại, tạo nên một "Bảng truy nã điện tử" uy quyền nhưng vô cùng tinh tế.

---

## 2. Mục Tiêu Phát Triển (Objectives)

Dự án được thiết kế để đạt được 3 mục tiêu chiến lược cốt lõi:

### 🎯 Mục tiêu Kỹ thuật
- Xây dựng một ứng dụng **Fullstack Serverless** hoàn chỉnh sử dụng mô hình kiến trúc hiện đại (Next.js + TailwindCSS + Supabase).
- Khai thác cơ chế **Row Level Security (RLS)** trong cơ sở dữ liệu SQL để phân quyền an toàn.
- Thiết kế UI/UX có tính thẩm mỹ cao, tận dụng tối đa hiệu ứng Layering, Noise Filter và Responsive Design giúp hoạt động hoàn hảo trên mọi thiết bị (Mobile, Tablet, PC).

### 🎯 Mục tiêu Chức năng
- Cung cấp thư viện thông tin trực quan, chính xác về hơn 60 đại hải tặc khét tiếng nhất.
- Xây dựng hệ thống phân loại, tìm kiếm mạnh mẽ giúp người dùng truy vấn nhanh chóng theo Mức truy nã (Bounty), Nhóm (Affiliation), hay Trái ác quỷ (Devil Fruit).
- Hỗ trợ cá nhân hóa thông qua khả năng tự sáng tạo "Lệnh Truy Nã" cho riêng mình.

### 🎯 Mục tiêu Vận hành
- Đảm bảo hiệu năng tải trang nhanh, tối ưu hóa hình ảnh không thông qua lưu trữ cứng nhắc (sử dụng kỹ thuật tính toán liên kết URL tối ưu từ Wikia).
- Dữ liệu tự động dự phòng (Fallback): Vẫn hoạt động ổn định ngay cả khi mất kết nối database thông qua bộ nhớ đệm Local Storage.

---

## 3. Phân Tích Chức Năng Dự Án (Functional Analysis)

Ứng dụng bao gồm 4 mô-đun chức năng chính, phối hợp liền mạch với nhau:

### 📊 3.1. Mô-đun Thống Kê Chiến Lược (Stats Dashboard)
Cung cấp cái nhìn tổng thể nhanh chóng về toàn bộ dữ liệu bảng truy nã:
- **Tổng tiền truy nã:** Tính tổng lũy kế mức tiền thưởng (Belly) của tất cả hải tặc đang lưu trữ.
- **Số lượng lực lượng:** Đếm tổng số đại hải tặc đang nằm trong tầm theo dõi của chính phủ thế giới.
- **Kẻ nguy hiểm nhất:** Tự động tìm ra và vinh danh nhân vật sở hữu mức truy nã cao nhất thời điểm hiện tại.
- **Thống kê người dùng:** Hiển thị số lượng hải tặc tùy chỉnh do chính người dùng vừa khởi tạo.

### 🔍 3.2. Mô-đun Bộ Lọc và Tìm Kiếm Nâng Cao (Filtering & Search)
Hệ thống phản hồi tức thì (Instant Feedback) giúp khám phá dữ liệu hiệu quả:
- **Tìm kiếm thông minh:** Tìm theo tên nhân vật, biệt danh, hoặc loại trái ác quỷ đang sở hữu.
- **Phân loại theo Thế lực (Affiliation):** Tập hợp hệ thống Tab phân loại nhanh theo các Băng nhóm (Mũ Rơm, Tứ Hoàng, Quân Cách Mạng, Hải Quân, v.v.).
- **Sắp xếp đa tiêu chí (Sorting):** Cho phép người dùng linh hoạt sắp xếp theo Mức truy nã (Cao/Thấp), Độ tuổi, hoặc Chiều cao vật lý của nhân vật.

### 📜 3.3. Mô-đun Hiển Thị Trực Quan (Wanted Board & Details)
Đây là linh hồn của giao diện dự án:
- **Card View Poster:** Mỗi hải tặc được hiển thị dưới dạng một lệnh truy nã giấy da (Parchment). Tích hợp hiệu ứng tỏa sáng (Shine hover), xoay nhẹ và đổ bóng chân thực.
- **Pop-up Thông Tin Chi Tiết:** Khi nhấp chọn, một bảng mở rộng (Modal) hiện ra hiển thị toàn bộ hồ sơ lý lịch:
    - Ảnh chân dung đặc tả Anime chuẩn.
    - Chi tiết về Trái Ác Quỷ và hệ tương ứng.
    - Thông tin nhân trắc học: Tuổi, Chiều cao, Quê quán.
    - **Hồ Sơ Tội Phạm:** Đoạn mô tả tiểu sử chuyên sâu bằng font Serif (Lora) thanh lịch, đảm bảo hiển thị tiếng Việt hoàn hảo, đậm chất văn bản cổ truyền.

### ➕ 3.4. Mô-đun Quản Trị Dữ Liệu (CRUD & Sync Engine)
Cho phép tương tác hai chiều giữa người dùng và hệ thống dữ liệu:
- **Thiết Kế Lệnh Truy Nã Mới:** Form nhập liệu đẹp mắt cho phép người dùng nhập Tên, mức truy nã, ảnh tùy chọn và lưu lại.
- **Gỡ bỏ lệnh truy nã:** Xóa bỏ các nhân vật tự tạo một cách bảo mật thông qua cơ chế Row Level Security Policies.
- **Đồng bộ Engine (Image Sync):** Tự động khắc phục và đồng bộ toàn bộ 60 đại hải tặc lên Supabase chỉ bằng một nút nhấn.

---

## 4. Kiến Trúc Công Nghệ (Tech Stack)

| Thành phần | Công nghệ sử dụng | Vai trò |
| :--- | :--- | :--- |
| **Framework** | React 18 + Next.js 14 (App Router) | Xây dựng cấu trúc, định tuyến và tối ưu hiệu năng UI. |
| **Styling** | Tailwind CSS v4 | Xây dựng giao diện phản hồi nhanh, hoạt ảnh chuyển động đẹp. |
| **Backend/DB** | Supabase (PostgreSQL) | Lưu trữ cơ sở dữ liệu đám mây, cung cấp API thời gian thực. |
| **Icons** | Lucide React | Thư viện biểu tượng vectơ tối giản, sắc nét. |
| **Typography** | Google Fonts (Lora & Outfit) | Xử lý hiển thị văn bản tiếng Việt nghệ thuật. |
