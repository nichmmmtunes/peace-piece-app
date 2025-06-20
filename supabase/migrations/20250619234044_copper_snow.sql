/*
  # Create Artist Applications System

  1. New Types
    - `application_status_enum` - Enum type for application statuses

  2. New Tables
    - `applications`
      - `id` (uuid, primary key)
      - `piece_id` (uuid, foreign key to pieces)
      - `applicant_profile_id` (uuid, foreign key to profiles)
      - `status` (application_status_enum)
      - `pitch_fit` (text) - Why the artist is a good fit
      - `pitch_cause` (text) - Why the artist believes in the cause
      - `portfolio_url` (text) - Link to artist's portfolio
      - `selected_mediums` (jsonb) - Array of selected artistic mediums
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  3. Security
    - Enable RLS on applications table
    - Add policies for viewing, creating, updating, and deleting applications
    - Ensure applicants can only see their own applications
    - Ensure organizers can only see applications for their pieces
*/

-- Create application status enum type
CREATE TYPE application_status_enum AS ENUM (
  'submitted',
  'reviewing',
  'approved',
  'rejected'
);

-- Create applications table
CREATE TABLE applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  piece_id uuid REFERENCES pieces(id) ON DELETE CASCADE NOT NULL,
  applicant_profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  status application_status_enum NOT NULL DEFAULT 'submitted',
  pitch_fit text NOT NULL,
  pitch_cause text NOT NULL,
  portfolio_url text,
  selected_mediums jsonb DEFAULT '[]'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX applications_piece_id_idx ON applications(piece_id);
CREATE INDEX applications_applicant_profile_id_idx ON applications(applicant_profile_id);
CREATE INDEX applications_status_idx ON applications(status);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_applications_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER update_applications_updated_at
  BEFORE UPDATE ON applications
  FOR EACH ROW
  EXECUTE FUNCTION update_applications_updated_at();

-- RLS Policies

-- 1. Applicants can view their own applications
CREATE POLICY "Applicants can view their own applications"
  ON applications
  FOR SELECT
  TO authenticated
  USING (applicant_profile_id = auth.uid());

-- 2. Organizers can view applications for their pieces
CREATE POLICY "Organizers can view applications for their pieces"
  ON applications
  FOR SELECT
  TO authenticated
  USING (
    piece_id IN (
      SELECT p.id
      FROM pieces p
      JOIN organizers o ON p.organizer_id = o.id
      WHERE o.user_id = auth.uid()
    )
  );

-- 3. Authenticated users can create applications for themselves
CREATE POLICY "Users can create applications for themselves"
  ON applications
  FOR INSERT
  TO authenticated
  WITH CHECK (applicant_profile_id = auth.uid());

-- 4. Applicants can update their own applications if not yet approved/rejected
CREATE POLICY "Applicants can update their own applications if not yet approved/rejected"
  ON applications
  FOR UPDATE
  TO authenticated
  USING (
    applicant_profile_id = auth.uid() AND 
    status NOT IN ('approved', 'rejected')
  )
  WITH CHECK (
    applicant_profile_id = auth.uid() AND 
    status NOT IN ('approved', 'rejected')
  );

-- 5. Organizers can update applications for their pieces
CREATE POLICY "Organizers can update applications for their pieces"
  ON applications
  FOR UPDATE
  TO authenticated
  USING (
    piece_id IN (
      SELECT p.id
      FROM pieces p
      JOIN organizers o ON p.organizer_id = o.id
      WHERE o.user_id = auth.uid()
    )
  )
  WITH CHECK (
    piece_id IN (
      SELECT p.id
      FROM pieces p
      JOIN organizers o ON p.organizer_id = o.id
      WHERE o.user_id = auth.uid()
    )
  );

-- 6. Applicants can delete their own applications if not yet approved/rejected
CREATE POLICY "Applicants can delete their own applications if not yet approved/rejected"
  ON applications
  FOR DELETE
  TO authenticated
  USING (
    applicant_profile_id = auth.uid() AND 
    status NOT IN ('approved', 'rejected')
  );

-- 7. Organizers can delete applications for their pieces
CREATE POLICY "Organizers can delete applications for their pieces"
  ON applications
  FOR DELETE
  TO authenticated
  USING (
    piece_id IN (
      SELECT p.id
      FROM pieces p
      JOIN organizers o ON p.organizer_id = o.id
      WHERE o.user_id = auth.uid()
    )
  );