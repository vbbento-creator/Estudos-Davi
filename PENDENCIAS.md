# Pendências e ideias do Cofrinho (backlog)

Situação conferida no banco de produção em 21/11/2026. Na próxima sessão, conferir de novo no Supabase (só lendo) o que mudou.

## 1. Pendências que dependem de você

- [ ] **Lançar a missão do Johann** (prazo era 19/11, 22h). Ainda não há nenhum lançamento de missão para ele. Se ele atingiu bronze (150), prata (250) ou ouro (400), lançar em Mais › Lançar médias e pontos.
- [ ] **Fotos das questões de treino.** O bônus de "Concluir treino" exige 50 questões por matéria.
  - Língua Portuguesa: 52 (ok)
  - Física: 37 (faltam 13)
  - Inglês: 34 (faltam 16)
  - Biologia: 30 (faltam 20)
  - Arte, Espanhol, Geografia, História, Matemática, Música, Química e Redação: 0 (faltam 50 em cada)
- [ ] **Médias do bimestre.** Quando saírem, lançar em Mais › Lançar médias e pontos. Se alguma ficar abaixo de 7, decidir se usa o botão "Tirar" daquela matéria.
- [ ] **Guardar as senhas da Brisa e da Juju** em lugar seguro. Elas ficaram no histórico de uma conversa anterior.
- [ ] **Cadastrar as matérias da Juju.** Hoje ela não tem nenhuma e só ganha pontos com tarefas.
- [ ] **Testar a tarefa avulsa no uso real** (Agenda › + Tarefa avulsa): criar, marcar, validar, Remover e ver no cadastro em "Encerradas" no dia seguinte.
- [ ] **Testar as telas novas no uso real** (no ar desde 21/11, testadas só no banco, não no navegador): Trocar na Agenda, ½ Metade (Aprovar e Agenda), recurso contra metade, Compra que já aconteceu (com aviso de saldo negativo e de limite) e Tema (Mais e fim da tela Hoje da criança). Anotar na seção 3 o que aparecer de estranho.

## 2. Ideias a desenvolver

### 2.5 Missão automática
- **Hoje:** o app calcula o nível (bronze, prata, ouro) a partir de `grupos.config` do grupo `estudos` (`prazo`, `materias`, `treino_min`, `prova_min`, `prova_qtd`, `pontos`), mas pai ou mãe precisam tocar em "Lançar" (Mais › Lançar médias e pontos) depois do prazo. O lançamento usa `origem = 'nivel'` e `origem_ref = 'meta:<prazo>'`.
- **Ideia:** o crédito cair sozinho quando o prazo acabar.
- **Em aberto (perguntar antes de programar):**
  - Como dispara: rotina agendada no banco (pg_cron) ou quando alguém abre o app depois do prazo?
  - O cálculo do nível hoje está no app (`calcMeta()` no `index.html`). Passar para o banco, para não depender do aparelho?
  - Pai ou mãe ainda conferem antes (ex.: aviso "Missão lançada: prata, +250") ou cai direto?
  - O que acontece se a missão de 19/11 do Johann ainda não tiver sido lançada quando isso entrar no ar?
- **Exige:** banco (função e talvez agendamento) + app.

### Testes que ficaram por fazer
- `02_testes.sql`, `03_testes_cofrinho.sql` e `04_testes_perda_estudo.sql` precisam de um backup dos dados de produção e não foram rodados de novo depois das migrações 08 a 10. Os testes que criam os próprios dados (05 a 08) passaram com as migrações 01 a 10.

## 3. Para ficar de olho

- **Telas novas de 21/11** (ver seção 1): anotar aqui qualquer comportamento estranho e o que apareceu.
- **Agenda dos pais:** os itens de estudo marcados sozinho aparecem só na visão da criança. Para pai e mãe, aparecem como estão no banco.
- **Botão "Não fiz":** foi retirado. O que não for marcado vira "não feito" sozinho.
- **Aplicar migração pelo Claude:** a ferramenta do Supabase recusa sozinha migrações com `drop` (aconteceu com a 10). Nesses casos, aplicar pelo SQL Editor do painel.

## 4. Manutenção, sem urgência

- [ ] **Ligar a proteção contra senhas vazadas** no painel do Supabase (Authentication › Settings). O aviso continua aberto.
- [ ] **Apagar as cópias antigas de 18/11** (`backup_20261118` e `backup_20261118_pre_migracao`, com 8 tabelas cada) quando não forem mais necessárias. Não tem volta. Elas também geram 16 avisos de "RLS sem política" no Supabase.

## 5. Feito

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
