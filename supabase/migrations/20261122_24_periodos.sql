-- =====================================================
-- Migração 24 — Tarefa com vários períodos no dia
--   • tarefas.periodos (manha, tarde, noite ou dia; "dia" só sozinho) no lugar de tarefas.periodo
--   • marcação, decisão e recurso por período: tarefa_dia e recursos ganham "periodo" na chave
--   • não dá para adiantar: no dia de hoje, manhã abre 0h, tarde 12h, noite e dia todo 18h (Brasília);
--     ontem continua livre. A trava vale só para marcar como feito; desmarcar segue livre antes da decisão
--   • lançamentos: origem_ref "tarefa:dia" no período "dia" (como antes) e "tarefa:dia:periodo" nos outros;
--     os já lançados de marcações com período são reescritos aqui
--   • as duas tarefas de escovar os dentes viram uma só (manhã + noite)
-- Pré-requisito: migrações 01 a 23.
-- ATENÇÃO: tem DROP (aplicar pelo SQL Editor) e o app antigo não manda período.
--          Aplicar JUNTO com a publicação do novo index.html.
-- =====================================================
begin;

-- ---------- relógio e horários ----------
-- hora de agora em Brasília (os testes trocam esta função para simular o horário)
create or replace function agora_sp() returns timestamp
language sql stable as $$ select (now() at time zone 'America/Sao_Paulo')::timestamp $$;

create or replace function abre_periodo(p text) returns time
language sql immutable as $$
  select case p when 'manha' then time '00:00' when 'tarde' then time '12:00' else time '18:00' end $$;

-- posição do período na lista (manhã, tarde, noite, dia todo)
create or replace function _ordem_periodo(p text) returns int
language sql immutable as $$ select array_position(array['manha','tarde','noite','dia'], p) $$;

create or replace function _periodos_ok(ps text[]) returns boolean
language sql immutable as $$
  select cardinality(ps) >= 1
     and ps <@ array['manha','tarde','noite','dia']
     and cardinality(ps) = (select count(distinct x) from unnest(ps) x)
     and not ('dia' = any (ps) and cardinality(ps) > 1) $$;

-- ---------- tarefas: lista de períodos ----------
alter table tarefas add column periodos text[] not null default '{dia}';
update tarefas set periodos = array[coalesce(periodo, 'dia')];
alter table tarefas add constraint tarefas_periodos_ok check (_periodos_ok(periodos));
comment on column tarefas.periodos is 'Períodos do dia: manha, tarde, noite (um ou mais) ou dia (sozinho: uma vez no dia, marcada a partir das 18h)';

-- ---------- marcações e recursos por período ----------
alter table tarefa_dia add column periodo text;
update tarefa_dia td set periodo = coalesce(t.periodo, 'dia') from tarefas t where t.id = td.tarefa;
alter table tarefa_dia alter column periodo set not null, alter column periodo set default 'dia',
  add constraint tarefa_dia_periodo_check check (periodo in ('manha','tarde','noite','dia'));

alter table recursos add column periodo text;
update recursos r set periodo = coalesce(t.periodo, 'dia') from tarefas t where t.id = r.tarefa;
alter table recursos alter column periodo set not null, alter column periodo set default 'dia';

-- chave estrangeira e "unique" dos recursos, e a chave de tarefa_dia, passam a incluir o período
do $$ declare c record; begin
  for c in select conname from pg_constraint where conrelid = 'recursos'::regclass and contype in ('f','u') loop
    execute format('alter table recursos drop constraint %I', c.conname);
  end loop;
  for c in select conname from pg_constraint where conrelid = 'tarefa_dia'::regclass and contype = 'p' loop
    execute format('alter table tarefa_dia drop constraint %I', c.conname);
  end loop;
end $$;
alter table tarefa_dia add primary key (tarefa, dia, aluno, periodo);
alter table recursos
  add constraint recursos_marcacao_fkey foreign key (tarefa, dia, aluno, periodo) references tarefa_dia,
  add constraint recursos_um_por_periodo unique (tarefa, dia, aluno, periodo);

-- lançamentos de marcações com período ganham o período no origem_ref ("dia" fica como estava)
update lancamentos l set origem_ref = l.origem_ref || ':' || td.periodo
  from tarefa_dia td
 where l.origem in ('tarefa','estorno') and l.aluno = td.aluno
   and l.origem_ref = td.tarefa || ':' || td.dia and td.periodo <> 'dia';

-- ---------- dados de produção: uma tarefa só para escovar os dentes ----------
update tarefas set nome = 'Escovar os dentes', periodos = '{manha,noite}'
 where id = 6 and nome = 'Escovar os dentes (manhã)';
update tarefas set ativa = false
 where id = 7 and nome = 'Escovar os dentes (noite)' and not exists (select 1 from tarefa_dia where tarefa = 7);

-- ---------- funções que mudam de assinatura ou de retorno ----------
drop function marcar_tarefa(bigint, date, text, uuid);
drop function tarefas_do_dia(uuid, date);
drop function agenda_tarefas(uuid, date, date);
alter table tarefas drop column periodo;

-- período pedido (ou, se nulo, o único período da tarefa)
create or replace function _periodo_da_tarefa(p_tarefa bigint, p_periodo text) returns text
language plpgsql stable security definer set search_path = public as $$
declare ps text[];
begin
  if p_periodo is not null then
    if p_periodo not in ('manha','tarde','noite','dia') then raise exception 'Período inválido'; end if;
    return p_periodo;
  end if;
  select periodos into ps from tarefas where id = p_tarefa;
  if cardinality(ps) = 1 then return ps[1]; end if;
  raise exception 'Escolha o período';
end $$;

-- criança (ou pai/mãe pela criança) marca um período; no dia de hoje, só depois que o período abre
create function marcar_tarefa(p_tarefa bigint, p_dia date, p_status text, p_aluno uuid default null, p_periodo text default null)
returns void language plpgsql security definer set search_path = public as $$
declare a uuid := coalesce(p_aluno, auth.uid()); t tarefas; td tarefa_dia; per text; abre time;
begin
  if not pode_ver(a) or not is_aluno(a) then raise exception 'Sem acesso'; end if;
  if p_status is not null and p_status not in ('feito','nao_feito') then raise exception 'Status inválido'; end if;
  select * into t from tarefas where id = p_tarefa;
  if t is null or not t.ativa then raise exception 'Tarefa inexistente ou desativada'; end if;
  if p_dia > hoje_sp() then raise exception 'Esse dia ainda não chegou'; end if;
  if not is_responsavel() and p_dia < hoje_sp() - 1 then raise exception 'O prazo para marcar essa tarefa acabou'; end if;
  per := _periodo_da_tarefa(p_tarefa, p_periodo);
  select * into td from tarefa_dia where tarefa = p_tarefa and dia = p_dia and aluno = a and periodo = per;
  if td.decisao is not null then raise exception 'Tarefa já decidida: só muda por recurso'; end if;
  -- período tirado da tarefa: o que já estava marcado só pode ser desmarcado
  if not (per = any (t.periodos)) and (td.tarefa is null or p_status is not null) then
    raise exception 'Essa tarefa não tem esse período';
  end if;
  if td.tarefa is null and not (a = any (responsaveis(p_tarefa, p_dia))) then
    raise exception 'Essa tarefa não é sua neste dia';
  end if;
  abre := abre_periodo(per);
  if p_status = 'feito' and p_dia = hoje_sp() and agora_sp()::time < abre then
    raise exception 'Esse período ainda não chegou: abre às %h', extract(hour from abre)::int;
  end if;
  if p_status is null then
    delete from tarefa_dia where tarefa = p_tarefa and dia = p_dia and aluno = a and periodo = per;
  else
    insert into tarefa_dia (tarefa, dia, aluno, periodo, status, valor, marcado_por)
         values (p_tarefa, p_dia, a, per, p_status, t.pontos, auth.uid())
    on conflict (tarefa, dia, aluno, periodo) do update
       set status = excluded.status, valor = excluded.valor,
           marcado_por = excluded.marcado_por, marcado_em = now();
  end if;
end $$;

-- lista do dia: uma linha por tarefa e período (os da tarefa e os que já têm marcação nesse dia)
create function tarefas_do_dia(p_aluno uuid, p_dia date)
returns table (tarefa bigint, nome text, emoji text, pontos numeric, status text, decisao text,
               valor numeric, marcado_por uuid, decidido_em timestamptz,
               recurso_id bigint, recurso_comentario text, recurso_decisao text, recurso_resposta text,
               pode_marcar boolean, pode_recorrer boolean, periodo text, motivo text, motivo_comentario text,
               abre_em time)
language plpgsql stable security definer set search_path = public as $$
#variable_conflict use_column
declare hoje date := hoje_sp(); agora time := agora_sp()::time;
begin
  if not pode_ver(p_aluno) then raise exception 'Sem acesso'; end if;
  return query
  with linhas as (
    select t, pp.per, td, r,
           case when p_dia = hoje and agora < abre_periodo(pp.per) then abre_periodo(pp.per) end as abre
      from tarefas t
     cross join lateral (select x from unnest(t.periodos) x
                         union
                         select td0.periodo from tarefa_dia td0
                          where td0.tarefa = t.id and td0.dia = p_dia and td0.aluno = p_aluno) pp(per)
      left join tarefa_dia td on td.tarefa = t.id and td.dia = p_dia and td.aluno = p_aluno and td.periodo = pp.per
      left join recursos r on r.tarefa = t.id and r.dia = p_dia and r.aluno = p_aluno and r.periodo = pp.per
     where td.tarefa is not null
        or (t.ativa and pp.per = any (t.periodos) and p_aluno = any (responsaveis(t.id, p_dia))))
  select (l.t).id, (l.t).nome, (l.t).emoji, (l.t).pontos,
         coalesce((l.td).status, case when p_dia < hoje - 1 then 'nao_feito' else 'a_fazer' end),
         (l.td).decisao, (l.td).valor, (l.td).marcado_por, (l.td).decidido_em,
         (l.r).id, (l.r).comentario, (l.r).decisao_final, (l.r).resposta,
         ((l.td).decisao is null and p_dia <= hoje and (l.t).ativa
            and (is_responsavel() or p_dia >= hoje - 1)
            and ((l.td).tarefa is not null or (l.per = any ((l.t).periodos) and l.abre is null))),
         ((l.td).decisao is not null and (l.r).id is null and p_aluno = auth.uid()
            and now() <= (l.td).decidido_em + interval '5 days'),
         l.per, (l.td).motivo, (l.td).motivo_comentario, l.abre
    from linhas l
   order by (select min(_ordem_periodo(x)) from unnest((l.t).periodos) x), (l.t).ordem, (l.t).id, _ordem_periodo(l.per);
end $$;

-- agenda: uma linha por dia, tarefa e período
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
  select d::date, t.id, t.nome, t.emoji, t.pontos, pp.per,
         coalesce(td.status, case when d::date < hoje - 1 then 'nao_feito' when d::date > hoje then 'futuro' else 'a_fazer' end),
         td.decisao, td.valor, td.motivo, td.motivo_comentario
    from generate_series(p_ini::timestamp, p_fim::timestamp, interval '1 day') d
    cross join tarefas t
    cross join lateral (select x from unnest(t.periodos) x
                        union
                        select td0.periodo from tarefa_dia td0
                         where td0.tarefa = t.id and td0.dia = d::date and td0.aluno = p_aluno) pp(per)
    left join tarefa_dia td on td.tarefa = t.id and td.dia = d::date and td.aluno = p_aluno and td.periodo = pp.per
   where td.tarefa is not null
      or (t.ativa and pp.per = any (t.periodos) and p_aluno = any (responsaveis(t.id, d::date)))
   order by d, (select min(_ordem_periodo(x)) from unnest(t.periodos) x), t.ordem, t.id, _ordem_periodo(pp.per);
end $$;

-- ---------- decisão e recurso por período ----------
drop function _aplicar_decisao(bigint, date, uuid, text, text, text);
drop function decidir_tarefa(bigint, date, uuid, text, text, text);
drop function abrir_recurso(bigint, date, text);

-- interno: aplica a decisão de um período e acerta o livro-razão pela diferença (crédito na data da tarefa)
-- origem_ref: "tarefa:dia" no período "dia" (como antes da 24) e "tarefa:dia:periodo" nos outros
create function _aplicar_decisao(p_tarefa bigint, p_dia date, p_aluno uuid, p_decisao text,
                                 p_motivo text default null, p_comentario text default null, p_periodo text default 'dia')
returns void language plpgsql security definer set search_path = public as $$
declare td tarefa_dia; nome_t text; alvo numeric; ja numeric; dif numeric; lid bigint;
        ref text := p_tarefa || ':' || p_dia || case when p_periodo = 'dia' then '' else ':' || p_periodo end;
begin
  select * into td from tarefa_dia where tarefa = p_tarefa and dia = p_dia and aluno = p_aluno and periodo = p_periodo for update;
  select nome || case p_periodo when 'manha' then ' (manhã)' when 'tarde' then ' (tarde)' when 'noite' then ' (noite)' else '' end
    into nome_t from tarefas where id = p_tarefa;
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
   where tarefa = p_tarefa and dia = p_dia and aluno = p_aluno and periodo = p_periodo;
end $$;
revoke execute on function _aplicar_decisao(bigint, date, uuid, text, text, text, text) from public, anon, authenticated;

-- pais decidem um período marcado como feito (sem prazo). Depois disso, só por recurso.
create function decidir_tarefa(p_tarefa bigint, p_dia date, p_aluno uuid, p_decisao text,
                               p_motivo text default null, p_comentario text default null, p_periodo text default null)
returns void language plpgsql security definer set search_path = public as $$
declare td tarefa_dia; per text;
begin
  if not is_responsavel() then raise exception 'Só pai ou mãe'; end if;
  if p_decisao is null or p_decisao not in ('validado','metade','rejeitado') then raise exception 'Decisão inválida'; end if;
  if p_decisao = 'metade' and (p_motivo is null or p_motivo not in ('reclamou','enrolou')) then
    raise exception 'Escolha o motivo da metade: reclamou ou enrolou';
  end if;
  per := _periodo_da_tarefa(p_tarefa, p_periodo);
  select * into td from tarefa_dia where tarefa = p_tarefa and dia = p_dia and aluno = p_aluno and periodo = per;
  if td.tarefa is null or td.status <> 'feito' then raise exception 'Só se valida tarefa marcada como feita'; end if;
  if td.decisao is not null then raise exception 'Já decidida: só muda por recurso'; end if;
  perform _aplicar_decisao(p_tarefa, p_dia, p_aluno, p_decisao, p_motivo, p_comentario, per);
end $$;

-- criança contesta um período até 5 dias corridos após a decisão inicial
create function abrir_recurso(p_tarefa bigint, p_dia date, p_comentario text, p_periodo text default null)
returns void language plpgsql security definer set search_path = public as $$
declare td tarefa_dia; per text;
begin
  per := _periodo_da_tarefa(p_tarefa, p_periodo);
  select * into td from tarefa_dia where tarefa = p_tarefa and dia = p_dia and aluno = auth.uid() and periodo = per;
  if td.tarefa is null or td.decisao is null then raise exception 'Não há decisão para contestar'; end if;
  if now() > td.decidido_em + interval '5 days' then raise exception 'Prazo de recurso (5 dias) encerrado'; end if;
  insert into recursos (tarefa, dia, aluno, periodo, comentario) values (p_tarefa, p_dia, auth.uid(), per, p_comentario);
end $$;

-- decisão final dos pais (o recurso já sabe o período). Contra a metade: validar inteira ou manter a metade.
create or replace function resolver_recurso(p_id bigint, p_decisao text, p_resposta text default null, p_motivo text default null)
returns void language plpgsql security definer set search_path = public as $$
declare r recursos; td tarefa_dia; mot text; com text;
begin
  if not is_responsavel() then raise exception 'Só pai ou mãe'; end if;
  if p_decisao is null or p_decisao not in ('validado','metade','rejeitado') then raise exception 'Decisão inválida'; end if;
  select * into r from recursos where id = p_id for update;
  if r.id is null or r.decisao_final is not null then raise exception 'Recurso inexistente ou já resolvido'; end if;
  select * into td from tarefa_dia where tarefa = r.tarefa and dia = r.dia and aluno = r.aluno and periodo = r.periodo;
  if td.decisao = 'metade' and p_decisao = 'rejeitado' then
    raise exception 'No recurso contra a metade: validar inteira ou manter a metade';
  end if;
  if p_decisao = 'metade' then
    mot := coalesce(p_motivo, case when td.decisao = 'metade' then td.motivo end);
    com := case when p_motivo is null and td.decisao = 'metade' then td.motivo_comentario end;
    if mot is null or mot not in ('reclamou','enrolou') then raise exception 'Escolha o motivo da metade: reclamou ou enrolou'; end if;
  end if;
  perform _aplicar_decisao(r.tarefa, r.dia, r.aluno, p_decisao, mot, com, r.periodo);
  update recursos set decisao_final = p_decisao, resposta = p_resposta,
         decidido_por = auth.uid(), decidido_em = now() where id = p_id;
end $$;

-- ---------- missão: cada período conta como uma tarefa ----------
-- interno: tudo que a tela da missão precisa (nulo se não há prazo ou matérias)
create or replace function _missao(p_aluno uuid) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  c jsonb; prazo timestamptz; dp date; ini date; mats text[]; n int; qtd int; hoje date := hoje_sp();
  tmin jsonb; det jsonb; tar jsonb; tot int; obt numeric; pend int;
  tmn numeric; pmn numeric; b boolean; p boolean; o boolean; nivel text; valor numeric; ref text;
begin
  select config into c from grupos where aluno = p_aluno and grupo = 'estudos';
  if coalesce(c->>'prazo', '') = '' then return null; end if;
  prazo := (c->>'prazo')::timestamptz;
  dp    := (prazo at time zone 'America/Sao_Paulo')::date;
  ini   := nullif(c->>'inicio', '')::date;
  select coalesce(array_agg(x.id order by x.ord), '{}') into mats
    from jsonb_array_elements_text(coalesce(c->'materias', '[]')) with ordinality x(id, ord)
   where exists (select 1 from materias m where m.aluno = p_aluno and m.id = x.id and m.ativa);
  n := cardinality(mats);
  if n = 0 then return null; end if;
  qtd := least(coalesce(nullif(floor(coalesce((c->>'prova_qtd')::numeric, 0))::int, 0), n), n);
  tmn := coalesce((c->>'treino_min')::numeric, 70);
  pmn := coalesce((c->>'prova_min')::numeric, 80);
  tmin := '{"bronze":70,"prata":80,"ouro":90}'::jsonb || coalesce(c->'tarefas_min', '{}');

  -- por matéria: todos os tópicos concluídos até o prazo; melhor treino (5+ questões) e melhor prova até o prazo
  select jsonb_agg(jsonb_build_object(
           'mid', m.id,
           'bronze', not exists (select 1 from topicos tp where tp.aluno = p_aluno and tp.materia = m.id and tp.ativo
                                   and not exists (select 1 from progresso pr where pr.aluno = p_aluno
                                                     and pr.chave = m.id || ':' || tp.idx and pr.concluido_em <= prazo)),
           'treino', coalesce((select max(te.pct) from tentativas te where te.aluno = p_aluno and te.materia = m.id
                                 and te.tipo = 'treino' and te.total >= 5 and te.criado <= prazo), -1),
           'prova',  coalesce((select max(te.pct) from tentativas te where te.aluno = p_aluno and te.materia = m.id
                                 and te.tipo = 'prova' and te.criado <= prazo), -1)) order by m.ord)
    into det from unnest(mats) with ordinality m(id, ord);

  -- tarefas de casa do período, cada período uma tarefa (mesma seleção da Agenda): validada 1, metade 0,5, o resto 0
  if ini is not null then
    with dias as (select g::date d from generate_series(ini::timestamp, least(dp, hoje)::timestamp, interval '1 day') g),
         tt as (select td.decisao
                  from dias x cross join tarefas t
                 cross join lateral (select y from unnest(t.periodos) y
                                     union
                                     select td0.periodo from tarefa_dia td0
                                      where td0.tarefa = t.id and td0.dia = x.d and td0.aluno = p_aluno) pp(per)
                  left join tarefa_dia td on td.tarefa = t.id and td.dia = x.d and td.aluno = p_aluno and td.periodo = pp.per
                 where td.tarefa is not null
                    or (t.ativa and pp.per = any (t.periodos) and p_aluno = any (responsaveis(t.id, x.d))))
    select count(*), coalesce(sum(case decisao when 'validado' then 1 when 'metade' then 0.5 else 0 end), 0)
      into tot, obt from tt;
    pend := (select count(*) from tarefa_dia where aluno = p_aluno and dia between ini and dp and status = 'feito' and decisao is null)
          + (select count(*) from recursos   where aluno = p_aluno and dia between ini and dp and decisao_final is null);
    tar := jsonb_build_object('total', tot, 'obtido', obt, 'pendentes', pend,
                              'pct', case when tot = 0 then 100 else round(100 * obt / tot, 1) end);
  end if;

  b := not exists (select 1 from jsonb_array_elements(det) e where not (e->>'bronze')::boolean)
       and (ini is null or tot = 0 or obt * 100 >= (tmin->>'bronze')::numeric * tot);
  p := b and not exists (select 1 from jsonb_array_elements(det) e where (e->>'treino')::numeric < tmn)
       and (ini is null or tot = 0 or obt * 100 >= (tmin->>'prata')::numeric * tot);
  o := p and (select count(*) from jsonb_array_elements(det) e where (e->>'prova')::numeric >= pmn) >= qtd
       and (ini is null or tot = 0 or obt * 100 >= (tmin->>'ouro')::numeric * tot);
  nivel := case when o then 'ouro' when p then 'prata' when b then 'bronze' end;
  valor := coalesce((c->'pontos'->>nivel)::numeric, 0);
  ref   := 'meta:' || to_char(prazo at time zone 'America/Sao_Paulo', 'YYYY-MM-DD HH24:MI');

  return jsonb_build_object(
    'prazo', prazo, 'dia_prazo', dp, 'inicio', ini, 'treino_min', tmn, 'prova_min', pmn, 'qtd', qtd,
    'pontos', coalesce(c->'pontos', '{}'), 'tarefas_min', tmin, 'det', det, 'tarefas', tar,
    'bronze', b, 'prata', p, 'ouro', o, 'nivel', nivel, 'valor', valor, 'ref', ref,
    'encerrada', now() > prazo,
    -- a referência antiga ('meta:' + texto do prazo) é a do botão Lançar do app anterior
    'lancada', exists (select 1 from lancamentos where aluno = p_aluno and origem = 'nivel'
                         and origem_ref in (ref, 'meta:' || (c->>'prazo'))),
    -- com tarefas, espera a criança poder marcar o dia do prazo (até o dia seguinte) e os pais decidirem tudo
    'pode_fechar', now() > prazo and (ini is null or (hoje >= dp + 2 and pend = 0)));
end $$;
revoke execute on function _missao(uuid) from public, anon, authenticated;

-- trocar_responsavel não muda: já recusa se houver qualquer marcação da criança no dia (qualquer período).


do $$ declare f text; begin
  foreach f in array array['marcar_tarefa(bigint,date,text,uuid,text)','tarefas_do_dia(uuid,date)','agenda_tarefas(uuid,date,date)',
                           'decidir_tarefa(bigint,date,uuid,text,text,text,text)','abrir_recurso(bigint,date,text,text)',
                           'resolver_recurso(bigint,text,text,text)'] loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
revoke execute on function _periodo_da_tarefa(bigint, text) from public, anon, authenticated;

commit;
