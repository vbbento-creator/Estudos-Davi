\set ON_ERROR_STOP 1
\pset format unaligned
\pset tuples_only on
-- Testes da migração 07 (concluir treino). Rodar num banco com as migrações 01 a 07 e sem 03/04 aplicados antes (cria os próprios dados).
create schema if not exists t; grant usage on schema t to authenticated;
create or replace function t.erro(q text) returns text language plpgsql as $$
begin execute q; return 'OK (sem erro)'; exception when others then return 'ERRO: ' || sqlerrm; end $$;
create or replace function t.como(u text) returns void language sql as $$ select set_config('request.jwt.claim.sub', u, false) $$;
grant execute on all functions in schema t to authenticated;
create temp table ids as select 'd5c2215c-797c-435b-859b-09be1fe3efbf'::uuid johann, '014341f0-99f3-4e14-b21d-6b4efc9bafbd'::uuid juju, '78768c03-68d4-420f-ba5d-c7fe46434042'::uuid pai;
grant select on ids to authenticated;
-- 50 questões de treino em física, 49 em biologia, resposta certa = alternativa 0
insert into materias (aluno, id, nome) select johann, 'biologia', 'Biologia' from ids on conflict do nothing;
insert into questoes (id, aluno, materia, topico, tipo, enunciado, alternativas)
  select 'f' || g, johann, 'fisica', 't', 'treino', 'Q' || g, '["a","b"]' from ids, generate_series(1, 50) g;
insert into questoes (id, aluno, materia, topico, tipo, enunciado, alternativas)
  select 'b' || g, johann, 'biologia', 't', 'treino', 'Q' || g, '["a","b"]' from ids, generate_series(1, 49) g;
insert into gabarito select id, 0, '' from questoes where id ~ '^[fb][0-9]+$';
create function pg_temp.det(prefixo text, de int, ate int, r int) returns jsonb language sql as
  $$ select jsonb_agg(jsonb_build_object('id', prefixo || g, 'r', r, 'c', 0)) from generate_series(de, ate) g $$;
grant execute on function pg_temp.det(text, int, int, int) to authenticated;
set role authenticated;

\echo '--- 1. Estado inicial (esperado: 50 questões, 0 dominadas, 0 erradas, 50 novas, mínimo 50, bônus 150)'
select t.como(johann::text) from ids;
select 'estado', total, dominadas, cardinality(erradas), cardinality(novas), minimo, pontos, bonus_dado from treino_estado((select johann from ids), 'fisica');

\echo '--- 2. Rodada 1: 10 certas (f1..f10) e 10 erradas (f11..f20)'
select 'tentativa revisão', t.erro($$insert into tentativas (materia, tipo, acertos, total, pct, detalhes) values ('fisica','revisao',10,20,50, pg_temp.det('f',1,10,0) || pg_temp.det('f',11,20,1))$$);
select 'estado (10 dominadas, 10 erradas, 30 novas)', dominadas, cardinality(erradas), cardinality(novas) from treino_estado((select johann from ids), 'fisica');
select 'sem bônus ainda', count(*) from lancamentos where origem = 'conclusao';

\echo '--- 3. Rodada 2: refaz as erradas, agora certas (f11..f20)'
select 'tentativa', t.erro($$insert into tentativas (materia, tipo, acertos, total, pct, detalhes) values ('fisica','revisao',10,10,100, pg_temp.det('f',11,20,0))$$);
select 'estado (20 dominadas, 0 erradas, 30 novas)', dominadas, cardinality(erradas), cardinality(novas) from treino_estado((select johann from ids), 'fisica');

\echo '--- 4. Campo "c" forjado não vale: f1 respondida errada mas marcada como certa'
select 'forja', t.erro($$insert into tentativas (materia, tipo, acertos, total, pct, detalhes) values ('fisica','revisao',1,1,100, '[{"id":"f1","r":1,"c":1}]')$$);
select 'f1 voltou a errada (19 dominadas, 1 errada)', dominadas, cardinality(erradas) from treino_estado((select johann from ids), 'fisica');
select 'sem bônus', count(*) from lancamentos where origem = 'conclusao';

\echo '--- 5. Fecha tudo certo num treino normal (f1 e f21..f50, 31 questões): bônus +150 uma vez, mais +40 do treino'
select 'tentativa', t.erro($$insert into tentativas (materia, tipo, acertos, total, pct, detalhes) values ('fisica','treino',31,31,100, pg_temp.det('f',1,1,0) || pg_temp.det('f',21,50,0))$$);
select 'estado (50 dominadas, 0 pendentes, bônus dado)', total, dominadas, cardinality(erradas) + cardinality(novas), bonus_dado from treino_estado((select johann from ids), 'fisica');
select 'lançamentos', origem, origem_ref, valor from lancamentos where origem in ('conclusao', 'treino') order by origem;
select 'saldo (150 + 40)', saldo_total(johann) from ids;

\echo '--- 6. Responder de novo não paga em dobro; errar depois reabre a questão mas não tira o bônus'
select 'tentativa certa', t.erro($$insert into tentativas (materia, tipo, acertos, total, pct, detalhes) values ('fisica','revisao',5,5,100, pg_temp.det('f',1,5,0))$$);
select 'tentativa errada f1', t.erro($$insert into tentativas (materia, tipo, acertos, total, pct, detalhes) values ('fisica','revisao',0,1,0, pg_temp.det('f',1,1,1))$$);
select 'estado (49 dominadas, 1 errada)', dominadas, cardinality(erradas) from treino_estado((select johann from ids), 'fisica');
select 'bônus continua um só', count(*), sum(valor) from lancamentos where origem = 'conclusao';
select 'saldo igual (190)', saldo_total(johann) from ids;

\echo '--- 7. Matéria com 49 questões não dá bônus (mínimo 50)'
select 'tudo certo em biologia', t.erro($$insert into tentativas (materia, tipo, acertos, total, pct, detalhes) values ('biologia','revisao',49,49,100, pg_temp.det('b',1,49,0))$$);
select 'estado biologia (49 de 49)', total, dominadas, minimo from treino_estado((select johann from ids), 'biologia');
select 'sem bônus de biologia', count(*) from lancamentos where origem = 'conclusao' and origem_ref like 'biologia%';

\echo '--- 8. Segurança'
select 'Juju vê o estado do Johann', t.erro($$select * from treino_estado('d5c2215c-797c-435b-859b-09be1fe3efbf', 'fisica')$$);
select t.como(juju::text) from ids;
select 'Juju vê o estado do Johann', t.erro($$select * from treino_estado('d5c2215c-797c-435b-859b-09be1fe3efbf', 'fisica')$$);
select 'Juju grava revisão no nome do Johann', t.erro($$insert into tentativas (aluno, materia, tipo, acertos, total, pct) values ('d5c2215c-797c-435b-859b-09be1fe3efbf','fisica','revisao',1,1,100)$$);
select 'Juju grava tipo prova', t.erro($$insert into tentativas (materia, tipo, acertos, total, pct) values ('fisica','prova',1,1,100)$$);
select t.como(pai::text) from ids;
select 'Pai vê o estado', total from treino_estado((select johann from ids), 'fisica');
select t.como(johann::text) from ids;
select 'Johann chama a função interna', t.erro($$select * from _dominio_treino(auth.uid(), 'fisica')$$);
select 'Johann chama a checagem interna', t.erro($$select _checar_conclusao(auth.uid(), 'fisica')$$);

\echo '--- 9. Perder pontos pela nota inclui o bônus (esperado: fisica 190 = 40 do treino + 150 do bônus)'
select t.como(pai::text) from ids;
select 'por matéria', materia, pontos from pontos_estudo_por_materia((select johann from ids)) where materia = 'fisica';
select 'Pai tira', perder_pontos_estudo((select johann from ids), 'fisica');
select 'saldo (0)', saldo_total(johann) from ids;
