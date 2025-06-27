/*
  # Create user_follows table for profile following functionality

  1. New Tables
    - `user_follows` - Tracks which users follow other users
      - `id` (uuid, primary key)
      - `follower_id` (uuid, foreign key to profiles)
      - `following_id` (uuid, foreign key to profiles)
      - `created_at` (timestamptz)

  2. Triggers
    - Add trigger to increment/decrement followers_count on profiles table

  3. Security
    - Enable RLS on user_follows table
    - Add policies for viewing, creating, and deleting follows
    - Ensure users can only manage their own follows
*/

-- Create user_follows table
CREATE TABLE IF NOT EXISTS user_follows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  following_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(follower_id, following_id)
);

-- Enable RLS
ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS user_follows_follower_id_idx ON user_follows(follower_id);
CREATE INDEX IF NOT EXISTS user_follows_following_id_idx ON user_follows(following_id);

-- Create RLS policies

-- Allow users to view follows
CREATE POLICY "Users can view follows"
  ON user_follows
  FOR SELECT
  TO authenticated
  USING (true);

-- Allow users to follow others
CREATE POLICY "Users can create follows"
  ON user_follows
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = follower_id);

-- Allow users to unfollow
CREATE POLICY "Users can delete their own follows"
  ON user_follows
  FOR DELETE
  TO authenticated
  USING (auth.uid() = follower_id);

-- Create function to update followers_count
CREATE OR REPLACE FUNCTION update_followers_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Increment followers_count for the user being followed
    UPDATE profiles
    SET followers_count = COALESCE(followers_count, 0) + 1
    WHERE id = NEW.following_id;
    
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    -- Decrement followers_count for the user being unfollowed
    UPDATE profiles
    SET followers_count = GREATEST(COALESCE(followers_count, 0) - 1, 0)
    WHERE id = OLD.following_id;
    
    RETURN OLD;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers for followers_count updates
CREATE TRIGGER increment_followers_count
  AFTER INSERT ON user_follows
  FOR EACH ROW
  EXECUTE FUNCTION update_followers_count();

CREATE TRIGGER decrement_followers_count
  AFTER DELETE ON user_follows
  FOR EACH ROW
  EXECUTE FUNCTION update_followers_count();