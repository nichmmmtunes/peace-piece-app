/*
  # Add piece_poem column to pieces table

  1. Changes
    - Add `piece_poem` column to `pieces` table to store poem text
    - Update `piece_details` view to include the new column
    
  2. Security
    - Maintain existing RLS policies
*/

-- Add piece_poem column to pieces table
ALTER TABLE pieces
ADD COLUMN IF NOT EXISTS piece_poem text;

-- Drop and recreate the piece_details view to include piece_poem
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
  p.project_status,
  p.milestones,
  p.approved,
  p.artist_fees,
  p.piece_poem, -- Add the new column here
  o.name as organizer_name,
  o.description as organizer_description,
  o.user_id as organizer_user_id,
  o.avatar_url as organizer_avatar_url,
  COALESCE(
    json_agg(
      DISTINCT jsonb_build_object(
        'id', a.id,
        'name', a.name,
        'role', pa.role,
        'bio', a.bio,
        'avatar_url', a.avatar_url
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