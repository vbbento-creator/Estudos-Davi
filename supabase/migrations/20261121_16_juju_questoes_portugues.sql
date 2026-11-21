-- Migração 16 — questões de treino de Português da Juju (P2 do 3º ano, prova 27/11/2026).
-- Criadas a partir do conteúdo da apostila (Unidade 8), sem copiar os exercícios. Só insere dados.
-- ids com prefixo juju- (questoes.id é único no banco todo).
begin;
insert into questoes (id,materia,topico,tipo,enunciado,alternativas,aluno) values
  ('juju-port-t01','portugues','Interpretação de texto','treino','TEXTO: "A bicicleta do Lucas"
Lucas ganhou uma bicicleta vermelha no aniversário. No primeiro dia, caiu três vezes e ralou o joelho. Pensou em desistir, mas o avô segurou o banco da bicicleta e disse:
– Calma, vamos devagar.
No fim da tarde, Lucas já pedalava sozinho pela praça, rindo alto. O avô, sentado num banco, batia palmas.

Por que Lucas pensou em desistir?','["A bicicleta era pequena", "Caiu várias vezes e se machucou", "Estava chovendo", "O avô mandou parar"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t02','portugues','Interpretação de texto','treino','TEXTO: "A bicicleta do Lucas"
Lucas ganhou uma bicicleta vermelha no aniversário. No primeiro dia, caiu três vezes e ralou o joelho. Pensou em desistir, mas o avô segurou o banco da bicicleta e disse:
– Calma, vamos devagar.
No fim da tarde, Lucas já pedalava sozinho pela praça, rindo alto. O avô, sentado num banco, batia palmas.

Quem ajudou Lucas a aprender?','["O avô", "A mãe", "Um amigo da praça", "Ninguém"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t03','portugues','Interpretação de texto','treino','TEXTO: "A bicicleta do Lucas"
Lucas ganhou uma bicicleta vermelha no aniversário. No primeiro dia, caiu três vezes e ralou o joelho. Pensou em desistir, mas o avô segurou o banco da bicicleta e disse:
– Calma, vamos devagar.
No fim da tarde, Lucas já pedalava sozinho pela praça, rindo alto. O avô, sentado num banco, batia palmas.

Quando o avô diz "vamos devagar", ele quer dizer que:','["A bicicleta está quebrada", "Eles estão atrasados", "É para aprender com calma, sem pressa", "Lucas deve ir embora"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t04','portugues','Interpretação de texto','treino','TEXTO: "A bicicleta do Lucas"
Lucas ganhou uma bicicleta vermelha no aniversário. No primeiro dia, caiu três vezes e ralou o joelho. Pensou em desistir, mas o avô segurou o banco da bicicleta e disse:
– Calma, vamos devagar.
No fim da tarde, Lucas já pedalava sozinho pela praça, rindo alto. O avô, sentado num banco, batia palmas.

Como Lucas estava no fim da tarde?','["Triste e cansado", "Com medo da bicicleta", "Bravo com o avô", "Feliz, pedalando sozinho"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t05','portugues','Interpretação de texto','treino','TEXTO: "O caderno da Bia"
Bia tem um caderno de capa azul onde escreve as coisas boas que acontecem com ela. Ontem escreveu: "Plantei uma semente de feijão no algodão com a minha irmã." Hoje escreveu: "O feijão ainda não nasceu. Amanhã vou olhar de novo."
A mãe perguntou por que ela escreve tudo. Bia respondeu:
– Para não esquecer nunca!

Para que Bia usa o caderno azul?','["Para fazer a lição de casa", "Para guardar as lembranças boas", "Para desenhar", "Para anotar recados da mãe"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t06','portugues','Interpretação de texto','treino','TEXTO: "O caderno da Bia"
Bia tem um caderno de capa azul onde escreve as coisas boas que acontecem com ela. Ontem escreveu: "Plantei uma semente de feijão no algodão com a minha irmã." Hoje escreveu: "O feijão ainda não nasceu. Amanhã vou olhar de novo."
A mãe perguntou por que ela escreve tudo. Bia respondeu:
– Para não esquecer nunca!

O que Bia plantou com a irmã?','["Uma flor", "Uma árvore", "Uma semente de feijão", "Uma semente de milho"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t07','portugues','Interpretação de texto','treino','TEXTO: "O caderno da Bia"
Bia tem um caderno de capa azul onde escreve as coisas boas que acontecem com ela. Ontem escreveu: "Plantei uma semente de feijão no algodão com a minha irmã." Hoje escreveu: "O feijão ainda não nasceu. Amanhã vou olhar de novo."
A mãe perguntou por que ela escreve tudo. Bia respondeu:
– Para não esquecer nunca!

"Amanhã vou olhar de novo." Essa frase mostra que Bia está:','["Curiosa, esperando o feijão nascer", "Brava com o feijão", "Querendo jogar o feijão fora", "Esquecida"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t08','portugues','Interpretação de texto','treino','Um texto em que a pessoa conta coisas que viveu, para guardar suas lembranças, chama-se:','["Receita", "Convite", "Bilhete", "Memórias"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t09','portugues','Interpretação de texto','treino','"O gato andava vagarosamente em cima do muro." Isso quer dizer que o gato andava:','["Bem devagar", "Muito rápido", "Pulando", "Correndo de medo"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t10','portugues','Interpretação de texto','treino','"Sujei a manga da camisa de tinta." Nessa frase, manga é:','["Uma fruta", "A parte da roupa que cobre o braço", "Um tipo de sapato", "Uma cor"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t11','portugues','Gramática: pontuação do diálogo','treino','"– Mãe, posso brincar lá fora? – perguntou Téo."

O primeiro travessão mostra:','["O fim da história", "Uma pergunta", "O começo da fala do Téo", "O nome da mãe"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t12','portugues','Gramática: pontuação do diálogo','treino','"– Mãe, posso brincar lá fora? – perguntou Téo."

A parte "perguntou Téo" é:','["Fala da mãe", "Fala do Téo", "Uma pergunta", "A parte do narrador, que conta quem falou"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t13','portugues','Gramática: pontuação do diálogo','treino','Qual frase está pontuada corretamente?','["– Vamos ao parque? – convidou Ana.", "Vamos ao parque – convidou Ana?", "– Vamos ao parque. convidou Ana?", "Vamos, ao parque convidou – Ana."]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t14','portugues','Gramática: pontuação do diálogo','treino','"– Que susto ___ – gritou Pedro."

Qual sinal completa melhor a fala?','["?", ",", "!", ";"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t15','portugues','Gramática: pontuação do diálogo','treino','Num diálogo, quando outro personagem responde, a fala dele deve:','["Continuar na mesma linha", "Começar numa linha nova, com travessão", "Ficar entre parênteses", "Ser escrita sem pontuação"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t16','portugues','Verbos','treino','Qual destas palavras é um verbo?','["bola", "azul", "pular", "escola"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t17','portugues','Verbos','treino','"Os meninos correram até o portão." Qual palavra é o verbo?','["meninos", "até", "portão", "correram"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t18','portugues','Verbos','treino','"O galo canta de manhã." Qual é o infinitivo (o nome) desse verbo?','["cantar", "canto", "cantor", "cantava"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t19','portugues','Verbos','treino','"O pato grasna na lagoa." Qual é o infinitivo desse verbo?','["grasnado", "grasnar", "grasnou", "grasnando"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t20','portugues','Verbos','treino','Em qual frase a palavra entre aspas é um verbo?','["A \"casa\" é amarela.", "O \"sol\" está forte.", "Júlia \"desenhou\" um sol.", "Meu cachorro é \"pequeno\"."]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t21','portugues','Tempos verbais','treino','"Amanhã nós viajaremos para a praia." Em que tempo está o verbo?','["Passado", "Presente", "Futuro", "Não tem tempo"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t22','portugues','Tempos verbais','treino','"Ontem eu comi bolo de cenoura." Em que tempo está o verbo?','["Passado", "Presente", "Futuro", "Infinitivo"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t23','portugues','Tempos verbais','treino','"Agora a professora lê uma história para a turma." Em que tempo está o verbo?','["Passado", "Presente", "Futuro", "Infinitivo"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t24','portugues','Tempos verbais','treino','"Maria brinca no quintal." Passando para o passado, fica:','["Maria brincará no quintal.", "Maria vai brincar no quintal.", "Maria brinca no quintal.", "Maria brincou no quintal."]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t25','portugues','Tempos verbais','treino','"Eu guardei os brinquedos." Passando para o futuro, fica:','["Eu guardarei os brinquedos.", "Eu guardo os brinquedos.", "Eu guardava os brinquedos.", "Eu guardei os brinquedos."]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t26','portugues','Tempos verbais','treino','Qual destas frases está no futuro?','["Eu visitei minha avó.", "Eu visito minha avó.", "Eu visitarei minha avó.", "Eu visitava minha avó."]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t27','portugues','Ortografia: letra S no início de palavras; SS e S entre vogais','treino','Complete: "O pá___aro pousou na janela."','["s", "ss", "z", "ç"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t28','portugues','Ortografia: letra S no início de palavras; SS e S entre vogais','treino','Complete: "A ro___a do jardim é vermelha."','["s", "ss", "ç", "c"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t29','portugues','Ortografia: letra S no início de palavras; SS e S entre vogais','treino','Em qual palavra o S tem som de Z?','["sopa", "sala", "camisa", "sapo"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t30','portugues','Ortografia: letra S no início de palavras; SS e S entre vogais','treino','Qual palavra está escrita corretamente?','["oso", "oço", "ozo", "osso"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t31','portugues','Ortografia: letra S no início de palavras; SS e S entre vogais','treino','Como separamos as sílabas de pêssego?','["pês-se-go", "pê-sse-go", "pêss-e-go", "pê-ss-e-go"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t32','portugues','Ortografia: letra S no início de palavras; SS e S entre vogais','treino','Qual destas palavras começa com a letra S?','["cenoura", "cidade", "sorvete", "cimento"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd'),
  ('juju-port-t33','portugues','Ortografia: letra S no início de palavras; SS e S entre vogais','treino','Acrescentando um S na palavra cota, formamos:','["coisa", "costa", "conta", "cosa"]'::jsonb,'014341f0-99f3-4e14-b21d-6b4efc9bafbd');
insert into gabarito (questao_id,correta,explicacao) values
  ('juju-port-t01',1,'Ele caiu três vezes e ralou o joelho. Por isso pensou em desistir.'),
  ('juju-port-t02',0,'O avô segurou o banco da bicicleta e o acalmou.'),
  ('juju-port-t03',2,'"Devagar" quer dizer com calma. O avô queria que Lucas aprendesse aos poucos.'),
  ('juju-port-t04',3,'O texto diz que ele pedalava sozinho, "rindo alto". Isso mostra alegria.'),
  ('juju-port-t05',1,'Ela escreve as coisas boas que acontecem "para não esquecer nunca".'),
  ('juju-port-t06',2,'Ela escreveu: "Plantei uma semente de feijão no algodão".'),
  ('juju-port-t07',0,'O feijão ainda não tinha nascido, e ela quer ver se amanhã ele vai aparecer.'),
  ('juju-port-t08',3,'Nas memórias, a pessoa registra o que viveu para lembrar depois, como faz a Bia.'),
  ('juju-port-t09',0,'"Vagarosamente" vem de "vagar", que quer dizer lentidão. O gato andava devagar.'),
  ('juju-port-t10',1,'A palavra "manga" tem mais de um significado. Na frase, ela fala da camisa, então é a parte que cobre o braço.'),
  ('juju-port-t11',2,'Num diálogo, o travessão no começo indica que um personagem vai falar.'),
  ('juju-port-t12',3,'"Perguntou Téo" não é fala do Téo: é o narrador contando quem falou. Ela vem separada por travessão.'),
  ('juju-port-t13',0,'A fala começa com travessão e termina com "?", porque é pergunta. Depois vem outro travessão e o narrador.'),
  ('juju-port-t14',2,'Pedro levou um susto e gritou, então a fala mostra emoção. Para isso usamos o ponto de exclamação.'),
  ('juju-port-t15',1,'Cada fala nova começa em outra linha, com travessão. Assim o leitor sabe que outra pessoa está falando.'),
  ('juju-port-t16',2,'Verbo indica ação. "Pular" é algo que a gente faz; bola e escola são nomes, e azul é cor.'),
  ('juju-port-t17',3,'"Correram" é a ação que os meninos fizeram.'),
  ('juju-port-t18',0,'O infinitivo é o nome do verbo e termina em -ar, -er ou -ir: cantar.'),
  ('juju-port-t19',1,'Grasnar é a "voz" do pato. Como todo infinitivo, termina em -ar, -er ou -ir.'),
  ('juju-port-t20',2,'"Desenhou" é uma ação. Casa e sol são nomes, e pequeno é uma característica.'),
  ('juju-port-t21',2,'"Viajaremos" mostra algo que ainda vai acontecer. A palavra "amanhã" ajuda a perceber.'),
  ('juju-port-t22',0,'"Comi" mostra uma ação que já aconteceu, e "ontem" confirma.'),
  ('juju-port-t23',1,'"Lê" mostra a ação acontecendo agora, no presente.'),
  ('juju-port-t24',3,'"Brincou" mostra que a brincadeira já aconteceu.'),
  ('juju-port-t25',0,'"Guardarei" mostra algo que ainda vai acontecer.'),
  ('juju-port-t26',2,'"Visitarei" fala de algo que ainda vai acontecer. "Visitei" e "visitava" são passado, e "visito" é presente.'),
  ('juju-port-t27',1,'Entre vogais, para ter som de "sss", usamos SS: pássaro. Com um S só, ficaria com som de Z.'),
  ('juju-port-t28',0,'Em "rosa", o S fica entre vogais e tem som de Z. Por isso é só um S.'),
  ('juju-port-t29',2,'Em "camisa", o S está entre as vogais I e A, então tem som de Z. Nas outras, ele está no início e soa "sss".'),
  ('juju-port-t30',3,'"Osso" tem som de "sss" entre vogais, por isso se escreve com SS.'),
  ('juju-port-t31',0,'Na separação de sílabas, o SS se separa: um S fica numa sílaba e o outro S na seguinte.'),
  ('juju-port-t32',2,'Cenoura, cidade e cimento começam com som de "sss", mas são escritas com C. Só "sorvete" começa com a letra S.'),
  ('juju-port-t33',1,'co + s + ta = costa. Basta colocar o S no meio da palavra.');
commit;
