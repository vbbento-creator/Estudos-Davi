# 2.5 Missão automática — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** o nível da missão passa a ser calculado no banco (tópicos, treinos, provas e, agora, tarefas de casa validadas) e o bônus cai sozinho depois do prazo, quando alguém da família abre o app.

**Architecture:** migração 12 cria `_missao(aluno)` (cálculo, interno), `missao(aluno)` (leitura com `pode_ver`) e `fechar_missoes()` (lança as vencidas). O `index.html` chama `fechar_missoes` ao carregar, troca o cálculo local de `calcMeta` pelo resultado de `missao`, tira o botão Lançar da missão e ganha os campos novos em Cadastros › Pontos.

**Tech Stack:** Postgres/Supabase (plpgsql, RLS), PGlite para testes (`supabase/testes/roda.mjs`), app em um único `index.html` (JS sem build), teste de telas em Node `vm` (`testes-app/`).

**Spec:** `docs/superpowers/specs/2026-11-21-missao-automatica-design.md`

## Global Constraints
- Banco é produção: aplicar migração, apagar qualquer coisa e `git push` só com confirmação do usuário.
- Migração sem `drop`. Se a ferramenta recusar, passar o passo a passo para o SQL Editor e conferir lendo.
- Migração 12 e o novo `index.html` entram no ar juntos.
- Funções novas: `security definer set search_path = public`; `revoke execute ... from public, anon`; `grant ... to authenticated`; `_missao` revogada também de `authenticated`.
- Referência do lançamento: `'meta:' || to_char(prazo at time zone 'America/Sao_Paulo', 'YYYY-MM-DD HH24:MI')`; `lancada` também reconhece a referência antiga `'meta:' || (config->>'prazo')`.
- Mínimos de tarefas padrão: bronze 70, prata 80, ouro 90. Validada = 1, metade = 0,5, resto = 0. Sem tarefas no período = critério cumprido. Sem `inicio` = sem critério de tarefas.
- Fechamento: missão sem `inicio` → depois de `now() > prazo`; com `inicio` → `hoje_sp() >= dia_do_prazo + 2` e zero pendências (tarefa `feito` sem decisão ou recurso sem `decisao_final`, nos dias do período).
- Lançamento: grupo `estudos`, `origem 'nivel'`, `data_ref` = dia do prazo (SP), descrição `'Missão: nível ' || nivel`.
- Textos do app em português, no tom das telas atuais.
- Ao terminar: atualizar PENDENCIAS.md e README.md.

## Review Focus
1. Prazo às 22h e fuso: tópico concluído / tentativa às 22h01 SP não conta; tarefa do dia do prazo conta.
2. Duas pessoas abrindo o app ao mesmo tempo: só um lançamento (índice único + `exception when unique_violation`).
3. Tarefa marcada pela criança no dia seguinte ao prazo (ainda permitido) antes do fechamento: espera de 2 dias cobre.
4. Pai salva de novo a missão já lançada (mesmo prazo): continua "lançada", não lança de novo.
5. Missão do Johann em produção (sem `inicio`): `_missao` deve dar bronze 150, igual ao app antigo, antes do deploy.

---

### Task 1: Migração 12 e testes do banco

**Files:**
- Create: `supabase/migrations/20261121_12_missao_automatica.sql`
- Create: `supabase/testes/10_testes_missao.sql`

**Interfaces:**
- Produces:
  - `_missao(p_aluno uuid) returns jsonb` (interno) — nulo se não há `prazo` ou nenhuma matéria da missão ativa. Chaves: `prazo` (timestamptz), `dia_prazo` (date), `inicio` (date|null), `treino_min`, `prova_min`, `qtd`, `pontos` ({bronze,prata,ouro}), `tarefas_min` ({bronze,prata,ouro}), `det` ([{mid, bronze bool, treino num (-1 = nenhum), prova num (-1)}], na ordem de `config.materias`), `tarefas` ({total, obtido, pct (1 casa), pendentes} ou null sem `inicio`), `bronze`, `prata`, `ouro`, `nivel` (text|null), `valor`, `ref`, `encerrada` (now() > prazo), `lancada`, `pode_fechar`.
  - `missao(p_aluno uuid) returns jsonb` — `if not pode_ver(p_aluno) then raise exception 'Sem acesso'`; devolve `_missao`.
  - `fechar_missoes() returns int` — `if not is_familia() then raise exception 'Sem acesso'`; para cada perfil `papel = 'aluno'`, se `pode_fechar and not lancada and valor > 0`, `_lancar(...)` dentro de `begin … exception when unique_violation then null; end`. Devolve quantos lançou.

Regras de cálculo (iguais ao `calcMeta` atual, mais tarefas):
- matérias = elementos de `config->'materias'` que existem em `materias` com `ativa` para o aluno.
- bronze da matéria: todo tópico `ativo` tem `progresso` (aluno, chave `materia||':'||idx`) com `concluido_em <= prazo`.
- treino: `max(pct)` de `tentativas` tipo `treino`, `total >= 5`, `criado <= prazo`; prova: idem tipo `prova` sem o filtro de total; nenhum = -1.
- `qtd = least(coalesce(nullif(prova_qtd,0), n), n)`.
- tarefas do período (só com `inicio`): dias de `inicio` até `least(dia_prazo, hoje_sp())`; mesma seleção de `agenda_tarefas` (linha em `tarefa_dia` do aluno, ou `t.ativa and p_aluno = any(responsaveis(t.id, d))`); `obtido = sum(validado 1, metade 0.5)`; `pendentes` = `tarefa_dia` `feito` sem decisão + `recursos` sem `decisao_final`, nos dias de `inicio` a `dia_prazo`.
- nível encadeado: `bronze = todas ok and tok('bronze')`, `prata = bronze and todo treino >= treino_min and tok('prata')`, `ouro = prata and count(prova >= prova_min) >= qtd and tok('ouro')`, onde `tok(n) = inicio is null or total = 0 or obtido*100 >= min(n)*total`.

- [ ] **Step 1: Escrever `10_testes_missao.sql`** no padrão do `09` (schema `t`, `t.erro`, `t.como`, `ids` com `hoje_sp()`; rótulo de cada select traz o esperado). Dados próprios: matérias `xa` e `xb` do Johann com 2 tópicos cada; tarefa diária `T1` (todos, Johann, base h−20); progresso e tentativas inseridos com `reset role` e datas explícitas. Seções e esperados:
  1. Sem prazo: `missao(johann)` nulo.
  2. Prazo = (h−3) 22:00 SP, inicio h−9, tópicos concluídos em h−5, treino 80% (total 10) e prova 90% nas duas: sem decisões → `tarefas.total 7, obtido 0`, nível `null`.
  3. Pai valida 5, metade 1, rejeita 1 → `obtido 5.5`, `pct 78.6`, nível `bronze`, `valor 150`.
  4. Muda decisões até 7 validadas → nível `ouro`.
  5. Tópico concluído às 22:01 do dia do prazo em `xb` → bronze falso (e nível null); volta ao normal depois.
  6. Prova às 22:01 do dia do prazo não conta (melhor continua o anterior).
  7. Pendência: tarefa `feito` sem decisão no período → `pendentes 1`, `pode_fechar false`; recurso aberto idem.
  8. Espera: prazo em h−1 (sem pendências) → `pode_fechar false`; h−2 → `true`.
  9. `fechar_missoes()` chamado como Johann → `1`; de novo → `0`; lançamento: valor 400, `data_ref` = dia do prazo, descrição `Missão: nível ouro`, `origem_ref` `meta:YYYY-MM-DD 22:00`.
  10. Regravar o prazo no mesmo minuto em UTC (`...T01:00:00.000Z`) → `lancada true`, `fechar_missoes()` → 0.
  11. Referência antiga: lançamento `nivel` com `origem_ref = 'meta:' || config->>'prazo'` → `lancada true`.
  12. Juju sem `inicio`, prazo now() − 1 hora, tópicos ok → `pode_fechar true` logo; sem nível (tópico faltando) → `fechar` não lança.
  13. Pausa num dia do período e troca "só este dia" de T1 para Juju → total cai 2 para o Johann.
  14. Juju lê `missao(johann)` → ERRO; `_missao` como authenticated → ERRO.

- [ ] **Step 2: Rodar e ver falhar**
  Run (em `supabase/testes`): `node roda.mjs 00_stub.sql ../../banco.sql 00_perfis.sql ../migrations/2026111*.sql ../migrations/20261121_0*.sql ../migrations/20261121_10*.sql ../migrations/20261121_11*.sql 10_testes_missao.sql`
  Expected: erros "function missao(uuid) does not exist".

- [ ] **Step 3: Escrever a migração 12** (`begin; … commit;`, cabeçalho no padrão da 11) com as três funções e os grants.

- [ ] **Step 4: Rodar com a migração e ver passar**
  Run: o mesmo comando com `../migrations/*.sql`.
  Expected: todos os rótulos batem com o valor; nenhum `!! ERRO`.

- [ ] **Step 5: Regressão** — rodar 05 a 09 com `../migrations/*.sql` e comparar com a saída sem a migração 12 (`diff`). Expected: idênticas.

- [ ] **Step 6: Commit** `Missão automática: migração 12 (cálculo no banco e fechamento) e testes`.

### Task 2: App — missão vinda do banco e fechamento ao abrir

**Files:**
- Modify: `index.html` (`carregar`, `calcMeta`, `atualizaPontos`, `comoGanhar`, `painelLancar`, ação `tg`, ação `lMeta` removida)
- Create: `testes-app/missao.mjs` (padrão de `testes-app/avulsa.mjs`; `rpc` simulado devolve `S.missao` do cenário e registra as chamadas)

**Interfaces:**
- Consumes: `missao`, `fechar_missoes` (Task 1).
- Produces: `carregarMissao()` (preenche `S.missao`); `calcMeta()` com a mesma forma de hoje (`c` com `treino_min`/`prova_min`, `prazo` Date, `mats`, `qtd`, `M`, `bronze/prata/ouro`, `bronzeDet {mid, ok}`, `prataDet/ouroDet {mid, v}`, `nivel`, `valor`) mais `tar` (= `tarefas`), `tmin`, `encerrada`, `lancada`, `pode_fechar`; `estadoMissao(g) → string`.

`estadoMissao(g)`, na ordem: `lancada` → `Lançada ✓ <Nível> +<valor>`; `!encerrada` → `Os pontos entram sozinhos depois do prazo.`; `tar?.pendentes` → `Esperando validação de N tarefa(s)`; `!nivel` → `Nenhum nível conquistado`; senão → `Os pontos entram em até 2 dias depois do prazo.`

- [ ] **Step 1: Escrever `testes-app/missao.mjs`** com checagens:
  - `carregar()` chama `fechar_missoes` antes de `missao` (ordem das chamadas `rpc`).
  - `calcMeta()` com `S.missao` de ouro devolve `nivel 'ouro'`, `prataDet[0].v` = treino do banco, `prazo instanceof Date`; `S.missao = null` → `null`.
  - `comoGanhar()` mostra `Tarefas validadas: 78.6%` e `70 / 80 / 90`; sem `tarefas` (sem início) não mostra a linha; não contém `O pai ou a mãe lançam`.
  - `estadoMissao` nos 5 casos (textos acima).
  - `painelLancar()` não tem `data-a="lMeta"` e mostra o estado; `acoes.lMeta` não existe.
- [ ] **Step 2: Rodar e ver falhar** — `node testes-app/missao.mjs index.html` → linhas `FALHA`.
- [ ] **Step 3: Implementar** no `index.html`:
  - `carregar`: `await sb.rpc('fechar_missoes')` antes do `Promise.all`; `missao` entra no `Promise.all` e vai para `S.missao`.
  - `carregarMissao()`; chamada em `atualizaPontos` e na ação `tg` (antes do `render`).
  - `calcMeta` reescrita a partir de `S.missao` (sem `melhor`/`S.prog` no cálculo; `melhor` fica se ainda for usado em outro lugar).
  - `comoGanhar`: linha `🏠 Tarefas validadas: <pct>% (mínimo <b> / <p> / <o>)` quando `g.tar`; troca o texto final por `estadoMissao(g)`.
  - `painelLancar`: sem botão; `estadoMissao(g)` no lugar de "Já lançada / Prazo…"; remove `refMeta/metaLancada`.
  - remove a ação `lMeta`.
- [ ] **Step 4: Rodar e ver passar** — `node testes-app/missao.mjs index.html` e `node testes-app/avulsa.mjs index.html scratch.html` → só `OK`.
- [ ] **Step 5: Commit** `Missão automática: app usa o cálculo do banco e fecha ao abrir`.

### Task 3: App — aviso em "Precisa de você" e campos em Cadastros › Pontos

**Files:**
- Modify: `index.html` (`carregarFamilia`, `hojePais`, `cadRegras`, ação `cRegra`)
- Modify: `testes-app/missao.mjs`

**Interfaces:**
- Consumes: `missao` (Task 1), `estadoMissao` (Task 2).
- Produces: `S.missoesFam` ({user_id: missao}) para pais.

- [ ] **Step 1: Acrescentar checagens** em `missao.mjs`:
  - `hojePais()` com `S.missoesFam[J]` encerrada, não lançada, `pendentes 3` → contém `Missão de Johann esperando 3 tarefas` e não mostra "Tudo em dia"; com `pendentes 0` → sem o aviso.
  - `cadRegras()` tem `id="ge-ini"` (type date) e `ge-tb`, `ge-tp`, `ge-to` com 70/80/90 quando a config não tem `tarefas_min`.
  - `cRegra` estudos com prazo e sem início → toast `Preencha "Começa em"` e nada gravado; início depois do prazo → toast `"Começa em" precisa ser antes do prazo`; válido → grava `inicio: 'YYYY-MM-DD'` e `tarefas_min {bronze:70, prata:80, ouro:90}`.
- [ ] **Step 2: Rodar e ver falhar.**
- [ ] **Step 3: Implementar**: `carregarFamilia` (pais) busca `missao` de cada criança; `hojePais` soma o aviso dentro do card "Precisa de você" (botão Ver → aba aprovar); `cadRegras` e `cRegra` com os campos e validações.
- [ ] **Step 4: Rodar os dois testes de telas** → só `OK`.
- [ ] **Step 5: Commit** `Missão automática: aviso para os pais e campos de início e tarefas`.

### Task 4: Documentação, produção e deploy (com confirmações)

**Files:** `README.md`, `PENDENCIAS.md`

- [ ] **Step 1:** README: migração 12 na lista, regra "Missão" em Regras principais (tarefas, fechamento sozinho, espera de 2 dias, sem início = regras antigas), teste 10 e `testes-app/missao.mjs`. PENDENCIAS: 2.5 em "Feito" (data), item da missão do Johann atualizado. Commit.
- [ ] **Step 2: Pedir confirmação** e aplicar a migração 12 no Supabase.
- [ ] **Step 3: Conferir em produção (só leitura):** funções existem; anon sem execute; `select _missao('d5c2215c-…')` → `nivel bronze`, `valor 150`, `pode_fechar true`, `lancada false`; Juju → nulo.
- [ ] **Step 4: Revisão final** do ramo (revisor novo, modelo mais capaz).
- [ ] **Step 5: Pedir confirmação** e fazer o push (main). Conferir o GitHub Pages com o texto novo.
- [ ] **Step 6:** Depois de alguém abrir o app: conferir o lançamento do Johann (+150, `data_ref` 2026-11-19, uma linha só).
