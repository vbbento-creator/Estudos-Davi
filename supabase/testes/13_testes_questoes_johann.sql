\set ON_ERROR_STOP 1
\pset format unaligned
\pset tuples_only on
-- Testes das migrações 25 a 27 (questões de Matemática, Geografia e História do Johann). Rodar num banco novo:
--   node roda.mjs 00_stub.sql ../../banco.sql 00_perfis.sql ../migrations/*.sql 13_testes_questoes_johann.sql
\echo '--- quantidade por matéria e tipo (esperado: 50 treino e 12 prova em cada uma)'
select materia || ' ' || tipo || ' ' || count(*) from questoes
 where aluno = 'd5c2215c-797c-435b-859b-09be1fe3efbf' and materia in ('matematica','geografia','historia')
 group by materia, tipo order by materia, tipo;
\echo '--- questões com tópico que não existe entre os tópicos ativos do Johann (esperado: 0)'
select count(*) from questoes q
 where q.aluno = 'd5c2215c-797c-435b-859b-09be1fe3efbf' and q.materia in ('matematica','geografia','historia')
   and not exists (select 1 from topicos t where t.aluno = q.aluno and t.materia = q.materia and t.nome = q.topico and t.ativo);
\echo '--- tópicos ativos dessas matérias sem nenhuma questão (esperado: 0)'
select count(*) from topicos t
 where t.aluno = 'd5c2215c-797c-435b-859b-09be1fe3efbf' and t.materia in ('matematica','geografia','historia') and t.ativo
   and not exists (select 1 from questoes q where q.aluno = t.aluno and q.materia = t.materia and q.topico = t.nome);
\echo '--- questões sem gabarito, com resposta fora de 0 a 3, sem explicação ou sem 4 alternativas diferentes (esperado: 0)'
select count(*) from questoes q left join gabarito g on g.questao_id = q.id
 where q.id ~ '^(mat|geo|hist)-[tp][0-9]{2}$'
   and (g.questao_id is null or g.correta not between 0 and 3 or coalesce(g.explicacao,'') = ''
        or jsonb_array_length(q.alternativas) <> 4
        or (select count(distinct x) from jsonb_array_elements_text(q.alternativas) x) <> 4);
\echo '--- resposta certa em cada posição, por matéria (esperado: equilibrado, 15 ou 16 em cada)'
select materia || ' ' || string_agg(correta || ':' || n, ' ' order by correta) from (
  select q.materia, g.correta, count(*) n from questoes q join gabarito g on g.questao_id = q.id
   where q.id ~ '^(mat|geo|hist)-' group by 1, 2) x
 group by materia order by materia;
\echo '--- todas as questões novas são do Johann (esperado: 0 de outra criança)'
select count(*) from questoes where id ~ '^(mat|geo|hist)-' and aluno <> 'd5c2215c-797c-435b-859b-09be1fe3efbf';
\echo '--- impressão digital (md5) de cada matéria, para comparar com o banco de produção depois de aplicar'
select q.materia || ' ' || md5(string_agg(q.id || '|' || q.topico || '|' || q.tipo || '|' || q.enunciado || '|' || q.alternativas::text || '|' || g.correta || '|' || g.explicacao, E'\n' order by q.id))
  from questoes q join gabarito g on g.questao_id = q.id
 where q.id ~ '^(mat|geo|hist)-' group by q.materia order by q.materia;
