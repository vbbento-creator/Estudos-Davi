-- Migração 14 — matérias, tópicos e plano de estudo da Juju (P2 do 3º ano, 4º bimestre/2026).
-- Fonte: cronograma do Colégio Objetivo DF (provas de 27/11 a 04/12). Só insere dados.
begin;
insert into materias (aluno,id,nome,emoji,cor,prova,ordem) values
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','portugues','Português','📝','#e5484d','2026-11-27',0),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','ciencias','Ciências','🔬','#1fa971','2026-12-01',1),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','ingles','Inglês','🇬🇧','#3b82f6','2026-12-02',2),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','historia','História','📜','#a16207','2026-12-03',3),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','geografia','Geografia','🌎','#84cc16','2026-12-03',4),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','matematica','Matemática','➗','#0ea5e9','2026-12-04',5);
insert into topicos (aluno,materia,idx,nome) values
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','portugues',0,'Interpretação de texto'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','portugues',1,'Gramática: pontuação do diálogo'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','portugues',2,'Verbos'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','portugues',3,'Tempos verbais'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','portugues',4,'Ortografia: letra S no início de palavras; SS e S entre vogais'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','ciencias',0,'Como percebemos o mundo: som e audição'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','ciencias',1,'Propriedades do som'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','ciencias',2,'Instrumentos musicais e seus diferentes sons'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','ciencias',3,'A natureza dos diferentes sons'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','ciencias',4,'Cuidando da saúde auditiva'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','ciencias',5,'Saiba mais: o que é deficiência auditiva?'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','ciencias',6,'Hora do texto: a poluição visual e a auditiva'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','ingles',0,'Things in nature (SB 92-93 / WB 77)'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','ingles',1,'Grammar: was/wasn''t, were/weren''t (SB 93 / WB 78)'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','ingles',2,'Prepositions: directions (SB 96 / WB 80)'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','ingles',3,'Grammar: went and didn''t go (SB 97 / WB 81)'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','historia',0,'A chegada dos portugueses ao Brasil'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','historia',1,'Povos africanos: povos, culturas e tradições'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','geografia',0,'Controle biológico de pragas na agricultura'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','geografia',1,'Aquecimento global'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','geografia',2,'Os problemas ambientais na área urbana'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','geografia',3,'Poluição dos rios'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','matematica',0,'Unidade 12: dividir e multiplicar'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','matematica',1,'Unidade 13: Restaurante do "Chef Gourmet"'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','matematica',2,'Situações-problema com as 4 operações'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','matematica',3,'Medidas de massa, capacidade e comprimento'),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','matematica',4,'Leitura de gráficos');
insert into cronograma (aluno,dia,titulo,itens) values
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','2026-11-22','Domingo','["Português: verbos e tempos verbais","Português: S no início, SS e S entre vogais"]'::jsonb),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','2026-11-23','Segunda','["Português: pontuação do diálogo","Português: ler 1 texto e responder (interpretação)"]'::jsonb),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','2026-11-24','Terça','["Ciências: som e audição + propriedades do som","Matemática: Unidade 12 (dividir e multiplicar)"]'::jsonb),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','2026-11-25','Quarta','["Ciências: instrumentos musicais e a natureza dos sons","Ditado de S e SS com pai ou mãe"]'::jsonb),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','2026-11-26','Quinta','["Revisão final: Português (verbos, diálogo, ortografia)","Ler 1 texto e responder 🙂"]'::jsonb),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','2026-11-27','Sexta · ✏️ Português','["Ciências: saúde auditiva e o que é deficiência auditiva"]'::jsonb),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','2026-11-28','Sábado','["Ciências: poluição visual e auditiva (Hora do texto)","Inglês: things in nature + was/were (SB 92-93, WB 77-78)"]'::jsonb),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','2026-11-29','Domingo','["Inglês: prepositions, directions (SB 96, WB 80)","Inglês: went e didn''t go (SB 97, WB 81)","Geografia: controle de pragas e aquecimento global"]'::jsonb),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','2026-11-30','Segunda','["Revisão final: Ciências","História: chegada dos portugueses e povos africanos","Matemática: medidas de massa, capacidade e comprimento"]'::jsonb),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','2026-12-01','Terça · ✏️ Ciências','["Revisão final: Inglês (Workbook 77 a 81)","Geografia: problemas da cidade e poluição dos rios"]'::jsonb),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','2026-12-02','Quarta · ✏️ Inglês','["Revisão final: História e Geografia","Matemática: gráficos e Unidade 13 (Chef Gourmet)"]'::jsonb),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','2026-12-03','Quinta · ✏️ História e Geografia','["Revisão final: Matemática (problemas com as 4 operações)"]'::jsonb),
  ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','2026-12-04','Sexta · ✏️ Matemática','["🏁 Acabou! Agora é esperar as notas"]'::jsonb);
commit;
