-- KISO Back Office — database & hak akses
-- Jalankan SEKALI di Supabase: menu SQL Editor → New query → tempel seluruh isi file ini → Run.

create extension if not exists pgcrypto;

-- 1. Semua data aplikasi: satu baris = satu dokumen (koleksi + id + isi JSON)
create table if not exists public.docs (
  coll text not null,
  id text not null,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid(),
  primary key (coll, id)
);
alter table public.docs replica identity full;

-- 2. Pengguna aplikasi & perannya
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  name text not null default '',
  role text not null check (role in ('ceo','admin','gudang','pemilik')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Peran pengguna yang sedang login (null = tidak punya akses)
create or replace function public.my_role() returns text
language sql stable security definer set search_path = public as $$
  select role from public.profiles where user_id = auth.uid() and active
$$;

-- Koleksi yang boleh diubah tiap peran (dijaga server, bukan hanya tampilan)
create or replace function public.can_write(c text) returns boolean
language sql stable security definer set search_path = public as $$
  select case public.my_role()
    when 'ceo' then true
    when 'admin' then c not in ('production','moves')
    when 'gudang' then c in ('production','moves','returns','products','materials')
    else false end
$$;

alter table public.docs enable row level security;
alter table public.profiles enable row level security;

drop policy if exists docs_read on public.docs;
drop policy if exists docs_insert on public.docs;
drop policy if exists docs_update on public.docs;
drop policy if exists docs_delete on public.docs;
create policy docs_read   on public.docs for select using (public.my_role() is not null and (coll <> 'customers' or public.my_role() in ('ceo','admin','pemilik')));
create policy docs_insert on public.docs for insert with check (public.can_write(coll));
create policy docs_update on public.docs for update using (public.can_write(coll)) with check (public.can_write(coll));
create policy docs_delete on public.docs for delete using (public.can_write(coll));

drop policy if exists prof_read on public.profiles;
drop policy if exists prof_write on public.profiles;
create policy prof_read  on public.profiles for select using (user_id = auth.uid() or public.my_role() = 'ceo');
create policy prof_write on public.profiles for all using (public.my_role() = 'ceo') with check (public.my_role() = 'ceo');

-- Akun pertama yang login saat belum ada pengguna sama sekali otomatis menjadi CEO
create or replace function public.bootstrap_ceo(p_username text, p_name text) returns boolean
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null or exists (select 1 from public.profiles) then return false; end if;
  insert into public.profiles(user_id, username, name, role) values (auth.uid(), lower(p_username), p_name, 'ceo');
  return true;
end $$;

-- CEO mengganti password pengguna lain (lupa password)
create or replace function public.admin_set_password(p_user uuid, p_password text) returns void
language plpgsql security definer set search_path = public, auth, extensions as $$
begin
  if coalesce(public.my_role(),'') <> 'ceo' then raise exception 'Hanya CEO yang bisa mengganti password pengguna lain'; end if;
  if length(p_password) < 6 then raise exception 'Password minimal 6 karakter'; end if;
  update auth.users set encrypted_password = crypt(p_password, gen_salt('bf')), updated_at = now() where id = p_user;
end $$;

revoke all on function public.admin_set_password(uuid, text) from anon;
revoke all on function public.bootstrap_ceo(text, text) from anon;

-- Perubahan data langsung terlihat di semua komputer
do $$ begin
  alter publication supabase_realtime add table public.docs;
exception when duplicate_object then null; end $$;

-- Halaman login perlu tahu apakah sudah ada pengguna (untuk membuat akun CEO pertama)
create or replace function public.has_users() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles)
$$;
grant execute on function public.has_users() to anon, authenticated;
