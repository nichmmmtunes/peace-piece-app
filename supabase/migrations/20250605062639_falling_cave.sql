-- Create storage buckets for pieces and audio files
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('pieces', 'pieces', true),
  ('audio', 'audio', true);

-- Policies for pieces bucket
CREATE POLICY "Authenticated users can upload piece images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'pieces');

CREATE POLICY "Piece images are publicly accessible"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'pieces');

-- Policies for audio bucket
CREATE POLICY "Authenticated users can upload audio files"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'audio');

CREATE POLICY "Audio files are publicly accessible"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'audio');