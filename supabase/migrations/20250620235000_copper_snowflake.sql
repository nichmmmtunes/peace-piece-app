/*
  # Add Delete Policy for Notifications

  1. Changes
    - Add RLS policy to allow users to delete their own notifications
    
  2. Security
    - Only allows users to delete notifications where they are the owner (user_id)
    - Maintains existing RLS policies for other operations
*/

-- Add policy to allow users to delete their own notifications
CREATE POLICY "Users can delete their own notifications"
  ON notifications
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);