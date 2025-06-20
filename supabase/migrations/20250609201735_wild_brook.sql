/*
  # Add donation tracking to profiles table

  1. Changes
    - Add `total_donated_amount` column to `profiles` table to track user donations
    - Set default value to 0 for existing and new profiles

  2. Security
    - Maintain existing RLS policies
    - Column will be updated via webhook function
*/

-- Add total_donated_amount column to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS total_donated_amount bigint DEFAULT 0;

-- Update existing profiles to have 0 as default if null
UPDATE profiles 
SET total_donated_amount = 0 
WHERE total_donated_amount IS NULL;