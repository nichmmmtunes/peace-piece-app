/*
  # Peace Pieces Schema

  1. New Tables
    - organizers
      - id (uuid, primary key)
      - name (text)
      - description (text)
      - created_at (timestamptz)
      - updated_at (timestamptz)
    
    - artists
      - id (uuid, primary key)
      - name (text)
      - bio (text)
      - created_at (timestamptz)
      - updated_at (timestamptz)
    
    - sponsors
      - id (uuid, primary key)
      - name (text)
      - logo_url (text)
      - website (text)
      - created_at (timestamptz)
      - updated_at (timestamptz)
    
    - pieces
      - id (uuid, primary key)
      - title (text)
      - image_url (text)
      - audio_url (text)
      - poem (text)
      - organizer_id (uuid, foreign key)
      - amount_raised (bigint)
      - created_at (timestamptz)
      - updated_at (timestamptz)
    
    - piece_artists (junction table)
      - piece_id (uuid, foreign key)
      - artist_id (uuid, foreign key)
      - role (text)
      - created_at (timestamptz)
    
    - piece_sponsors (junction table)
      - piece_id (uuid, foreign key)
      - sponsor_id (uuid, foreign key)
      - amount (bigint)
      - created_at (timestamptz)
    
    - piece_followers (junction table)
      - piece_id (uuid, foreign key)
      - profile_id (uuid, foreign key)
      - created_at (timestamptz)
    
    - comments
      - id (uuid, primary key)
      - piece_id (uuid, foreign key)
      - profile_id (uuid, foreign key)
      - content (text)
      - created_at (timestamptz)
      - updated_at (timestamptz)

  2. Security
    - Enable RLS on all tables
    - Add appropriate policies for each table
*/

-- Create organizers table
CREATE TABLE organizers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE organizers ENABLE ROW LEVEL SECURITY;

-- Create artists table
CREATE TABLE artists (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  bio text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE artists ENABLE ROW LEVEL SECURITY;

-- Create sponsors table
CREATE TABLE sponsors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  logo_url text,
  website text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE sponsors ENABLE ROW LEVEL SECURITY;

-- Create pieces table
CREATE TABLE pieces (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  image_url text,
  audio_url text,
  poem text,
  organizer_id uuid REFERENCES organizers(id),
  amount_raised bigint DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE pieces ENABLE ROW LEVEL SECURITY;

-- Create piece_artists junction table
CREATE TABLE piece_artists (
  piece_id uuid REFERENCES pieces(id) ON DELETE CASCADE,
  artist_id uuid REFERENCES artists(id) ON DELETE CASCADE,
  role text NOT NULL,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (piece_id, artist_id)
);

ALTER TABLE piece_artists ENABLE ROW LEVEL SECURITY;

-- Create piece_sponsors junction table
CREATE TABLE piece_sponsors (
  piece_id uuid REFERENCES pieces(id) ON DELETE CASCADE,
  sponsor_id uuid REFERENCES sponsors(id) ON DELETE CASCADE,
  amount bigint NOT NULL,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (piece_id, sponsor_id)
);

ALTER TABLE piece_sponsors ENABLE ROW LEVEL SECURITY;

-- Create piece_followers junction table
CREATE TABLE piece_followers (
  piece_id uuid REFERENCES pieces(id) ON DELETE CASCADE,
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (piece_id, profile_id)
);

ALTER TABLE piece_followers ENABLE ROW LEVEL SECURITY;

-- Create comments table
CREATE TABLE comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  piece_id uuid REFERENCES pieces(id) ON DELETE CASCADE,
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  content text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Add RLS policies

-- Pieces policies
CREATE POLICY "Pieces are viewable by everyone"
  ON pieces FOR SELECT
  TO public
  USING (true);

-- Comments policies
CREATE POLICY "Comments are viewable by everyone"
  ON comments FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Users can create comments"
  ON comments FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can update their own comments"
  ON comments FOR UPDATE
  TO authenticated
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can delete their own comments"
  ON comments FOR DELETE
  TO authenticated
  USING (auth.uid() = profile_id);

-- Followers policies
CREATE POLICY "Users can view followers"
  ON piece_followers FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Users can follow pieces"
  ON piece_followers FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can unfollow pieces"
  ON piece_followers FOR DELETE
  TO authenticated
  USING (auth.uid() = profile_id);

-- Create view for piece details
CREATE VIEW piece_details AS
SELECT 
  p.id,
  p.title,
  p.image_url,
  p.audio_url,
  p.poem,
  p.amount_raised,
  p.created_at,
  o.id as organizer_id,
  o.name as organizer_name,
  o.description as organizer_description,
  (
    SELECT json_agg(json_build_object(
      'id', a.id,
      'name', a.name,
      'bio', a.bio,
      'role', pa.role
    ))
    FROM piece_artists pa
    JOIN artists a ON a.id = pa.artist_id
    WHERE pa.piece_id = p.id
  ) as contributors,
  (
    SELECT json_agg(json_build_object(
      'id', s.id,
      'name', s.name,
      'logo_url', s.logo_url,
      'amount', ps.amount
    ))
    FROM piece_sponsors ps
    JOIN sponsors s ON s.id = ps.sponsor_id
    WHERE ps.piece_id = p.id
  ) as sponsors,
  (
    SELECT COUNT(*)
    FROM piece_followers pf
    WHERE pf.piece_id = p.id
  ) as follower_count
FROM pieces p
LEFT JOIN organizers o ON o.id = p.organizer_id;