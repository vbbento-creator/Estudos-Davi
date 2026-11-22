\set ON_ERROR_STOP 1
\pset format unaligned
\pset tuples_only on
-- Testes da migração 23 (treino e prova valendo no plano da Juju). Rodar num banco novo com as migrações 01 a 23
-- e depois a 23 de novo, para conferir que ela não repete itens:
--   node roda.mjs 00_stub.sql ../../banco.sql 00_perfis.sql ../migrations/*.sql ../migrations/20261121_23_juju_plano_treino_prova.sql 11_testes_plano_juju.sql
create temp table esperado(dia date, itens jsonb);
insert into esperado values
  ('2026-11-22','["Português: verbos e tempos verbais","Português: S no início, SS e S entre vogais"]'),
  ('2026-11-23','["Português: pontuação do diálogo","Português: ler 1 texto e responder (interpretação)","🎯 Português: treino"]'),
  ('2026-11-24','["Ciências: som e audição + propriedades do som","Matemática: Unidade 12 (dividir e multiplicar)","🎯 Português: treino"]'),
  ('2026-11-25','["Ciências: instrumentos musicais e a natureza dos sons","Ditado de S e SS com pai ou mãe","🏛️ Português: prova valendo (com pai ou mãe)"]'),
  ('2026-11-26','["Revisão final: Português (verbos, diálogo, ortografia)","Ler 1 texto e responder 🙂","🎯 Português: treino"]'),
  ('2026-11-27','["Ciências: saúde auditiva e o que é deficiência auditiva","🎯 Ciências: treino"]'),
  ('2026-11-28','["Ciências: poluição visual e auditiva (Hora do texto)","Inglês: things in nature + was/were (SB 92-93, WB 77-78)","🏛️ Ciências: prova valendo (com pai ou mãe)"]'),
  ('2026-11-29','["Inglês: prepositions, directions (SB 96, WB 80)","Inglês: went e didn''t go (SB 97, WB 81)","Geografia: controle de pragas e aquecimento global","🎯 Inglês: treino"]'),
  ('2026-11-30','["Revisão final: Ciências","História: chegada dos portugueses e povos africanos","Matemática: medidas de massa, capacidade e comprimento","🏛️ Inglês: prova valendo (com pai ou mãe)"]'),
  ('2026-12-01','["Revisão final: Inglês (Workbook 77 a 81)","Geografia: problemas da cidade e poluição dos rios","🏛️ História: prova valendo (com pai ou mãe)"]'),
  ('2026-12-02','["Revisão final: História e Geografia","Matemática: gráficos e Unidade 13 (Chef Gourmet)","🏛️ Geografia: prova valendo (com pai ou mãe)"]'),
  ('2026-12-03','["Revisão final: Matemática (problemas com as 4 operações)","🎯 Matemática: treino","🏛️ Matemática: prova valendo (com pai ou mãe)"]'),
  ('2026-12-04','["🏁 Acabou! Agora é esperar as notas"]');
\echo '--- plano da Juju igual ao esperado, dia a dia (esperado: 13 linhas OK)'
select e.dia || ' ' || case when c.itens = e.itens then 'OK' else 'FALHA: ' || coalesce(c.itens::text, '(sem dia)') end
  from esperado e left join cronograma c on c.aluno = '014341f0-99f3-4e14-b21d-6b4efc9bafbd' and c.dia = e.dia order by e.dia;
\echo '--- totais (esperado: 13 dias, 37 itens, máximo 4 por dia)'
select count(*) || ' dias, ' || sum(jsonb_array_length(itens)) || ' itens, máximo ' || max(jsonb_array_length(itens))
  from cronograma where aluno = '014341f0-99f3-4e14-b21d-6b4efc9bafbd';
\echo '--- no máximo uma prova valendo por dia (esperado: 0)'
select count(*) from cronograma where aluno = '014341f0-99f3-4e14-b21d-6b4efc9bafbd'
   and (select count(*) from jsonb_array_elements_text(itens) x where x like '%prova valendo%') > 1;
\echo '--- plano do Johann intacto (esperado: nenhum item com treino/prova valendo novo)'
select count(*) from cronograma where aluno = 'd5c2215c-797c-435b-859b-09be1fe3efbf' and itens::text like '%(com pai ou mãe)%';
