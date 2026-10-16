-- KISO Back Office — riwayat perubahan (siapa mengubah apa, kapan)
-- Jalankan SEKALI di Supabase: SQL Editor → New query → tempel → Run.

create table if not exists public.audit_log (
  id bigserial primary key,
  at timestamptz not null default now(),
  user_id uuid default auth.uid(),
  username text,
  coll text not null,
  doc_id text not null,
  action text not null,
  info jsonb
);
create index if not exists audit_log_at on public.audit_log (at desc);
create index if not exists audit_log_coll on public.audit_log (coll, at desc);
alter table public.audit_log enable row level security;
drop policy if exists audit_read on public.audit_log;
create policy audit_read on public.audit_log for select using (public.my_role() is not null);
-- tidak ada policy insert/update/delete: riwayat hanya ditulis oleh trigger dan tidak bisa diubah dari aplikasi

create or replace function public.log_docs() returns trigger
language plpgsql security definer set search_path = public as $$
declare d jsonb; u text;
begin
  if tg_op = 'UPDATE' and new.data = old.data then return null; end if;
  select username into u from public.profiles where user_id = auth.uid();
  d := case when tg_op = 'DELETE' then old.data else new.data end;
  if length(d::text) > 1500 then
    d := jsonb_strip_nulls(jsonb_build_object('date', d->'date', 'ch', d->'ch', 'kind', d->'kind', 'from', d->'from', 'to', d->'to', 'name', d->'name',
      'count', case when jsonb_typeof(d->'orders') = 'array' then jsonb_array_length(d->'orders') when jsonb_typeof(d->'rows') = 'array' then jsonb_array_length(d->'rows') end));
  end if;
  insert into public.audit_log (user_id, username, coll, doc_id, action, info)
  values (auth.uid(), u, case when tg_op = 'DELETE' then old.coll else new.coll end, case when tg_op = 'DELETE' then old.id else new.id end, lower(tg_op), d);
  return null;
end $$;
drop trigger if exists docs_audit on public.docs;
create trigger docs_audit after insert or update or delete on public.docs for each row execute function public.log_docs();

create or replace function public.log_profiles() returns trigger
language plpgsql security definer set search_path = public as $$
declare u text; r record;
begin
  select username into u from public.profiles where user_id = auth.uid();
  if tg_op = 'DELETE' then r := old; else r := new; end if;
  insert into public.audit_log (user_id, username, coll, doc_id, action, info)
  values (auth.uid(), coalesce(u, r.username), 'profiles', r.username, lower(tg_op), jsonb_build_object('name', r.username, 'role', r.role, 'active', r.active));
  return null;
end $$;
drop trigger if exists profiles_audit on public.profiles;
create trigger profiles_audit after insert or update or delete on public.profiles for each row execute function public.log_profiles();

do $$ begin
  alter publication supabase_realtime add table public.audit_log;
exception when duplicate_object then null; end $$;
