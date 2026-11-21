-- =====================================================
-- Migração 11 — Tarefa avulsa (um dia só)
--   • tarefas ganham data de fim opcional (ate); avulsa = base = ate = o dia
--   • depois do fim a tarefa não aparece mais (o que já foi marcado continua na agenda e no extrato)
-- Pré-requisito: migrações 01 a 10. Só acrescenta: o app antigo continua funcionando.
-- =====================================================
begin;

alter table tarefas add column ate date;
alter table tarefas add constraint tarefas_ate_check check (ate is null or ate >= base);
comment on column tarefas.ate is 'Último dia da tarefa (nulo = sem fim). Tarefa avulsa: base = ate';

-- quem faz a tarefa no dia d (igual à migração 08, mais o fim da tarefa)
create or replace function responsaveis(p_tarefa bigint, d date) returns uuid[]
language plpgsql stable security definer set search_path = public as $$
declare t tarefas; n int; k int; tr uuid; ini revez_inicios; b date; i0 int; res uuid[]; s substituicoes;
begin
  select * into t from tarefas where id = p_tarefa;
  if t is null or d < t.base or (t.ate is not null and d > t.ate) or dia_pausado(d) then return '{}'; end if;
  if t.dias_semana is not null and not (extract(dow from d)::int = any (t.dias_semana)) then return '{}'; end if;
  if t.modo = 'todos' then
    res := t.alunos;
    for s in select * from substituicoes where tarefa = p_tarefa and desde <= d and (ate is null or ate >= d) order by criado, id loop
      if s.de = any (res) then
        res := array_remove(res, s.de);
        if not (s.para = any (res)) then res := res || s.para; end if;
      end if;
    end loop;
    return res;
  end if;
  select aluno into tr from trocas where tarefa = p_tarefa and dia = d;
  if tr is not null then return array[tr]; end if;
  -- recomeço mais recente (ignorado se a criança saiu do revezamento)
  select * into ini from revez_inicios where tarefa = p_tarefa and desde <= d and aluno = any (t.alunos)
   order by desde desc limit 1;
  b  := coalesce(greatest(ini.desde, t.base), t.base);
  i0 := coalesce(array_position(t.alunos, ini.aluno), 1) - 1;
  n  := cardinality(t.alunos);
  k  := (select count(*) from generate_series(b, d - 1, interval '1 day') g
          where (t.dias_semana is null or extract(dow from g)::int = any (t.dias_semana))
            and not dia_pausado(g::date))::int;
  return array[t.alunos[((i0 + k) % n) + 1]];
end $$;
revoke execute on function responsaveis(bigint, date) from public, anon;
grant execute on function responsaveis(bigint, date) to authenticated;

commit;
