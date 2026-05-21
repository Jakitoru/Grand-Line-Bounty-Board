const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://akkkcxnelsmixflgnuwe.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFra2tjeG5lbHNtaXhmbGdudXdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzMjYxMDMsImV4cCI6MjA5MzkwMjEwM30.K7eHCLmR7NC6vwmnUxM14jsbfLXTYw2qPBwOdaGWEvc';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function run() {
  console.log("Step 1: Insert test char");
  const { data, error } = await supabase
    .from('characters')
    .insert([{ name: 'TMP_DEBUG', bounty: 1, affiliation: 'None', is_custom: true }])
    .select();
  
  if (error) {
    console.error("INSERT ERROR", error);
    return;
  }
  
  const char = data[0];
  console.log("INSERTED CHAR:", char);

  console.log("Step 2: Deleting char with ID", char.id);
  const { error: delErr } = await supabase
    .from('characters')
    .delete()
    .eq('id', char.id);

  if (delErr) {
    console.error("DELETE ERROR!!", delErr);
  } else {
    console.log("SUCCESSFULLY DELETED!");
  }
}

run();
