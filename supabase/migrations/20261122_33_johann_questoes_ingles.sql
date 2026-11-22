-- Migração 33: questões de treino de Inglês do Johann que faltavam para 50 (ing-t35 a ing-t50; prova 23/11/2026).
-- Questões criadas do zero; a apostila (PDF do CamScanner de 17/11) foi só inspiração. Só insere dados.
-- A resposta certa fica equilibrada entre a, b, c e d nas 50 de treino da matéria.
begin;
insert into questoes (id,materia,topico,tipo,enunciado,alternativas,aluno) values
  ('ing-t35','ingles','Question tag','treino','Your sister is coming to the film festival, ___?','["won''t she", "doesn''t she", "is she", "isn''t she"]'::jsonb,'d5c2215c-797c-435b-859b-09be1fe3efbf'),
  ('ing-t36','ingles','Question tag','treino','We could rent a comedy tonight, ___?','["couldn''t we", "can''t we", "could we", "don''t we"]'::jsonb,'d5c2215c-797c-435b-859b-09be1fe3efbf'),
  ('ing-t37','ingles','Question tag','treino','The tickets were expensive, ___?','["were they", "wasn''t it", "didn''t they", "weren''t they"]'::jsonb,'d5c2215c-797c-435b-859b-09be1fe3efbf'),
  ('ing-t38','ingles','Relative pronouns: who, which and whose','treino','Complete: "My neighbor, ___ dog barks all night, loves action movies."','["what", "who", "which", "whose"]'::jsonb,'d5c2215c-797c-435b-859b-09be1fe3efbf'),
  ('ing-t39','ingles','Relative pronouns: who, which and whose','treino','Complete: "The cinema ___ opened downtown has giant screens."','["who", "what", "which", "whose"]'::jsonb,'d5c2215c-797c-435b-859b-09be1fe3efbf'),
  ('ing-t40','ingles','Relative pronouns: who, which and whose','treino','Complete: "The girl ___ sits next to me collects movie posters."','["which", "what", "who", "whose"]'::jsonb,'d5c2215c-797c-435b-859b-09be1fe3efbf'),
  ('ing-t41','ingles','Relative pronouns: who, which and whose','treino','Which sentence uses WHOSE correctly?','["That''s the director whose films always win awards.", "The popcorn whose I bought was cold.", "The camera whose is broken belongs to Tom.", "That''s the director whose made three films."]'::jsonb,'d5c2215c-797c-435b-859b-09be1fe3efbf'),
  ('ing-t42','ingles','Relative pronouns: who, which and whose','treino','We use WHICH to talk about:','["people only", "possession", "places and times only", "things and animals"]'::jsonb,'d5c2215c-797c-435b-859b-09be1fe3efbf'),
  ('ing-t43','ingles','Relative pronouns: who, which and whose','treino','We use WHOSE to show:','["a thing or an animal", "a person doing an action", "a question about time", "possession (cujo, de quem)"]'::jsonb,'d5c2215c-797c-435b-859b-09be1fe3efbf'),
  ('ing-t44','ingles','Relative pronouns: who, which and whose','treino','Join the sentences: "I watched a documentary. It was about the ocean."','["I watched a documentary who was about the ocean.", "I watched a documentary whose was about the ocean.", "I watched a documentary which was about the ocean.", "I watched a documentary which it was about the ocean."]'::jsonb,'d5c2215c-797c-435b-859b-09be1fe3efbf'),
  ('ing-t45','ingles','Text comprehension','treino','TEXT: "Every Friday, the students at Pine Valley School meet in the library for Film Club. They vote for a movie, watch it together and then talk about the story, the music and the characters. This year, the club also made its own short film about a robot that gets lost in a big city. It took six weeks to finish, and the whole school watched it at the end-of-year party."

How often does the Film Club meet?','["Once a week, on Fridays", "Every day", "Once a month", "Only at the end of the year"]'::jsonb,'d5c2215c-797c-435b-859b-09be1fe3efbf'),
  ('ing-t46','ingles','Text comprehension','treino','TEXT: "Every Friday, the students at Pine Valley School meet in the library for Film Club. They vote for a movie, watch it together and then talk about the story, the music and the characters. This year, the club also made its own short film about a robot that gets lost in a big city. It took six weeks to finish, and the whole school watched it at the end-of-year party."

What is the club''s short film about?','["The school library", "The end-of-year party", "A robot that gets lost in a big city", "A famous film director"]'::jsonb,'d5c2215c-797c-435b-859b-09be1fe3efbf'),
  ('ing-t47','ingles','Text comprehension','treino','TEXT: "Every Friday, the students at Pine Valley School meet in the library for Film Club. They vote for a movie, watch it together and then talk about the story, the music and the characters. This year, the club also made its own short film about a robot that gets lost in a big city. It took six weeks to finish, and the whole school watched it at the end-of-year party."

How long did it take to make the short film?','["Six days", "Two weeks", "Six weeks", "One year"]'::jsonb,'d5c2215c-797c-435b-859b-09be1fe3efbf'),
  ('ing-t48','ingles','Text comprehension','treino','TEXT: "Streaming services let people watch movies at home whenever they want. Many families love this, but some cinema owners are worried, because fewer people are buying tickets. To bring audiences back, some theaters now offer giant screens, comfortable seats and special events, like midnight premieres."

Why are some cinema owners worried?','["Because fewer people are buying tickets", "Because movies are getting shorter", "Because streaming services are free", "Because people don''t like midnight premieres"]'::jsonb,'d5c2215c-797c-435b-859b-09be1fe3efbf'),
  ('ing-t49','ingles','Text comprehension','treino','TEXT: "Streaming services let people watch movies at home whenever they want. Many families love this, but some cinema owners are worried, because fewer people are buying tickets. To bring audiences back, some theaters now offer giant screens, comfortable seats and special events, like midnight premieres."

What are some theaters doing to bring audiences back?','["Offering giant screens, comfortable seats and special events", "Closing before midnight", "Showing only old movies", "Giving free tickets to everyone"]'::jsonb,'d5c2215c-797c-435b-859b-09be1fe3efbf'),
  ('ing-t50','ingles','Text comprehension','treino','TEXT: "Streaming services let people watch movies at home whenever they want. Many families love this, but some cinema owners are worried, because fewer people are buying tickets. To bring audiences back, some theaters now offer giant screens, comfortable seats and special events, like midnight premieres."

In the text, "whenever" means:','["onde quer que", "somente à noite", "nunca", "sempre que, a qualquer hora que"]'::jsonb,'d5c2215c-797c-435b-859b-09be1fe3efbf');
insert into gabarito (questao_id,correta,explicacao) values
  ('ing-t35',3,'Frase afirmativa com "is" → tag negativa com o mesmo verbo: "isn''t she?".'),
  ('ing-t36',0,'O verbo auxiliar é "could". Frase afirmativa → tag negativa: "couldn''t we?".'),
  ('ing-t37',3,'"The tickets" é plural (they) e o verbo é "were". Afirmativa → "weren''t they?".'),
  ('ing-t38',3,'O cachorro é DO vizinho: ideia de posse → "whose" (cujo).'),
  ('ing-t39',2,'O cinema é uma coisa → "which".'),
  ('ing-t40',2,'"The girl" é uma pessoa que faz a ação (sits) → "who".'),
  ('ing-t41',0,'"Whose" vem sempre seguido do que pertence a alguém: "whose films" = os filmes dele.'),
  ('ing-t42',3,'"Which" é para coisas e animais; "who" para pessoas; "whose" para posse.'),
  ('ing-t43',3,'"Whose" indica posse: "the actor whose movie won" = o ator cujo filme venceu.'),
  ('ing-t44',2,'"Documentary" é uma coisa → "which", e ele substitui o "it" (não se repete o "it").'),
  ('ing-t45',0,'"Every Friday" = toda sexta-feira, ou seja, uma vez por semana.'),
  ('ing-t46',2,'O texto diz: "a short film about a robot that gets lost in a big city".'),
  ('ing-t47',2,'"It took six weeks to finish" = levou seis semanas para terminar.'),
  ('ing-t48',0,'"...some cinema owners are worried, because fewer people are buying tickets."'),
  ('ing-t49',0,'O texto cita telas gigantes, poltronas confortáveis e eventos especiais, como pré-estreias à meia-noite.'),
  ('ing-t50',3,'"Whenever they want" = sempre que quiserem, na hora que quiserem.');
commit;
