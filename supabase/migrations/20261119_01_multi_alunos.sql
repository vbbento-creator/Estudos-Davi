-- =====================================================
-- Migração 01 — vários alunos, tarefas da casa, livro-razão de recompensas
-- Pré-requisito: banco.sql (v1) já aplicado. Rodar inteiro no SQL Editor.
-- Tudo dentro de uma transação: se algo falhar, nada muda.
-- Depois desta, rodar 20261119_02_seed_davi.sql (matérias/tópicos/cronograma atuais).
-- =====================================================
begin;

-- ---------- Pessoas ----------
-- Davi  = d5c2215c-797c-435b-859b-09be1fe3efbf (perfil "Johann")
-- Juju  = 014341f0-99f3-4e14-b21d-6b4efc9bafbd
insert into perfis (user_id, papel, nome)
values ('014341f0-99f3-4e14-b21d-6b4efc9bafbd', 'aluno', 'Juju')
on conflict (user_id) do nothing;

-- ---------- Funções básicas ----------
create or replace function hoje_sp() returns date
language sql stable as $$ select (now() at time zone 'America/Sao_Paulo')::date $$;

create or replace function is_aluno(a uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from perfis where user_id = a and papel = 'aluno')
$$;

-- Pais veem todos; cada criança só a si mesma
create or replace function pode_ver(a uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select is_responsavel() or (a = auth.uid() and is_familia())
$$;

-- ---------- Matérias por aluno (catálogo editável) ----------
create table materias (
  aluno uuid not null references perfis(user_id) on delete cascade,
  id    text not null check (id ~ '^[a-z0-9_]+$'),
  nome  text not null,
  emoji text not null default '📘',
  cor   text not null default '#3b82f6',
  prova date,
  ordem int  not null default 0,
  ativa boolean not null default true,
  primary key (aluno, id)
);

-- idx nunca muda: o progresso usa a chave "materia:idx". Tópico removido = ativo false.
create table topicos (
  aluno   uuid not null,
  materia text not null,
  idx     int  not null check (idx >= 0),
  nome    text not null,
  ativo   boolean not null default true,
  primary key (aluno, materia, idx),
  foreign key (aluno, materia) references materias(aluno, id) on delete cascade
);

create table cronograma (
  aluno  uuid not null references perfis(user_id) on delete cascade,
  dia    date not null,
  titulo text not null,
  itens  jsonb not null default '[]',
  primary key (aluno, dia)
);

-- ---------- Dono nas tabelas existentes (dados atuais = Davi) ----------
alter table progresso  add column aluno uuid references perfis(user_id) on delete cascade;
alter table tentativas add column aluno uuid references perfis(user_id) on delete cascade;
alter table liberacoes add column aluno uuid references perfis(user_id) on delete cascade;
alter table notas_p2   add column aluno uuid references perfis(user_id) on delete cascade;
alter table questoes   add column aluno uuid references perfis(user_id) on delete cascade;

update progresso  set aluno = 'd5c2215c-797c-435b-859b-09be1fe3efbf' where aluno is null;
update tentativas set aluno = 'd5c2215c-797c-435b-859b-09be1fe3efbf' where aluno is null;
update liberacoes set aluno = 'd5c2215c-797c-435b-859b-09be1fe3efbf' where aluno is null;
update notas_p2   set aluno = 'd5c2215c-797c-435b-859b-09be1fe3efbf' where aluno is null;
update questoes   set aluno = 'd5c2215c-797c-435b-859b-09be1fe3efbf' where aluno is null;

-- default auth.uid(): quem grava como criança não precisa mandar o campo
alter table progresso  alter column aluno set not null, alter column aluno set default auth.uid();
alter table tentativas alter column aluno set not null, alter column aluno set default auth.uid();
alter table liberacoes alter column aluno set not null;
alter table notas_p2   alter column aluno set not null;
alter table questoes   alter column aluno set not null;

alter table progresso  drop constraint progresso_pkey,  add primary key (aluno, chave);
alter table liberacoes drop constraint liberacoes_pkey, add primary key (aluno, materia);
alter table notas_p2   drop constraint notas_p2_pkey,   add primary key (aluno, materia);
create index on questoes (aluno, materia, tipo);
create index on tentativas (aluno, materia);

-- ---------- Grupos de recompensa (por aluno) ----------
-- notas → R$, estudos → minutos de tela, casa → pontos (loja). Tudo editável pelos pais.
-- teto = máximo ganho por janela (semana, se expira semanal). Notas: limite de R$ 100 por rodada fica em config.maximo.
create table grupos (
  aluno  uuid not null references perfis(user_id) on delete cascade,
  grupo  text not null check (grupo in ('notas','estudos','casa')),
  moeda  text not null check (moeda in ('reais','minutos','pontos')),
  teto   numeric check (teto > 0),
  expira text not null default 'nunca' check (expira in ('nunca','semanal')),  -- semanal: zera domingo 23h59
  config jsonb not null default '{}',
  primary key (aluno, grupo)
);

create or replace function criar_grupos(a uuid) returns void
language sql security definer set search_path = public as $$
  insert into grupos (aluno, grupo, moeda, teto, expira, config) values
    (a, 'notas',   'reais',   null, 'nunca',   '{"por_materia":7,"nota_min":8,"bonus":9,"bonus_min":7,"maximo":100}'),
    (a, 'estudos', 'minutos', 840,  'semanal', '{"prazo":null,"materias":[],"treino_min":70,"prova_min":80,"prova_qtd":3,"minutos":{"bronze":300,"prata":540,"ouro":840}}'),
    (a, 'casa',    'pontos',  null, 'nunca',   '{}')
  on conflict do nothing
$$;
revoke execute on function criar_grupos(uuid) from public, anon, authenticated;

create or replace function tg_perfil_aluno() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.papel = 'aluno' then perform criar_grupos(new.user_id); end if;
  return new;
end $$;
create trigger perfil_aluno after insert on perfis for each row execute function tg_perfil_aluno();

select criar_grupos(user_id) from perfis where papel = 'aluno';
-- Meta atual do Davi (P2): prazo e matérias da Missão GTA
update grupos set config = config || '{"prazo":"2026-11-19T22:00:00-03:00","materias":["portugues","ingles","fisica","biologia"]}'
 where aluno = 'd5c2215c-797c-435b-859b-09be1fe3efbf' and grupo = 'estudos';

-- ---------- Livro-razão ----------
-- Saldo = soma dos lançamentos. Nunca se edita nem apaga: correção = lançamento de estorno.
create table lancamentos (
  id         bigint generated always as identity primary key,
  aluno      uuid not null references perfis(user_id),
  grupo      text not null check (grupo in ('notas','estudos','casa')),
  moeda      text not null check (moeda in ('reais','minutos','pontos')),
  valor      numeric not null check (valor <> 0),
  data_ref   date not null default hoje_sp(),
  descricao  text not null,
  origem     text not null default 'manual'
             check (origem in ('manual','uso','tarefa','estorno','resgate','nivel','notas')),
  origem_ref text,
  criado_por uuid default auth.uid(),
  criado     timestamptz not null default now()
);
create index on lancamentos (aluno, grupo, data_ref);
-- impede lançar duas vezes o mesmo nível / a mesma rodada de notas
create unique index lancamentos_unico on lancamentos (aluno, origem, origem_ref)
  where origem in ('nivel','notas');

create or replace function inicio_janela(a uuid, g text, d date) returns date
language sql stable security definer set search_path = public as $$
  select case when (select expira from grupos where aluno = a and grupo = g) = 'semanal'
              then date_trunc('week', d)::date   -- segunda-feira
              else '-infinity'::date end
$$;

-- saldo do grupo na janela que contém o dia d (hoje, por padrão)
create or replace function saldo(p_aluno uuid, p_grupo text, p_dia date default null) returns numeric
language plpgsql stable security definer set search_path = public as $$
declare d date := coalesce(p_dia, hoje_sp()); v numeric;
begin
  if not pode_ver(p_aluno) then raise exception 'Sem acesso'; end if;
  select coalesce(sum(l.valor), 0) into v
    from lancamentos l join grupos g on g.aluno = l.aluno and g.grupo = l.grupo and g.moeda = l.moeda
   where l.aluno = p_aluno and l.grupo = p_grupo
     and l.data_ref >= inicio_janela(p_aluno, p_grupo, d)
     and l.data_ref <= case when g.expira = 'semanal' then (date_trunc('week', d)::date + 6) else 'infinity'::date end;
  return v;
end $$;

-- interno: grava lançamento respeitando o teto do grupo; devolve o id (null se o teto zerou o crédito)
create or replace function _lancar(p_aluno uuid, p_grupo text, p_valor numeric, p_descricao text,
                                   p_data_ref date, p_origem text, p_origem_ref text) returns bigint
language plpgsql security definer set search_path = public as $$
declare g grupos; v numeric := p_valor; atual numeric; novo_id bigint;
begin
  select * into g from grupos where aluno = p_aluno and grupo = p_grupo;
  if g is null then raise exception 'Grupo % não existe para este aluno', p_grupo; end if;
  if v > 0 and g.teto is not null then
    -- teto = máximo GANHO na janela (gastar não reabre espaço)
    select coalesce(sum(valor), 0) into atual from lancamentos
     where aluno = p_aluno and grupo = p_grupo and moeda = g.moeda and (valor > 0 or origem = 'estorno')
       and data_ref >= inicio_janela(p_aluno, p_grupo, p_data_ref)
       and data_ref <= case when g.expira = 'semanal' then date_trunc('week', p_data_ref)::date + 6 else 'infinity'::date end;
    v := least(v, g.teto - atual);
    if v <= 0 then return null; end if;
  end if;
  insert into lancamentos (aluno, grupo, moeda, valor, data_ref, descricao, origem, origem_ref)
       values (p_aluno, p_grupo, g.moeda, v, p_data_ref, p_descricao, p_origem, p_origem_ref)
    returning id into novo_id;
  return novo_id;
end $$;
revoke execute on function _lancar(uuid, text, numeric, text, date, text, text) from public, anon, authenticated;

-- pais: crédito/débito manual, uso de tempo de tela, nível conquistado, notas
create or replace function lancar(p_aluno uuid, p_grupo text, p_valor numeric, p_descricao text,
                                  p_data_ref date default null, p_origem text default 'manual',
                                  p_origem_ref text default null) returns bigint
language plpgsql security definer set search_path = public as $$
begin
  if not is_responsavel() then raise exception 'Só pai ou mãe'; end if;
  if not is_aluno(p_aluno) then raise exception 'Aluno inválido'; end if;
  if p_origem not in ('manual','uso','nivel','notas') then raise exception 'Origem inválida'; end if;
  if p_valor < 0 and p_valor + saldo(p_aluno, p_grupo, coalesce(p_data_ref, hoje_sp())) < 0 then
    raise exception 'Saldo insuficiente';
  end if;
  return _lancar(p_aluno, p_grupo, p_valor, p_descricao, coalesce(p_data_ref, hoje_sp()), p_origem, p_origem_ref);
end $$;

-- ---------- Tarefas da casa ----------
create table tarefas (
  id     bigint generated always as identity primary key,
  nome   text not null,
  emoji  text not null default '✅',
  pontos numeric not null default 0 check (pontos >= 0),
  modo   text not null default 'todos' check (modo in ('todos','revezamento')),
  alunos uuid[] not null check (cardinality(alunos) >= 1),   -- no revezamento, a ordem define a vez
  base   date not null default hoje_sp(),                    -- revezamento: alunos[1] é o responsável neste dia
  ordem  int  not null default 0,
  ativa  boolean not null default true,
  criado timestamptz not null default now()
);

-- troca manual do responsável de um dia (não desloca o revezamento dos outros dias)
create table trocas (
  tarefa bigint not null references tarefas(id),
  dia    date   not null,
  aluno  uuid   not null references perfis(user_id),
  por    uuid default auth.uid(),
  primary key (tarefa, dia)
);

-- dias pausados (viagem etc.): nada é cobrado e o revezamento não anda
create table pausas (
  id     bigint generated always as identity primary key,
  inicio date not null,
  fim    date not null check (fim >= inicio),
  motivo text,
  criado_por uuid default auth.uid()
);

-- só existe linha quando alguém marcou; sem linha após o prazo = "não feito"
create table tarefa_dia (
  tarefa      bigint not null references tarefas(id),
  dia         date   not null,
  aluno       uuid   not null references perfis(user_id),
  status      text   not null check (status in ('feito','nao_feito')),
  valor       numeric not null,                 -- pontos da tarefa no momento da marcação
  marcado_por uuid   not null,
  marcado_em  timestamptz not null default now(),
  decisao     text check (decisao in ('validado','rejeitado')),
  decidido_por uuid,
  decidido_em timestamptz,
  lancamento  bigint references lancamentos(id),  -- crédito ativo, se houver
  primary key (tarefa, dia, aluno)
);

create table recursos (
  id          bigint generated always as identity primary key,
  tarefa      bigint not null,
  dia         date   not null,
  aluno       uuid   not null,
  comentario  text   not null check (length(trim(comentario)) > 0),
  criado      timestamptz not null default now(),
  resposta    text,
  decisao_final text check (decisao_final in ('validado','rejeitado')),
  decidido_por uuid,
  decidido_em timestamptz,
  foreign key (tarefa, dia, aluno) references tarefa_dia,
  unique (tarefa, dia, aluno)                     -- um recurso por tarefa/dia
);

create table premios (
  id     bigint generated always as identity primary key,
  nome   text not null,
  emoji  text not null default '🎁',
  custo  numeric not null check (custo > 0),
  alunos uuid[],                                   -- null = para todos
  ativo  boolean not null default true
);

create or replace function dia_pausado(d date) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from pausas where d between inicio and fim)
$$;

-- quem faz a tarefa no dia d (contagem absoluta de dias desde a base, pulando dias pausados)
create or replace function responsaveis(p_tarefa bigint, d date) returns uuid[]
language plpgsql stable security definer set search_path = public as $$
declare t tarefas; n int; k int; tr uuid;
begin
  select * into t from tarefas where id = p_tarefa;
  if t is null or d < t.base or dia_pausado(d) then return '{}'; end if;
  if t.modo = 'todos' then return t.alunos; end if;
  select aluno into tr from trocas where tarefa = p_tarefa and dia = d;
  if tr is not null then return array[tr]; end if;
  n := cardinality(t.alunos);
  k := (d - t.base) - (select count(distinct g) from pausas p,
         generate_series(greatest(p.inicio, t.base), least(p.fim, d - 1), interval '1 day') g)::int;
  return array[t.alunos[(k % n) + 1]];
end $$;

-- lista do dia para um aluno, com o status efetivo
create or replace function tarefas_do_dia(p_aluno uuid, p_dia date)
returns table (tarefa bigint, nome text, emoji text, pontos numeric, status text, decisao text,
               valor numeric, marcado_por uuid, decidido_em timestamptz,
               recurso_id bigint, recurso_comentario text, recurso_decisao text, recurso_resposta text,
               pode_marcar boolean, pode_recorrer boolean)
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
            and now() <= td.decidido_em + interval '5 days')
    from tarefas t
    left join tarefa_dia td on td.tarefa = t.id and td.dia = p_dia and td.aluno = p_aluno
    left join recursos r on r.tarefa = t.id and r.dia = p_dia and r.aluno = p_aluno
   where td.tarefa is not null
      or (t.ativa and p_aluno = any (responsaveis(t.id, p_dia)))
   order by t.ordem, t.id;
end $$;

-- marcar feito / não feito (p_status null = desmarcar). Criança: hoje ou ontem. Pais: qualquer dia passado.
create or replace function marcar_tarefa(p_tarefa bigint, p_dia date, p_status text, p_aluno uuid default null)
returns void language plpgsql security definer set search_path = public as $$
declare a uuid := coalesce(p_aluno, auth.uid()); t tarefas; td tarefa_dia;
begin
  if not pode_ver(a) or not is_aluno(a) then raise exception 'Sem acesso'; end if;
  if p_status is not null and p_status not in ('feito','nao_feito') then raise exception 'Status inválido'; end if;
  select * into t from tarefas where id = p_tarefa;
  if t is null or not t.ativa then raise exception 'Tarefa inexistente ou desativada'; end if;
  if p_dia > hoje_sp() then raise exception 'Esse dia ainda não chegou'; end if;
  if not is_responsavel() and p_dia < hoje_sp() - 1 then raise exception 'O prazo para marcar essa tarefa acabou'; end if;
  select * into td from tarefa_dia where tarefa = p_tarefa and dia = p_dia and aluno = a;
  if td.decisao is not null then raise exception 'Tarefa já decidida: só muda por recurso'; end if;
  if td.tarefa is null and not (a = any (responsaveis(p_tarefa, p_dia))) then
    raise exception 'Essa tarefa não é sua neste dia';
  end if;
  if p_status is null then
    delete from tarefa_dia where tarefa = p_tarefa and dia = p_dia and aluno = a;
  else
    insert into tarefa_dia (tarefa, dia, aluno, status, valor, marcado_por)
         values (p_tarefa, p_dia, a, p_status, t.pontos, auth.uid())
    on conflict (tarefa, dia, aluno) do update
       set status = excluded.status, valor = excluded.valor,
           marcado_por = excluded.marcado_por, marcado_em = now();
  end if;
end $$;

-- interno: aplica a decisão e acerta o livro-razão (crédito na data da tarefa)
create or replace function _aplicar_decisao(p_tarefa bigint, p_dia date, p_aluno uuid, p_decisao text)
returns void language plpgsql security definer set search_path = public as $$
declare td tarefa_dia; nome_t text; lid bigint; v numeric;
begin
  select * into td from tarefa_dia where tarefa = p_tarefa and dia = p_dia and aluno = p_aluno for update;
  select nome into nome_t from tarefas where id = p_tarefa;
  if p_decisao = 'validado' and td.lancamento is null and td.valor > 0 then
    lid := _lancar(p_aluno, 'casa', td.valor, 'Tarefa: ' || nome_t, p_dia, 'tarefa', p_tarefa || ':' || p_dia);
  elsif p_decisao = 'rejeitado' and td.lancamento is not null then
    select valor into v from lancamentos where id = td.lancamento;
    perform _lancar(p_aluno, 'casa', -v, 'Estorno: ' || nome_t, p_dia, 'estorno', p_tarefa || ':' || p_dia);
    lid := null;
  else
    lid := td.lancamento;
  end if;
  update tarefa_dia set decisao = p_decisao, decidido_por = auth.uid(),
         decidido_em = coalesce(decidido_em, now()), lancamento = lid
   where tarefa = p_tarefa and dia = p_dia and aluno = p_aluno;
end $$;
revoke execute on function _aplicar_decisao(bigint, date, uuid, text) from public, anon, authenticated;

-- pais validam/rejeitam uma tarefa marcada como feita (sem prazo). Depois disso, só por recurso.
create or replace function decidir_tarefa(p_tarefa bigint, p_dia date, p_aluno uuid, p_decisao text)
returns void language plpgsql security definer set search_path = public as $$
declare td tarefa_dia;
begin
  if not is_responsavel() then raise exception 'Só pai ou mãe'; end if;
  if p_decisao not in ('validado','rejeitado') then raise exception 'Decisão inválida'; end if;
  select * into td from tarefa_dia where tarefa = p_tarefa and dia = p_dia and aluno = p_aluno;
  if td.tarefa is null or td.status <> 'feito' then raise exception 'Só se valida tarefa marcada como feita'; end if;
  if td.decisao is not null then raise exception 'Já decidida: só muda por recurso'; end if;
  perform _aplicar_decisao(p_tarefa, p_dia, p_aluno, p_decisao);
end $$;

-- criança contesta até 5 dias corridos após a decisão inicial
create or replace function abrir_recurso(p_tarefa bigint, p_dia date, p_comentario text)
returns void language plpgsql security definer set search_path = public as $$
declare td tarefa_dia;
begin
  select * into td from tarefa_dia where tarefa = p_tarefa and dia = p_dia and aluno = auth.uid();
  if td.tarefa is null or td.decisao is null then raise exception 'Não há decisão para contestar'; end if;
  if now() > td.decidido_em + interval '5 days' then raise exception 'Prazo de recurso (5 dias) encerrado'; end if;
  insert into recursos (tarefa, dia, aluno, comentario) values (p_tarefa, p_dia, auth.uid(), p_comentario);
end $$;

-- decisão final dos pais
create or replace function resolver_recurso(p_id bigint, p_decisao text, p_resposta text default null)
returns void language plpgsql security definer set search_path = public as $$
declare r recursos;
begin
  if not is_responsavel() then raise exception 'Só pai ou mãe'; end if;
  if p_decisao not in ('validado','rejeitado') then raise exception 'Decisão inválida'; end if;
  select * into r from recursos where id = p_id for update;
  if r.id is null or r.decisao_final is not null then raise exception 'Recurso inexistente ou já resolvido'; end if;
  perform _aplicar_decisao(r.tarefa, r.dia, r.aluno, p_decisao);
  update recursos set decisao_final = p_decisao, resposta = p_resposta,
         decidido_por = auth.uid(), decidido_em = now() where id = p_id;
end $$;

-- criança troca pontos por prêmio
create or replace function resgatar(p_premio bigint) returns void
language plpgsql security definer set search_path = public as $$
declare p premios; a uuid := auth.uid();
begin
  if not is_aluno(a) then raise exception 'Só a criança resgata'; end if;
  select * into p from premios where id = p_premio and ativo and (alunos is null or a = any (alunos));
  if p.id is null then raise exception 'Prêmio indisponível'; end if;
  if saldo(a, 'casa') < p.custo then raise exception 'Pontos insuficientes'; end if;
  perform _lancar(a, 'casa', -p.custo, 'Prêmio: ' || p.nome, hoje_sp(), 'resgate', p.id::text);
end $$;

-- ---------- Prova valendo, agora por aluno ----------
create or replace function prova_liberada(a uuid, m text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from liberacoes where aluno = a and materia = m and ate > now())
$$;

create or replace function corrigir_prova(p_materia text, p_respostas jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_total int; v_acertos int; v_det jsonb; v_pct numeric; a uuid := auth.uid();
begin
  if not is_aluno(a) then raise exception 'Sem acesso'; end if;
  if not exists (select 1 from liberacoes where aluno = a and materia = p_materia and ate > now() - interval '2 minutes') then
    raise exception 'Prova não liberada ou tempo esgotado';
  end if;
  select count(*),
         count(*) filter (where (p_respostas ->> q.id)::int = g.correta),
         jsonb_agg(jsonb_build_object('id', q.id, 'enunciado', q.enunciado, 'alternativas', q.alternativas,
                   'resposta', (p_respostas ->> q.id)::int, 'correta', g.correta, 'explicacao', g.explicacao))
    into v_total, v_acertos, v_det
    from questoes q join gabarito g on g.questao_id = q.id
   where q.aluno = a and q.materia = p_materia and q.tipo = 'prova';
  if v_total = 0 then raise exception 'Sem questões de prova para esta matéria'; end if;
  v_pct := round(100.0 * v_acertos / v_total, 1);
  insert into tentativas (aluno, materia, tipo, acertos, total, pct, detalhes)
       values (a, p_materia, 'prova', v_acertos, v_total, v_pct, v_det);
  update liberacoes set ate = now() where aluno = a and materia = p_materia;
  return jsonb_build_object('acertos', v_acertos, 'total', v_total, 'pct', v_pct, 'detalhes', v_det);
end $$;

-- ---------- Regras de acesso (RLS) ----------
drop policy progresso_tudo   on progresso;
drop policy questoes_ler     on questoes;
drop policy gabarito_ler     on gabarito;
drop policy liberacoes_ler   on liberacoes;
drop policy tentativas_ler   on tentativas;
drop policy tentativas_treino on tentativas;
drop policy notas_ler        on notas_p2;
drop function prova_liberada(text);

create policy progresso_tudo on progresso for all
  using (pode_ver(aluno)) with check (pode_ver(aluno) and is_aluno(aluno));

create policy questoes_ler on questoes for select
  using (is_responsavel() or (aluno = auth.uid() and (tipo = 'treino' or prova_liberada(aluno, materia))));
create policy gabarito_ler on gabarito for select
  using (is_responsavel() or exists (select 1 from questoes q
          where q.id = questao_id and q.tipo = 'treino' and q.aluno = auth.uid()));

create policy liberacoes_ler on liberacoes for select using (pode_ver(aluno));
create policy tentativas_ler on tentativas for select using (pode_ver(aluno));
create policy tentativas_treino on tentativas for insert
  with check (aluno = auth.uid() and is_aluno(aluno) and tipo = 'treino');
create policy notas_ler on notas_p2 for select using (pode_ver(aluno));

alter table materias    enable row level security;
alter table topicos     enable row level security;
alter table cronograma  enable row level security;
alter table grupos      enable row level security;
alter table lancamentos enable row level security;
alter table tarefas     enable row level security;
alter table trocas      enable row level security;
alter table pausas      enable row level security;
alter table tarefa_dia  enable row level security;
alter table recursos    enable row level security;
alter table premios     enable row level security;

create policy materias_ler   on materias   for select using (pode_ver(aluno));
create policy materias_admin on materias   for all using (is_responsavel()) with check (is_responsavel());
create policy topicos_ler    on topicos    for select using (pode_ver(aluno));
create policy topicos_admin  on topicos    for all using (is_responsavel()) with check (is_responsavel());
create policy crono_ler      on cronograma for select using (pode_ver(aluno));
create policy crono_admin    on cronograma for all using (is_responsavel()) with check (is_responsavel());
create policy grupos_ler     on grupos     for select using (pode_ver(aluno));
create policy grupos_admin   on grupos     for update using (is_responsavel()) with check (is_responsavel());
create policy lanc_ler       on lancamentos for select using (pode_ver(aluno));      -- escrita só pelas funções
create policy tarefas_ler    on tarefas    for select using (is_familia());
create policy tarefas_admin  on tarefas    for all using (is_responsavel()) with check (is_responsavel());
create policy trocas_ler     on trocas     for select using (is_familia());
create policy trocas_admin   on trocas     for all using (is_responsavel()) with check (is_responsavel());
create policy pausas_ler     on pausas     for select using (is_familia());
create policy pausas_admin   on pausas     for all using (is_responsavel()) with check (is_responsavel());
create policy td_ler         on tarefa_dia for select using (pode_ver(aluno));       -- escrita só pelas funções
create policy recursos_ler   on recursos   for select using (pode_ver(aluno));       -- escrita só pelas funções
create policy premios_ler    on premios    for select using (is_familia());
create policy premios_admin  on premios    for all using (is_responsavel()) with check (is_responsavel());

-- tarefas e prêmios: desativar, nunca excluir
revoke delete on tarefas, premios, lancamentos, tarefa_dia, recursos from anon, authenticated;
revoke insert, update on lancamentos, tarefa_dia, recursos from anon, authenticated;

grant execute on function saldo(uuid, text, date), lancar(uuid, text, numeric, text, date, text, text),
  responsaveis(bigint, date), tarefas_do_dia(uuid, date), marcar_tarefa(bigint, date, text, uuid),
  decidir_tarefa(bigint, date, uuid, text), abrir_recurso(bigint, date, text),
  resolver_recurso(bigint, text, text), resgatar(bigint), prova_liberada(uuid, text),
  corrigir_prova(text, jsonb), hoje_sp(), dia_pausado(date) to authenticated;
revoke execute on function saldo(uuid, text, date), lancar(uuid, text, numeric, text, date, text, text),
  tarefas_do_dia(uuid, date), marcar_tarefa(bigint, date, text, uuid), decidir_tarefa(bigint, date, uuid, text),
  abrir_recurso(bigint, date, text), resolver_recurso(bigint, text, text), resgatar(bigint),
  corrigir_prova(text, jsonb) from anon;

-- ---------- Tarefa inicial: Kika (revezamento; 18/11/2026 = Juju) ----------
-- pontos de exemplo: editar no painel
insert into tarefas (nome, emoji, pontos, modo, alunos, base, ordem) values
  ('Cuidar da Kika (comida, água e passeio)', '🐶', 10, 'revezamento',
   array['014341f0-99f3-4e14-b21d-6b4efc9bafbd','d5c2215c-797c-435b-859b-09be1fe3efbf']::uuid[], '2026-11-18', 0);

-- uso_gta fica obsoleto (vazio); o uso de tempo de tela vira lançamento negativo no grupo "estudos".

commit;
