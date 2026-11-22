# 2.7 Tarefa com vários períodos no dia — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** uma tarefa tem um ou mais períodos (Manhã, Tarde, Noite ou Dia todo); cada período é marcado, decidido e contestado separado, e não pode ser marcado antes de abrir.

**Architecture:** migração 24 põe `periodo` na chave de `tarefa_dia` e `recursos`, troca `tarefas.periodo` por `tarefas.periodos text[]`, coloca a trava de horário em `marcar_tarefa` e devolve uma linha por tarefa e período em `tarefas_do_dia` / `agenda_tarefas`. O `index.html` agrupa essas linhas numa linha por tarefa, com um botão por período.

**Tech Stack:** Postgres (Supabase), plpgsql; testes do banco em PGlite (`supabase/testes/roda.mjs`); app em um único `index.html` (JS sem build); testes de tela em `testes-app/*.mjs` (vm + banco simulado).

**Spec:** `docs/superpowers/specs/2026-11-22-tarefa-varios-periodos-design.md`

## Global Constraints
- Períodos: `manha`, `tarde`, `noite`, `dia`. `dia` só sozinho. Ordem de exibição: manha, tarde, noite, dia.
- Abertura (horário de Brasília), só no dia de hoje: manhã 00:00, tarde 12:00, noite 18:00, dia 18:00. Ontem: qualquer período. Pai e mãe: sem prazo para dias passados (como hoje).
- Mensagem da trava: `Esse período ainda não chegou: abre às 12h` (ou `18h`).
- Pontos: cada período vale `tarefas.pontos`.
- `origem_ref` dos lançamentos de tarefa: `tarefa:dia` quando o período é `dia` (igual a hoje); `tarefa:dia:periodo` nos outros. **Refinamento do design:** assim só as marcações antigas com período (a tarefa 6, manhã) têm o `origem_ref` reescrito, e os testes 05–11 continuam valendo.
- Extrato: "Tarefa: Nome (manhã|tarde|noite)"; sem sufixo para `dia`. Estorno e metade seguem o mesmo sufixo.
- Rótulos na tela: Manhã ☀️, Tarde 🌤️, Noite 🌙, Dia todo 🌙.
- Migração 24 com `drop` → aplicada pelo SQL Editor, com confirmação, junto com o push do novo `index.html`. Nada vai para produção ou GitHub sem confirmação.
- Novo parâmetro `p_periodo text default null` entra **no fim** das assinaturas (as chamadas posicionais dos testes antigos continuam valendo). `p_periodo` nulo = o único período configurado na tarefa; se ela tiver mais de um → erro `Escolha o período`.

## Review Focus
1. Recurso ou decisão sobre marcação **antiga** de período não-`dia` (tarefa 6, manhã) não pode creditar de novo: o `origem_ref` reescrito tem de bater com a nova regra.
2. Virada da hora com a tela aberta: às 12h/18h o cadeado precisa sumir sem a criança sair do app (recarregar quando `abre_em` passar).
3. Relógio do aparelho errado: a trava na tela usa `abre_em` vindo do banco; o banco recusa mesmo assim.
4. Tarefa editada (período removido) com marcação já feita naquele período: continua aparecendo, pode ser decidida e contestada, mas não pode ser marcada de novo se foi desmarcada.
5. Virada do dia: a noite de hoje vira "ontem" à 0h e continua marcável no dia seguinte.

---

### Task 1: Migração 24, parte 1: tabelas, dados e marcar com trava

**Files:**
- Create: `supabase/migrations/20261122_24_periodos.sql`
- Create: `supabase/testes/00_relogio_noite.sql`
- Create: `supabase/testes/12_testes_periodos.sql`

**Interfaces:**
- Produces:
  - `agora_sp() returns timestamp` (= `now() at time zone 'America/Sao_Paulo'`), única fonte de hora da trava; os testes a substituem.
  - `abre_periodo(p text) returns time`.
  - `_periodo_da_tarefa(p_tarefa bigint, p_periodo text) returns text` (resolve o nulo; erro `Escolha o período`).
  - `tarefas.periodos text[] not null default '{dia}'`; `tarefa_dia.periodo`, `recursos.periodo` `text not null`; PK `tarefa_dia(tarefa, dia, aluno, periodo)`; `recursos` FK e unique com `periodo`.
  - `marcar_tarefa(p_tarefa bigint, p_dia date, p_status text, p_aluno uuid default null, p_periodo text default null) returns void`.

- [ ] **Step 1: `00_relogio_noite.sql`**: `create or replace function agora_sp() ... select hoje_sp() + time '20:00'`. Rodado depois das migrações nos testes 05–11, deixa todas as tarefas abertas. Atualizar o comando no README (Task 6).
- [ ] **Step 2: Escrever `12_testes_periodos.sql`** no padrão do `09_testes_tarefa_avulsa.sql` (schema `t`, `t.erro`, `t.como`, `ids`, `pg_temp.tk`; rótulo com o esperado). Função auxiliar `pg_temp.relogio(hh int)`, que recria `agora_sp()` para hoje às `hh`h. Tarefas: `ESC` `{manha,noite}` 5 pts; `KIKA` `{dia}` 20; `MESA` `{tarde,noite}` 20; todas do Johann. Casos:
  - check: `periodos '{}'`, `'{dia,manha}'`, `'{manha,manha}'`, `'{madrugada}'` → ERRO cada um.
  - relógio 10h, Johann: marca ESC manha → OK; ESC noite → `ERRO: Esse período ainda não chegou: abre às 18h`; KIKA (sem período) → ERRO `abre às 18h`; MESA tarde → ERRO `abre às 12h`; MESA sem período → `ERRO: Escolha o período`; ESC `tarde` (não configurado) → ERRO.
  - relógio 10h: ESC noite de **ontem** → OK.
  - relógio 19h: ESC noite, KIKA, MESA tarde e MESA noite → OK.
  - ESC noite marcada às 19h; relógio volta para 10h; desmarcar (status nulo) → OK.
  - pai marcando pela criança às 10h ESC noite → ERRO (trava vale para todos).
  - `tarefas_do_dia(johann, hoje)` às 10h: 5 linhas (ESC×2, KIKA, MESA×2) em ordem ESC manha, ESC noite, MESA tarde, MESA noite, KIKA; `abre_em` nulo / 18:00 / 12:00 / 18:00 / 18:00; `pode_marcar` t/f/f/f/f.
  - `agenda_tarefas(johann, hoje, hoje)`: 5 linhas, com `periodo`.
  - tarefa editada: marca MESA noite, depois `update tarefas set periodos='{tarde}'` → `tarefas_do_dia` ainda traz 2 linhas de MESA (tarde e noite); desmarcar MESA noite → OK; marcar MESA noite de novo → ERRO.
  - migração de dados: num banco com uma tarefa criada **antes** da 24 (inserir num arquivo de preparo rodado entre as migrações 23 e 24, ver Step 3) com `periodo='manha'`, marcada e validada: depois da 24, `periodos = {manha}`, linha de `tarefa_dia` com `periodo='manha'` e `origem_ref` reescrito para `id:dia:manha`; uma sem período: `{dia}`, `periodo='dia'`, `origem_ref` igual.
- [ ] **Step 3: Arquivo de preparo `supabase/testes/12_preparo_antes_24.sql`** (sem `_testes` no nome; só carrega): cria as duas tarefas antigas, marca e valida (como pai), abre um recurso na de manhã. Comando: `node roda.mjs 00_stub.sql ../../banco.sql 00_perfis.sql <migrações 01..23> 12_preparo_antes_24.sql ../migrations/20261122_24_periodos.sql 12_testes_periodos.sql`.
- [ ] **Step 4: Rodar e ver falhar** (a migração 24 ainda não existe): erro ao carregar.
- [ ] **Step 5: Escrever a parte 1 da migração 24** (`begin; … commit;` no fim do arquivo todo):
  - cabeçalho no padrão das outras (o quê, pré-requisito 01–23, "ATENÇÃO: aplicar pelo SQL Editor junto com o novo index.html");
  - `agora_sp`, `abre_periodo`, `_periodo_da_tarefa`;
  - `tarefas.periodos` + check (`cardinality>=1`, `<@ array['manha','tarde','noite','dia']`, sem repetidos, `not ('dia' = any(periodos) and cardinality>1)`), preenchida de `periodo`;
  - `tarefa_dia.periodo` / `recursos.periodo` preenchidas por `coalesce(t.periodo,'dia')`, `not null` + check; trocar PK, FK e unique (`drop constraint` pelo nome real, achado em `pg_constraint` como a migração 10 faz);
  - reescrever `lancamentos.origem_ref` (`origem in ('tarefa','estorno')`, mesmo aluno, `origem_ref = tarefa||':'||dia`) para as linhas de `tarefa_dia` com `periodo <> 'dia'`;
  - dados de produção: `update tarefas set nome='Escovar os dentes', periodos='{manha,noite}' where id=6 and nome='Escovar os dentes (manhã)'`; `update tarefas set ativa=false where id=7 and nome='Escovar os dentes (noite)' and not exists (select 1 from tarefa_dia where tarefa=7)`;
  - `drop` das funções antigas que mudam de assinatura ou de retorno, e depois `alter table tarefas drop column periodo`;
  - `marcar_tarefa` nova: igual à atual (migração 01), mais: resolve período; período fora de `periodos` só é aceito se já existe linha desse período (e só para desmarcar); trava `p_status = 'feito' and p_dia = hoje_sp() and agora_sp()::time < abre_periodo(per)`, com a mensagem das Global Constraints (hora sem minutos: `to_char(abre,'FMHH24')||'h'`);
  - `tarefas_do_dia` e `agenda_tarefas` (base: versões da migração 10): `cross join lateral unnest(t.periodos)` unido aos períodos que já têm linha naquele dia; retornam `periodo` e (`tarefas_do_dia`) `abre_em time`; `pode_marcar` passa a exigir que o período esteja em `periodos` e que já tenha aberto; ordenação: posição do primeiro período da tarefa, `ordem`, `id`, posição do período.
- [ ] **Step 6: Rodar o 12 até passar** (todas as linhas com o valor do rótulo).
- [ ] **Step 7: Commit** `Migração 24 (parte 1): períodos na tarefa e na marcação, trava de horário`.

### Task 2: Migração 24, parte 2: decisão, recurso, missão e troca

**Files:**
- Modify: `supabase/migrations/20261122_24_periodos.sql`
- Modify: `supabase/testes/12_testes_periodos.sql`

**Interfaces:**
- Consumes: Task 1 (colunas, `_periodo_da_tarefa`).
- Produces:
  - `_aplicar_decisao(p_tarefa bigint, p_dia date, p_aluno uuid, p_decisao text, p_motivo text default null, p_comentario text default null, p_periodo text default 'dia')`
  - `decidir_tarefa(p_tarefa bigint, p_dia date, p_aluno uuid, p_decisao text, p_motivo text default null, p_comentario text default null, p_periodo text default null)`
  - `abrir_recurso(p_tarefa bigint, p_dia date, p_comentario text, p_periodo text default null)`
  - `resolver_recurso(p_id, p_decisao, p_resposta, p_motivo)`: mesma assinatura, usa `recursos.periodo`.
  - `_missao`, `trocar_responsavel`: mesmas assinaturas.

- [ ] **Step 1: Acrescentar casos ao 12** (relógio 20h):
  - ESC manha e noite validadas → `rendeu` 10; `origem_ref` `id:dia:manha` e `id:dia:noite`; descrições `Tarefa: ESC (manhã)` e `Tarefa: ESC (noite)`.
  - KIKA validada → `origem_ref` `id:dia` e descrição `Tarefa: KIKA`.
  - MESA tarde metade (enrolou) → 10; recurso na tarde → validar inteira → total 20 na tarde; MESA noite não afetada.
  - `decidir_tarefa` em ESC sem período → `ERRO: Escolha o período`.
  - recurso duplicado no mesmo período → ERRO; recurso no outro período do mesmo dia → OK.
  - tarefa antiga do preparo (manhã, já validada): recurso → resolver `validado` → `rendeu` continua igual ao crédito original (não duplica).
  - `trocar_responsavel` em ESC com só a manhã marcada → `ERRO: A tarefa já foi marcada nesse dia: não dá para trocar`.
  - `_missao` (ou `missao`) com um período de missão cobrindo hoje: `total` conta 5 (ESC×2, KIKA, MESA×2); `pendentes` conta por período.
- [ ] **Step 2: Rodar e ver falhar.**
- [ ] **Step 3: Implementar na migração 24:** `_aplicar_decisao` (base: migração 10) com `p_periodo`, `ref` pela regra das Global Constraints e descrição com sufixo; `decidir_tarefa` resolve o período e passa adiante; `abrir_recurso` resolve o período e grava `recursos.periodo`; `resolver_recurso` lê `td` por `r.periodo`; `_missao` (base: migração 12) faz o `cross join lateral` dos períodos (mesma união da Task 1) no `tt`; `trocar_responsavel` (base: migração 08, já com o `exists` sem período): só confirmar que continua certo e recriar se a assinatura de algo que ela usa mudou. `revoke` de `_aplicar_decisao` como nas migrações 01 e 10. `grant execute` nas funções novas que o app chama, se as anteriores tinham.
- [ ] **Step 4: Rodar o 12 até passar.** Rodar também 05 a 11 com `00_relogio_noite.sql` depois das migrações: `node roda.mjs 00_stub.sql ../../banco.sql 00_perfis.sql ../migrations/*.sql 00_relogio_noite.sql 0X_testes_….sql` (para o 11, a 23 de novo como hoje). Esperado: as mesmas saídas de antes da 24.
- [ ] **Step 5: Commit** `Migração 24 (parte 2): decisão, recurso, missão e troca por período`.

### Task 3: App: lista da criança (Hoje e Ontem) com um botão por período

**Files:**
- Modify: `index.html` (`PERIODO`, `grupoPeriodo`, `linhaTarefa`, `hojeAluno`, ações `tMarcar`, `tRecurso`)
- Create: `testes-app/periodos.mjs`

**Interfaces:**
- Consumes: linhas de `tarefas_do_dia` com `periodo` e `abre_em` (Task 1).
- Produces:
  - `PERIODO = { manha:'Manhã', tarde:'Tarde', noite:'Noite', dia:'Dia todo' }`, `ICONE_P = { manha:'☀️', tarde:'🌤️', noite:'🌙', dia:'🌙' }`
  - `porTarefa(L) → [{ tarefa, nome, emoji, pontos, itens:[linha por período] }]`, mantendo a ordem do banco (substitui `grupoPeriodo`).
  - botões com `data-p="<periodo>"`; `tMarcar` e `tRecurso` mandam `p_periodo:el.dataset.p`; id do recurso `rc-<tarefa>-<dia>-<periodo>`.

- [ ] **Step 1: Escrever `testes-app/periodos.mjs`** no padrão do `avulsa.mjs` (exportar `linhaTarefa`, `hojeAluno`, `porTarefa`, `acoes`, `S`). Cenário de criança com `S.tarefas[hoje]`: ESC manha (validado), ESC noite (`a_fazer`, `pode_marcar:false`, `abre_em:'18:00:00'`), KIKA dia (`a_fazer`, `abre_em:'18:00:00'`), MESA tarde (feito, aguardando). Verificações:
  - ESC aparece uma vez (`(html.match(/Escovar/g)).length === 1`).
  - 4 botões de período no total; o de ESC noite está `disabled` e mostra `às 18h`.
  - nenhum `<h3>Manhã` / `<h3>Noite`; há `Tarefas de casa`.
  - `x de y` = `2 de 4` (validada + aguardando contam como hoje).
  - recurso aberto numa linha validada mostra `Não concordo` junto do período.
  - `acoes.tMarcar({ dataset:{ t:'1', d:hoje, s:'feito', p:'noite' } })` chama `rpc('marcar_tarefa', { …, p_periodo:'noite' })` (o `rpc` simulado guarda os argumentos).
  - ontem: card "Ainda dá para marcar (ontem)" lista o período pendente de ontem.
- [ ] **Step 2: Rodar `node testes-app/periodos.mjs index.html` e ver FALHA.**
- [ ] **Step 3: Implementar.** Linha da tarefa: nome, emoji e pontos (com "cada" se houver mais de um período), e um botão por item com ícone, nome do período e estado (`⏳`, `✓`, `½`, `✕`, ou `🔒 às HHh` se `abre_em`). Subtexto de metade, rejeição e recurso por item. `hojeAluno` lista `porTarefa(T)` sob um título só, "Tarefas de casa". Recarregar ao passar `abre_em`: no `render` do Hoje, se algum item tiver `abre_em`, agendar um `setTimeout` (um só, guardado em `S`) para o próximo horário (12h/18h, no relógio de Brasília), que chama `carregarTarefas()` e depois `render()`.
- [ ] **Step 4: Rodar `periodos.mjs` (todos OK) e de novo `adiantar`, `missao`, `avulsa` e `erro-rede`.** Corrigir no próprio teste qualquer cenário antigo que use `periodo:null` onde agora deveria ser `'dia'`.
- [ ] **Step 5: Commit** `App: tarefa com vários períodos na lista da criança`.

### Task 4: App: Agenda, Aprovar e recursos por período

**Files:**
- Modify: `index.html` (`linhaAgenda`, `telaAgenda`, `telaAprovar`, `hojePais`, `carregarTarefas` (recursos abertos), ações `tDecidir`, `tMetade`, `tTrocar`)
- Modify: `testes-app/periodos.mjs`

**Interfaces:**
- Consumes: `porTarefa`, `PERIODO`, `ICONE_P`, `data-p` (Task 3); linhas de `agenda_tarefas` com `periodo`; `tarefa_dia` / `recursos` com `periodo`.
- Produces: chaves de painel com período: metade `ag|t|d|w|p`, `ap|t|d|w|p`; `tDecidir` manda `p_periodo`. Trocar continua por tarefa e dia (sem período).

- [ ] **Step 1: Casos novos no `periodos.mjs`** (como pai):
  - Agenda: ESC aparece uma vez por criança e dia, com os dois períodos e o estado de cada um; ESC noite feito mostra Validar / ½ / Rejeitar com `data-p="noite"`; "Trocar" aparece uma vez por tarefa (não por período) e só se nenhum período tiver sido marcado.
  - Aprovar: pendência `{tarefa:ESC, periodo:'noite'}` mostra `Escovar os dentes · Noite`; pendência `periodo:'dia'` não mostra sufixo.
  - Recurso aberto mostra o período e a decisão atual **daquele período** (`r.atual` casado por `periodo`).
  - `tDecidir` com `data-p` chama `decidir_tarefa` com `p_periodo`.
- [ ] **Step 2: Rodar e ver FALHA.**
- [ ] **Step 3: Implementar.** `telaAgenda` agrupa as linhas de cada criança e dia com `porTarefa`; a linha da tarefa traz um sub-bloco por período com marca, subtexto e ações de pai e mãe (Marcar como feita, Validar, ½, Rejeitar, cada uma com `data-p`); Trocar e Remover (avulsa) ficam na linha da tarefa. `hojePais` conta por período (linhas), como já faz. Em `carregarTarefas`, o casamento de `r.atual` inclui `periodo`.
- [ ] **Step 4: Rodar todos os testes de tela.**
- [ ] **Step 5: Commit** `App: Agenda, Aprovar e recursos por período`.

### Task 5: App: cadastro e tarefa avulsa com períodos

**Files:**
- Modify: `index.html` (`formTarefa`, `blocoAvulsa`, `IDEIAS`, `possivelSemana`, ações `preset`, `cTarefaSalvar`, `avCriar`)
- Modify: `testes-app/periodos.mjs`, `testes-app/avulsa.mjs` (cenários com `periodo:null` → `periodos:['dia']`)

**Interfaces:**
- Consumes: `PERIODO`, `ICONE_P` (Task 3).
- Produces: `lerPeriodos(prefixo) → string[]` (das caixas `${p}-per-manha|tarde|noite|dia`); registros gravados com `periodos` (nunca `periodo`).

- [ ] **Step 1: Casos novos:**
  - `formTarefa` de ESC `{manha,noite}`: caixas manha e noite marcadas, tarde e dia não.
  - salvar com `dia` e `manha` marcados → grava `periodos:['dia']` (Dia todo vence); salvar sem nenhuma → toast `Escolha pelo menos um período` e nada gravado.
  - avulsa: o formulário tem as caixas, com padrão `Dia todo`; criar grava `periodos`.
  - `possivelSemana`: ESC 5 pts `{manha,noite}` todos os dias = 70.
  - presets: `IDEIAS` tem "Escovar os dentes" com `manha,noite` (um só, no lugar dos dois), e `preset` marca as caixas.
- [ ] **Step 2: Rodar e ver FALHA.**
- [ ] **Step 3: Implementar.** As caixas ficam na linha de pontos, no lugar do `<select>`. Marcar Dia todo desmarca as outras na tela (`onchange` simples, via ação existente de render ou handler leve), e marcar outra desmarca Dia todo. `possivelSemana` multiplica por `t.periodos.length`.
- [ ] **Step 4: Rodar todos os testes de tela (`periodos`, `avulsa`, `missao`, `adiantar`, `erro-rede`).**
- [ ] **Step 5: Commit** `App: cadastro e avulsa com vários períodos`.

### Task 6: Documentação, conferência e entrada no ar

**Files:**
- Modify: `README.md` (testes do banco: 24, `00_relogio_noite.sql`, `12_preparo_antes_24.sql`, `12_testes_periodos.sql`; descrição de tarefas com períodos e horários)
- Modify: `PENDENCIAS.md` (2.7 sai de ideias para "Feito" depois de no ar; nota no topo)

- [ ] **Step 1: Atualizar README e PENDENCIAS** (o "Feito" da 2.7 é escrito como pendente de aplicação até o Step 4). Commit.
- [ ] **Step 2: Conferir produção só lendo:** `tarefas` (ids 6 e 7, nomes), `tarefa_dia where tarefa=7` vazio, `trocas`/`revez_inicios`/`substituicoes` sem a 7, `recursos` abertos, e os `lancamentos` que serão reescritos (contagem esperada = marcações decididas da tarefa 6 com crédito ou estorno).
- [ ] **Step 3: Pedir confirmação à pessoa usuária** para: aplicar a 24 pelo SQL Editor (ela cola o arquivo) e fazer o push logo em seguida. Sem confirmação, parar aqui.
- [ ] **Step 4: Depois de aplicada:** conferir lendo (colunas, PK, `periodos` da 6 e da 7, `origem_ref` reescritos, `tarefas_do_dia` do Johann e da Juju hoje); push; abrir o app publicado se o Chrome estiver disponível. Atualizar PENDENCIAS ("Feito" em 22/11 ou na data real) e a memória. Commit e push com confirmação.
