/*
  # Add new fields for Peace Piece projects

  1. New Columns
    - `cause_tags` (jsonb) - Array of cause tags for the piece
    - `accepted_mediums` (jsonb) - Array of accepted artistic mediums
    - `full_project_overview` (text) - Detailed project overview
    - `collaboration_structure` (text) - How artists will collaborate
    - `deliverable_format` (text) - Final format of the piece
    - `application_start_date` (timestamptz) - When applications open
    - `application_end_date` (timestamptz) - When applications close
    - `kickoff_date` (timestamptz) - Project kickoff date
    - `submission_due_date` (timestamptz) - When submissions are due
    - `feedback_window_end_date` (timestamptz) - End of feedback period
    - `publication_target_date` (timestamptz) - Target publication date
    - `artists_needed` (integer) - Number of artists needed
    - `project_visibility` (text) - 'open' or 'invite_only'
    - `compensation_details` (text) - Compensation information
    - `funding_goal` (bigint) - Funding goal amount
    - `donation_cta_type` (text) - 'cause' or 'project'
    - `preliminary_sponsor_info` (text) - Initial sponsor information

  2. View Updates
    - Update piece_details view to include new fields
*/

-- Add new columns to the pieces table for detailed project information
ALTER TABLE pieces
ADD COLUMN IF NOT EXISTS cause_tags jsonb DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS accepted_mediums jsonb DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS full_project_overview text,
ADD COLUMN IF NOT EXISTS collaboration_structure text,
ADD COLUMN IF NOT EXISTS deliverable_format text,
ADD COLUMN IF NOT EXISTS application_start_date timestamptz,
ADD COLUMN IF NOT EXISTS application_end_date timestamptz,
ADD COLUMN IF NOT EXISTS kickoff_date timestamptz,
ADD COLUMN IF NOT EXISTS submission_due_date timestamptz,
ADD COLUMN IF NOT EXISTS feedback_window_end_date timestamptz,
ADD COLUMN IF NOT EXISTS publication_target_date timestamptz,
ADD COLUMN IF NOT EXISTS artists_needed integer,
ADD COLUMN IF NOT EXISTS project_visibility text, -- 'open' or 'invite_only'
ADD COLUMN IF NOT EXISTS compensation_details text,
ADD COLUMN IF NOT EXISTS funding_goal bigint,
ADD COLUMN IF NOT EXISTS donation_cta_type text, -- 'cause' or 'project'
ADD COLUMN IF NOT EXISTS preliminary_sponsor_info text;

-- Update the piece_details view to include the new columns
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
  p.updated_at, -- Add updated_at to the view
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