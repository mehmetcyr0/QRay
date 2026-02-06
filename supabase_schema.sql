-- Create QR codes table
CREATE TABLE qr_codes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Add a constraint to ensure content is not empty
  CONSTRAINT content_not_empty CHECK (content <> '')
);

-- Set up Row Level Security (RLS)
ALTER TABLE qr_codes ENABLE ROW LEVEL SECURITY;

-- Create policies for QR codes table
-- Allow users to select only their own QR codes
CREATE POLICY "Users can view their own QR codes" ON qr_codes
  FOR SELECT USING (auth.uid() = user_id);

-- Allow users to insert their own QR codes
CREATE POLICY "Users can insert their own QR codes" ON qr_codes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow users to delete only their own QR codes
CREATE POLICY "Users can delete their own QR codes" ON qr_codes
  FOR DELETE USING (auth.uid() = user_id);

-- Create index for faster queries
CREATE INDEX qr_codes_user_id_idx ON qr_codes (user_id);
CREATE INDEX qr_codes_created_at_idx ON qr_codes (created_at DESC);

