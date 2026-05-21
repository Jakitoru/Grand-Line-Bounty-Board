import { createClient as createBrowserClient } from '@/lib/supabase/client';

// Create a single supabase client for the entire app
export const supabase = createBrowserClient();

export interface Character {
  id: number;
  name: string;
  alias: string;
  bounty: number;
  affiliation: string;
  role: string;
  devil_fruit: string;
  devil_fruit_type: string;
  hometown: string;
  age?: number;
  height?: number;
  status: string;
  description: string;
  image_url: string;
  is_custom: boolean;
  user_id?: string;
  created_at: string;
}

export const DEFAULT_CHARACTERS_PLACEHOLDER = "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=400";

/**
 * Fetch characters
 */
export async function getCharacters(): Promise<Character[]> {
  const { data, error } = await supabase
    .from('characters')
    .select('*')
    .order('bounty', { ascending: false });
  
  if (error) {
    console.error("Error fetching characters:", error);
    return [];
  }
  
  return data as Character[];
}

/**
 * Add character
 */
export async function addCharacter(character: Omit<Character, 'id' | 'created_at' | 'is_custom'>): Promise<Character | null> {
  const { data: userData } = await supabase.auth.getUser();
  const user_id = userData.user?.id;

  const { data, error } = await supabase
    .from('characters')
    .insert([{ ...character, is_custom: true, user_id }])
    .select()
    .single();

  if (error) {
    console.error("Error adding character:", error);
    return null;
  }

  return data as Character;
}

/**
 * Update character
 */
export async function updateCharacter(id: number, character: Partial<Character>): Promise<Character | null> {
  const { data, error } = await supabase
    .from('characters')
    .update(character)
    .eq('id', id)
    .select()
    .single();

  if (error) {
    console.error("Error updating character:", error);
    return null;
  }

  return data as Character;
}

/**
 * Delete character
 */
export async function deleteCharacter(id: number): Promise<boolean> {
  const { error } = await supabase
    .from('characters')
    .delete()
    .eq('id', id);

  if (error) {
    console.error("Error deleting character:", error);
    return false;
  }

  return true;
}

/**
 * Upload image to Supabase Storage
 */
export async function uploadCharacterImage(file: File): Promise<string | null> {
  const fileExt = file.name.split('.').pop();
  const fileName = `${Math.random()}.${fileExt}`;
  const filePath = `character-images/${fileName}`;

  const { error: uploadError } = await supabase.storage
    .from('avatars')
    .upload(filePath, file);

  if (uploadError) {
    console.error("Error uploading image:", uploadError);
    return null;
  }

  const { data } = supabase.storage
    .from('avatars')
    .getPublicUrl(filePath);

  return data.publicUrl;
}
