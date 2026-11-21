\set ON_ERROR_STOP 1
\pset format unaligned
\pset tuples_only on
-- Testes da migração 08 (trocar o responsável pela tarefa). Rodar num banco novo com as migrações 01 a 08 (cria os próprios dados).
create schema if not exists t; grant usage on schema t to authenticated;
create or replace function t.erro(q text) returns text language plpgsql as $$
begin execute q; return 'OK (sem erro)'; exception when others then return 'ERRO: ' || sqlerrm; end $$;
create or replace function t.como(u text) returns void language sql as $$ select set_config('request.jwt.claim.sub', u, false) $$;
grant execute on all functions in schema t to authenticated;
create temp table ids as select 'd5c2215c-797c-435b-859b-09be1fe3efbf'::uuid johann, '014341f0-99f3-4e14-b21d-6b4efc9bafbd'::uuid juju,
  '78768c03-68d4-420f-ba5d-c7fe46434042'::uuid pai, hoje_sp() h;
grant select on ids to authenticated;
-- R = revezamento Johann, Juju (começou há 10 dias: hoje = Juju, pois 10 é par → Johann; ver rótulos)
insert into tarefas (nome, pontos, modo, alunos, base) select 'R', 20, 'revezamento', array[johann, juju], h - 10 from ids;
-- T = "todos" só do Johann; A = "todos" dos dois
insert into tarefas (nome, pontos, modo, alunos, base) select 'T', 20, 'todos', array[johann], h - 10 from ids;
insert into tarefas (nome, pontos, modo, alunos, base) select 'A', 20, 'todos', array[johann, juju], h - 10 from ids;
create temp table tk as select (select id from tarefas where nome = 'R') r, (select id from tarefas where nome = 'T') tt, (select id from tarefas where nome = 'A') a;
grant select on tk to authenticated;
create function pg_temp.quem(tarefa bigint, d date) returns text language sql as $$
  select coalesce(string_agg(p.nome, '+' order by p.nome), '-') from unnest(responsaveis(tarefa, d)) u join perfis p on p.user_id = u $$;
grant execute on function pg_temp.quem(bigint, date) to authenticated;
set role authenticated;
select t.como(pai::text) from ids;

\echo '--- 1. Revezamento antes de trocar (esperado: hoje Johann, amanhã Juju, depois Johann)'
select 'R', pg_temp.quem(r, h), pg_temp.quem(r, h + 1), pg_temp.quem(r, h + 2) from tk, ids;

\echo '--- 2. Revezamento, só aquele dia: amanhã Johann no lugar da Juju (esperado: Johann, Johann, Johann; grava em trocas)'
select 'troca dia', t.erro(format('select trocar_responsavel(%s, %L, %L, %L, false)', r, h + 1, juju, johann)) from tk, ids;
select 'R', pg_temp.quem(r, h), pg_temp.quem(r, h + 1), pg_temp.quem(r, h + 2) from tk, ids;
select 'linhas em trocas (1)', count(*) from trocas;

\echo '--- 3. Revezamento, daqui em diante: hoje Juju no lugar do Johann, recomeça por ela (esperado: Juju, Johann (troca de 1 dia continua), Juju, Johann)'
select 'recomeço', t.erro(format('select trocar_responsavel(%s, %L, %L, %L, true)', r, h, johann, juju)) from tk, ids;
select 'R', pg_temp.quem(r, h), pg_temp.quem(r, h + 1), pg_temp.quem(r, h + 2), pg_temp.quem(r, h + 3) from tk, ids;
select 'R ontem continua (esperado: Juju, pois h-1 é ímpar a partir da base)', pg_temp.quem(r, h - 1) from tk, ids;

\echo '--- 4. Recomeço com pausa no meio: pausa em h+2 (esperado: h+2 ninguém, h+3 Juju, h+4 Johann)'
reset role; insert into pausas (inicio, fim) select h + 2, h + 2 from ids; set role authenticated; select t.como(pai::text) from ids;
select 'R', pg_temp.quem(r, h + 2), pg_temp.quem(r, h + 3), pg_temp.quem(r, h + 4) from tk, ids;
reset role; delete from pausas; set role authenticated; select t.como(pai::text) from ids;

\echo '--- 5. "Todos", só aquele dia: hoje a Juju faz no lugar do Johann (esperado: hoje Juju, amanhã Johann)'
select 'troca T', t.erro(format('select trocar_responsavel(%s, %L, %L, %L, false)', tt, h, johann, juju)) from tk, ids;
select 'T', pg_temp.quem(tt, h), pg_temp.quem(tt, h + 1) from tk, ids;

\echo '--- 6. "Todos", daqui em diante a partir de amanhã (esperado: hoje Juju, amanhã Juju, depois Juju, ontem Johann)'
select 'troca T em diante', t.erro(format('select trocar_responsavel(%s, %L, %L, %L, true)', tt, h + 1, johann, juju)) from tk, ids;
select 'T', pg_temp.quem(tt, h), pg_temp.quem(tt, h + 1), pg_temp.quem(tt, h + 5), pg_temp.quem(tt, h - 1) from tk, ids;

\echo '--- 7. A Juju marca a tarefa que passou a ser dela (esperado: OK)'
select t.como(juju::text) from ids;
select 'Juju marca T hoje', t.erro(format('select marcar_tarefa(%s, %L, %L)', tt, h, 'feito')) from tk, ids;
select t.como(johann::text) from ids;
select 'Johann marca T hoje: ERRO', t.erro(format('select marcar_tarefa(%s, %L, %L)', tt, h, 'feito')) from tk, ids;
select t.como(pai::text) from ids;

\echo '--- 8. Recusas'
select 'para quem já faz (A, Juju já faz): ERRO', t.erro(format('select trocar_responsavel(%s, %L, %L, %L, false)', a, h, johann, juju)) from tk, ids;
select 'de quem não faz no dia: ERRO', t.erro(format('select trocar_responsavel(%s, %L, %L, %L, false)', tt, h + 1, johann, juju)) from tk, ids;
reset role; insert into tarefa_dia (tarefa, dia, aluno, status, valor, marcado_por) select tt, h - 1, johann, 'feito', 20, johann from tk, ids;
set role authenticated; select t.como(pai::text) from ids;
select 'de quem já marcou (Johann, ontem, T): ERRO', t.erro(format('select trocar_responsavel(%s, %L, %L, %L, false)', tt, h - 1, johann, juju)) from tk, ids;
select 'em diante pegando dia já marcado (T desde anteontem): ERRO', t.erro(format('select trocar_responsavel(%s, %L, %L, %L, true)', tt, h - 2, johann, juju)) from tk, ids;
select 'para o próprio: ERRO', t.erro(format('select trocar_responsavel(%s, %L, %L, %L, false)', r, h + 5, (responsaveis(r, h + 5))[1], (responsaveis(r, h + 5))[1])) from tk, ids;
select 'para o pai: ERRO', t.erro(format('select trocar_responsavel(%s, %L, %L, %L, false)', r, h + 5, (responsaveis(r, h + 5))[1], pai)) from tk, ids;
reset role; insert into tarefas (nome, pontos, modo, alunos, base) select 'S', 20, 'revezamento', array[johann], h from ids;
set role authenticated; select t.como(pai::text) from ids;
select 'recomeço com criança fora do revezamento: ERRO', t.erro(format('select trocar_responsavel(%s, %L, %L, %L, true)', (select id from tarefas where nome = 'S'), h, johann, juju)) from ids;

\echo '--- 9. Segurança'
select t.como(juju::text) from ids;
select 'criança troca: ERRO', t.erro(format('select trocar_responsavel(%s, %L, %L, %L, false)', r, h + 7, (responsaveis(r, h + 7))[1], juju)) from tk, ids;
select 'criança grava regra direto: ERRO', t.erro(format('insert into substituicoes (tarefa, de, para, desde) values (%s, %L, %L, %L)', tt, johann, juju, h)) from tk, ids;
select 'criança grava recomeço direto: ERRO', t.erro(format('insert into revez_inicios (tarefa, desde, aluno) values (%s, %L, %L)', r, h, juju)) from tk, ids;
select 'criança lê as regras (esperado: 2 substituições, 1 recomeço)', (select count(*) from substituicoes), (select count(*) from revez_inicios);
