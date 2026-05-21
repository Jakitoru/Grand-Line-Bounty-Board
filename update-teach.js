const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://akkkcxnelsmixflgnuwe.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFra2tjeG5lbHNtaXhmbGdudXdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzMjYxMDMsImV4cCI6MjA5MzkwMjEwM30.K7eHCLmR7NC6vwmnUxM14jsbfLXTYw2qPBwOdaGWEvc';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function run() {
  console.log("Step 1: Fetching Marshall D. Teach (ID 7) from Supabase...");
  const { data: characters, error: fetchError } = await supabase
    .from('characters')
    .select('*')
    .eq('id', 7);
  
  if (fetchError) {
    console.error("FETCH ERROR", fetchError);
    return;
  }
  
  if (!characters || characters.length === 0) {
    console.log("WARNING: Marshall D. Teach with ID 7 not found in DB. Database might use different IDs, searching by name...");
    const { data: byName, error: nameError } = await supabase
      .from('characters')
      .select('*')
      .ilike('name', '%Marshall%D.%Teach%');
      
    if (nameError) {
       console.error("SEARCH ERROR", nameError);
       return;
    }
    if (!byName || byName.length === 0) {
       console.log("ERROR: Marshall D. Teach not found by name either! No record to update in DB.");
       return;
    }
    console.log("Found record by name. ID is:", byName[0].id);
    characters.push(byName[0]);
  }

  const teach = characters[0];
  console.log("Current record in DB:", teach);
  console.log("Step 2: Updating DB row...");

  const { data: updated, error: updateError } = await supabase
    .from('characters')
    .update({
      affiliation: "Băng Râu Đen (Cựu Băng Râu Trắng)",
      description: "Kẻ xảo quyệt và tham vọng bậc nhất Grand Line. Teach từng có hàng chục năm ẩn mình dưới trướng Băng Râu Trắng trước khi phản bội đồng đội để cướp đoạt Trái Yami Yami. Hắn là người duy nhất trong lịch sử sở hữu sức mạnh của hai Trái Ác Quỷ cùng một lúc: bóng tối hấp thụ và chấn động hủy diệt."
    })
    .eq('id', teach.id)
    .select();

  if (updateError) {
    console.error("UPDATE ERROR", updateError);
    return;
  }

  console.log("SUCCESS! Updated record:", updated);
}

run();
