# Pendências e ideias do Cofrinho

Situação conferida no banco de produção em 21/11/2026.

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

## 2. Ideias novas (a desenvolver)

### 2.1 Alterar o responsável pela tarefa ✅ feito em 21/11 (falta aplicar a migração 08 e publicar)
- Na **Agenda**, pai ou mãe tocam em **Trocar** numa tarefa ainda não marcada, escolhem a criança e **Só este dia** ou **Deste dia em diante**.
- Revezamento, deste dia em diante: o revezamento **recomeça pela criança escolhida**. Uma troca de um dia só, feita antes, continua valendo.
- "Todos": a criança escolhida faz **no lugar** da outra. Só dá para passar para quem ainda não faz essa tarefa no dia.
- Não dá para trocar um dia que a criança já marcou. O "Trocar o responsável de um dia" saiu de Cadastros.
- Banco: migração `20261121_08_trocar_responsavel.sql` (só acrescenta; o app antigo continua funcionando). Testes: `06_testes_trocar_responsavel.sql`.

### 2.2 Validar a tarefa pela metade
- **Ideia:** além de "validado" e "rejeitado", uma terceira decisão, **"validado pela metade"**, para quando a criança fez reclamando ou enrolou para fazer. Credita 50% dos pontos.
- **Decidido:**
  - Pai ou mãe escolhem o motivo: **reclamou** ou **enrolou**, com comentário opcional. A criança vê o motivo.
  - A criança pode abrir recurso contra a metade, como já pode contra a rejeição.
  - No teto semanal (490) conta só a metade creditada.
- **Exige:** migração no banco (`tarefa_dia.decisao`, `decidir_tarefa`, `resolver_recurso`) e publicar junto com o novo `index.html`.

### 2.3 Pai e mãe lançarem compras/gastos ✅ feito em 21/11 (falta aplicar a migração 09 e publicar)
- Em **Mais › Lançar médias e pontos › 🛍️ Compra que já aconteceu**: item da loja (custo × quantidade vira o total sugerido, editável; no jantar dividido, o jantar inteiro) ou "Outro" com descrição; data livre (qualquer dia até hoje, sem valor pré-preenchido); uma ou mais crianças.
- O total é dividido igualmente, aceitando meio ponto (95 ÷ 2 = 47,5). Sem saldo ou acima do limite, o app avisa na confirmação mas deixa lançar.
- Vira pedido já combinado (entregue) e conta no limite da semana ou do mês **da data da compra**. Na criança aparece no extrato como "Loja: …". Para desfazer: ➕ Dar pontos no Ajuste manual.
- Banco: migração `20261121_09_compra_pais.sql` (só acrescenta). Testes: `07_testes_compra_pais.sql`.

### 2.4 Escolher tema claro ou escuro ✅ feito em 21/11 (falta publicar)
- Pai e mãe escolhem em **Mais › 🎨 Tema**; as crianças, no fim da tela **Hoje** (elas não têm a aba Mais). Opções: Automático (segue o aparelho), Claro e Escuro, guardadas em cada aparelho.
- Só no app (`index.html`), não mexe no banco.

### 2.5 Missão automática
- Hoje o app já calcula o nível, mas pai ou mãe precisam tocar em "Lançar" (Mais › Lançar médias e pontos) depois do prazo. Dá para o crédito cair sozinho quando o prazo acabar.

## 3. Para ficar de olho

- **Primeiro uso real:** o app já está em uso (treinos do Johann e tarefas validadas de 18 a 20/11). Anotar aqui qualquer tela com comportamento estranho e o que apareceu.
- **Agenda dos pais:** os itens de estudo marcados sozinho aparecem só na visão da criança. Para pai e mãe, aparecem como estão no banco.
- **Botão "Não fiz":** foi retirado. O que não for marcado vira "não feito" sozinho.

## 4. Manutenção, sem urgência

- [ ] **Ligar a proteção contra senhas vazadas** no painel do Supabase (Authentication › Settings). O aviso continua aberto.
- [ ] **Apagar as cópias antigas de 18/11** (`backup_20261118` e `backup_20261118_pre_migracao`, com 8 tabelas cada) quando não forem mais necessárias. Não tem volta.
