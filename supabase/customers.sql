-- KISO Back Office — data pelanggan (modul Pelanggan)
-- Data pembeli disimpan di koleksi "customers". Hanya CEO, Pemilik, dan Admin yang bisa membacanya.
-- Riwayat perubahan tidak menyimpan isi data pembeli (hanya tanggal, channel, dan jumlah baris).

drop policy if exists docs_read on public.docs;
create policy docs_read on public.docs for select using (
  public.my_role() is not null
  and (coll <> 'customers' or public.my_role() in ('ceo','admin','pemilik'))
);

create or replace function public.log_docs() returns trigger
language plpgsql security definer set search_path = public as $$
declare d jsonb; u text; c text;
begin
  if tg_op = 'UPDATE' and new.data = old.data then return null; end if;
  select username into u from public.profiles where user_id = auth.uid();
  c := case when tg_op = 'DELETE' then old.coll else new.coll end;
  d := case when tg_op = 'DELETE' then old.data else new.data end;
  if c = 'customers' then
    d := jsonb_strip_nulls(jsonb_build_object('date', d->'date', 'ch', d->'ch',
      'count', case when jsonb_typeof(d->'list') = 'array' then jsonb_array_length(d->'list') end));
  elsif length(d::text) > 1500 then
    d := jsonb_strip_nulls(jsonb_build_object('date', d->'date', 'ch', d->'ch', 'kind', d->'kind', 'from', d->'from', 'to', d->'to', 'name', d->'name',
      'count', case when jsonb_typeof(d->'orders') = 'array' then jsonb_array_length(d->'orders') when jsonb_typeof(d->'rows') = 'array' then jsonb_array_length(d->'rows') end));
  end if;
  insert into public.audit_log (user_id, username, coll, doc_id, action, info)
  values (auth.uid(), u, c, case when tg_op = 'DELETE' then old.id else new.id end, lower(tg_op), d);
  return null;
end $$;
