/*
  # Add notification trigger for new followers

  1. New Function
    - `notify_new_follower` - Sends a notification when a user gets a new follower
    - Gets follower's username from profiles table
    - Creates a notification for the user being followed
    - Sets appropriate notification type, title, and message
    - Includes link to follower's profile

  2. New Trigger
    - `trg_notify_new_follower` - Executes after INSERT on user_follows table
    - Calls the notify_new_follower function for each new row
    - Creates notifications automatically when users follow each other

  3. Security
    - Function uses SECURITY DEFINER to ensure it can create notifications
    - Maintains existing RLS policies on notifications table
*/

-- Create function to send notification when a user gets a new follower
CREATE OR REPLACE FUNCTION notify_new_follower()
RETURNS TRIGGER AS $$
DECLARE
  follower_username TEXT;
BEGIN
  -- Get the username of the follower
  SELECT username INTO follower_username
  FROM profiles
  WHERE id = NEW.follower_id;

  -- Insert notification for the user being followed
  INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    action_url
  ) VALUES (
    NEW.following_id,
    'New Follower!',
    CASE
      WHEN follower_username IS NOT NULL THEN follower_username || ' is now following you.'
      ELSE 'You have a new follower!'
    END,
    'info',
    '/profile/' || follower_username
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to execute the function after a new follow is created
CREATE TRIGGER trg_notify_new_follower
AFTER INSERT ON user_follows
FOR EACH ROW
EXECUTE FUNCTION notify_new_follower();