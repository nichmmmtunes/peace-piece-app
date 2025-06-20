/*
  # Add project status and milestones to pieces table

  1. New Columns
    - `project_status` (enum type) - Status of the project: 'open_to_applications', 'seeking_funding', or 'published'
    - `milestones` (jsonb) - Array of project milestones with title, description, and completion status

  2. Changes
    - Creates a new enum type for project status
    - Adds the new columns to the pieces table
    - Sets default value for project_status to 'open_to_applications'
    - Sets default value for milestones to an empty array
*/

-- Create enum type for project status if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'project_status_type') THEN
    CREATE TYPE project_status_type AS ENUM ('open_to_applications', 'seeking_funding', 'published');
  END IF;
END $$;

-- Add project_status column to pieces table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pieces' AND column_name = 'project_status'
  ) THEN
    ALTER TABLE pieces ADD COLUMN project_status project_status_type DEFAULT 'open_to_applications'::project_status_type;
  END IF;
END $$;

-- Add milestones column to pieces table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pieces' AND column_name = 'milestones'
  ) THEN
    ALTER TABLE pieces ADD COLUMN milestones JSONB DEFAULT '[]'::jsonb;
  END IF;
END $$;

-- Update the piece_details view to include the new columns
CREATE OR REPLACE VIEW piece_details AS
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
  o.name AS organizer_name,
  o.description AS organizer_description,
  (
    SELECT json_agg(
      json_build_object(
        'id', a.id,
        'name', a.name,
        'bio', a.bio,
        'role', pa.role
      )
    )
    FROM piece_artists pa
    JOIN artists a ON pa.artist_id = a.id
    WHERE pa.piece_id = p.id
  ) AS contributors,
  (
    SELECT json_agg(
      json_build_object(
        'id', s.id,
        'name', s.name,
        'logo_url', s.logo_url,
        'website', s.website,
        'bio', s.bio,
        'additional_links', s.additional_links,
        'amount', ps.amount
      )
    )
    FROM piece_sponsors ps
    JOIN sponsors s ON ps.sponsor_id = s.id
    WHERE ps.piece_id = p.id
  ) AS sponsors,
  (
    SELECT COUNT(*)
    FROM piece_followers pf
    WHERE pf.piece_id = p.id
  ) AS follower_count
FROM
  pieces p
LEFT JOIN
  organizers o ON p.organizer_id = o.id;