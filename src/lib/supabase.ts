import { createClient } from '@supabase/supabase-js';
import { Character, DEFAULT_CHARACTERS } from './data';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';

// Kiểm tra xem Supabase đã được cấu hình chưa
export const isSupabaseConfigured = Boolean(supabaseUrl && supabaseAnonKey);

// Tạo Supabase client (sẽ báo lỗi nhẹ nếu thiếu biến môi trường, chúng ta bọc lại)
export const supabase = isSupabaseConfigured
  ? createClient(supabaseUrl, supabaseAnonKey)
  : null;

/**
 * Hàm lấy danh sách nhân vật.
 * Nếu có kết nối Supabase -> lấy từ DB.
 * Nếu không -> lấy từ LocalData kết hợp với localStorage (cho phần người dùng tự tạo).
 */
export async function getCharacters(): Promise<Character[]> {
  if (isSupabaseConfigured && supabase) {
    try {
      const { data, error } = await supabase
        .from('characters')
        .select('*')
        .order('bounty', { ascending: false });
      
      if (!error && data) {
        const uniqueNames = new Set<string>();
        const cleanData: Character[] = [];

        // Lọc bỏ các nhân vật bị lặp lại trong trường hợp DB bị clone nhiều lần
        const castedData = data as Character[];
        
        for (const char of castedData) {
          // Normalize name for deduplication
          const nameKey = char.name.trim().toLowerCase();
          if (!uniqueNames.has(nameKey)) {
            uniqueNames.add(nameKey);
            
            const matchedDefault = DEFAULT_CHARACTERS.find(
              dc => dc.name.toLowerCase() === nameKey
            );

            if (matchedDefault) {
              cleanData.push({ 
                ...char, 
                image_url: matchedDefault.image_url, // Đảm bảo sử dụng link ảnh chuẩn 100% từ data.ts
                alias: matchedDefault.alias,
                is_custom: false
              });
            } else {
              cleanData.push(char);
            }
          }
        }
        return cleanData;
      }
      console.warn("Supabase fetch failed, falling back to local storage:", error);
    } catch (e) {
      console.warn("Supabase exception, falling back to local storage:", e);
    }
  }

  // Fallback sang Local Storage + Mock Data
  if (typeof window !== 'undefined') {
    const customData = localStorage.getItem('op_custom_characters');
    const customCharacters: Character[] = customData ? JSON.parse(customData) : [];
    return [...customCharacters, ...DEFAULT_CHARACTERS].sort((a, b) => b.bounty - a.bounty);
  }

  return DEFAULT_CHARACTERS;
}

/**
 * Hàm thêm một nhân vật mới.
 * Nếu có Supabase -> thêm vào DB.
 * Nếu không -> thêm vào localStorage.
 */
export async function addCharacter(character: Omit<Character, 'id' | 'created_at'>): Promise<Character> {
  const newId = typeof window !== 'undefined' ? Date.now() : Math.floor(Math.random() * 1000000);
  const newChar: Character = {
    ...character,
    id: newId,
    is_custom: true,
    created_at: new Date().toISOString()
  };

  if (isSupabaseConfigured && supabase) {
    try {
      const { data, error } = await supabase
        .from('characters')
        .insert([character])
        .select();

      if (!error && data && data[0]) {
        return data[0] as Character;
      }
      console.warn("Supabase insert failed, falling back to local storage:", error);
    } catch (e) {
      console.warn("Supabase exception during insert, falling back to local storage:", e);
    }
  }

  // Fallback sang Local Storage
  if (typeof window !== 'undefined') {
    const customData = localStorage.getItem('op_custom_characters');
    const customCharacters: Character[] = customData ? JSON.parse(customData) : [];
    const updated = [newChar, ...customCharacters];
    localStorage.setItem('op_custom_characters', JSON.stringify(updated));
  }

  return newChar;
}

/**
 * Xóa một nhân vật tự tạo (chỉ dành cho các nhân vật có is_custom = true)
 */
export async function deleteCharacter(id: number): Promise<boolean> {
  if (isSupabaseConfigured && supabase) {
    try {
      const { error } = await supabase
        .from('characters')
        .delete()
        .eq('id', id);

      if (!error) return true;
      console.warn("Supabase delete failed:", error);
    } catch (e) {
      console.warn("Supabase exception during delete:", e);
    }
  }

  if (typeof window !== 'undefined') {
    const customData = localStorage.getItem('op_custom_characters');
    if (customData) {
      const customCharacters: Character[] = JSON.parse(customData);
      const filtered = customCharacters.filter(c => c.id !== id);
      localStorage.setItem('op_custom_characters', JSON.stringify(filtered));
      return true;
    }
  }

  return false;
}

export async function resyncDefaultImages(): Promise<boolean> {
  if (isSupabaseConfigured && supabase) {
    try {
      console.log(`[Resync] Starting bulk resync of all ${DEFAULT_CHARACTERS.length} default characters...`);
      
      // 1. Xóa toàn bộ các nhân vật mặc định cũ
      const { error: deleteError } = await supabase
        .from('characters')
        .delete()
        .neq('is_custom', true);
      
      if (deleteError) {
        console.error("[Resync] Delete failed:", deleteError);
        return false;
      }

      // 2. Chuẩn bị dữ liệu 60 nhân vật mới
      const cleanCharacters = DEFAULT_CHARACTERS.map(({ id, ...charWithoutId }) => ({
        ...charWithoutId,
        is_custom: false
      }));

      // 3. Tiến hành chèn hàng loạt (Bulk Insert)
      const { error: insertError } = await supabase
        .from('characters')
        .insert(cleanCharacters);

      if (insertError) {
        console.error("[Resync] Insert failed:", insertError);
        return false;
      }

      console.log("[Resync] Bulk resync completed successfully!");
      return true;
    } catch (e) {
      console.error("Lỗi khi đồng bộ ảnh và nhân vật lên Supabase:", e);
    }
  }
  return false;
}
