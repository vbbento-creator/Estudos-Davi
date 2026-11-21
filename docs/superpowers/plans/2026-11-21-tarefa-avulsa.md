# 2.6 Tarefa avulsa — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pai ou mãe criam, na Agenda, uma tarefa que vale só para um dia.

**Architecture:** Coluna `tarefas.ate` (último dia, opcional). Avulsa = `base = ate = dia`, `modo = 'todos'`, `dias_semana = null`. `responsaveis()` devolve vazio depois de `ate`; o resto (agenda, tarefas do dia, marcar, decidir, trocar) já passa por ela. App: formulário inline na Agenda, Remover, etiqueta, cadastro com "Encerradas".

**Tech Stack:** Postgres/Supabase (plpgsql, RLS), `index.html` (JS puro + supabase-js), testes SQL rodados com `supabase/testes/roda.mjs` (PGlite).

**Spec:** `docs/superpowers/specs/2026-11-21-tarefa-avulsa-design.md`

## Global Constraints
- Banco de produção: nada é aplicado no Supabase nem enviado ao GitHub sem confirmação da pessoa usuária.
- Migração 11 entra no ar junto com o novo `index.html`.
- Textos da tela em português, no tom das telas existentes.
- Tarefas não se apagam: remover = `ativa = false`.
- Janela de criação: de `hoje − 7` a `hoje + 27`; dia pausado não permite.

## Review Focus
- Avulsa criada para hoje e o teto da semana já cheio: validar credita 0, como qualquer tarefa (teste 09, caso teto).
- Avulsa num dia passado (≥ hoje − 7): pai marca como feita e valida; a criança não consegue marcar além de ontem (teste 09).
- Remover depois que uma criança marcou: o botão não aparece; se a tarefa for desativada pelo cadastro, a linha marcada continua na Agenda (teste 09, caso desativar).
- Editar no cadastro uma avulsa: precisa manter `base = ate` (o formulário reduzido grava os dois).
- Criança tenta inserir tarefa direto pela API: RLS recusa (teste 09).

---

### Task 1: Banco — migração 11 e testes

**Files:**
- Create: `supabase/migrations/20261121_11_tarefa_avulsa.sql`
- Create: `supabase/testes/09_testes_tarefa_avulsa.sql`

**Interfaces:**
- Produces: `tarefas.ate date null`, constraint `tarefas_ate_check (ate is null or ate >= base)`; `responsaveis(p_tarefa bigint, d date) returns uuid[]` com a mesma assinatura, devolvendo `'{}'` quando `t.ate is not null and d > t.ate`.

- [ ] **Step 1: Escrever `09_testes_tarefa_avulsa.sql`** no padrão do `08_testes_metade.sql` (cabeçalho `\set`/`\pset`, `t.erro`, `t.como`, `ids`, rótulos com o esperado). Dados: tarefa avulsa `AV` (20 pts, Johann e Juju, `base = ate = h`), avulsa `ONT` (Johann, `base = ate = h − 3`), avulsa `PZ` (Johann, `base = ate = h + 2`, dia pausado via `pausas`), avulsa `RM` (Johann, hoje). Casos:
  1. `agenda_tarefas(johann, h−1, h+1)` traz `AV` só em `h` (1 linha); idem para Juju.
  2. `tarefas_do_dia(johann, h+1)` não traz `AV`.
  3. Johann marca `AV` hoje; pai valida: rendeu 20; Juju marca e pai dá metade (`enrolou`): rendeu 10.
  4. `ONT`: Johann marcar → ERRO (prazo); pai `marcar_tarefa(ONT, h−3, 'feito', johann)` OK e valida → rendeu 20.
  5. `PZ` no dia pausado: `responsaveis` vazio, agenda não traz.
  6. Teto: com o teto cheio (como no caso 9 do teste 08), validar uma avulsa nova rende 0.
  7. `RM` desativada sem marcação some da agenda; avulsa marcada e depois desativada continua aparecendo.
  8. `insert ... ate = base − 1` → ERRO (check).
  9. Como Johann, `insert into tarefas` → ERRO (RLS).
  10. Tarefa comum sem `ate` continua aparecendo amanhã (sem regressão).
  11. Trocar só este dia numa avulsa (Johann → Juju não se aplica, Juju já faz): usar avulsa só do Johann e trocar para Juju → Juju aparece no dia.

- [ ] **Step 2: Rodar e ver falhar**
Run (em `supabase/testes`): `node roda.mjs 00_stub.sql ../../banco.sql 00_perfis.sql ../migrations/20261119_*.sql ../migrations/20261121_08_*.sql ../migrations/20261121_09_*.sql ../migrations/20261121_10_*.sql 09_testes_tarefa_avulsa.sql`
Expected: falha em `column "ate" does not exist`.

- [ ] **Step 3: Escrever a migração 11** (`begin; … commit;`, cabeçalho no padrão da 09): `alter table tarefas add column ate date`, constraint, `comment on column`, e `create or replace function responsaveis` copiada da versão atual (migração 08) com a condição de `ate` acrescentada na primeira linha de saída. Manter `security definer`, `search_path` e os grants da 08.

- [ ] **Step 4: Rodar de novo com a 11** (mesmo comando, `../migrations/*.sql` no lugar da lista). Expected: todos os rótulos batem com o valor esperado. Rodar também `06_testes_trocar_responsavel.sql`, `07_testes_compra_pais.sql` e `08_testes_metade.sql` com 01–11: sem diferença em relação a antes.

- [ ] **Step 5: Commit** `Tarefa avulsa: data de fim nas tarefas (migração 11) e testes`

### Task 2: App — Agenda

**Files:** Modify `index.html` (`telaAgenda` ~666, `linhaAgenda` ~633, `painelTroca` ~652, ações ~1303, `linhaTarefa` da tela Hoje da criança).

**Interfaces:**
- Consumes: `tarefas.ate`.
- Produces: `ehAvulsa(id) → boolean` (`!!S.tarefasCad.find(t => t.id === id)?.ate`); estado `S.avulsaAberta` (dia ou null); ações `avAbrir`, `avCriar`, `avRemover`.

- [ ] **Step 1:** No card do dia (só `ehResp()`): botão **+ Tarefa avulsa** quando `sel` está na janela e não é dia pausado; em dia pausado, nada (o aviso de pausa já aparece). Ao tocar, formulário inline: emoji (`✅`), nome, pontos (5), período (`PERIODO`, padrão "O dia todo"), crianças (`ckAlunos`, pré-marcadas: todas se `S.agFiltro === 'todos'`, senão a filtrada), Criar / Cancelar.
- [ ] **Step 2:** `avCriar`: valida nome e ao menos uma criança (toasts no padrão de `cTarefaSalvar`), insere `{nome, emoji, pontos, periodo, modo:'todos', alunos, base:dia, ate:dia, dias_semana:null}`, `recarregar()`, toast "Tarefa avulsa criada".
- [ ] **Step 3:** Em `linhaAgenda`, para pais: se `ehAvulsa(r.tarefa)` e nenhuma criança tem marcação nela no dia (`S.alunos.every(a => !agendaItens(a.user_id, r.dia).some(x => x.tarefa === r.tarefa && (x.status === 'feito' || x.decisao)))`), botão **Remover** → `ativa = false`.
- [ ] **Step 4:** `painelTroca`: em avulsa, esconder "Deste dia em diante" e o parágrafo explicativo.
- [ ] **Step 5:** Etiqueta `<span class="tag">avulsa</span>` no título da linha na Agenda e na tela Hoje da criança.
- [ ] **Step 6: Verificar** servindo localmente (`python -m http.server 8000`) e abrindo no navegador, com a pessoa usuária fazendo o login. Atenção: o app aponta para produção, então criar avulsa só depois da migração aplicada. Antes disso, só conferir que nada quebrou (`node --check` do script extraído e a tela carrega).
- [ ] **Step 7: Commit** `Tarefa avulsa na Agenda`

### Task 3: App — Cadastro

**Files:** Modify `index.html` (`formTarefa` ~1062, `possivelSemana` ~1076, `cadTarefas` ~1083, `cTarefaSalvar` ~1343).

- [ ] **Step 1:** `formTarefa` para tarefa com `ate`: etiqueta "avulsa · dd/mm"; sem modo e sem dias da semana; campo **Dia** (`${p}-base`) no lugar de "Começa em". `cTarefaSalvar` grava `ate = base` quando a tarefa tem `ate`, e não manda `modo`/`dias_semana`.
- [ ] **Step 2:** `cadTarefas`: lista principal = tarefas sem `ate` ou com `ate >= hoje`; tarefas com `ate < hoje` num `<details><summary>Encerradas (n)</summary>` no fim do card.
- [ ] **Step 3:** `possivelSemana` ignora tarefas com `ate`.
- [ ] **Step 4: Commit** `Cadastro: avulsas com etiqueta e lista de encerradas`

### Task 4: Docs e entrada no ar

**Files:** `README.md`, `PENDENCIAS.md`.

- [ ] **Step 1:** README: item 11 na lista de migrações (aplicar junto com o `index.html`), regra "Tarefa avulsa" nas regras principais, `09_testes_tarefa_avulsa.sql` em Testes. PENDENCIAS: 2.6 sai das ideias e entra em Feito; testar avulsa no uso real.
- [ ] **Step 2:** Pedir confirmação; aplicar a 11 (`apply_migration`); conferir lendo (coluna, função); pedir confirmação do push; `git push`.
- [ ] **Step 3: Commit** `Docs: 2.6 tarefa avulsa`
