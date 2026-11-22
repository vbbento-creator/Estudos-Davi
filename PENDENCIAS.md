# Pendências e ideias do Cofrinho (backlog)

Situação conferida no banco de produção em 22/11/2026. Na próxima sessão, conferir de novo no Supabase (só lendo) o que mudou.

Última conferência (22/11, noite): desde a tarde, só entrou a validação do "Escovar os dentes · Manhã" de 22/11 do Johann e da Juju (16h17). Seguem 4 marcações esperando validação: Johann 21/11 Escovar · Noite, 22/11 Arrumar a lava-louças e Arrumar o quarto; Juju 22/11 Tirar e limpar a mesa (as três de 22/11 são de "Dia todo", marcadas entre 10h42 e 11h26, antes da migração 24). Nenhum treino ou prova novos depois das 11h40 (Juju: Matemática 90%, Geografia e História 100%); nenhuma prova valendo ainda; nenhum recurso aberto nem pedido da loja. Missões sem mudança: a Juju sem missão e a do Johann ainda é a de 19/11 (bônus bronze já lançado). Física, Inglês e Biologia do Johann seguiam com 37, 34 e 30 questões de treino.

## 1. Pendências que dependem de você

- [ ] **Períodos das tarefas (2.7, no ar desde 22/11):** toda tarefa sem período virou "Dia todo" e só abre às 18h. Mudar no cadastro as que acontecem antes (ex.: Tirar e limpar a mesa = Tarde + Noite; Arrumar o quarto = Manhã, se for de manhã). Validar a "Escovar os dentes · Noite" do Johann de 21/11 (veio da tarefa antiga da noite).
- [ ] **Próxima missão:** ao cadastrar, preencher "Começa em" e os mínimos de tarefas (padrão 70/80/90%).
- [ ] **Provas valendo da Juju:** o plano pede uma por dia (25/11 Português, 28/11 Ciências, 30/11 Inglês, 01/12 História, 02/12 Geografia, 03/12 Matemática). Cada uma precisa que pai ou mãe liberem no app naquele dia.
- [ ] **Revisar as questões novas** de Física, Inglês e Biologia em `docs/johann/questoes-revisao-3.md` (já no ar desde 22/11).
- [ ] **Ver as mensagens de motivação no uso real** (no ar desde 22/11): primeiro acesso do dia, fim de treino e de prova, tarefas do dia. Anotar na seção 3 o que aparecer de estranho.
- [x] **Questões do Johann:** todas as matérias com questões têm 50 de treino (Português 52), conferido em produção em 22/11. O bônus de "Concluir treino" dele exige 50 por matéria.
  - Redação (prova 25/11): sem questões. A prova é só sobre a leitura do livro (Quarto de Despejo) e não há material da escola (decidido em 22/11). O bônus de Concluir treino de Redação não tem como sair.
- [ ] **Médias do bimestre.** Quando saírem, lançar em Mais › Lançar médias e pontos. Se alguma ficar abaixo de 7, decidir se usa o botão "Tirar" daquela matéria.
- [ ] **Guardar as senhas da Brisa e da Juju** em lugar seguro. Elas ficaram no histórico de uma conversa anterior.
- [ ] **Telas novas no uso real.** Conferido no Chrome em 21/11/2026, logado como Pai:
  - Tarefa avulsa (criar com o filtro de uma criança, etiqueta, Trocar só "Só este dia", não aparece no dia seguinte, cadastro com Dia e sem modo, Remover) ok.
  - Painel Trocar, formulário de Compra que já aconteceu e Tema (Claro/Escuro) ok, sem gravar nada.
  - Troca confirmada no uso real em 22/11 (revezamento de "Cuidar da Kika", ver conferência no topo).
  - Falta ver no uso real (gravam pontos de verdade): ½ Metade, recurso contra metade, lançar uma compra, e a visão da criança (Hoje com etiqueta "avulsa", tema no fim do Hoje). Anotar na seção 3 o que aparecer de estranho.

## 2. Ideias a desenvolver

### Outras ideias
- Possível depois: rotina de hora em hora (pg_cron) para fechar a missão mesmo sem ninguém abrir o app; hoje não faz falta.

### Testes que ficaram por fazer
- `02_testes.sql`, `03_testes_cofrinho.sql` e `04_testes_perda_estudo.sql` precisam de um backup dos dados de produção e não foram rodados de novo depois das migrações 08 a 13. Os testes que criam os próprios dados (05 a 10) passaram com as migrações 01 a 13.

## 3. Para ficar de olho

- **Telas novas de 21/11** (ver seção 1): anotar aqui qualquer comportamento estranho e o que apareceu.
- **Agenda dos pais:** os itens de estudo marcados sozinho aparecem só na visão da criança. Para pai e mãe, aparecem como estão no banco.
- **Botão "Não fiz":** foi retirado. O que não for marcado vira "não feito" sozinho.
- **Aplicar migração pelo Claude:** a ferramenta do Supabase recusa sozinha migrações com `drop` (aconteceu com a 10). Nesses casos, aplicar pelo SQL Editor do painel.

- **Plano adiantado (21/11):** item marcado sozinho não se desmarca. Com a janela de 7 dias, os tópicos do Johann de 18/11 marcam a "Revisão final: Português e Inglês" e a "Revisão Física e Biologia" de 23/11. Decidido em 22/11: deixar como está.

## 4. Manutenção, sem urgência

- **Proteção contra senhas vazadas:** só existe no plano Pro do Supabase; o projeto está no plano gratuito (conferido em 22/11). Não dá para ligar; o aviso vai continuar aberto.
- **Aviso "Signed-In Users Can Execute SECURITY DEFINER Function"** (28 funções): aceito em 22/11. É o desenho do app: o app chama as funções, e cada uma confere por dentro quem está pedindo (ex.: criança validando tarefa recebe "Sem acesso"). Não mexer; o aviso continua aparecendo.

## 5. Feito

### 22/11/2026: mensagens de motivação (só `index.html`, publicado em 22/11)
- Cartão com o botão "Valeu!", só na visão da criança: no primeiro acesso do dia, no fim de um treino ou prova valendo (até 69%, de 70 a 90% e acima de 90%) e quando ela marca a última tarefa de casa de hoje (tarefa rejeitada não conta; não espera validação).
- 20 frases sorteadas por situação para cada criança; as da Juju são mais simples (decidido em 22/11). Primeiro acesso e tarefas: uma vez por dia em cada aparelho. As rodadas do Concluir treino ficam sem mensagem.
- Teste `testes-app/motivacao.mjs` (50 OK); `periodos`, `missao`, `avulsa`, `adiantar` e `erro-rede` continuam sem falha.

### 22/11/2026: questões de treino do Johann de Física, Inglês e Biologia (migrações 32 a 34)
- As que faltavam para 50: Física 13 (`fis-t38` a `t50`: 6 do Módulo 10 e 7 do Módulo 11), Inglês 16 (`ing-t35` a `t50`: 3 de question tag, 7 de relative pronouns e 6 de leitura, com dois textos inventados) e Biologia 20 (`bio-t31` a `t50`: 8 de 16.1 e 12 de 16.2). Criadas do zero a partir das apostilas (PDFs do CamScanner de 17/11 em Downloads); nada copiado do livro.
- Resposta certa nas 50 de treino, contando as antigas: Física 15/11/12/12 (a posição "a" já tinha 15), Inglês 12/13/13/12, Biologia 12/12/13/13.
- Testadas no PGlite com todas as migrações (`15_testes_questoes_johann_3.sql`) e conferidas em produção depois de aplicar: 50 de treino e 12 de prova em cada matéria, md5 das novas igual ao do banco local, nenhum enunciado repetido, 688 questões do Johann no total. Revisão em `docs/johann/questoes-revisao-3.md`.
- Observação: várias questões antigas de Inglês (`ing-t01` a `t09`, de 17/11) repetem frases dos exercícios da apostila. Decidido em 22/11: ficam como estão.

### 22/11/2026: questões do Johann de Espanhol, Química, Arte e Música (migrações 28 a 31)
- 50 de treino e 12 de prova em cada matéria, criadas do zero a partir das apostilas (PDFs do CamScanner de 22/11, 13h50 a 15h38, em Downloads). O material é só inspiração; não se copiam exercícios nem textos do livro.
- Espanhol (prova 25/11): Clases 4 a 6 e Cuba, nos 3 tópicos cadastrados (variantes 27, leitura 20, Cuba 15). Enunciado em espanhol e explicação em português; textos de leitura inventados. Superlativo, heterotónicos e sustantivos ficaram de fora (decidido em 22/11).
- Química (prova 26/11): Módulos 11 e 12 (introdução, tipos de carbono e fórmulas, classificação de cadeias e aromáticos). As fórmulas vêm em texto, com a ramificação entre parênteses.
- Arte (prova 01/12): Ciberarte, Bioarte e História da Arte, esta com a "Tabela de História da Arte" do anexo.
- Música (prova 01/12): p. 174 a 179, nos 8 tópicos cadastrados; figuras e sinais pelo nome (sem partitura).
- A resposta certa fica 15 ou 16 vezes em cada posição por matéria.
- Testadas no PGlite com todas as migrações (`14_testes_questoes_johann_2.sql`) e conferidas em produção: 50 + 12 por matéria, md5 de cada matéria igual ao do banco local, todos os tópicos com questão, as 391 questões anteriores do Johann intactas.
- Revisão em `docs/johann/questoes-revisao-2.md`.

### 22/11/2026: questões do Johann de Matemática, Geografia e História (migrações 25 a 27)
- 50 de treino e 12 de prova em cada matéria, criadas do zero a partir das apostilas (PDFs do CamScanner de 22/11 em Downloads), com níveis variados (conceito, cálculo direto e situações-problema). O material é só inspiração; não se copiam exercícios nem textos do livro.
- Matemática (prova 26/11): Módulo 14, trigonometria no triângulo retângulo, nos 6 tópicos cadastrados. Os valores da tabela trigonométrica e de √2 e √3 vêm no enunciado.
- Geografia (prova 27/11): Módulo 8, só Japão (36 de treino) e Antártida (14), como os tópicos cadastrados; Oceania ficou de fora (decidido em 22/11).
- História (prova 27/11): Módulo 13, nos 6 tópicos cadastrados.
- A resposta certa fica 15 ou 16 vezes em cada posição (a, b, c, d) por matéria.
- Testadas no PGlite com todas as migrações (`13_testes_questoes_johann.sql`) e conferidas em produção: 50 + 12 por matéria, impressão digital (md5) de cada matéria igual à do banco local, todos os tópicos com questão, as 205 questões antigas do Johann intactas.
- Ids `mat-`, `geo-` e `hist-` (`tNN` treino, `pNN` prova). Revisão em `docs/johann/questoes-revisao.md`.

### 22/11/2026: tarefa com vários períodos no dia (2.7, migração 24 + `index.html`)
Design e plano em `docs/superpowers/` (`2026-11-22-tarefa-varios-periodos`).
- Uma tarefa tem um ou mais períodos (Manhã, Tarde, Noite) ou "Dia todo". Cada período é marcado, validado (inteira, ½, rejeitar) e contestado separado e vale os pontos da tarefa. A lista mostra uma linha por tarefa, com um botão por período.
- Não dá para adiantar: no dia de hoje, tarde abre às 12h, noite e Dia todo às 18h (Brasília), e o banco recusa antes. Ontem continua livre. Trocar quem faz vale para o dia inteiro. Na missão, cada período conta como uma tarefa.
- "Escovar os dentes (manhã)" virou "Escovar os dentes" (manhã + noite); a de noite foi desativada e a marcação dela (Johann, 21/11) passou para a noite da nova. Lançamentos antigos de escovar de manhã ganharam o período na referência (3).
- Testes: `12_testes_periodos.sql` (todas as linhas como o esperado), 05 a 11 com a mesma saída de antes (com `00_relogio_noite.sql`), telas `periodos.mjs` (40 OK) e as outras sem falha.
- Aplicada pelo SQL Editor e conferida lendo: coluna antiga apagada, chave nova, 24 marcações e 17 lançamentos de tarefa como antes. App publicado logo em seguida.
- Para ficar de olho: na Agenda dos pais, "Marcar como feita" num período de hoje ainda fechado dá o aviso "abre às 18h"; aba antiga do app aberta precisa ser recarregada; o primeiro recurso de verdade num período (confirmar que os botões mostram a decisão daquele período).

### 22/11/2026: faxina e avisos do Supabase (sem código)
- Cópias `backup_20261118` e `backup_20261118_pre_migracao` apagadas pelo SQL Editor (avaliado antes: idênticas e com tudo presente nas tabelas atuais). Saíram os 16 avisos de "RLS sem política".
- Proteção contra senhas vazadas: só no plano Pro; o projeto está no gratuito. Fica sem ligar.
- Aviso das 28 funções `SECURITY DEFINER`: aceito (ver seção 4).
- Plano adiantado do Johann (revisões de 23/11): fica como está.

### 22/11/2026: erro de conexão em português (só `index.html`)
- Quando o pedido nem chega ao servidor, o aviso dizia "Failed to fetch" (aconteceu ao trocar uma tarefa; o pedido não chegou ao Supabase e nada foi gravado). Agora diz "Sem conexão com o servidor. Tente de novo." (vale para Chrome, Firefox e Safari). Erros do banco continuam como antes.
- Teste `testes-app/erro-rede.mjs` (6 OK); `adiantar`, `missao` e `avulsa` continuam OK.

### 21/11/2026: plano de estudo marca o que a criança adiantou (só `index.html`)
Design e plano em `docs/superpowers/` (`2026-11-21-adiantar-plano`).
- O que a criança fez **até 7 dias antes** marca sozinho o item do plano, **um item por atividade**: treino adiantado → próximo item de treino da matéria (com a nota mínima do item); tópico concluído adiantado → próximo item de estudo da matéria. No próprio dia, nada mudou. Prova valendo continua só no dia.
- O item mostra "Marcado sozinho: você adiantou em DD/MM". Na Agenda da criança, em dia futuro, a frase virou "Tarefas de casa: você marca só hoje e ontem.".
- Nada é gravado no banco; sem migração. Teste `testes-app/adiantar.mjs` (27 OK); `missao.mjs` e `avulsa.mjs` continuam OK.
- Conferido com os dados reais (só lendo): Juju, treino de 21/11 → "🎯 Português: treino" de 23/11; Johann, tópicos de 18/11 → Física e Biologia de 19/11 e as duas revisões de 23/11.

### 21/11/2026: treino e prova valendo no plano da Juju (migração 23)
- 12 itens novos no fim dos dias de 23/11 a 03/12: 6 treinos (Português 23, 24 e 26/11; Ciências 27/11; Inglês 29/11; Matemática 03/12) e 6 provas valendo, uma por matéria e no máximo uma por dia. Os itens que já existiam ficaram como estavam e nas mesmas posições.
- De 1 a 4 itens por dia (4 só em 29 e 30/11). História e Geografia ficaram sem item de treino: a "Revisão final: História e Geografia" (02/12) é marcada com o treino das duas.
- O app marca sozinho: "<Matéria>: treino" com um treino daquela matéria no dia (qualquer nota); "prova valendo" com qualquer prova feita no dia (o app não olha a matéria; por isso, uma por dia).
- Testada no PGlite com as migrações 01 a 23 e a 23 rodada duas vezes (teste `11_testes_plano_juju.sql`) e conferida em produção: 13 dias, 37 itens, impressão digital (md5) igual à do banco local.

### 21/11/2026: questões da Juju para todas as matérias da P2 (migrações 17 a 22)
- Treino e prova de todas as matérias, criados do zero a partir das apostilas (PDFs do CamScanner em Downloads). O material é só inspiração; não se copiam exercícios nem textos do livro.

| Matéria | Prova | Treino | Prova (tipo `prova`) | Migração |
|---|---|---|---|---|
| Português | 27/11 | 33 | 12 | 16 e 17 |
| Ciências | 01/12 | 28 | 12 | 18 |
| Inglês | 02/12 | 28 | 12 | 19 |
| História | 03/12 | 28 | 12 | 20 |
| Geografia | 03/12 | 29 | 12 | 21 |
| Matemática | 04/12 | 28 | 12 | 22 |

- História vai até a página 32 da apostila (migrações internas, p. 33 em diante, não cai).
- Matemática: "Leitura de gráficos" usa tabelas e gráficos de barras feitos com ▮, porque o app só mostra texto.
- Todas as questões para revisar em `docs/juju/questoes-revisao.md`.
- Testadas no PGlite com as migrações 01 a 22 e conferidas em produção: a impressão digital (md5) de cada matéria é igual à do banco local; todos os tópicos batem; as 205 questões do Johann ficaram intactas.
- Ids: `juju-<matéria>-tNN` (treino) e `juju-<matéria>-pNN` (prova), porque `questoes.id` é único no banco todo.

### 21/11/2026: questões de treino de Português da Juju (migração 16)
- 33 questões (`juju-port-t01` a `t33`), criadas a partir do conteúdo da apostila (Unidade 8, "Muito prazer, Emília!"), sem copiar os exercícios. Distribuição: Interpretação de texto 10 (dois textos curtos inventados), Pontuação do diálogo 5, Verbos 5, Tempos verbais 6, Ortografia S/SS 7.
- Testada no PGlite com as migrações 01 a 16 e conferida no banco de produção: 33 questões, 33 gabaritos, todos os tópicos batem com os cadastrados.

### 21/11/2026: matérias e plano de estudo da Juju (migração 14)
- A partir do cronograma da P2 do 3º ano (Colégio Objetivo DF): Português (27/11), Ciências (01/12), Inglês (02/12), História e Geografia (03/12, como duas matérias) e Matemática (04/12), com os 27 tópicos do PDF.
- Bônus de Concluir treino da Juju com mínimo de 25 questões por matéria (migração 15; o Johann continua com 50).
- Plano de estudo de 22/11 a 04/12, com 1 a 3 itens por dia e sem treino (ela ainda não tem questões). Os itens que citam uma matéria são marcados sozinhos quando ela conclui um tópico daquela matéria no dia.

### 21/11/2026: ideia 2.5 missão automática (migrações 12 e 13 + `index.html`)
Design e plano em `docs/superpowers/` (`2026-11-21-missao-automatica`).
- O nível da missão passa a ser calculado no banco (`missao`) e o bônus **cai sozinho** depois do prazo, quando alguém abre o app (`fechar_missoes`). Sai o botão Lançar da missão; no lugar, o estado (lançada, esperando N tarefas, nenhum nível…).
- **Tarefas de casa contam:** cada nível exige uma porcentagem das tarefas validadas de "Começa em" até o dia do prazo (padrão 70/80/90; metade vale 0,5). Tópicos, treinos e provas continuam automáticos; médias da escola ficam fora.
- Com tarefas, o fechamento espera 2 dias depois do prazo e nenhuma tarefa ou recurso do período sem decisão; enquanto isso, aviso em "Precisa de você".
- Corrigido o risco de lançar duas vezes ao salvar de novo o mesmo prazo (a referência agora é a data e hora do prazo em São Paulo).
- Migrações 12 e 13 (a 13 impede o botão Lançar do app antigo de lançar a missão de novo), testes 10 e `testes-app/missao.mjs`.
- Conferido no Chrome como Pai (21/11): o bônus da missão do Johann de 19/11 entrou sozinho ao abrir o app, uma vez só (bronze +150, data 19/11); Mais › Lançar mostra "Lançada ✓ Bronze +150" sem botão; Cadastros › Pontos tem "Começa em" e os mínimos 70/80/90.

### 21/11/2026: ideia 2.6 tarefa avulsa (migração 11 + `index.html`)
Design e plano em `docs/superpowers/` (`2026-11-21-tarefa-avulsa`).
- Na **Agenda**, pai ou mãe tocam em **+ Tarefa avulsa** no dia selecionado: nome, emoji, pontos, período e crianças (cada uma faz a sua). Vale só naquele dia: de 7 dias atrás até o fim da Agenda, fora de dia pausado.
- Marcar, validar, ½ metade, rejeitar, recurso e teto semanal funcionam como em qualquer tarefa. **Remover** enquanto ninguém marcou; **Trocar** só "Só este dia". Etiqueta "avulsa" para pais e crianças.
- Cadastro: avulsa com etiqueta e campo Dia; as que já passaram ficam em **Encerradas**; o resumo semanal não conta avulsas.
- Banco: `tarefas.ate` (data de fim opcional) e `responsaveis()` ignorando os dias depois dela. Migração 11, testes 09 e `testes-app/avulsa.mjs`.

### 21/11/2026: ideias 2.1 a 2.4 (migrações 08, 09 e 10 + `index.html`)
Design e plano em `docs/superpowers/`.
- **2.1 Trocar quem faz a tarefa:** na **Agenda**, pai ou mãe tocam em **Trocar** numa tarefa ainda não marcada, escolhem a criança e **Só este dia** ou **Deste dia em diante**. Revezamento, deste dia em diante: recomeça pela criança escolhida (uma troca de um dia feita antes continua valendo). "Todos": a escolhida faz no lugar da outra, só se ainda não faz a tarefa no dia. Não se troca dia já marcado. Saiu de Cadastros. Migração 08, testes 06.
- **2.2 Validar pela metade:** **Rejeitar · ½ Metade · Validar** em Aprovar e na Agenda; motivo **Reclamou** ou **Enrolou** + comentário opcional; 50% dos pontos; a criança vê e pode recorrer. Recurso contra a metade: validar inteira ou manter a metade; contra rejeição, também pode virar metade. No teto conta só o creditado. Migração 10, testes 08.
- **2.3 Compra lançada pelos pais:** **Mais › Lançar médias e pontos › 🛍️ Compra que já aconteceu**; item da loja (total sugerido editável) ou "Outro"; data livre até hoje; total dividido igualmente entre as crianças marcadas (aceita meio ponto); avisa saldo negativo e limite, mas deixa; conta no limite da data da compra; desfazer com ➕ Dar pontos. Migração 09, testes 07.
- **2.4 Tema:** Automático, Claro ou Escuro, guardado em cada aparelho. Pais em **Mais › 🎨 Tema**; crianças no fim da tela **Hoje**. Só app.
