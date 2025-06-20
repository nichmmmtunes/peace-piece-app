-- Create a table for public profiles
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  username text unique,
  website text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.profiles enable row level security;

-- Create policies
create policy "Public profiles are viewable by everyone" 
  on profiles 
  for select 
  using (true);

create policy "Users can insert their own profile" 
  on profiles 
  for insert 
  with check (auth.uid() = id);

create policy "Users can update their own profile" 
  on profiles 
  for update 
  using (auth.uid() = id);

-- Set up storage for profile images
insert into storage.buckets (id, name, public) 
values ('profiles', 'profiles', true);

create policy "Profile images are publicly accessible"
  on storage.objects 
  for select 
  using (bucket_id = 'profiles');

create policy "Anyone can upload a profile image"
  on storage.objects 
  for insert 
  with check (bucket_id = 'profiles');

create policy "Users can update their own profile image"
  on storage.objects 
  for update 
  using (auth.uid() = owner);