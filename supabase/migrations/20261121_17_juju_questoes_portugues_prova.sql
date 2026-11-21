-- Migração 17 — questões de prova de Português da Juju (P2 do 3º ano, prova 27/11/2026).
-- 12 questões tipo prova (prova valendo), diferentes das de treino da migração 16.
-- Questões criadas do zero; o material da escola foi só inspiração. Só insere dados.
begin;
insert into questoes (id,materia,topico,tipo,enunciado,alternativas,aluno) values
  ('juju-port-p01','portugues','Interpretação de texto','prova','TEXTO: "O piquenique"
No sábado, a turma do 3º ano fez um piquenique no parque. Cada criança levou uma comida. Rafa esqueceu o lanche em casa e ficou sentado sozinho embaixo de uma árvore, triste. Clara percebeu, sentou ao lado dele e dividiu seu sanduíche.
– Obrigado, Clara! – disse Rafa, sorrindo.
– Amigo é para essas coisas! – respondeu ela.

Onde a turma fez o piquenique?','["Na escola", "No parque", "Na praia", "Na casa do Rafa"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-p02','portugues','Interpretação de texto','prova','TEXTO: "O piquenique"
No sábado, a turma do 3º ano fez um piquenique no parque. Cada criança levou uma comida. Rafa esqueceu o lanche em casa e ficou sentado sozinho embaixo de uma árvore, triste. Clara percebeu, sentou ao lado dele e dividiu seu sanduíche.
– Obrigado, Clara! – disse Rafa, sorrindo.
– Amigo é para essas coisas! – respondeu ela.

Por que Rafa ficou triste?','["Brigou com a Clara", "Choveu no parque", "Esqueceu o lanche em casa", "Não gostava de piquenique"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-p03','portugues','Interpretação de texto','prova','TEXTO: "O piquenique"
No sábado, a turma do 3º ano fez um piquenique no parque. Cada criança levou uma comida. Rafa esqueceu o lanche em casa e ficou sentado sozinho embaixo de uma árvore, triste. Clara percebeu, sentou ao lado dele e dividiu seu sanduíche.
– Obrigado, Clara! – disse Rafa, sorrindo.
– Amigo é para essas coisas! – respondeu ela.

A atitude da Clara mostra que ela é:','["Generosa e boa amiga", "Egoísta", "Distraída", "Brava"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-p04','portugues','Interpretação de texto','prova','TEXTO: "O piquenique"
No sábado, a turma do 3º ano fez um piquenique no parque. Cada criança levou uma comida. Rafa esqueceu o lanche em casa e ficou sentado sozinho embaixo de uma árvore, triste. Clara percebeu, sentou ao lado dele e dividiu seu sanduíche.
– Obrigado, Clara! – disse Rafa, sorrindo.
– Amigo é para essas coisas! – respondeu ela.

Como Rafa ficou depois da ajuda da Clara?','["Mais triste", "Com raiva", "Com sono", "Feliz e agradecido"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-p05','portugues','Gramática: pontuação do diálogo','prova','TEXTO: "O piquenique"
No sábado, a turma do 3º ano fez um piquenique no parque. Cada criança levou uma comida. Rafa esqueceu o lanche em casa e ficou sentado sozinho embaixo de uma árvore, triste. Clara percebeu, sentou ao lado dele e dividiu seu sanduíche.
– Obrigado, Clara! – disse Rafa, sorrindo.
– Amigo é para essas coisas! – respondeu ela.

Na linha "– Obrigado, Clara! – disse Rafa, sorrindo.", a parte "disse Rafa, sorrindo" é:','["Fala da Clara", "A parte do narrador, que conta quem falou", "Fala do Rafa", "O título do texto"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-p06','portugues','Gramática: pontuação do diálogo','prova','TEXTO: "O piquenique"
No sábado, a turma do 3º ano fez um piquenique no parque. Cada criança levou uma comida. Rafa esqueceu o lanche em casa e ficou sentado sozinho embaixo de uma árvore, triste. Clara percebeu, sentou ao lado dele e dividiu seu sanduíche.
– Obrigado, Clara! – disse Rafa, sorrindo.
– Amigo é para essas coisas! – respondeu ela.

Na fala "– Amigo é para essas coisas!", o ponto de exclamação mostra:','["Uma pergunta", "O fim do texto", "Emoção e entusiasmo", "Que ela está em dúvida"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-p07','portugues','Verbos','prova','TEXTO: "O piquenique"
No sábado, a turma do 3º ano fez um piquenique no parque. Cada criança levou uma comida. Rafa esqueceu o lanche em casa e ficou sentado sozinho embaixo de uma árvore, triste. Clara percebeu, sentou ao lado dele e dividiu seu sanduíche.
– Obrigado, Clara! – disse Rafa, sorrindo.
– Amigo é para essas coisas! – respondeu ela.

Qual destas palavras do texto é um verbo?','["árvore", "sanduíche", "triste", "sentou"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-p08','portugues','Verbos','prova','"Clara dividiu seu sanduíche." Qual é o infinitivo do verbo dessa frase?','["dividir", "divisão", "dividido", "dividia"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-p09','portugues','Tempos verbais','prova','"Rafa esqueceu o lanche em casa." Passando essa frase para o presente, fica:','["Rafa esquecerá o lanche em casa.", "Rafa esquece o lanche em casa.", "Rafa esqueceu o lanche em casa.", "Rafa vai esquecer o lanche em casa."]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-p10','portugues','Tempos verbais','prova','"No próximo sábado, a turma ______ outro piquenique." Qual palavra completa a frase no futuro?','["fez", "faz", "fará", "fazia"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-p11','portugues','Ortografia: letra S no início de palavras; SS e S entre vogais','prova','Em qual palavra o S tem som de Z?','["sábado", "sozinho", "sanduíche", "casa"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-p12','portugues','Ortografia: letra S no início de palavras; SS e S entre vogais','prova','Qual palavra está escrita de forma ERRADA?','["pasear", "massa", "sapato", "vaso"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd');
insert into gabarito (questao_id,correta,explicacao) values
  ('juju-port-p01',1,'O texto diz: "a turma do 3º ano fez um piquenique no parque".'),
  ('juju-port-p02',2,'Rafa esqueceu o lanche e ficou sozinho, triste, embaixo da árvore.'),
  ('juju-port-p03',0,'Clara percebeu que o amigo estava triste e dividiu o sanduíche com ele.'),
  ('juju-port-p04',3,'Ele disse "Obrigado, Clara!" sorrindo. Isso mostra alegria e gratidão.'),
  ('juju-port-p05',1,'O narrador conta quem falou e como falou. Essa parte vem depois do segundo travessão.'),
  ('juju-port-p06',2,'O ponto de exclamação mostra emoção. Clara falou com alegria e entusiasmo.'),
  ('juju-port-p07',3,'"Sentou" é uma ação. Árvore e sanduíche são nomes, e triste é como a pessoa está.'),
  ('juju-port-p08',0,'O verbo é "dividiu". O nome dele, o infinitivo, é dividir, terminado em -ir.'),
  ('juju-port-p09',1,'"Esquece" mostra a ação acontecendo agora. "Esqueceu" é passado e "esquecerá" é futuro.'),
  ('juju-port-p10',2,'"Fará" mostra algo que ainda vai acontecer. "No próximo sábado" indica o futuro.'),
  ('juju-port-p11',3,'Em "casa", o S está entre vogais e tem som de Z. Nas outras, o S está no início e soa "sss".'),
  ('juju-port-p12',0,'O certo é "passear", com SS, porque o som de "sss" está entre vogais. As outras estão certas.');
commit;
