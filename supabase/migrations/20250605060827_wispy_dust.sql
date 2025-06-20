/*
  # Create avatar storage bucket and policies

  1. Storage
    - Creates 'avatars' storage bucket for user profile pictures
  
  2. Security
    - Enables authenticated users to upload their own avatars
    - Allows public read access to avatar files
    - Restricts users to only manage their own avatar files
*/

-- Create the storage bucket for avatars
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true);

-- Policy to allow authenticated users to upload files to their own folder
CREATE POLICY "Users can upload their own avatar"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' AND 
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy to allow users to update/delete their own files
CREATE POLICY "Users can manage their own avatar"
ON storage.objects
FOR ALL
TO authenticated
USING (
  bucket_id = 'avatars' AND 
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy to allow public access to avatar files
CREATE POLICY "Avatar files are publicly accessible"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'avatars');