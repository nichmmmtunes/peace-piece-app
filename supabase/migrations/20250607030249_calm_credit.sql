/*
  # Insert sample notifications

  This migration adds sample notifications for testing the notifications system.
  These will be visible to all users for demonstration purposes.
*/

-- Function to create sample notifications for a user
CREATE OR REPLACE FUNCTION create_sample_notifications(target_user_id uuid)
RETURNS void AS $$
BEGIN
  -- Welcome notification
  INSERT INTO notifications (user_id, title, message, type, action_url) VALUES 
  (target_user_id, 'Welcome to Peace Piece!', 'Thank you for joining our community of artists and supporters. Explore amazing pieces and start supporting independent creators.', 'success', '/explore');

  -- Info notification about new features
  INSERT INTO notifications (user_id, title, message, type, created_at) VALUES 
  (target_user_id, 'New Feature: Real-time Updates', 'We''ve added real-time notifications so you''ll never miss important updates about the pieces you follow.', 'info', now() - interval '2 hours');

  -- Piece update notification
  INSERT INTO notifications (user_id, title, message, type, action_url, created_at) VALUES 
  (target_user_id, 'New Piece: "Whispers of Tomorrow"', 'A beautiful new piece has been added by Artists for Peace. Check it out and consider supporting this amazing work.', 'info', '/piece/550e8400-e29b-41d4-a716-446655440006', now() - interval '1 day');

  -- System maintenance notification
  INSERT INTO notifications (user_id, title, message, type, created_at) VALUES 
  (target_user_id, 'Scheduled Maintenance', 'We''ll be performing system maintenance tonight from 2-4 AM EST. The site may be briefly unavailable during this time.', 'warning', now() - interval '3 days');

  -- Achievement notification
  INSERT INTO notifications (user_id, title, message, type, created_at) VALUES 
  (target_user_id, 'Thank You for Your Support!', 'Your contributions have helped raise over $1000 for independent artists this month. You''re making a real difference!', 'success', now() - interval '1 week');
END;
$$ LANGUAGE plpgsql;

-- Note: This function can be called manually for testing:
-- SELECT create_sample_notifications('your-user-id-here');