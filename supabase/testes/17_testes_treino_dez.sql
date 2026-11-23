\set ON_ERROR_STOP 1
\pset format unaligned
\pset tuples_only on
-- Testes da migração 37 (treino só vale com 10 questões ou mais). Banco novo com todas as migrações.
create temp table ids as select 'd5c2215c-797c-435b-859b-09be1fe3efbf'::uuid johann;
insert into materias (aluno, id, nome) select johann, m, m from ids, unnest(array['tda', 'tdb']) m on conflict do nothing;

\echo '--- 1. Pontos de treino com 70%+ (esperado: 9 questões não dá, 10 dá)'
insert into tentativas (aluno, materia, tipo, acertos, total, pct, detalhes) select johann, 'tda', 'treino', 9, 9, 100, '[]' from ids;
select 'treino de 9 questões, 100%: lançamentos (0)', count(*) from lancamentos where origem = 'treino' and origem_ref like 'tda:%';
insert into tentativas (aluno, materia, tipo, acertos, total, pct, detalhes) select johann, 'tda', 'treino', 7, 10, 70, '[]' from ids;
select 'treino de 10 questões, 70%: lançamentos (1)', count(*) from lancamentos where origem = 'treino' and origem_ref like 'tda:%';
insert into tentativas (aluno, materia, tipo, acertos, total, pct, detalhes) select johann, 'tdb', 'treino', 6, 10, 60, '[]' from ids;
select 'treino de 10 questões, 60%: lançamentos (0)', count(*) from lancamentos where origem = 'treino' and origem_ref like 'tdb:%';

\echo '--- 2. Missão: melhor treino conta só os de 10+ questões (esperado: tda 70, tdb 60)'
insert into tentativas (aluno, materia, tipo, acertos, total, pct, detalhes) select johann, 'tdb', 'treino', 8, 8, 100, '[]' from ids;
update grupos set config = config || jsonb_build_object('prazo', (now() + interval '3 days')::text, 'materias', '["tda","tdb"]'::jsonb) - 'inicio'
 where aluno = (select johann from ids) and grupo = 'estudos';
select 'treino tda (70)', e->>'treino' from jsonb_array_elements(_missao((select johann from ids))->'det') e where e->>'mid' = 'tda';
select 'treino tdb (60, o de 8 questões com 100% não conta)', e->>'treino' from jsonb_array_elements(_missao((select johann from ids))->'det') e where e->>'mid' = 'tdb';
