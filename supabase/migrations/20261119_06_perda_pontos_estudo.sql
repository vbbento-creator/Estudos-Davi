-- =====================================================
-- Migração 06 — perder os pontos de estudo e de treino de uma matéria
-- Pai ou mãe avaliam pela nota da prova da escola. Se a média ficar abaixo do mínimo, retiram
-- os pontos de tópico concluído e de treino daquela matéria (a prova valendo no app não entra).
-- Cada crédito só pode ser retirado uma vez (estorno com origem_ref 'perda:<id do crédito>').
-- Pré-requisito: migração 05.
-- =====================================================
begin;

create unique index lancamentos_unico_perda on lancamentos (aluno, origem_ref)
  where origem = 'estorno' and origem_ref like 'perda:%';

-- pontos de estudo e treino ainda valendo, por matéria (créditos ainda não retirados)
create function pontos_estudo_por_materia(p_aluno uuid) returns table (materia text, pontos numeric)
language plpgsql stable security definer set search_path = public as $$
begin
  if not pode_ver(p_aluno) then raise exception 'Sem acesso'; end if;
  return query
  select split_part(l.origem_ref, ':', 1), sum(l.valor)
    from lancamentos l
   where l.aluno = p_aluno and l.origem in ('topico', 'treino') and l.valor > 0
     and not exists (select 1 from lancamentos e where e.aluno = l.aluno and e.origem = 'estorno' and e.origem_ref = 'perda:' || l.id)
   group by 1;
end $$;

-- retira esses pontos; devolve o total retirado. O saldo pode ficar negativo se a criança já gastou.
create function perder_pontos_estudo(p_aluno uuid, p_materia text) returns numeric
language plpgsql security definer set search_path = public as $$
declare r record; total numeric := 0;
begin
  if not is_responsavel() then raise exception 'Só pai ou mãe'; end if;
  if not is_aluno(p_aluno) then raise exception 'Aluno inválido'; end if;
  for r in
    select l.id, l.valor, l.descricao from lancamentos l
     where l.aluno = p_aluno and l.origem in ('topico', 'treino') and l.valor > 0
       and split_part(l.origem_ref, ':', 1) = p_materia
       and not exists (select 1 from lancamentos e where e.aluno = l.aluno and e.origem = 'estorno' and e.origem_ref = 'perda:' || l.id)
     order by l.id
  loop
    perform _lancar(p_aluno, 'estudos', -r.valor, 'Perdeu: ' || r.descricao, hoje_sp(), 'estorno', 'perda:' || r.id);
    total := total + r.valor;
  end loop;
  return total;
end $$;

do $$ declare f text; begin
  foreach f in array array['pontos_estudo_por_materia(uuid)', 'perder_pontos_estudo(uuid,text)'] loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

commit;
