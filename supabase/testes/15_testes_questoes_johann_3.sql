\set ON_ERROR_STOP 1
\pset format unaligned
\pset tuples_only on
-- Testes das migrações 32 a 34 (questões de treino de Física, Inglês e Biologia do Johann que faltavam para 50). Rodar num banco novo:
--   node roda.mjs 00_stub.sql ../../banco.sql 00_perfis.sql ../migrations/*.sql 15_testes_questoes_johann_3.sql
-- As questões antigas dessas matérias (fis-t01 a t37, ing-t01 a t34, bio-t01 a t30 e as de prova) existem só no banco de produção;
-- aqui se testam as novas. O total de 50 e o equilíbrio das respostas nas 50 são conferidos em produção depois de aplicar.
\echo '--- quantidade de questões novas por matéria (esperado: biologia 20, fisica 13, ingles 16; todas de treino)'
select materia || ' ' || tipo || ' ' || count(*) from questoes
 where id ~ '^(fis-t(3[89]|4[0-9]|50)|ing-t(3[5-9]|4[0-9]|50)|bio-t(3[1-9]|4[0-9]|50))$'
 group by materia, tipo order by materia, tipo;
\echo '--- ids novos esperados que faltam (esperado: 0)'
select count(*) from (
  select 'fis-t' || lpad(n::text, 2, '0') id from generate_series(38, 50) n
  union all select 'ing-t' || lpad(n::text, 2, '0') from generate_series(35, 50) n
  union all select 'bio-t' || lpad(n::text, 2, '0') from generate_series(31, 50) n) e
 where not exists (select 1 from questoes q where q.id = e.id);
\echo '--- questões novas com tópico que não existe entre os tópicos ativos do Johann (esperado: 0)'
select count(*) from questoes q
 where q.id ~ '^(fis-t(3[89]|4[0-9]|50)|ing-t(3[5-9]|4[0-9]|50)|bio-t(3[1-9]|4[0-9]|50))$'
   and not exists (select 1 from topicos t where t.aluno = q.aluno and t.materia = q.materia and t.nome = q.topico and t.ativo);
\echo '--- questões novas por tópico'
select materia || ' | ' || topico || ' | ' || count(*) from questoes
 where id ~ '^(fis-t(3[89]|4[0-9]|50)|ing-t(3[5-9]|4[0-9]|50)|bio-t(3[1-9]|4[0-9]|50))$'
 group by materia, topico order by materia, topico;
\echo '--- sem gabarito, resposta fora de 0 a 3, sem explicação ou sem 4 alternativas diferentes (esperado: 0)'
select count(*) from questoes q left join gabarito g on g.questao_id = q.id
 where q.id ~ '^(fis-t(3[89]|4[0-9]|50)|ing-t(3[5-9]|4[0-9]|50)|bio-t(3[1-9]|4[0-9]|50))$'
   and (g.questao_id is null or g.correta not between 0 and 3 or coalesce(g.explicacao,'') = ''
        or jsonb_array_length(q.alternativas) <> 4
        or (select count(distinct x) from jsonb_array_elements_text(q.alternativas) x) <> 4);
\echo '--- questão nova com enunciado igual ao de outra questão da mesma matéria (esperado: 0; contra as antigas, conferir em produção)'
select count(*) from questoes n join questoes o on o.materia = n.materia and o.enunciado = n.enunciado and o.id <> n.id
 where n.id ~ '^(fis-t(3[89]|4[0-9]|50)|ing-t(3[5-9]|4[0-9]|50)|bio-t(3[1-9]|4[0-9]|50))$';
\echo '--- resposta certa por posição nas novas (somada às antigas em produção, deve dar fisica 15 11 12 12, ingles 12 13 13 12, biologia 12 12 13 13)'
select materia || ' ' || string_agg(correta || ':' || n, ' ' order by correta) from (
  select q.materia, g.correta, count(*) n from questoes q join gabarito g on g.questao_id = q.id
   where q.id ~ '^(fis-t(3[89]|4[0-9]|50)|ing-t(3[5-9]|4[0-9]|50)|bio-t(3[1-9]|4[0-9]|50))$' group by 1, 2) x
 group by materia order by materia;
\echo '--- todas as questões novas são do Johann (esperado: 0 de outra criança)'
select count(*) from questoes where id ~ '^(fis-t(3[89]|4[0-9]|50)|ing-t(3[5-9]|4[0-9]|50)|bio-t(3[1-9]|4[0-9]|50))$'
   and aluno <> 'd5c2215c-797c-435b-859b-09be1fe3efbf';
\echo '--- impressão digital (md5) das novas de cada matéria, para comparar com o banco de produção depois de aplicar'
select q.materia || ' ' || md5(string_agg(q.id || '|' || q.topico || '|' || q.tipo || '|' || q.enunciado || '|' || q.alternativas::text || '|' || g.correta || '|' || g.explicacao, E'\n' order by q.id))
  from questoes q join gabarito g on g.questao_id = q.id
 where q.id ~ '^(fis-t(3[89]|4[0-9]|50)|ing-t(3[5-9]|4[0-9]|50)|bio-t(3[1-9]|4[0-9]|50))$' group by q.materia order by q.materia;
