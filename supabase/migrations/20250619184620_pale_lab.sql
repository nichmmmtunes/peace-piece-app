/*
  # Add UPDATE policy for pieces table

  1. Changes
    - Add RLS policy allowing authenticated users to update pieces they own
    - This fixes the issue where users couldn't update their piece images or other details

  2. Security
    - Only allows updates to pieces where the user owns the organizer
    - Maintains existing security model where pieces can only be modified by their organizers
*/

-- Add UPDATE policy to the pieces table
CREATE POLICY "Users can update their own pieces" 
ON public.pieces
FOR UPDATE
TO authenticated
USING (organizer_id IN (
  SELECT organizers.id 
  FROM organizers 
  WHERE (organizers.user_id = auth.uid())
));