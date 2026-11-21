-- Migração 22 — questões de treino e de prova de Matemática da Juju (P2 do 3º ano, prova 04/12/2026).
-- Conteúdo da apostila: Unidade 12 (dividir e multiplicar, tabela) e Unidade 13 (massa, capacidade, comprimento,
-- dobro de receita, preço por metro). Números e situações novos.
-- Questões criadas do zero; o material da escola foi só inspiração. Só insere dados.
begin;
insert into questoes (id,materia,topico,tipo,enunciado,alternativas,aluno) values
  ('juju-mat-t01','matematica','Unidade 12: dividir e multiplicar','treino','Mamãe vai dividir 24 balas igualmente entre 4 crianças. Quantas balas cada uma recebe?','["8", "6", "20", "28"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t02','matematica','Unidade 12: dividir e multiplicar','treino','Quanto é 45 ÷ 5?','["9", "8", "40", "50"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t03','matematica','Unidade 12: dividir e multiplicar','treino','Quanto é 7 × 8?','["54", "15", "56", "63"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t04','matematica','Unidade 12: dividir e multiplicar','treino','Uma caixa tem 6 ovos. Quantos ovos há em 9 caixas?','["15", "45", "63", "54"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t05','matematica','Unidade 12: dividir e multiplicar','treino','Quanto é 50 ÷ 10?','["5", "10", "40", "500"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t06','matematica','Unidade 12: dividir e multiplicar','treino','Pedro vai dividir 17 figurinhas igualmente entre 3 amigos. O que acontece?','["Cada um recebe 6 e sobra 1", "Cada um recebe 5 e não sobra nada", "Cada um recebe 5 e sobram 2", "Cada um recebe 4 e sobram 5"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t07','matematica','Unidade 12: dividir e multiplicar','treino','Qual multiplicação tem o mesmo resultado que 36 ÷ 3?','["6 × 6", "4 × 3", "5 × 3", "2 × 5"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t08','matematica','Unidade 13: Restaurante do "Chef Gourmet"','treino','No estoque do restaurante há 13 kg de batata e 11 kg de cenoura. Quantos quilos há ao todo?','["24 kg", "2 kg", "22 kg", "34 kg"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t09','matematica','Unidade 13: Restaurante do "Chef Gourmet"','treino','Na balança, um saco de feijão de 5 kg ficou em equilíbrio. Quais pesos podem estar do outro lado?','["3 kg + 3 kg", "1 kg + 1 kg + 1 kg", "8 kg", "3 kg + 1 kg + 1 kg"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t10','matematica','Unidade 13: Restaurante do "Chef Gourmet"','treino','Uma receita usa 2 copos de leite para 10 porções. Quantos copos são precisos para fazer o dobro, 20 porções?','["2", "3", "4", "10"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t11','matematica','Unidade 13: Restaurante do "Chef Gourmet"','treino','Uma receita leva 50 gramas de coco ralado. No dobro da receita, quanto coco vamos usar?','["100 gramas", "52 gramas", "25 gramas", "150 gramas"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t12','matematica','Unidade 13: Restaurante do "Chef Gourmet"','treino','Cada metro de tecido custa 15 reais. Quanto custam 4 metros?','["19 reais", "45 reais", "30 reais", "60 reais"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t13','matematica','Situações-problema com as 4 operações','treino','Na gincana, 42 crianças formaram 6 equipes com o mesmo número de crianças. Quantas crianças há em cada equipe?','["6", "7", "8", "36"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t14','matematica','Situações-problema com as 4 operações','treino','Ana tinha 85 figurinhas e deu 27 para o irmão. Com quantas ela ficou?','["58", "112", "62", "68"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t15','matematica','Situações-problema com as 4 operações','treino','A escola arrecadou 128 brinquedos no primeiro dia e 96 no segundo. Quantos brinquedos foram arrecadados ao todo?','["214", "32", "224", "234"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t16','matematica','Situações-problema com as 4 operações','treino','Cada pacote tem 8 biscoitos. Lia abriu 5 pacotes e a turma comeu 12 biscoitos. Quantos biscoitos sobraram?','["40", "13", "52", "28"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t17','matematica','Situações-problema com as 4 operações','treino','Paulo tinha 100 reais e comprou 3 livros de 20 reais cada. Quanto dinheiro sobrou?','["80 reais", "40 reais", "60 reais", "20 reais"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t18','matematica','Situações-problema com as 4 operações','treino','Um ônibus leva 40 pessoas. Quantos ônibus são precisos para levar 120 pessoas?','["3", "4", "2", "80"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t19','matematica','Medidas de massa, capacidade e comprimento','treino','Para medir a massa (o "peso") de uma melancia, usamos:','["O litro", "O metro", "O quilograma", "A hora"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t20','matematica','Medidas de massa, capacidade e comprimento','treino','1 quilograma é igual a:','["10 gramas", "1000 gramas", "100 gramas", "1 grama"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t21','matematica','Medidas de massa, capacidade e comprimento','treino','1 litro é igual a:','["1000 mililitros", "100 mililitros", "10 mililitros", "500 mililitros"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t22','matematica','Medidas de massa, capacidade e comprimento','treino','Quantos copos de 250 ml enchem uma jarra de 1 litro?','["2", "3", "5", "4"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t23','matematica','Medidas de massa, capacidade e comprimento','treino','1 metro é igual a:','["10 centímetros", "1000 centímetros", "100 centímetros", "50 centímetros"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t24','matematica','Medidas de massa, capacidade e comprimento','treino','Para saber quanto suco cabe numa garrafa, medimos a capacidade em:','["Quilogramas", "Litros", "Metros", "Centímetros"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t25','matematica','Leitura de gráficos','treino','TABELA: Fruta preferida da turma
Maçã: 8 alunos
Banana: 12 alunos
Uva: 5 alunos
Manga: 9 alunos

Qual fruta foi a mais escolhida?','["Maçã", "Uva", "Banana", "Manga"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t26','matematica','Leitura de gráficos','treino','TABELA: Fruta preferida da turma
Maçã: 8 alunos
Banana: 12 alunos
Uva: 5 alunos
Manga: 9 alunos

Quantos alunos escolheram uva?','["5", "8", "9", "12"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t27','matematica','Leitura de gráficos','treino','TABELA: Fruta preferida da turma
Maçã: 8 alunos
Banana: 12 alunos
Uva: 5 alunos
Manga: 9 alunos

Quantos alunos a mais escolheram banana do que maçã?','["20", "4", "3", "8"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-t28','matematica','Leitura de gráficos','treino','TABELA: Fruta preferida da turma
Maçã: 8 alunos
Banana: 12 alunos
Uva: 5 alunos
Manga: 9 alunos

Quantos alunos votaram ao todo?','["30", "32", "35", "34"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-p01','matematica','Unidade 12: dividir e multiplicar','prova','Foram arrecadados 84 brinquedos para dividir igualmente em 4 caixas. Quantos brinquedos vão em cada caixa?','["21", "20", "80", "88"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-p02','matematica','Unidade 12: dividir e multiplicar','prova','Uma joaninha tem 6 patas. Quantas patas têm 8 joaninhas?','["14", "42", "48", "56"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-p03','matematica','Unidade 12: dividir e multiplicar','prova','Qual destas contas NÃO tem resultado 24?','["4 × 6", "3 × 8", "48 ÷ 2", "5 × 5"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-p04','matematica','Unidade 13: Restaurante do "Chef Gourmet"','prova','Para fazer 1 bolo, o chef usa 3 ovos. Quantos ovos ele usa para fazer 4 bolos?','["7", "12", "9", "15"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-p05','matematica','Unidade 13: Restaurante do "Chef Gourmet"','prova','O chef vai guardar 18 kg de tomate em 3 caixas, com a mesma quantidade em cada uma. Quantos quilos vão em cada caixa?','["6 kg", "15 kg", "21 kg", "9 kg"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-p06','matematica','Situações-problema com as 4 operações','prova','Na festa há 6 mesas com 8 cadeiras cada. Chegaram 50 convidados. Quantos convidados ficaram sem cadeira?','["0", "8", "2", "6"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-p07','matematica','Situações-problema com as 4 operações','prova','Um livro tem 96 páginas. Juju lê 8 páginas por dia. Em quantos dias ela termina o livro?','["10", "11", "88", "12"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-p08','matematica','Medidas de massa, capacidade e comprimento','prova','Uma janela mede 1 metro e 80 centímetros de altura. Quantos centímetros são?','["180 cm", "108 cm", "81 cm", "1080 cm"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-p09','matematica','Medidas de massa, capacidade e comprimento','prova','Uma garrafa tem 2 litros de suco. Quantos copos de 500 ml dá para encher?','["2", "4", "5", "10"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-p10','matematica','Medidas de massa, capacidade e comprimento','prova','Qual destes objetos tem massa mais perto de 1 kg?','["Uma formiga", "Um elefante", "Uma pena", "Um pacote de arroz pequeno"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-p11','matematica','Leitura de gráficos','prova','GRÁFICO: Livros lidos no mês (cada ▮ = 1 livro)
Ana:  ▮▮▮▮
Beto: ▮▮
Caio: ▮▮▮▮▮▮
Duda: ▮▮▮

Quem leu menos livros?','["Ana", "Beto", "Caio", "Duda"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-mat-p12','matematica','Leitura de gráficos','prova','GRÁFICO: Livros lidos no mês (cada ▮ = 1 livro)
Ana:  ▮▮▮▮
Beto: ▮▮
Caio: ▮▮▮▮▮▮
Duda: ▮▮▮

Quantos livros Caio leu a mais do que Duda?','["2", "6", "3", "9"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd');
insert into gabarito (questao_id,correta,explicacao) values
  ('juju-mat-t01',1,'24 ÷ 4 = 6, porque 4 × 6 = 24.'),
  ('juju-mat-t02',0,'45 ÷ 5 = 9, porque 5 × 9 = 45.'),
  ('juju-mat-t03',2,'7 × 8 = 56. Dica: 7 × 8 é o mesmo que 8 + 8 + 8 + 8 + 8 + 8 + 8.'),
  ('juju-mat-t04',3,'9 × 6 = 54 ovos.'),
  ('juju-mat-t05',0,'Dividir por 10 é ver quantos grupos de 10 cabem: em 50 cabem 5.'),
  ('juju-mat-t06',2,'3 × 5 = 15. De 17 tiramos 15 e sobram 2, que não dá para dividir igualmente entre 3.'),
  ('juju-mat-t07',1,'36 ÷ 3 = 12, e 4 × 3 = 12.'),
  ('juju-mat-t08',0,'13 + 11 = 24 kg.'),
  ('juju-mat-t09',3,'Para equilibrar, o outro lado precisa ter 5 kg: 3 + 1 + 1 = 5.'),
  ('juju-mat-t10',2,'O dobro de 2 é 4: 2 + 2 = 4 copos.'),
  ('juju-mat-t11',0,'O dobro de 50 é 50 + 50 = 100 gramas.'),
  ('juju-mat-t12',3,'4 × 15 = 60 reais.'),
  ('juju-mat-t13',1,'42 ÷ 6 = 7, porque 6 × 7 = 42.'),
  ('juju-mat-t14',0,'85 − 27 = 58 figurinhas.'),
  ('juju-mat-t15',2,'128 + 96 = 224 brinquedos.'),
  ('juju-mat-t16',3,'Primeiro: 5 × 8 = 40 biscoitos. Depois: 40 − 12 = 28 sobraram.'),
  ('juju-mat-t17',1,'3 × 20 = 60 reais gastos. 100 − 60 = 40 reais sobraram.'),
  ('juju-mat-t18',0,'120 ÷ 40 = 3, porque 40 + 40 + 40 = 120.'),
  ('juju-mat-t19',2,'Massa se mede em quilogramas (kg) e gramas (g).'),
  ('juju-mat-t20',1,'1 kg = 1000 g.'),
  ('juju-mat-t21',0,'1 L = 1000 ml.'),
  ('juju-mat-t22',3,'250 + 250 + 250 + 250 = 1000 ml = 1 litro. São 4 copos.'),
  ('juju-mat-t23',2,'1 m = 100 cm.'),
  ('juju-mat-t24',1,'Capacidade (quanto cabe de líquido) se mede em litros (L) e mililitros (ml).'),
  ('juju-mat-t25',2,'A banana tem o maior número: 12 alunos.'),
  ('juju-mat-t26',0,'Na linha da uva está escrito 5 alunos.'),
  ('juju-mat-t27',1,'Banana 12, maçã 8: 12 − 8 = 4 alunos a mais.'),
  ('juju-mat-t28',3,'8 + 12 + 5 + 9 = 34 alunos.'),
  ('juju-mat-p01',0,'84 ÷ 4 = 21, porque 4 × 21 = 84.'),
  ('juju-mat-p02',2,'8 × 6 = 48 patas.'),
  ('juju-mat-p03',3,'5 × 5 = 25. As outras dão 24.'),
  ('juju-mat-p04',1,'4 × 3 = 12 ovos.'),
  ('juju-mat-p05',0,'18 ÷ 3 = 6 kg em cada caixa.'),
  ('juju-mat-p06',2,'6 × 8 = 48 cadeiras. 50 − 48 = 2 convidados ficaram sem cadeira.'),
  ('juju-mat-p07',3,'96 ÷ 8 = 12 dias, porque 8 × 12 = 96.'),
  ('juju-mat-p08',0,'1 metro = 100 cm. 100 + 80 = 180 cm.'),
  ('juju-mat-p09',1,'1 litro enche 2 copos de 500 ml. 2 litros enchem 4 copos.'),
  ('juju-mat-p10',3,'Um pacote de arroz pequeno costuma ter 1 kg. A formiga e a pena são leves demais, e o elefante é pesado demais.'),
  ('juju-mat-p11',1,'Beto tem só 2 ▮, o menor número.'),
  ('juju-mat-p12',2,'Caio leu 6 e Duda leu 3: 6 − 3 = 3 livros a mais.');
commit;
