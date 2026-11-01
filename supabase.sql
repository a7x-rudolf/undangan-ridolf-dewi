-- Jalankan di Supabase > SQL Editor
create table guests (
  code text primary key default upper(substr(md5(gen_random_uuid()::text),1,8)),
  name text not null,
  redeemed_at timestamptz
);
create unique index guests_name_uq on guests (lower(trim(name)));  -- 1 nama = 1 souvenir
create table settings (pin text not null);
insert into settings values ('GANTI_PIN_INI');                    -- PIN panitia
alter table guests enable row level security;                      -- tanpa policy = tabel tertutup
alter table settings enable row level security;

create function get_guest(p_code text) returns table(name text, redeemed boolean)
language sql security definer set search_path=public as
$$ select name, redeemed_at is not null from guests where code = upper(trim(p_code)) $$;

create function redeem_souvenir(p_code text, p_pin text) returns json
language plpgsql security definer set search_path=public as $$
declare g guests;
begin
  if p_pin is distinct from (select pin from settings limit 1) then return json_build_object('status','pin_salah'); end if;
  update guests set redeemed_at = now() where code = upper(trim(p_code)) and redeemed_at is null returning * into g;
  if found then return json_build_object('status','ok','name',g.name); end if;
  select * into g from guests where code = upper(trim(p_code));
  if not found then return json_build_object('status','tidak_ditemukan'); end if;
  return json_build_object('status','sudah_diambil','name',g.name,'at',g.redeemed_at);
end $$;

create function add_guests(p_pin text, p_names text[]) returns table(name text, code text)
language plpgsql security definer set search_path=public as $$
begin
  if p_pin is distinct from (select pin from settings limit 1) then raise exception 'PIN salah'; end if;
  insert into guests(name) select trim(n) from unnest(p_names) n where trim(n) <> '' on conflict do nothing;
  return query select g.name, g.code from guests g where lower(trim(g.name)) in (select lower(trim(n)) from unnest(p_names) n);
end $$;

create function list_guests(p_pin text) returns table(name text, code text, redeemed_at timestamptz)
language plpgsql security definer set search_path=public as $$
begin
  if p_pin is distinct from (select pin from settings limit 1) then raise exception 'PIN salah'; end if;
  return query select g.name, g.code, g.redeemed_at from guests g order by g.name;
end $$;

grant execute on function get_guest, redeem_souvenir, add_guests, list_guests to anon;
