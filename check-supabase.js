const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://akkkcxnelsmixflgnuwe.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFra2tjeG5lbHNtaXhmbGdudXdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzMjYxMDMsImV4cCI6MjA5MzkwMjEwM30.K7eHCLmR7NC6vwmnUxM14jsbfLXTYw2qPBwOdaGWEvc';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function run() {
  console.log("Step 1: Fetching characters from Supabase with name like 'DEBUG_V4'");
  const { data, error } = await supabase
    .from('characters')
    .select('*')
    .ilike('name', '%DEBUG_V4%');
  
  if (error) {
    console.error("FETCH ERROR", error);
    return;
  }
  
  console.log("MATCHING CHARACTERS IN DB:", data);
  if (data.length === 0) {
    console.log("CONFIRMED: NO CHARACTERS FOUND. SUCCESSFUL DELETION.");
  } else {
    console.log("WARNING: CHARACTERS FOUND. DELETION FAILED.");
  }
}

run();
