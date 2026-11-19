-- Imitação mínima do Supabase: papéis, auth.users e auth.uid()
do $$ begin create role anon nologin; create role authenticated nologin; exception when duplicate_object then null; end $$;
create schema auth;
create table auth.users (id uuid primary key);
create function auth.uid() returns uuid language sql stable as
  $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
grant usage on schema auth, public to anon, authenticated;
grant execute on function auth.uid() to anon, authenticated;
alter default privileges in schema public grant all on tables to anon, authenticated;
alter default privileges in schema public grant all on sequences to anon, authenticated;
alter default privileges in schema public grant execute on functions to anon, authenticated;
insert into auth.users values
 ('78768c03-68d4-420f-ba5d-c7fe46434042'),('24409def-6870-4624-828a-84e9d6884de0'),
 ('d5c2215c-797c-435b-859b-09be1fe3efbf'),('014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
 ('99999999-9999-9999-9999-999999999999'); -- intruso logado sem perfil
