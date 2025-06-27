/*
  # Fix Profile Creation with Database Trigger

  1. Changes
    - Create a database function to handle new user creation
    - Set up a trigger on auth.users to automatically create profiles
    - This bypasses RLS policies during profile creation
    - Ensures profiles are created immediately when users sign up

  2. Security
    - Maintains existing RLS policies
    - Handles profile creation at the database level
    - Eliminates client-side RLS timing issues
*/

-- Create a function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert a row into public.profiles for the new user
  INSERT INTO public.profiles (id, username, onboarding_completed, created_at, updated_at)
  VALUES (
    NEW.id, 
    NEW.email, -- Use email as initial username
    false,     -- Set onboarding_completed to false
    NOW(),     -- Set created_at to current time
    NOW()      -- Set updated_at to current time
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a trigger to call the function when a new user is created
CREATE OR REPLACE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();