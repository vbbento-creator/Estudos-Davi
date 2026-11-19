-- Migração 04: tarefa só em alguns dias da semana (0 = domingo … 6 = sábado; null = todos os dias)
-- No revezamento, a vez só anda nos dias em que a tarefa existe (e não está pausado).
alter table tarefas add column dias_semana int[]
  check (dias_semana is null or (cardinality(dias_semana) between 1 and 7 and dias_semana <@ array[0,1,2,3,4,5,6]));

create or replace function responsaveis(p_tarefa bigint, d date) returns uuid[]
language plpgsql stable security definer set search_path = public as $$
declare t tarefas; n int; k int; tr uuid;
begin
  select * into t from tarefas where id = p_tarefa;
  if t is null or d < t.base or dia_pausado(d) then return '{}'; end if;
  if t.dias_semana is not null and not (extract(dow from d)::int = any (t.dias_semana)) then return '{}'; end if;
  if t.modo = 'todos' then return t.alunos; end if;
  select aluno into tr from trocas where tarefa = p_tarefa and dia = d;
  if tr is not null then return array[tr]; end if;
  n := cardinality(t.alunos);
  k := (select count(*) from generate_series(t.base, d - 1, interval '1 day') g
         where (t.dias_semana is null or extract(dow from g)::int = any (t.dias_semana))
           and not dia_pausado(g::date))::int;
  return array[t.alunos[(k % n) + 1]];
end $$;
revoke execute on function responsaveis(bigint, date) from public, anon;
grant execute on function responsaveis(bigint, date) to authenticated;
