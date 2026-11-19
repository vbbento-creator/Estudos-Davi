-- =====================================================
-- Migração 05 — Cofrinho: pontos como moeda única
--   • tudo vira pontos (10 pontos = R$ 1), sem validade
--   • teto semanal de ganho nas tarefas (cadastrar tarefa nova não aumenta o custo)
--   • loja com tela, experiências e dinheiro, com limites por semana/mês
--   • jantar dividido: cada criança paga a sua metade
--   • pontos de estudo caem sozinhos (tópico, treino, prova)
--   • tarefas com período do dia (manhã, tarde, noite) e agenda de tarefas
-- Pré-requisito: migrações 01 a 04. Rodar inteira no SQL Editor (é uma transação).
-- Lançamentos que já existirem são convertidos para pontos (veja o início do script).
-- =====================================================
begin;

-- Lançamentos que já existam (missão, notas, tarefas) são convertidos para pontos:
--   tarefas (pontos) × 2, para acompanhar o novo valor de 20 por tarefa; 1 min de tela = 2 pontos; R$ 1 = 10 pontos.
update lancamentos set valor = valor * 2  where moeda = 'pontos' and grupo = 'casa';
update lancamentos set valor = valor * 2,  moeda = 'pontos' where moeda = 'minutos';
update lancamentos set valor = valor * 10, moeda = 'pontos' where moeda = 'reais';

-- ---------- 1. Moeda única ----------
do $$ declare c record; begin
  for c in select conrelid::regclass::text as t, conname from pg_constraint
            where contype = 'c' and conrelid in ('lancamentos'::regclass, 'grupos'::regclass)
              and pg_get_constraintdef(oid) ilike '%grupo = any%' loop
    execute format('alter table %s drop constraint %I', c.t, c.conname);
  end loop;
  for c in select conname from pg_constraint
            where contype = 'c' and conrelid = 'lancamentos'::regclass
              and pg_get_constraintdef(oid) ilike '%origem = any%' loop
    execute format('alter table lancamentos drop constraint %I', c.conname);
  end loop;
end $$;
alter table lancamentos add constraint lancamentos_grupo_check  check (grupo in ('notas','estudos','casa','loja'));
alter table grupos      add constraint grupos_grupo_check       check (grupo in ('notas','estudos','casa','loja'));
alter table lancamentos add constraint lancamentos_origem_check
  check (origem in ('manual','uso','tarefa','estorno','resgate','nivel','notas','topico','treino','prova'));

alter table grupos add column teto_semana numeric check (teto_semana > 0);   -- máximo ganho por semana (segunda a domingo)

update grupos set moeda = 'pontos', expira = 'nunca', teto = null;
insert into grupos (aluno, grupo, moeda, config)
  select aluno, 'loja', 'pontos', '{}' from grupos where grupo = 'casa' on conflict do nothing;

update grupos set teto_semana = 490 where grupo = 'casa';
update grupos set config = (jsonb_set(config - 'minutos', '{pontos}', '{"bronze":150,"prata":250,"ouro":400}'::jsonb))
                           || '{"pts_topico":30,"pts_treino":40,"pts_prova":100}'
 where grupo = 'estudos';
update grupos set config = config || '{"por_materia":70,"nota_min":8,"bonus":90,"bonus_min":7,"maximo":1000}'
 where grupo = 'notas';

create or replace function criar_grupos(a uuid) returns void
language sql security definer set search_path = public as $$
  insert into grupos (aluno, grupo, moeda, teto_semana, config) values
    (a, 'notas',   'pontos', null, '{"por_materia":70,"nota_min":8,"bonus":90,"bonus_min":7,"maximo":1000}'),
    (a, 'estudos', 'pontos', null, '{"prazo":null,"materias":[],"treino_min":70,"prova_min":80,"prova_qtd":3,"pontos":{"bronze":150,"prata":250,"ouro":400},"pts_topico":30,"pts_treino":40,"pts_prova":100}'),
    (a, 'casa',    'pontos', 490,  '{}'),
    (a, 'loja',    'pontos', null, '{}')
  on conflict do nothing
$$;

-- saldo único: soma de tudo que o aluno ganhou e gastou
create or replace function saldo_total(p_aluno uuid) returns numeric
language plpgsql stable security definer set search_path = public as $$
begin
  if not pode_ver(p_aluno) then raise exception 'Sem acesso'; end if;
  return coalesce((select sum(valor) from lancamentos where aluno = p_aluno and moeda = 'pontos'), 0);
end $$;

-- _lancar: respeita o teto semanal de ganho (estorno reabre espaço)
create or replace function _lancar(p_aluno uuid, p_grupo text, p_valor numeric, p_descricao text,
                                   p_data_ref date, p_origem text, p_origem_ref text) returns bigint
language plpgsql security definer set search_path = public as $$
declare g grupos; v numeric := p_valor; atual numeric; ini date; novo_id bigint;
begin
  select * into g from grupos where aluno = p_aluno and grupo = p_grupo;
  if g is null then raise exception 'Grupo % não existe para este aluno', p_grupo; end if;
  if v > 0 and g.teto_semana is not null then
    ini := date_trunc('week', p_data_ref)::date;
    select coalesce(sum(valor), 0) into atual from lancamentos
     where aluno = p_aluno and grupo = p_grupo and (valor > 0 or origem = 'estorno')
       and data_ref between ini and ini + 6;
    v := least(v, g.teto_semana - atual);
    if v <= 0 then return null; end if;
  end if;
  insert into lancamentos (aluno, grupo, moeda, valor, data_ref, descricao, origem, origem_ref)
       values (p_aluno, p_grupo, g.moeda, v, p_data_ref, p_descricao, p_origem, p_origem_ref)
    returning id into novo_id;
  return novo_id;
end $$;

-- lancar (pais): o saldo para gastar/ajustar para baixo é o saldo único
create or replace function lancar(p_aluno uuid, p_grupo text, p_valor numeric, p_descricao text,
                                  p_data_ref date default null, p_origem text default 'manual',
                                  p_origem_ref text default null) returns bigint
language plpgsql security definer set search_path = public as $$
begin
  if not is_responsavel() then raise exception 'Só pai ou mãe'; end if;
  if not is_aluno(p_aluno) then raise exception 'Aluno inválido'; end if;
  if p_origem not in ('manual','uso','nivel','notas') then raise exception 'Origem inválida'; end if;
  if p_valor < 0 and p_valor + saldo_total(p_aluno) < 0 then raise exception 'Saldo insuficiente'; end if;
  return _lancar(p_aluno, p_grupo, p_valor, p_descricao, coalesce(p_data_ref, hoje_sp()), p_origem, p_origem_ref);
end $$;

-- ---------- 2. Pontos de estudo automáticos ----------
create unique index lancamentos_unico_auto on lancamentos (aluno, origem, origem_ref)
  where origem in ('topico','treino','prova');

create or replace function _credito_estudo(p_aluno uuid, p_cfg text, p_padrao numeric, p_desc text, p_origem text, p_ref text)
returns void language plpgsql security definer set search_path = public as $$
declare v numeric;
begin
  select coalesce((config ->> p_cfg)::numeric, p_padrao) into v from grupos where aluno = p_aluno and grupo = 'estudos';
  if v is null or v <= 0 then return; end if;
  begin
    perform _lancar(p_aluno, 'estudos', v, p_desc, hoje_sp(), p_origem, p_ref);
  exception when unique_violation then null;   -- já creditado: nunca duas vezes
  end;
end $$;
revoke execute on function _credito_estudo(uuid, text, numeric, text, text, text) from public, anon, authenticated;

create or replace function tg_progresso_pontos() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.estudou and new.exercicios and new.chave ~ '^[a-z0-9_]+:[0-9]+$' and is_aluno(new.aluno) then
    perform _credito_estudo(new.aluno, 'pts_topico', 30, 'Tópico concluído: ' || new.chave, 'topico', new.chave);
  end if;
  return new;
end $$;
create trigger progresso_pontos after insert or update on progresso for each row execute function tg_progresso_pontos();

create or replace function tg_tentativa_pontos() returns trigger
language plpgsql security definer set search_path = public as $$
declare c jsonb;
begin
  select config into c from grupos where aluno = new.aluno and grupo = 'estudos';
  if new.tipo = 'treino' and new.total >= 5 and new.pct >= coalesce((c ->> 'treino_min')::numeric, 70) then
    perform _credito_estudo(new.aluno, 'pts_treino', 40, 'Treino ' || new.materia || ' ' || new.pct || '%',
                            'treino', new.materia || ':' || hoje_sp());      -- 1 por matéria por dia
  elsif new.tipo = 'prova' and new.pct >= coalesce((c ->> 'prova_min')::numeric, 80) then
    perform _credito_estudo(new.aluno, 'pts_prova', 100, 'Prova ' || new.materia || ' ' || new.pct || '%', 'prova', new.id::text);
  end if;
  return new;
end $$;
create trigger tentativa_pontos after insert on tentativas for each row execute function tg_tentativa_pontos();

-- ---------- 3. Tarefas: período do dia e agenda ----------
alter table tarefas add column periodo text check (periodo in ('manha','tarde','noite'));

drop function tarefas_do_dia(uuid, date);
create function tarefas_do_dia(p_aluno uuid, p_dia date)
returns table (tarefa bigint, nome text, emoji text, pontos numeric, status text, decisao text,
               valor numeric, marcado_por uuid, decidido_em timestamptz,
               recurso_id bigint, recurso_comentario text, recurso_decisao text, recurso_resposta text,
               pode_marcar boolean, pode_recorrer boolean, periodo text)
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
         t.periodo
    from tarefas t
    left join tarefa_dia td on td.tarefa = t.id and td.dia = p_dia and td.aluno = p_aluno
    left join recursos r on r.tarefa = t.id and r.dia = p_dia and r.aluno = p_aluno
   where td.tarefa is not null
      or (t.ativa and p_aluno = any (responsaveis(t.id, p_dia)))
   order by case t.periodo when 'manha' then 1 when 'tarde' then 2 when 'noite' then 3 else 4 end, t.ordem, t.id;
end $$;

create function agenda_tarefas(p_aluno uuid, p_ini date, p_fim date)
returns table (dia date, tarefa bigint, nome text, emoji text, pontos numeric, periodo text, status text, decisao text)
language plpgsql stable security definer set search_path = public as $$
#variable_conflict use_column
declare hoje date := hoje_sp();
begin
  if not pode_ver(p_aluno) then raise exception 'Sem acesso'; end if;
  if p_fim < p_ini or p_fim - p_ini > 62 then raise exception 'Intervalo inválido'; end if;
  return query
  select d::date, t.id, t.nome, t.emoji, t.pontos, t.periodo,
         coalesce(td.status, case when d::date < hoje - 1 then 'nao_feito' when d::date > hoje then 'futuro' else 'a_fazer' end),
         td.decisao
    from generate_series(p_ini::timestamp, p_fim::timestamp, interval '1 day') d
    cross join tarefas t
    left join tarefa_dia td on td.tarefa = t.id and td.dia = d::date and td.aluno = p_aluno
   where td.tarefa is not null or (t.ativa and p_aluno = any (responsaveis(t.id, d::date)))
   order by d, case t.periodo when 'manha' then 1 when 'tarde' then 2 when 'noite' then 3 else 4 end, t.ordem, t.id;
end $$;

-- ---------- 4. Loja ----------
alter table premios
  add column tipo           text    not null default 'experiencia' check (tipo in ('tela','experiencia','dinheiro')),
  add column unidade        numeric check (unidade > 0),     -- tela: minutos por unidade; dinheiro: reais por unidade
  add column limite         int     check (limite > 0),      -- máximo de unidades no período
  add column limite_periodo text    check (limite_periodo in ('semana','mes')),
  add column limite_grupo   text,                            -- itens com o mesmo grupo dividem o limite (ex.: passeio)
  add column divide         int     not null default 1 check (divide between 1 and 4),  -- quantas crianças pagam (jantar dividido)
  add constraint premios_limite_ok check ((limite is null) = (limite_periodo is null));
comment on column premios.custo is 'Pontos por unidade (e por criança, quando divide > 1)';

create table resgates (
  id         bigint generated always as identity primary key,
  aluno      uuid   not null references perfis(user_id),
  premio     bigint not null references premios(id),
  nome       text   not null,
  quantidade int    not null check (quantidade > 0),
  custo      numeric not null check (custo > 0),
  semana     date   not null,                                  -- segunda-feira do pedido (agrupa a divisão)
  status     text   not null check (status in ('aguardando','pedido','entregue','cancelado')),
  lancamento bigint references lancamentos(id),
  criado     timestamptz not null default now(),
  decidido_em  timestamptz,
  decidido_por uuid
);
create index on resgates (aluno, criado);
alter table resgates enable row level security;
create policy resgates_ler on resgates for select using (pode_ver(aluno));
revoke insert, update, delete on resgates from anon, authenticated;

-- unidades já trocadas no período (compartilhado por limite_grupo)
create or replace function _usado_loja(a uuid, p premios) returns int
language plpgsql stable security definer set search_path = public as $$
declare ini date; fim date; hoje date := hoje_sp();
begin
  if p.limite is null then return 0; end if;
  if p.limite_periodo = 'semana' then ini := date_trunc('week', hoje)::date; fim := ini + 6;
  else ini := date_trunc('month', hoje)::date; fim := (ini + interval '1 month')::date - 1; end if;
  return coalesce((select sum(r.quantidade) from resgates r join premios q on q.id = r.premio
                    where r.aluno = a and r.status <> 'cancelado'
                      and (r.criado at time zone 'America/Sao_Paulo')::date between ini and fim
                      and coalesce(q.limite_grupo, 'p' || q.id) = coalesce(p.limite_grupo, 'p' || p.id)), 0)::int;
end $$;
revoke execute on function _usado_loja(uuid, premios) from public, anon, authenticated;

create function limites_loja(p_aluno uuid) returns table (premio bigint, usado int, limite int)
language plpgsql stable security definer set search_path = public as $$
begin
  if not pode_ver(p_aluno) then raise exception 'Sem acesso'; end if;
  return query select p.id, _usado_loja(p_aluno, p), p.limite from premios p where p.ativo and p.limite is not null;
end $$;

drop function resgatar(bigint);
create function resgatar(p_premio bigint, p_qtd int default 1) returns bigint
language plpgsql security definer set search_path = public as $$
declare p premios; a uuid := auth.uid(); v_custo numeric; v_sem date := date_trunc('week', hoje_sp())::date;
        v_lanc bigint; v_id bigint; v_status text; v_pagos int;
begin
  if not is_aluno(a) then raise exception 'Só a criança resgata'; end if;
  if p_qtd is null or p_qtd < 1 then raise exception 'Quantidade inválida'; end if;
  select * into p from premios where id = p_premio and ativo and (alunos is null or a = any (alunos));
  if p.id is null then raise exception 'Prêmio indisponível'; end if;
  if p.divide > 1 then
    if p_qtd <> 1 then raise exception 'Este item é um por vez'; end if;
    if exists (select 1 from resgates where aluno = a and premio = p.id and semana = v_sem and status <> 'cancelado') then
      raise exception 'Você já pagou a sua parte desta semana';
    end if;
  end if;
  if p.limite is not null and _usado_loja(a, p) + p_qtd > p.limite then
    raise exception 'Limite % atingido nesta %', p.limite, case p.limite_periodo when 'semana' then 'semana' else 'mês' end;
  end if;
  v_custo := p.custo * p_qtd;
  if saldo_total(a) < v_custo then raise exception 'Pontos insuficientes'; end if;
  v_lanc := _lancar(a, 'loja', -v_custo, 'Loja: ' || p.nome || case when p_qtd > 1 then ' × ' || p_qtd else '' end,
                    hoje_sp(), 'resgate', p.id::text);
  v_status := case when p.divide > 1 then 'aguardando' else 'pedido' end;
  insert into resgates (aluno, premio, nome, quantidade, custo, semana, status, lancamento)
       values (a, p.id, p.nome, p_qtd, v_custo, v_sem, v_status, v_lanc) returning id into v_id;
  if p.divide > 1 then
    select count(distinct aluno) into v_pagos from resgates where premio = p.id and semana = v_sem and status = 'aguardando';
    if v_pagos >= p.divide then
      update resgates set status = 'pedido' where premio = p.id and semana = v_sem and status = 'aguardando';
    end if;
  end if;
  return v_id;
end $$;

-- cancelar: a criança cancela o que ainda aguarda a outra metade; pais cancelam qualquer pedido não entregue. Os pontos voltam.
create function cancelar_resgate(p_id bigint) returns void
language plpgsql security definer set search_path = public as $$
declare r resgates; p premios;
begin
  select * into r from resgates where id = p_id for update;
  if r.id is null or r.status not in ('aguardando','pedido') then raise exception 'Este pedido não pode ser cancelado'; end if;
  if not (is_responsavel() or (r.aluno = auth.uid() and r.status = 'aguardando')) then raise exception 'Sem permissão'; end if;
  select * into p from premios where id = r.premio;
  perform _lancar(r.aluno, 'loja', r.custo, 'Estorno: ' || r.nome, hoje_sp(), 'estorno', 'resgate:' || r.id);
  update resgates set status = 'cancelado', decidido_em = now(), decidido_por = auth.uid() where id = r.id;
  if p.divide > 1 then   -- quem já tinha pago volta a aguardar
    update resgates set status = 'aguardando' where premio = r.premio and semana = r.semana and status = 'pedido';
  end if;
end $$;

-- pais marcam como combinado/entregue (no jantar dividido, entrega as duas metades de uma vez)
create function entregar_resgate(p_id bigint) returns void
language plpgsql security definer set search_path = public as $$
declare r resgates; p premios;
begin
  if not is_responsavel() then raise exception 'Só pai ou mãe'; end if;
  select * into r from resgates where id = p_id for update;
  if r.id is null or r.status <> 'pedido' then raise exception 'Este pedido não está esperando'; end if;
  select * into p from premios where id = r.premio;
  update resgates set status = 'entregue', decidido_em = now(), decidido_por = auth.uid()
   where id = r.id or (p.divide > 1 and premio = r.premio and semana = r.semana and status = 'pedido');
end $$;

do $$ declare f text; begin
  foreach f in array array['saldo_total(uuid)','agenda_tarefas(uuid,date,date)','limites_loja(uuid)','resgatar(bigint,int)',
                           'cancelar_resgate(bigint)','entregar_resgate(bigint)','tarefas_do_dia(uuid,date)'] loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
  revoke execute on function public.tg_progresso_pontos() from public, anon, authenticated;
  revoke execute on function public.tg_tentativa_pontos() from public, anon, authenticated;
end $$;

-- ---------- 5. Dados iniciais ----------
update tarefas set pontos = 20 where pontos = 10;     -- 24,5 tarefas por semana × 20 = 490
update materias set emoji = '🗣️' where emoji = '🇬🇧';   -- bandeira não aparece no Windows (vira "GB")

insert into premios (nome, emoji, custo, tipo, unidade, limite, limite_periodo, limite_grupo, divide)
select * from (values
  ('Tempo de tela (30 min)',        '🎮', 60::numeric,  'tela',        30::numeric, 28, 'semana', 'tela',     1),
  ('Sorvete',                       '🍦', 95,           'experiencia', null,        2,  'semana', 'sorvete',  1),
  ('Ir ao cinema',                  '🎬', 400,          'experiencia', null,        1,  'semana', 'passeio',  1),
  ('Jantar fora (a sua metade)',    '🍽️', 300,          'experiencia', null,        1,  'semana', 'passeio',  2),
  ('Escolher o filme da noite',     '🍿', 100,          'experiencia', null,        null::int, null,  null,   1),
  ('Dinheiro (R$ 10)',              '💰', 100,          'dinheiro',    10,          10, 'mes',    'dinheiro', 1)
) v(nome, emoji, custo, tipo, unidade, limite, limite_periodo, limite_grupo, divide)
where not exists (select 1 from premios);

commit;
