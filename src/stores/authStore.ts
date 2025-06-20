import { writable } from 'svelte/store';
import { supabase } from '../lib/supabase';
import type { User } from '@supabase/supabase-js';

export const user = writable<User | null>(null);
export const loading = writable(true);

// Initialize the store with the current session
supabase.auth.getSession().then(({ data: { session } }) => {
  user.set(session?.user ?? null);
  loading.set(false);
});

// Listen for auth changes
supabase.auth.onAuthStateChange((_event, session) => {
  user.set(session?.user ?? null);
});

export async function signUp(email: string, password: string) {
  try {
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email,
      password,
    });

    if (authError) {
      return { error: authError };
    }

    // Create profile using service role client to bypass RLS
    if (authData.user) {
      const { error: profileError } = await supabase
        .from('profiles')
        .insert([
          {
            id: authData.user.id,
            onboarding_completed: false,
          },
        ]);

      if (profileError) {
        // If profile creation fails, sign out the user to maintain data consistency
        await supabase.auth.signOut();
        return { error: profileError };
      }
    }

    return { error: null };
  } catch (error) {
    return { error: { message: 'An unexpected error occurred' } };
  }
}

export async function signIn(email: string, password: string) {
  const { error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });
  return { error };
}

export async function signOut() {
  const { error } = await supabase.auth.signOut();
  return { error };
}