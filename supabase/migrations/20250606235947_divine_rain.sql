/*
  # Create sample data for Peace Piece

  1. Sample Data
    - Create sample organizer, artists, sponsors
    - Create sample piece with relationships
    - Add sample followers and comments

  2. Security
    - All tables already have RLS enabled
    - Sample data will be publicly viewable
*/

-- Insert sample organizer
INSERT INTO organizers (id, name, description) VALUES 
('550e8400-e29b-41d4-a716-446655440000', 'Artists for Peace', 'A collective of artists working together to promote peace through creative expression and community engagement.');

-- Insert sample artists
INSERT INTO artists (id, name, bio) VALUES 
('550e8400-e29b-41d4-a716-446655440001', 'Maya Chen', 'A spoken word poet and visual artist who explores themes of identity, belonging, and social justice through her work.'),
('550e8400-e29b-41d4-a716-446655440002', 'David Rodriguez', 'Musician and composer specializing in ambient soundscapes that blend traditional instruments with modern electronic elements.'),
('550e8400-e29b-41d4-a716-446655440003', 'Sarah Johnson', 'Digital artist and photographer whose work captures the beauty in everyday moments and human connections.');

-- Insert sample sponsors
INSERT INTO sponsors (id, name, logo_url, website) VALUES 
('550e8400-e29b-41d4-a716-446655440004', 'Community Arts Foundation', 'https://images.pexels.com/photos/1181467/pexels-photo-1181467.jpeg?auto=compress&cs=tinysrgb&w=100&h=100&fit=crop', 'https://communityarts.org'),
('550e8400-e29b-41d4-a716-446655440005', 'Local Coffee Co.', 'https://images.pexels.com/photos/302899/pexels-photo-302899.jpeg?auto=compress&cs=tinysrgb&w=100&h=100&fit=crop', 'https://localcoffee.com');

-- Insert sample piece
INSERT INTO pieces (id, title, image_url, audio_url, poem, organizer_id, amount_raised) VALUES 
('550e8400-e29b-41d4-a716-446655440006', 
 'Whispers of Tomorrow', 
 'https://images.pexels.com/photos/1181467/pexels-photo-1181467.jpeg?auto=compress&cs=tinysrgb&w=800&h=600&fit=crop',
 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
 'In the quiet moments between heartbeats,
We find the space where dreams take root.
Tomorrow whispers its promises
Through the rustling leaves of today.

Each breath carries the weight of possibility,
Each step forward writes a new story.
We are the authors of our own peace,
The architects of our shared tomorrow.

Listen closely to the silence—
It speaks of hope, of change, of love.
In whispers soft as morning dew,
Tomorrow calls us home.',
 '550e8400-e29b-41d4-a716-446655440000',
 2500);

-- Link artists to the piece
INSERT INTO piece_artists (piece_id, artist_id, role) VALUES 
('550e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440001', 'Poet'),
('550e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440002', 'Sound Designer'),
('550e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440003', 'Visual Artist');

-- Link sponsors to the piece
INSERT INTO piece_sponsors (piece_id, sponsor_id, amount) VALUES 
('550e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440004', 1500),
('550e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440005', 1000);

-- Insert another sample piece
INSERT INTO pieces (id, title, image_url, poem, organizer_id, amount_raised) VALUES 
('550e8400-e29b-41d4-a716-446655440007', 
 'Urban Symphony', 
 'https://images.pexels.com/photos/1105766/pexels-photo-1105766.jpeg?auto=compress&cs=tinysrgb&w=800&h=600&fit=crop',
 'City lights dance in rhythm,
Concrete jungle finds its beat.
Every footstep tells a story,
Every corner holds a dream.

We are the music of the streets,
The harmony in chaos found.
Together we create the symphony
That makes this urban heart resound.',
 '550e8400-e29b-41d4-a716-446655440000',
 1800);

-- Link artists to the second piece
INSERT INTO piece_artists (piece_id, artist_id, role) VALUES 
('550e8400-e29b-41d4-a716-446655440007', '550e8400-e29b-41d4-a716-446655440002', 'Composer'),
('550e8400-e29b-41d4-a716-446655440007', '550e8400-e29b-41d4-a716-446655440003', 'Photographer');

-- Link sponsors to the second piece
INSERT INTO piece_sponsors (piece_id, sponsor_id, amount) VALUES 
('550e8400-e29b-41d4-a716-446655440007', '550e8400-e29b-41d4-a716-446655440004', 1800);

-- Insert a third sample piece
INSERT INTO pieces (id, title, image_url, poem, organizer_id, amount_raised) VALUES 
('550e8400-e29b-41d4-a716-446655440008', 
 'Ocean of Dreams', 
 'https://images.pexels.com/photos/1001682/pexels-photo-1001682.jpeg?auto=compress&cs=tinysrgb&w=800&h=600&fit=crop',
 'Waves carry messages from distant shores,
Salt air whispers ancient secrets.
In the vast expanse of blue,
We find reflections of our souls.

Each tide brings new possibilities,
Each sunset paints hope anew.
We are drops in this ocean of dreams,
Connected by currents unseen.',
 '550e8400-e29b-41d4-a716-446655440000',
 3200);

-- Link artists to the third piece
INSERT INTO piece_artists (piece_id, artist_id, role) VALUES 
('550e8400-e29b-41d4-a716-446655440008', '550e8400-e29b-41d4-a716-446655440001', 'Poet'),
('550e8400-e29b-41d4-a716-446655440008', '550e8400-e29b-41d4-a716-446655440003', 'Visual Artist');

-- Link sponsors to the third piece
INSERT INTO piece_sponsors (piece_id, sponsor_id, amount) VALUES 
('550e8400-e29b-41d4-a716-446655440008', '550e8400-e29b-41d4-a716-446655440004', 2000),
('550e8400-e29b-41d4-a716-446655440008', '550e8400-e29b-41d4-a716-446655440005', 1200);