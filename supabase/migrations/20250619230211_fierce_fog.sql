/*
  # Create organizer_avatars storage bucket and policies

  1. Storage
    - Creates 'organizer_avatars' storage bucket for organizer profile pictures
  
  2. Security
    - Enables authenticated users to upload their own organizer avatars
    - Allows public read access to organizer avatar files
    - Restricts users to only manage their own organizer avatar files
*/

-- Create the storage bucket for organizer avatars
INSERT INTO storage.buckets (id, name, public)
VALUES ('organizer_avatars', 'organizer_avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Policy to allow authenticated users to upload files to their own folder
CREATE POLICY "Users can upload their own organizer avatar"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'organizer_avatars' AND 
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy to allow users to update/delete their own files
CREATE POLICY "Users can manage their own organizer avatar"
ON storage.objects
FOR ALL
TO authenticated
USING (
  bucket_id = 'organizer_avatars' AND 
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy to allow public access to organizer avatar files
CREATE POLICY "Organizer avatar files are publicly accessible"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'organizer_avatars');