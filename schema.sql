-- THE SEVEN SLEEPERS
-- Supabase SQL Editor'da çalıştır.
-- Auth kullanıcıları Dashboard > Authentication > Users üzerinden oluştur.
-- Kullanıcı email formatı: said@seven-sleepers.local vb.
-- Email confirmation kapalıysa giriş doğrudan çalışır.
-- Şifreleri frontend koduna yazma.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  display_name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.growth_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null check (type in ('book','listen','learn')),
  title text not null,
  source text,
  body text,
  is_public boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text,
  body text,
  created_at timestamptz not null default now()
);

create table if not exists public.personal_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  completed boolean not null default false,
  due_date date not null default current_date,
  due_time time,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.shared_tasks (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  total_amount numeric(12,2) not null check (total_amount > 0),
  unit text not null,
  created_by uuid not null references public.profiles(id),
  status text not null default 'active' check (status in ('active','completed','archived')),
  created_at timestamptz not null default now()
);

create table if not exists public.shared_task_members (
  id uuid primary key default gen_random_uuid(),
  shared_task_id uuid not null references public.shared_tasks(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  assigned_amount numeric(12,2) not null default 0 check (assigned_amount >= 0),
  completed_amount numeric(12,2) not null default 0 check (completed_amount >= 0),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  unique(shared_task_id,user_id)
);

create index if not exists idx_growth_user_created on public.growth_records(user_id,created_at desc);
create index if not exists idx_growth_public_created on public.growth_records(is_public,created_at desc);
create index if not exists idx_notes_user_created on public.notes(user_id,created_at desc);
create index if not exists idx_personal_tasks_user_due on public.personal_tasks(user_id,due_date);
create index if not exists idx_shared_tasks_status on public.shared_tasks(status,created_at desc);
create index if not exists idx_shared_members_task on public.shared_task_members(shared_task_id);
create index if not exists idx_shared_members_user on public.shared_task_members(user_id);

-- Profil oluşturma yardımcı trigger'ı:
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id,username,display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email,'@',1)),
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email,'@',1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- RLS
alter table public.profiles enable row level security;
alter table public.growth_records enable row level security;
alter table public.notes enable row level security;
alter table public.personal_tasks enable row level security;
alter table public.shared_tasks enable row level security;
alter table public.shared_task_members enable row level security;

-- Profiles: giriş yapmış herkes 7 kişiyi görebilir.
create policy "profiles_select_authenticated" on public.profiles
for select to authenticated using (true);

create policy "profiles_update_self" on public.profiles
for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- Growth: kişi kendi kayıtlarını yönetir; toplulukta sadece public kayıtlar okunur.
create policy "growth_select_own_or_public" on public.growth_records
for select to authenticated
using (user_id = auth.uid() or is_public = true);

create policy "growth_insert_own" on public.growth_records
for insert to authenticated
with check (user_id = auth.uid());

create policy "growth_update_own" on public.growth_records
for update to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "growth_delete_own" on public.growth_records
for delete to authenticated
using (user_id = auth.uid());

-- Notes private.
create policy "notes_select_own" on public.notes for select to authenticated using (user_id = auth.uid());
create policy "notes_insert_own" on public.notes for insert to authenticated with check (user_id = auth.uid());
create policy "notes_update_own" on public.notes for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "notes_delete_own" on public.notes for delete to authenticated using (user_id = auth.uid());

-- Personal tasks private.
create policy "tasks_select_own" on public.personal_tasks for select to authenticated using (user_id = auth.uid());
create policy "tasks_insert_own" on public.personal_tasks for insert to authenticated with check (user_id = auth.uid());
create policy "tasks_update_own" on public.personal_tasks for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "tasks_delete_own" on public.personal_tasks for delete to authenticated using (user_id = auth.uid());

-- Shared tasks: authenticated users can see/create/update.
create policy "shared_tasks_select" on public.shared_tasks for select to authenticated using (true);
create policy "shared_tasks_insert" on public.shared_tasks for insert to authenticated with check (created_by = auth.uid());
create policy "shared_tasks_update_creator" on public.shared_tasks for update to authenticated using (created_by = auth.uid()) with check (created_by = auth.uid());

create policy "shared_members_select" on public.shared_task_members for select to authenticated using (true);
create policy "shared_members_insert_own" on public.shared_task_members for insert to authenticated with check (user_id = auth.uid());
create policy "shared_members_update_own" on public.shared_task_members for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- 7 kişilik başlangıç profilleri, Auth kullanıcıları oluşturulduktan sonra otomatik trigger ile gelir.
-- Auth > Users:
-- said@seven-sleepers.local
-- ahmet@seven-sleepers.local
-- emre@seven-sleepers.local
-- furkan@seven-sleepers.local
-- talha@seven-sleepers.local
-- yasir@seven-sleepers.local
-- ihsan@seven-sleepers.local
