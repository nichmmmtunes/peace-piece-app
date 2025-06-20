/*
  # Add onboarding status to profiles table
  
  1. Changes
    - Add onboarding_completed boolean column to profiles table with default false
    
  2. Security
    - Maintain existing RLS policies
*/

ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT false;