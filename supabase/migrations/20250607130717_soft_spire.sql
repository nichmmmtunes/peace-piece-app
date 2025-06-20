/*
  # Add piece_description column to pieces table

  1. New Columns
    - `piece_description` (text, nullable) - Markdown-enabled description for pieces

  2. Changes
    - Add piece_description column to pieces table
    - Update piece_details view to include piece_description
*/

-- Add piece_description column to pieces table
ALTER TABLE pieces 
ADD COLUMN IF NOT EXISTS piece_description text;

-- Drop and recreate the piece_details view to include piece_description
DROP VIEW IF EXISTS piece_details;

CREATE VIEW piece_details AS
SELECT 
  p.id,
  p.title,
  p.image_url,
  p.audio_url,
  p.poem,
  p.piece_description,
  p.amount_raised,
  p.created_at,
  p.organizer_id,
  o.name as organizer_name,
  o.description as organizer_description,
  COALESCE(
    json_agg(
      DISTINCT jsonb_build_object(
        'id', a.id,
        'name', a.name,
        'role', pa.role,
        'bio', a.bio
      )
    ) FILTER (WHERE a.id IS NOT NULL),
    '[]'::json
  ) as contributors,
  COALESCE(
    json_agg(
      DISTINCT jsonb_build_object(
        'id', s.id,
        'name', s.name,
        'logo_url', s.logo_url,
        'website', s.website,
        'amount', ps.amount
      )
    ) FILTER (WHERE s.id IS NOT NULL),
    '[]'::json
  ) as sponsors,
  COUNT(DISTINCT pf.profile_id) as follower_count
FROM pieces p
LEFT JOIN organizers o ON p.organizer_id = o.id
LEFT JOIN piece_artists pa ON p.id = pa.piece_id
LEFT JOIN artists a ON pa.artist_id = a.id
LEFT JOIN piece_sponsors ps ON p.id = ps.piece_id
LEFT JOIN sponsors s ON ps.sponsor_id = s.id
LEFT JOIN piece_followers pf ON p.id = pf.piece_id
GROUP BY p.id, o.id;