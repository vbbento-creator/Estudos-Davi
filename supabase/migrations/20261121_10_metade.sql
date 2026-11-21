-- =====================================================
-- Migração 10 — Validar a tarefa pela metade
--   • terceira decisão "metade": credita 50% dos pontos; motivo obrigatório (reclamou ou enrolou) e comentário opcional
--   • a criança vê o motivo e pode recorrer
--   • recurso contra a metade: validar inteira ou manter a metade; recurso contra a rejeição também pode virar metade
--   • a decisão acerta o livro-razão pela diferença (crédito sujeito ao teto semanal; o que sobra vira estorno)
-- Pré-requisito: migrações 01 a 09.
-- ATENÇÃO: o app antigo não entende a decisão "metade". Aplicar JUNTO com a publicação do novo index.html.
-- =====================================================
begin;

do $$ declare c record; begin
  for c in select conrelid::regclass::text as t, conname from pg_constraint
            where contype = 'c' and conrelid in ('tarefa_dia'::regclass, 'recursos'::regclass)
              and pg_get_constraintdef(oid) ilike '%validado%' loop
    execute format('alter table %s drop constraint %I', c.t, c.conname);
  end loop;
end $$;
alter table tarefa_dia add constraint tarefa_dia_decisao_check check (decisao in ('validado','metade','rejeitado'));
alter table recursos   add constraint recursos_decisao_final_check check (decisao_final in ('validado','metade','rejeitado'));
alter table tarefa_dia
  add column motivo text check (motivo in ('reclamou','enrolou')),
  add column motivo_comentario text,
  add constraint tarefa_dia_motivo_ok check (coalesce(decisao, '') = 'metade' and motivo is not null or coalesce(decisao, '') <> 'metade' and motivo is null);

-- interno: aplica a decisão e acerta o livro-razão pela diferença (crédito na data da tarefa)
drop function _aplicar_decisao(bigint, date, uuid, text);
create function _aplicar_decisao(p_tarefa bigint, p_dia date, p_aluno uuid, p_decisao text,
                                 p_motivo text default null, p_comentario text default null)
returns void language plpgsql security definer set search_path = public as $$
declare td tarefa_dia; nome_t text; ref text := p_tarefa || ':' || p_dia; alvo numeric; ja numeric; dif numeric; lid bigint;
begin
  select * into td from tarefa_dia where tarefa = p_tarefa and dia = p_dia and aluno = p_aluno for update;
  select nome into nome_t from tarefas where id = p_tarefa;
  alvo := case p_decisao when 'validado' then td.valor when 'metade' then round(td.valor / 2, 1) else 0 end;
  select coalesce(sum(valor), 0) into ja from lancamentos
   where aluno = p_aluno and grupo = 'casa' and origem in ('tarefa','estorno') and origem_ref = ref;
  dif := alvo - ja;
  lid := td.lancamento;
  if dif > 0 then
    lid := coalesce(_lancar(p_aluno, 'casa', dif, case when p_decisao = 'metade' then 'Tarefa (metade): ' else 'Tarefa: ' end || nome_t,
                            p_dia, 'tarefa', ref), td.lancamento);
  elsif dif < 0 then
    perform _lancar(p_aluno, 'casa', dif, 'Estorno: ' || nome_t, p_dia, 'estorno', ref);
  end if;
  if alvo = 0 then lid := null; end if;
  update tarefa_dia set decisao = p_decisao, decidido_por = auth.uid(),
         decidido_em = coalesce(decidido_em, now()), lancamento = lid,
         motivo = case when p_decisao = 'metade' then p_motivo end,
         motivo_comentario = case when p_decisao = 'metade' then nullif(trim(p_comentario), '') end
   where tarefa = p_tarefa and dia = p_dia and aluno = p_aluno;
end $$;
revoke execute on function _aplicar_decisao(bigint, date, uuid, text, text, text) from public, anon, authenticated;

-- pais decidem uma tarefa marcada como feita (sem prazo). Depois disso, só por recurso.
drop function decidir_tarefa(bigint, date, uuid, text);
create function decidir_tarefa(p_tarefa bigint, p_dia date, p_aluno uuid, p_decisao text,
                               p_motivo text default null, p_comentario text default null)
returns void language plpgsql security definer set search_path = public as $$
declare td tarefa_dia;
begin
  if not is_responsavel() then raise exception 'Só pai ou mãe'; end if;
  if p_decisao is null or p_decisao not in ('validado','metade','rejeitado') then raise exception 'Decisão inválida'; end if;
  if p_decisao = 'metade' and (p_motivo is null or p_motivo not in ('reclamou','enrolou')) then
    raise exception 'Escolha o motivo da metade: reclamou ou enrolou';
  end if;
  select * into td from tarefa_dia where tarefa = p_tarefa and dia = p_dia and aluno = p_aluno;
  if td.tarefa is null or td.status <> 'feito' then raise exception 'Só se valida tarefa marcada como feita'; end if;
  if td.decisao is not null then raise exception 'Já decidida: só muda por recurso'; end if;
  perform _aplicar_decisao(p_tarefa, p_dia, p_aluno, p_decisao, p_motivo, p_comentario);
end $$;

-- decisão final dos pais. Contra a metade: validar inteira ou manter a metade.
drop function resolver_recurso(bigint, text, text);
create function resolver_recurso(p_id bigint, p_decisao text, p_resposta text default null, p_motivo text default null)
returns void language plpgsql security definer set search_path = public as $$
declare r recursos; td tarefa_dia; mot text; com text;
begin
  if not is_responsavel() then raise exception 'Só pai ou mãe'; end if;
  if p_decisao is null or p_decisao not in ('validado','metade','rejeitado') then raise exception 'Decisão inválida'; end if;
  select * into r from recursos where id = p_id for update;
  if r.id is null or r.decisao_final is not null then raise exception 'Recurso inexistente ou já resolvido'; end if;
  select * into td from tarefa_dia where tarefa = r.tarefa and dia = r.dia and aluno = r.aluno;
  if td.decisao = 'metade' and p_decisao = 'rejeitado' then
    raise exception 'No recurso contra a metade: validar inteira ou manter a metade';
  end if;
  if p_decisao = 'metade' then
    mot := coalesce(p_motivo, case when td.decisao = 'metade' then td.motivo end);
    com := case when p_motivo is null and td.decisao = 'metade' then td.motivo_comentario end;
    if mot is null or mot not in ('reclamou','enrolou') then raise exception 'Escolha o motivo da metade: reclamou ou enrolou'; end if;
  end if;
  perform _aplicar_decisao(r.tarefa, r.dia, r.aluno, p_decisao, mot, com);
  update recursos set decisao_final = p_decisao, resposta = p_resposta,
         decidido_por = auth.uid(), decidido_em = now() where id = p_id;
end $$;

-- lista do dia e agenda devolvem também o motivo da metade
drop function tarefas_do_dia(uuid, date);
create function tarefas_do_dia(p_aluno uuid, p_dia date)
returns table (tarefa bigint, nome text, emoji text, pontos numeric, status text, decisao text,
               valor numeric, marcado_por uuid, decidido_em timestamptz,
               recurso_id bigint, recurso_comentario text, recurso_decisao text, recurso_resposta text,
               pode_marcar boolean, pode_recorrer boolean, periodo text, motivo text, motivo_comentario text)
language plpgsql stable security definer set search_path = public as $$
#variable_conflict use_column
declare hoje date := hoje_sp();
begin
  if not pode_ver(p_aluno) then raise exception 'Sem acesso'; end if;
  return query
  select t.id, t.nome, t.emoji, t.pontos,
         coalesce(td.status, case when p_dia < hoje - 1 then 'nao_feito' else 'a_fazer' end),
         td.decisao, td.valor, td.marcado_por, td.decidido_em,
         r.id, r.comentario, r.decisao_final, r.resposta,
         (td.decisao is null and p_dia <= hoje and t.ativa
            and (is_responsavel() or p_dia >= hoje - 1)),
         (td.decisao is not null and r.id is null and p_aluno = auth.uid()
            and now() <= td.decidido_em + interval '5 days'),
         t.periodo, td.motivo, td.motivo_comentario
    from tarefas t
    left join tarefa_dia td on td.tarefa = t.id and td.dia = p_dia and td.aluno = p_aluno
    left join recursos r on r.tarefa = t.id and r.dia = p_dia and r.aluno = p_aluno
   where td.tarefa is not null
      or (t.ativa and p_aluno = any (responsaveis(t.id, p_dia)))
   order by case t.periodo when 'manha' then 1 when 'tarde' then 2 when 'noite' then 3 else 4 end, t.ordem, t.id;
end $$;

drop function agenda_tarefas(uuid, date, date);
create function agenda_tarefas(p_aluno uuid, p_ini date, p_fim date)
returns table (dia date, tarefa bigint, nome text, emoji text, pontos numeric, periodo text, status text, decisao text,
               valor numeric, motivo text, motivo_comentario text)
language plpgsql stable security definer set search_path = public as $$
#variable_conflict use_column
declare hoje date := hoje_sp();
begin
  if not pode_ver(p_aluno) then raise exception 'Sem acesso'; end if;
  if p_fim < p_ini or p_fim - p_ini > 62 then raise exception 'Intervalo inválido'; end if;
  return query
  select d::date, t.id, t.nome, t.emoji, t.pontos, t.periodo,
         coalesce(td.status, case when d::date < hoje - 1 then 'nao_feito' when d::date > hoje then 'futuro' else 'a_fazer' end),
         td.decisao, td.valor, td.motivo, td.motivo_comentario
    from generate_series(p_ini::timestamp, p_fim::timestamp, interval '1 day') d
    cross join tarefas t
    left join tarefa_dia td on td.tarefa = t.id and td.dia = d::date and td.aluno = p_aluno
   where td.tarefa is not null or (t.ativa and p_aluno = any (responsaveis(t.id, d::date)))
   order by d, case t.periodo when 'manha' then 1 when 'tarde' then 2 when 'noite' then 3 else 4 end, t.ordem, t.id;
end $$;

do $$ declare f text; begin
  foreach f in array array['decidir_tarefa(bigint,date,uuid,text,text,text)','resolver_recurso(bigint,text,text,text)',
                           'tarefas_do_dia(uuid,date)','agenda_tarefas(uuid,date,date)'] loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

commit;
