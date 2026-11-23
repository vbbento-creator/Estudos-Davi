-- Treino só vale com 10 questões ou mais (antes, 5). Decidido em 22/11.
-- Muda o mínimo nos dois lugares do banco: os +40 pontos de treino com 70%+ (tg_tentativa_pontos) e o melhor treino
-- da missão, nível prata (_missao). As funções são as mesmas de antes (07 e 24), só com 5 trocado por 10.
-- Em 22/11 nenhum treino tinha de 5 a 9 questões, e toda matéria tinha 10+ questões de treino: nada já feito muda.
-- Só "create or replace"; as permissões continuam as mesmas. Pode rodar de novo. O app novo faz o mesmo na liberação
-- da prova valendo e no plano do dia; o app antigo continua funcionando com esta migração.

create or replace function tg_tentativa_pontos() returns trigger
language plpgsql security definer set search_path = public as $$
declare c jsonb;
begin
  select config into c from grupos where aluno = new.aluno and grupo = 'estudos';
  if new.tipo = 'treino' and new.total >= 10 and new.pct >= coalesce((c ->> 'treino_min')::numeric, 70) then
    perform _credito_estudo(new.aluno, 'pts_treino', 40, 'Treino ' || new.materia || ' ' || new.pct || '%',
                            'treino', new.materia || ':' || hoje_sp());      -- 1 por matéria por dia
  elsif new.tipo = 'prova' and new.pct >= coalesce((c ->> 'prova_min')::numeric, 80) then
    perform _credito_estudo(new.aluno, 'pts_prova', 100, 'Prova ' || new.materia || ' ' || new.pct || '%', 'prova', new.id::text);
  end if;
  if new.tipo in ('treino', 'revisao') then perform _checar_conclusao(new.aluno, new.materia); end if;
  return new;
end $$;

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

  -- por matéria: todos os tópicos concluídos até o prazo; melhor treino (10+ questões) e melhor prova até o prazo
  select jsonb_agg(jsonb_build_object(
           'mid', m.id,
           'bronze', not exists (select 1 from topicos tp where tp.aluno = p_aluno and tp.materia = m.id and tp.ativo
                                   and not exists (select 1 from progresso pr where pr.aluno = p_aluno
                                                     and pr.chave = m.id || ':' || tp.idx and pr.concluido_em <= prazo)),
           'treino', coalesce((select max(te.pct) from tentativas te where te.aluno = p_aluno and te.materia = m.id
                                 and te.tipo = 'treino' and te.total >= 10 and te.criado <= prazo), -1),
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
