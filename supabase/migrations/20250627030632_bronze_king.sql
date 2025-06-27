/*
  # Add location and bio fields to profiles table

  1. Changes
    - Add `location` column to profiles table (text, nullable)
    - Add `bio` column to profiles table (text, nullable) 
    - Add constraint to limit bio length to 250 characters

  2. Security
    - No changes to RLS policies needed as existing policies cover new columns
*/

-- Add location column to profiles table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'location'
  ) THEN
    ALTER TABLE profiles ADD COLUMN location text;
  END IF;
END $$;

-- Add bio column to profiles table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'bio'
  ) THEN
    ALTER TABLE profiles ADD COLUMN bio text;
  END IF;
END $$;

-- Add constraint to limit bio length to 250 characters
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.check_constraints
    WHERE constraint_name = 'bio_length_check'
  ) THEN
    ALTER TABLE profiles ADD CONSTRAINT bio_length_check CHECK (bio IS NULL OR length(bio) <= 250);
  END IF;
END $$;