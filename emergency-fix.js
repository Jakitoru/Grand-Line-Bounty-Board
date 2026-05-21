
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = "https://akkkcxnelsmixflgnuwe.supabase.co";
const supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFra2tjeG5lbHNtaXhmbGdudXdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzMjYxMDMsImV4cCI6MjA5MzkwMjEwM30.K7eHCLmR7NC6vwmnUxM14jsbfLXTYw2qPBwOdaGWEvc";

const supabase = createClient(supabaseUrl, supabaseKey);

async function fixData() {
  console.log("🚀 Bắt đầu quá trình dọn dẹp và sửa lỗi dữ liệu...");

  // 1. Xóa toàn bộ dữ liệu hiện tại
  console.log("🧹 Đang xóa toàn bộ nhân vật cũ...");
  const { error: deleteError } = await supabase.from('characters').delete().neq('id', 0);
  
  if (deleteError) {
    console.error("❌ Lỗi khi xóa dữ liệu:", deleteError.message);
    return;
  }
  console.log("✅ Đã dọn sạch database.");

  // 2. Nạp lại dữ liệu chuẩn từ file data.ts
  const coreCharacters = [
    {
      name: "Monkey D. Luffy",
      alias: "Mũ Rơm",
      bounty: 3000000000,
      affiliation: "Băng Mũ Rơm",
      role: "Thuyền trưởng (Tứ Hoàng)",
      devil_fruit: "Hito Hito no Mi, Model: Nika",
      devil_fruit_type: "Zoan Thần Thoại",
      hometown: "Làng Foosha, Biển Đông",
      age: 19,
      height: 174,
      status: "Còn sống",
      description: "Nhân vật chính của One Piece.",
      image_url: "https://static.wikia.nocookie.net/onepiece/images/6/6d/Monkey_D._Luffy_Anime_Post_Timeskip_Infobox.png"
    },
    {
      name: "Monkey D. Dragon",
      alias: "Nhà Cách Mạng",
      bounty: 0,
      affiliation: "Quân Cách Mạng",
      role: "Tổng tư lệnh",
      devil_fruit: "Trái Thời Tiết (Dự kiến)",
      devil_fruit_type: "Chưa xác định",
      hometown: "Làng Foosha, Biển Đông",
      age: 55,
      height: 256,
      status: "Còn sống",
      description: "Người đàn ông bị truy nã gắt gao nhất thế giới.",
      image_url: "https://static.wikia.nocookie.net/onepiece/images/f/f5/Monkey_D._Dragon_Anime_Infobox.png"
    },
    {
      name: "Douglas Bullet",
      alias: "Kế Thừa Quỷ Dữ",
      bounty: 0,
      affiliation: "Cựu Băng Roger",
      role: "Hải tặc đơn độc",
      devil_fruit: "Gasha Gasha no Mi",
      devil_fruit_type: "Paramecia",
      hometown: "Tân Thế Giới",
      age: 45,
      height: 491,
      status: "Còn sống",
      description: "Một con quái vật chiến tranh đích thực.",
      image_url: "https://static.wikia.nocookie.net/onepiece/images/5/54/Douglas_Bullet_Anime_Infobox.png"
    }
  ];

  console.log(`📥 Đang nạp lại dữ liệu chuẩn...`);
  const { error: insertError } = await supabase.from('characters').insert(coreCharacters);

  if (insertError) {
    console.error("❌ Lỗi khi nạp dữ liệu:", insertError.message);
  } else {
    console.log("✨ THÀNH CÔNG! Dragon đã về mức 0 và Bullet không còn bị lặp.");
    console.log("👉 Bây giờ bạn hãy quay lại Web, F5 và nhấn nút 'Sync Data' một lần cuối để lấy đầy đủ 53 nhân vật.");
  }
}

fixData();
