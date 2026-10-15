create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  display_name text,
  theme_preferences jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_format check (username is null or username ~ '^[a-zA-Z0-9_]{3,24}$')
);
create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 120),
  description text,
  scheduled_date date,
  start_time time,
  end_time time,
  category text,
  color_hex text,
  highlight_mode text not null default 'light' check (highlight_mode in ('light','dark')),
  priority text not null default 'medium' check (priority in ('low','medium','high')),
  status text not null default 'pending' check (status in ('pending','completed')),
  recurrence_rule jsonb,
  recurrence_series_id uuid,
  reminder_settings jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tasks_valid_time check (start_time is null or end_time is null or end_time > start_time),
  constraint tasks_valid_color check (color_hex is null or color_hex ~ '^#[0-9A-Fa-f]{6}$')
);
create index if not exists tasks_user_schedule_idx on public.tasks(user_id, scheduled_date, start_time);
create index if not exists tasks_updated_idx on public.tasks(updated_at);

create table if not exists public.task_attachments (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null,
  file_name text not null,
  mime_type text not null check (mime_type in ('application/pdf','image/png','image/jpeg','image/webp','image/gif')),
  size_bytes bigint not null check (size_bytes between 1 and 5242880),
  created_at timestamptz not null default now()
);
create index if not exists attachments_task_idx on public.task_attachments(user_id, task_id);

alter table public.profiles enable row level security;
alter table public.tasks enable row level security;
alter table public.task_attachments enable row level security;
create policy "Users manage their own profile" on public.profiles for all to authenticated using (id=auth.uid()) with check (id=auth.uid());
create policy "Users manage their own tasks" on public.tasks for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy "Users manage their own attachment metadata" on public.task_attachments for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('task-attachments','task-attachments',false,5242880,array['application/pdf','image/png','image/jpeg','image/webp','image/gif'])
on conflict(id) do update set public=false,file_size_limit=5242880,allowed_mime_types=excluded.allowed_mime_types;
create policy "Users access own attachment objects" on storage.objects for all to authenticated
using (bucket_id='task-attachments' and (storage.foldername(name))[1]=auth.uid()::text)
with check (bucket_id='task-attachments' and (storage.foldername(name))[1]=auth.uid()::text);

-- Create a profile for each new auth identity, including anonymous sessions.
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into public.profiles(id) values(new.id) on conflict(id) do nothing; return new; end; $$;
drop trigger if exists on_auth_user_created_dodoo on auth.users;
create trigger on_auth_user_created_dodoo after insert on auth.users for each row execute procedure public.handle_new_user();
