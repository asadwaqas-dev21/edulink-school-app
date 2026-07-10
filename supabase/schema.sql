-- ============================================================
-- Edulink LMS — Supabase schema
-- Run this in the Supabase SQL Editor (Dashboard -> SQL -> New query).
-- Safe to re-run: uses IF NOT EXISTS / CREATE OR REPLACE where possible.
-- ============================================================

-- ---------- Extensions ----------
create extension if not exists "pgcrypto";

-- ============================================================
-- PROFILES  (1:1 with auth.users)
-- ============================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text not null default '',
  role text not null default 'student'
    check (role in ('principal','teacher','student','parent')),
  institute_id uuid,
  avatar_url text,
  phone text,
  created_at timestamptz not null default now()
);

-- Auto-create a profile row when a new auth user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'role', 'student')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Helper functions (security definer to avoid RLS recursion).
-- Named with an "edulink_" prefix to avoid clashing with reserved words
-- like CURRENT_ROLE.
create or replace function public.edulink_role()
returns text language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.edulink_institute()
returns uuid language sql stable security definer set search_path = public as $$
  select institute_id from public.profiles where id = auth.uid();
$$;

-- ============================================================
-- CORE TABLES
-- ============================================================
create table if not exists public.institutes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type text not null default 'school',
  address text,
  phone text,
  email text,
  logo_url text,
  principal_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  institute_id uuid not null references public.institutes(id) on delete cascade,
  name text not null,
  section text,
  grade_level text,
  class_teacher_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(),
  institute_id uuid not null references public.institutes(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  name text not null,
  code text,
  teacher_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.enrollments (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  roll_no text,
  created_at timestamptz not null default now(),
  unique (class_id, student_id)
);

create table if not exists public.parent_links (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references public.profiles(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  relation text,
  created_at timestamptz not null default now(),
  unique (parent_id, student_id)
);

-- ---------- Content ----------
create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references public.subjects(id) on delete cascade,
  title text not null,
  description text,
  order_index int not null default 0,
  video_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.materials (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  title text not null,
  file_url text not null,
  file_type text,
  created_at timestamptz not null default now()
);

-- ---------- Assessments ----------
create table if not exists public.assignments (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references public.subjects(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  title text not null,
  description text,
  due_date timestamptz,
  max_points int not null default 100,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.submissions (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references public.assignments(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  file_url text,
  note text,
  grade numeric,
  feedback text,
  status text not null default 'submitted',
  submitted_at timestamptz not null default now(),
  graded_at timestamptz,
  unique (assignment_id, student_id)
);

create table if not exists public.quizzes (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references public.subjects(id) on delete cascade,
  title text not null,
  description text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  question text not null,
  options jsonb not null default '[]'::jsonb,
  correct_index int not null default 0,
  points int not null default 1,
  created_at timestamptz not null default now()
);

-- ---------- Attendance & timetable ----------
create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  date date not null,
  status text not null default 'present',
  marked_by uuid references public.profiles(id) on delete set null,
  note text,
  unique (class_id, student_id, date)
);

create table if not exists public.timetable (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete set null,
  day_of_week int not null,
  start_time text not null,
  end_time text not null,
  room text,
  created_at timestamptz not null default now()
);

-- ---------- Finance ----------
create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  institute_id uuid not null references public.institutes(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  amount numeric not null default 0,
  amount_paid numeric not null default 0,
  due_date date,
  status text not null default 'pending',
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

-- Line items on an invoice / fee slip (one slip can hold many expenses).
create table if not exists public.invoice_items (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  description text not null,
  quantity numeric not null default 1,
  unit_price numeric not null default 0,
  amount numeric not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists invoice_items_invoice_id_idx
  on public.invoice_items(invoice_id);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  amount numeric not null,
  method text,
  reference text,
  recorded_by uuid references public.profiles(id) on delete set null,
  paid_at timestamptz not null default now()
);

-- Institute expenses (salaries, rent, utilities, etc.) — admin only.
create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  institute_id uuid not null references public.institutes(id) on delete cascade,
  category text not null default 'other',
  title text not null,
  amount numeric not null default 0,
  payee text,
  status text not null default 'paid',
  paid_on date,
  note text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists expenses_institute_id_idx
  on public.expenses(institute_id);

-- ---------- Communication ----------
create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  institute_id uuid not null references public.institutes(id) on delete cascade,
  class_id uuid references public.classes(id) on delete cascade,
  title text not null,
  body text not null,
  author_id uuid references public.profiles(id) on delete set null,
  audience text not null default 'all',
  created_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- NOTE: These policies are intentionally pragmatic for an MVP so the
-- app works out-of-the-box for authenticated users. Tighten them
-- per-role/per-institute before going to production.
-- ============================================================
alter table public.profiles       enable row level security;
alter table public.institutes     enable row level security;
alter table public.classes        enable row level security;
alter table public.subjects       enable row level security;
alter table public.enrollments    enable row level security;
alter table public.parent_links   enable row level security;
alter table public.lessons        enable row level security;
alter table public.materials      enable row level security;
alter table public.assignments    enable row level security;
alter table public.submissions    enable row level security;
alter table public.quizzes        enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.attendance     enable row level security;
alter table public.timetable      enable row level security;
alter table public.invoices       enable row level security;
alter table public.invoice_items  enable row level security;
alter table public.payments       enable row level security;
alter table public.expenses       enable row level security;
alter table public.announcements  enable row level security;
alter table public.messages       enable row level security;

-- Profiles: everyone authenticated can read; users manage their own row;
-- principals may update any profile (e.g. assign institute).
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select to authenticated using (true);

drop policy if exists profiles_insert on public.profiles;
create policy profiles_insert on public.profiles
  for insert to authenticated with check (id = auth.uid());

drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles
  for update to authenticated
  using (id = auth.uid() or public.edulink_role() = 'principal')
  with check (id = auth.uid() or public.edulink_role() = 'principal');

-- Generic authenticated access for operational tables (MVP).
do $$
declare t text;
begin
  foreach t in array array[
    'institutes','classes','subjects','enrollments','parent_links',
    'lessons','materials','assignments','submissions','quizzes',
    'quiz_questions','attendance','timetable','invoices','invoice_items',
    'payments','announcements','messages'
  ]
  loop
    execute format('drop policy if exists %I_all on public.%I;', t, t);
    execute format(
      'create policy %I_all on public.%I for all to authenticated using (true) with check (true);',
      t, t);
  end loop;
end $$;

-- Expenses are restricted to the principal (admin) of the owning institute.
drop policy if exists expenses_admin on public.expenses;
create policy expenses_admin on public.expenses
  for all to authenticated
  using (
    public.edulink_role() = 'principal'
    and institute_id = public.edulink_institute()
  )
  with check (
    public.edulink_role() = 'principal'
    and institute_id = public.edulink_institute()
  );

-- ============================================================
-- STORAGE BUCKETS
-- ============================================================
insert into storage.buckets (id, name, public)
values
  ('materials', 'materials', true),
  ('submissions', 'submissions', true),
  ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists "authenticated upload" on storage.objects;
create policy "authenticated upload" on storage.objects
  for insert to authenticated with check (true);

drop policy if exists "public read" on storage.objects;
create policy "public read" on storage.objects
  for select using (true);

drop policy if exists "authenticated update" on storage.objects;
create policy "authenticated update" on storage.objects
  for update to authenticated using (true) with check (true);

drop policy if exists "authenticated delete" on storage.objects;
create policy "authenticated delete" on storage.objects
  for delete to authenticated using (true);
