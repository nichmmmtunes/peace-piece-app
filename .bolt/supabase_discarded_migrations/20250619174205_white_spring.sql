/*
  # Add video_url support for exported videos

  1. Changes
    - Add `video_url` column to `pieces` table to store exported video URLs
    - Update `piece_details` view to include the new column
    - Create a new storage bucket for videos with appropriate policies

  2. Security
    - Maintain existing RLS policies
    - Add appropriate storage policies for video files
*/

-- Add video_url column to pieces table
ALTER TABLE pieces
ADD COLUMN IF NOT EXISTS video_url text;

-- Create a dedicated storage bucket for videos if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('videos', 'videos', true)
ON CONFLICT (id) DO NOTHING;

-- Add policies for videos bucket
CREATE POLICY "Authenticated users can upload videos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'videos');

CREATE POLICY "Videos are publicly accessible"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'videos');

CREATE POLICY "Users can update their own videos"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'videos' AND owner = auth.uid());

CREATE POLICY "Users can delete their own videos"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'videos' AND owner = auth.uid());

-- Drop and recreate the piece_details view to include video_url
DROP VIEW IF EXISTS piece_details;

CREATE VIEW piece_details AS
SELECT
  p.id,
  p.title,
  p.image_url,
  p.audio_url,
  p.video_url,
  p.mission,
  p.piece_description,
  p.amount_raised,
  p.created_at,
  p.updated_at,
  p.organizer_id,
  p.editor_data,
  p.cause_tags,
  p.accepted_mediums,
  p.full_project_overview,
  p.collaboration_structure,
  p.deliverable_format,
  p.application_start_date,
  p.application_end_date,
  p.kickoff_date,
  p.submission_due_date,
  p.feedback_window_end_date,
  p.publication_target_date,
  p.artists_needed,
  p.project_visibility,
  p.compensation_details,
  p.funding_goal,
  p.donation_cta_type,
  p.preliminary_sponsor_info,
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
        'bio', s.bio,
        'additional_links', s.additional_links,
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