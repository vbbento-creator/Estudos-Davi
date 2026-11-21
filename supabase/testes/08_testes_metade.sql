\set ON_ERROR_STOP 1
\pset format unaligned
\pset tuples_only on
-- Testes da migração 10 (validar a tarefa pela metade). Rodar num banco novo com as migrações 01 a 10 (cria os próprios dados).
create schema if not exists t; grant usage on schema t to authenticated;
create or replace function t.erro(q text) returns text language plpgsql as $$
begin execute q; return 'OK (sem erro)'; exception when others then return 'ERRO: ' || sqlerrm; end $$;
create or replace function t.como(u text) returns void language sql as $$ select set_config('request.jwt.claim.sub', u, false) $$;
grant execute on all functions in schema t to authenticated;
create temp table ids as select 'd5c2215c-797c-435b-859b-09be1fe3efbf'::uuid johann, '014341f0-99f3-4e14-b21d-6b4efc9bafbd'::uuid juju,
  '78768c03-68d4-420f-ba5d-c7fe46434042'::uuid pai, hoje_sp() h;
grant select on ids to authenticated;
-- tarefas "todos" do Johann valendo 20 (uma por caso) e uma valendo 0
insert into tarefas (nome, pontos, modo, alunos, base) select x, 20, 'todos', array[johann], h - 10 from ids, unnest(array['A','B','C','D','E','F']) x;
insert into tarefas (nome, pontos, modo, alunos, base) select 'Z', 0, 'todos', array[johann], h - 10 from ids;
create function pg_temp.tk(n text) returns bigint language sql as $$ select id from tarefas where nome = n $$;
grant execute on function pg_temp.tk(text) to authenticated;
-- quanto a tarefa já rendeu ao Johann (crédito menos estorno)
create function pg_temp.rendeu(n text) returns numeric language sql as $$
  select coalesce(sum(valor), 0) from lancamentos where origem in ('tarefa','estorno') and origem_ref = pg_temp.tk(n) || ':' || hoje_sp() $$;
grant execute on function pg_temp.rendeu(text) to authenticated;
set role authenticated;
select t.como(johann::text) from ids;
select 'Johann marca', n, t.erro(format('select marcar_tarefa(%s, %L, %L)', pg_temp.tk(n), h, 'feito')) from ids, unnest(array['A','B','C','D','E','F','Z']) n;
select t.como(pai::text) from ids;

\echo '--- 1. Metade: credita 10 de 20, com motivo e comentário'
select 'metade A', t.erro(format('select decidir_tarefa(%s, %L, %L, %L, %L, %L)', pg_temp.tk('A'), h, johann, 'metade', 'reclamou', 'fez bufando')) from ids;
select 'A rendeu (10)', pg_temp.rendeu('A');
select 'A gravada', decisao, motivo, motivo_comentario from tarefa_dia where tarefa = pg_temp.tk('A');

\echo '--- 2. Metade sem motivo ou com motivo inválido: ERRO'
select 'sem motivo: ERRO', t.erro(format('select decidir_tarefa(%s, %L, %L, %L)', pg_temp.tk('B'), h, johann, 'metade')) from ids;
select 'motivo inválido: ERRO', t.erro(format('select decidir_tarefa(%s, %L, %L, %L, %L)', pg_temp.tk('B'), h, johann, 'metade', 'preguiça')) from ids;

\echo '--- 3. Chamada antiga (4 argumentos) continua funcionando: validar B (20) e rejeitar C (0)'
select 'validar B', t.erro(format('select decidir_tarefa(%s, %L, %L, %L)', pg_temp.tk('B'), h, johann, 'validado')) from ids;
select 'rejeitar C', t.erro(format('select decidir_tarefa(%s, %L, %L, %L)', pg_temp.tk('C'), h, johann, 'rejeitado')) from ids;
select 'B e C renderam (20 e 0)', pg_temp.rendeu('B'), pg_temp.rendeu('C');

\echo '--- 4. A criança vê o motivo na lista do dia'
select t.como(johann::text) from ids;
select 'lista do Johann', nome, decisao, motivo, motivo_comentario, pode_recorrer from tarefas_do_dia((select johann from ids), (select h from ids)) where nome in ('A', 'B');
select 'agenda do Johann', nome, decisao, motivo from agenda_tarefas((select johann from ids), (select h from ids), (select h from ids)) where nome = 'A';

\echo '--- 5. Recurso contra a metade: validar inteira credita mais 10 (total 20)'
select 'recurso A', t.erro(format('select abrir_recurso(%s, %L, %L)', pg_temp.tk('A'), h, 'Eu fiz sem reclamar')) from ids;
select t.como(pai::text) from ids;
select 'rejeitar no recurso contra metade: ERRO', t.erro(format('select resolver_recurso(%s, %L)', (select id from recursos where tarefa = pg_temp.tk('A')), 'rejeitado')) from ids;
select 'validar inteira', t.erro(format('select resolver_recurso(%s, %L, %L)', (select id from recursos where tarefa = pg_temp.tk('A')), 'validado', 'ok, valeu')) from ids;
select 'A rendeu (20), decisão validado, motivo apagado', pg_temp.rendeu('A'), decisao, motivo is null from tarefa_dia where tarefa = pg_temp.tk('A');

\echo '--- 6. Recurso contra a metade: manter a metade (fica 10, motivo continua)'
select 'metade D', t.erro(format('select decidir_tarefa(%s, %L, %L, %L, %L)', pg_temp.tk('D'), h, johann, 'metade', 'enrolou')) from ids;
select t.como(johann::text) from ids;
select 'recurso D', t.erro(format('select abrir_recurso(%s, %L, %L)', pg_temp.tk('D'), h, 'Não enrolei')) from ids;
select t.como(pai::text) from ids;
select 'manter metade', t.erro(format('select resolver_recurso(%s, %L)', (select id from recursos where tarefa = pg_temp.tk('D')), 'metade')) from ids;
select 'D rendeu (10), motivo enrolou, recurso final metade', pg_temp.rendeu('D'), td.motivo, r.decisao_final from tarefa_dia td join recursos r using (tarefa, dia, aluno) where td.tarefa = pg_temp.tk('D');

\echo '--- 7. Recurso contra rejeição: pode virar metade (exige motivo) e credita 10'
select t.como(johann::text) from ids;
select 'recurso C', t.erro(format('select abrir_recurso(%s, %L, %L)', pg_temp.tk('C'), h, 'Eu fiz')) from ids;
select t.como(pai::text) from ids;
select 'metade sem motivo: ERRO', t.erro(format('select resolver_recurso(%s, %L)', (select id from recursos where tarefa = pg_temp.tk('C')), 'metade')) from ids;
select 'metade com motivo', t.erro(format('select resolver_recurso(%s, %L, null, %L)', (select id from recursos where tarefa = pg_temp.tk('C')), 'metade', 'reclamou')) from ids;
select 'C rendeu (10), motivo reclamou', pg_temp.rendeu('C'), motivo from tarefa_dia where tarefa = pg_temp.tk('C');

\echo '--- 8. Metade de tarefa valendo 0: nada é lançado, sem erro'
select 'metade Z', t.erro(format('select decidir_tarefa(%s, %L, %L, %L, %L)', pg_temp.tk('Z'), h, johann, 'metade', 'enrolou')) from ids;
select 'Z rendeu (0)', pg_temp.rendeu('Z');

\echo '--- 9. Teto: quando o teto já cortou, metade conta só o que foi creditado'
reset role;
update grupos set teto_semana = (select coalesce(sum(valor), 0) from lancamentos l, ids where l.aluno = johann and grupo = 'casa'
                                   and data_ref between date_trunc('week', h)::date and date_trunc('week', h)::date + 6) + 5
 where grupo = 'casa' and aluno = (select johann from ids);
set role authenticated; select t.como(pai::text) from ids;
select 'metade E com 5 de espaço no teto', t.erro(format('select decidir_tarefa(%s, %L, %L, %L, %L)', pg_temp.tk('E'), h, johann, 'metade', 'enrolou')) from ids;
select 'E rendeu (5)', pg_temp.rendeu('E');
select 'validar F com o teto cheio', t.erro(format('select decidir_tarefa(%s, %L, %L, %L)', pg_temp.tk('F'), h, johann, 'validado')) from ids;
select 'F rendeu (0)', pg_temp.rendeu('F');

\echo '--- 10. Segurança'
select t.como(johann::text) from ids;
select 'criança decide: ERRO', t.erro(format('select decidir_tarefa(%s, %L, %L, %L, %L)', pg_temp.tk('B'), h, johann, 'metade', 'enrolou')) from ids;
select t.como(pai::text) from ids;
select 'decisão inválida: ERRO', t.erro(format('select decidir_tarefa(%s, %L, %L, %L)', pg_temp.tk('B'), h, johann, 'quase')) from ids;
