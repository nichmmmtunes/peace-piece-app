import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

// Validate that Supabase credentials are properly configured
if (!supabaseUrl || supabaseUrl === 'https://your-supabase-project-url.supabase.co') {
  console.error('Supabase URL is not configured. Please click "Connect to Supabase" in the top right corner.');
}

if (!supabaseAnonKey || supabaseAnonKey === 'your-supabase-anon-key') {
  console.error('Supabase Anon Key is not configured. Please click "Connect to Supabase" in the top right corner.');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);