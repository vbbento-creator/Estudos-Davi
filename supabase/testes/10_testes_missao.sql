\set ON_ERROR_STOP 1
\pset format unaligned
\pset tuples_only on
-- Testes da migração 12 (missão automática: cálculo no banco e fechamento). Rodar num banco novo com as migrações 01 a 12 (cria os próprios dados).
create schema if not exists t; grant usage on schema t to authenticated;
create or replace function t.erro(q text) returns text language plpgsql as $$
begin execute q; return 'OK (sem erro)'; exception when others then return 'ERRO: ' || sqlerrm; end $$;
create or replace function t.como(u text) returns void language sql as $$ select set_config('request.jwt.claim.sub', u, false) $$;
grant execute on all functions in schema t to authenticated;
create temp table ids as select 'd5c2215c-797c-435b-859b-09be1fe3efbf'::uuid johann, '014341f0-99f3-4e14-b21d-6b4efc9bafbd'::uuid juju,
  '78768c03-68d4-420f-ba5d-c7fe46434042'::uuid pai, hoje_sp() h;
grant select on ids to authenticated;
-- prazo "dia às 22:00" em São Paulo, no formato que o app grava hoje
create function pg_temp.pz(d date) returns text language sql as $$ select to_char(d, 'YYYY-MM-DD') || 'T22:00:00-03:00' $$;
create function pg_temp.cfg(a uuid, novo jsonb) returns void language sql as $$
  update grupos set config = config || novo where aluno = a and grupo = 'estudos' $$;
-- missão do Johann / da Juju (lida como pai)
create function pg_temp.mj() returns jsonb language sql as $$ select missao('d5c2215c-797c-435b-859b-09be1fe3efbf') $$;
create function pg_temp.mu() returns jsonb language sql as $$ select missao('014341f0-99f3-4e14-b21d-6b4efc9bafbd') $$;
grant execute on all functions in schema pg_temp to authenticated;
-- dados: só a tarefa T1 (diária, Johann) conta; matérias xa e xb do Johann (2 tópicos cada), ya da Juju (1 tópico)
update tarefas set ativa = false;
insert into tarefas (nome, pontos, modo, alunos, base) select 'T1', 10, 'todos', array[johann], h - 20 from ids;
insert into materias (aluno, id, nome) select johann, x, x from ids, unnest(array['xa','xb']) x;
insert into topicos (aluno, materia, idx, nome) select johann, m, i, m || i from ids, unnest(array['xa','xb']) m, generate_series(0, 1) i;
insert into materias (aluno, id, nome) select juju, 'ya', 'ya' from ids;
insert into topicos (aluno, materia, idx, nome) select juju, 'ya', 0, 'ya0' from ids;
-- tópicos concluídos 2 dias antes do prazo (h-3); treino 80% (10 questões) e prova 90% nas duas
insert into progresso (aluno, chave, estudou, exercicios, concluido_em)
  select johann, m || ':' || i, true, true, (h - 5)::timestamp at time zone 'America/Sao_Paulo' from ids, unnest(array['xa','xb']) m, generate_series(0, 1) i;
insert into tentativas (aluno, materia, tipo, acertos, total, pct, criado)
  select johann, m, 'treino', 8, 10, 80, (h - 4)::timestamp at time zone 'America/Sao_Paulo' from ids, unnest(array['xa','xb']) m;
insert into tentativas (aluno, materia, tipo, acertos, total, pct, criado)
  select johann, m, 'prova', 9, 10, 90, (h - 4)::timestamp at time zone 'America/Sao_Paulo' from ids, unnest(array['xa','xb']) m;
set role authenticated;
select t.como(pai::text) from ids;

\echo '--- 1. Sem prazo: missão nula'
-- as migrações antigas gravam a missão de 19/11 do Johann: limpa o prazo
reset role; select pg_temp.cfg(johann, '{"prazo":null}') from ids;
set role authenticated; select t.como(pai::text) from ids;
select 'missao Johann sem prazo (nula)', coalesce(pg_temp.mj()::text, 'nula');

\echo '--- 2. Prazo h-3 22:00, início h-9, nenhuma tarefa decidida: sem nível'
reset role;
select pg_temp.cfg(johann, jsonb_build_object('prazo', pg_temp.pz(h - 3), 'inicio', (h - 9)::text, 'materias', '["xa","xb"]'::jsonb)) from ids;
set role authenticated; select t.como(pai::text) from ids;
select 'tarefas total 7, obtido 0', pg_temp.mj()->'tarefas'->>'total', pg_temp.mj()->'tarefas'->>'obtido';
select 'nível (nulo), dia do prazo h-3', coalesce(pg_temp.mj()->>'nivel', 'nulo'), (pg_temp.mj()->>'dia_prazo')::date - h from ids;
select 'det xa: bronze true, treino 80, prova 90', pg_temp.mj()->'det'->0->>'bronze', pg_temp.mj()->'det'->0->>'treino', pg_temp.mj()->'det'->0->>'prova';

\echo '--- 3. 5 validadas, 1 metade, 1 rejeitada: 78.6% = bronze'
reset role;
insert into tarefa_dia (tarefa, dia, aluno, status, valor, marcado_por, decisao, motivo)
  select (select id from tarefas where nome = 'T1'), h - k, johann, 'feito', 10, johann,
         case when k between 5 and 9 then 'validado' when k = 4 then 'metade' else 'rejeitado' end,
         case when k = 4 then 'enrolou' end
    from ids, generate_series(3, 9) k;
set role authenticated; select t.como(pai::text) from ids;
select 'obtido 5.5, pct 78.6', pg_temp.mj()->'tarefas'->>'obtido', pg_temp.mj()->'tarefas'->>'pct';
select 'nível bronze, valor 150', pg_temp.mj()->>'nivel', pg_temp.mj()->>'valor';

\echo '--- 4. Todas validadas: ouro'
reset role;
update tarefa_dia set decisao = 'validado', motivo = null where aluno = (select johann from ids);
set role authenticated; select t.como(pai::text) from ids;
select 'nível ouro, valor 400', pg_temp.mj()->>'nivel', pg_temp.mj()->>'valor';

\echo '--- 5. Tópico concluído às 22:01 do dia do prazo não conta'
reset role;
update progresso set concluido_em = ((h - 3)::timestamp + time '22:01') at time zone 'America/Sao_Paulo' from ids where aluno = johann and chave = 'xb:0';
set role authenticated; select t.como(pai::text) from ids;
select 'det xb bronze false, nível nulo', pg_temp.mj()->'det'->1->>'bronze', coalesce(pg_temp.mj()->>'nivel', 'nulo');
reset role;
update progresso set concluido_em = ((h - 3)::timestamp + time '21:59') at time zone 'America/Sao_Paulo' from ids where aluno = johann and chave = 'xb:0';
set role authenticated; select t.como(pai::text) from ids;
select 'às 21:59 conta: ouro', pg_temp.mj()->>'nivel';

\echo '--- 6. Prova às 22:01 do dia do prazo não conta'
reset role;
insert into tentativas (aluno, materia, tipo, acertos, total, pct, criado)
  select johann, 'xa', 'prova', 10, 10, 100, ((h - 3)::timestamp + time '22:01') at time zone 'America/Sao_Paulo' from ids;
insert into tentativas (aluno, materia, tipo, acertos, total, pct, criado)
  select johann, 'xa', 'treino', 4, 4, 100, (h - 4)::timestamp at time zone 'America/Sao_Paulo' from ids;
set role authenticated; select t.como(pai::text) from ids;
select 'xa prova 90 (a de 100 foi depois), treino 80 (o de 4 questões não vale)', pg_temp.mj()->'det'->0->>'prova', pg_temp.mj()->'det'->0->>'treino';

\echo '--- 7. Pendências seguram o fechamento'
reset role;
insert into tarefas (nome, pontos, modo, alunos, base, ate) select 'T2', 10, 'todos', array[johann], h - 5, h - 5 from ids;
insert into tarefa_dia (tarefa, dia, aluno, status, valor, marcado_por) select (select id from tarefas where nome = 'T2'), h - 5, johann, 'feito', 10, johann from ids;
set role authenticated; select t.como(pai::text) from ids;
select 'avulsa marcada sem decisão: total 8, pendentes 1, pode_fechar false', pg_temp.mj()->'tarefas'->>'total', pg_temp.mj()->'tarefas'->>'pendentes', pg_temp.mj()->>'pode_fechar';
reset role;
update tarefa_dia set decisao = 'validado' where tarefa = (select id from tarefas where nome = 'T2');
insert into recursos (tarefa, dia, aluno, comentario) select (select id from tarefas where nome = 'T1'), h - 3, johann, 'fiz sim' from ids;
set role authenticated; select t.como(pai::text) from ids;
select 'recurso aberto: pendentes 1, pode_fechar false', pg_temp.mj()->'tarefas'->>'pendentes', pg_temp.mj()->>'pode_fechar';
reset role;
update recursos set decisao_final = 'validado';
set role authenticated; select t.como(pai::text) from ids;
select 'sem pendências: pendentes 0, pode_fechar true, lancada false', pg_temp.mj()->'tarefas'->>'pendentes', pg_temp.mj()->>'pode_fechar', pg_temp.mj()->>'lancada';

\echo '--- 8. Espera de 2 dias depois do dia do prazo'
reset role; select pg_temp.cfg(johann, jsonb_build_object('prazo', pg_temp.pz(h - 1))) from ids;
set role authenticated; select t.como(pai::text) from ids;
select 'prazo ontem: encerrada true, pode_fechar false', pg_temp.mj()->>'encerrada', pg_temp.mj()->>'pode_fechar';
reset role; select pg_temp.cfg(johann, jsonb_build_object('prazo', pg_temp.pz(h - 2))) from ids;
set role authenticated; select t.como(pai::text) from ids;
select 'prazo anteontem: pode_fechar true', pg_temp.mj()->>'pode_fechar';
reset role; select pg_temp.cfg(johann, jsonb_build_object('prazo', pg_temp.pz(h - 3))) from ids;
set role authenticated;

\echo '--- 9. Fechar: a criança abrindo o app lança uma vez só'
select t.como(johann::text) from ids;
select 'fechar_missoes como Johann (1)', fechar_missoes();
select 'de novo (0)', fechar_missoes();
select t.como(pai::text) from ids;
select 'lançamento: 400, dia h-3, descrição, referência', l.valor, l.data_ref - i.h, l.descricao, l.origem_ref = 'meta:' || to_char(i.h - 3, 'YYYY-MM-DD') || ' 22:00'
  from lancamentos l, ids i where l.aluno = i.johann and l.origem = 'nivel';
select 'lancada true', pg_temp.mj()->>'lancada';

\echo '--- 10. Regravar o mesmo prazo em UTC não lança de novo'
reset role; select pg_temp.cfg(johann, jsonb_build_object('prazo', to_char(h - 2, 'YYYY-MM-DD') || 'T01:00:00.000Z')) from ids;
set role authenticated; select t.como(pai::text) from ids;
select 'lancada true, fechar (0), lançamentos de nível (1)', pg_temp.mj()->>'lancada', fechar_missoes(),
  (select count(*) from lancamentos l, ids i where l.aluno = i.johann and l.origem = 'nivel');

\echo '--- 11 e 12. Juju sem início: fecha logo depois do prazo; sem nível não lança; referência antiga conta como lançada'
reset role;
select pg_temp.cfg(juju, jsonb_build_object('prazo', to_char((now() - interval '1 hour') at time zone 'America/Sao_Paulo', 'YYYY-MM-DD"T"HH24:MI:SS') || '-03:00',
                                            'materias', '["ya"]'::jsonb)) from ids;
set role authenticated; select t.como(pai::text) from ids;
select 'Juju: tarefas nulo, nível nulo, pode_fechar true', coalesce(pg_temp.mu()->>'tarefas', 'nulo'), coalesce(pg_temp.mu()->>'nivel', 'nulo'), pg_temp.mu()->>'pode_fechar';
select 'fechar sem nível (0)', fechar_missoes();
reset role;
insert into progresso (aluno, chave, estudou, exercicios, concluido_em) select juju, 'ya:0', true, true, now() - interval '2 days' from ids;
insert into lancamentos (aluno, grupo, moeda, valor, data_ref, descricao, origem, origem_ref)
  select juju, 'estudos', 'pontos', 150, h, 'Missão: nível bronze', 'nivel', 'meta:' || (select config->>'prazo' from grupos where aluno = juju and grupo = 'estudos') from ids;
set role authenticated; select t.como(pai::text) from ids;
select 'Juju bronze, lancada true (referência antiga), fechar (0)', pg_temp.mu()->>'nivel', pg_temp.mu()->>'lancada', fechar_missoes();

\echo '--- 13. Pausa e troca tiram dias do Johann'
reset role;
delete from tarefa_dia where tarefa = (select id from tarefas where nome = 'T1') and dia in (select h - 6 from ids union select h - 7 from ids);
set role authenticated; select t.como(pai::text) from ids;
select 'sem marcação em h-6 e h-7: total 8', pg_temp.mj()->'tarefas'->>'total';
select 'trocar h-7 para Juju', t.erro(format('select trocar_responsavel(%s, %L, %L, %L, false)', (select id from tarefas where nome = 'T1'), h - 7, johann, juju)) from ids;
reset role; insert into pausas (inicio, fim, motivo) select h - 6, h - 6, 'viagem' from ids;
set role authenticated; select t.como(pai::text) from ids;
select 'com pausa e troca: total 6', pg_temp.mj()->'tarefas'->>'total';

\echo '--- 14. Acesso'
select t.como(juju::text) from ids;
select 'Juju lê a missão do Johann: ERRO', t.erro(format('select missao(%L)', johann)) from ids;
select 'Juju chama _missao: ERRO', t.erro(format('select _missao(%L)', johann)) from ids;
select t.como('99999999-9999-9999-9999-999999999999');
select 'intruso sem perfil fecha: ERRO', t.erro('select fechar_missoes()');
