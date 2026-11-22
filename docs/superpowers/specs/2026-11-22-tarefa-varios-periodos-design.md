# 2.7 Tarefa com vários períodos no dia — design

## Por quê
Várias tarefas só terminam à noite (ex.: cuidar da Kika), mas as crianças marcam de manhã. Pai e mãe não validam o que ainda não acabou, deixam para depois, e as pendências acumulam. Ao mesmo tempo, tarefas que acontecem mais de uma vez no dia (escovar os dentes de manhã e de noite) viraram tarefas duplicadas no cadastro e na lista.

Com períodos: a criança marca cada parte quando ela já aconteceu, pai ou mãe validam na hora, e a tarefa aparece **uma vez só** na lista.

## Objetivo
- Uma tarefa tem um ou mais períodos: **Manhã, Tarde, Noite**, ou **Dia todo** (sozinho).
- Cada período é marcado, validado (inteira, ½ metade, rejeitar) e contestado (recurso) separado, e cada um vale os pontos da tarefa (escovar = 5 de manhã + 5 de noite).
- **Não dá para adiantar:** no dia de hoje, um período só pode ser marcado depois que abre (horário de Brasília):
  - Manhã: desde 0h
  - Tarde: desde 12h
  - Noite: desde 18h
  - Dia todo: desde 18h (uma marcação no dia, feita à noite)
- Ontem continua podendo ser marcado em qualquer período (o prazo atual de "hoje e ontem" não muda); pai e mãe seguem sem prazo para dias passados.
- Na lista da criança, a tarefa é uma linha com um botão por período.

## Fora do escopo / não objetivos
- Horários configuráveis por tarefa ou por família (os quatro horários acima são fixos).
- Opção "Qualquer hora" sem trava: decidido **não** criar. Toda tarefa sem período passa a ser "Dia todo" e abre às 18h; o que for de manhã ou de tarde, pai ou mãe mudam no cadastro.
- Trocar quem faz e revezamento por período: continuam valendo para a tarefa no dia inteiro.
- Mudar o teto semanal (490) por causa dos períodos a mais.

## Anti-objetivos (falharia mesmo funcionando)
- Perder ou duplicar pontos já lançados ao migrar (ex.: um recurso numa marcação antiga creditar de novo).
- A tarefa continuar aparecendo repetida na lista da criança.
- A trava de horário existir só na tela (tem de ser recusada pelo banco).

## Abordagens
- **A) Período faz parte da marcação (escolhida pela pessoa usuária).** `tarefas` guarda a lista de períodos; `tarefa_dia` e `recursos` ganham `periodo` na chave; a trava fica em `marcar_tarefa`. A tarefa é de fato uma só. Custo: migração grande, mexe em várias funções e telas, entra no ar junto com o novo `index.html`.
- B) Tarefas "filhas" por período ligadas a uma "mãe", juntadas na tela. Mexe menos na marcação, mas as duplicatas continuam no banco e o cadastro fica confuso (pontos em vários lugares). Descartada.
- C) Só a trava de horário, juntando na tela tarefas de mesmo nome. Frágil (depende do nome) e mantém o cadastro duplicado. Descartada.

## Banco (migração 24)
Aplicar pelo **SQL Editor** (tem `drop`; a ferramenta do Supabase recusa), com confirmação, **junto com a publicação do novo `index.html`** (o app antigo não manda período).

### Tabelas
- `tarefas.periodos text[] not null default '{dia}'`, com check: valores em `manha, tarde, noite, dia`; não vazio; sem repetição; `dia` só sozinho. Preenchida a partir de `tarefas.periodo` (`null` → `{dia}`). Depois, `tarefas.periodo` é **apagada**.
- `tarefa_dia.periodo text not null` (check nos quatro valores), preenchida com o período que a tarefa tinha (`coalesce(t.periodo, 'dia')`). Chave primária passa a ser `(tarefa, dia, aluno, periodo)`.
- `recursos.periodo text not null`, preenchida igual (pela tarefa). Chave estrangeira e `unique` passam a incluir `periodo`.
- `lancamentos.origem_ref` das tarefas passa de `tarefa:dia` para `tarefa:dia:periodo`. A migração **reescreve** os `origem_ref` existentes com `origem in ('tarefa','estorno')`, acrescentando o período da marcação correspondente, para que `_aplicar_decisao` (que soma por `origem_ref`) continue achando o que já foi lançado.

### Função auxiliar
- `abre_periodo(p text) returns time`: manhã 00:00, tarde 12:00, noite 18:00, dia 18:00.
- Trava: `p_dia = hoje_sp()` e `(now() at time zone 'America/Sao_Paulo')::time < abre_periodo(p_periodo)` → erro "Esse período ainda não chegou: abre às 12h" (ou 18h). Vale para todos (criança, pai e mãe), só para **marcar como feito**; desmarcar (`p_status null`) segue permitido enquanto não há decisão.

### Funções que mudam (assinatura ganha `p_periodo`)
- `marcar_tarefa(p_tarefa, p_dia, p_periodo, p_status, p_aluno)`: recusa período que a tarefa não tem (salvo se já houver linha desse período, ver "tarefa editada" abaixo), aplica a trava e grava por período.
- `_aplicar_decisao`, `decidir_tarefa`: por período; `ref = tarefa:dia:periodo`. A descrição no extrato ganha o período quando não for "dia" (ex.: "Tarefa: Escovar os dentes (noite)").
- `abrir_recurso(p_tarefa, p_dia, p_periodo, p_comentario)`; `resolver_recurso` continua por `id` (o recurso já sabe o período).
- `tarefas_do_dia`: uma linha por **tarefa e período** (os períodos configurados da tarefa, mais qualquer período que já tenha marcação naquele dia). Devolve `periodo` e um novo campo `abre_em time` (nulo se já abriu ou se não é hoje); `pode_marcar` passa a considerar a trava. Ordenação: pela posição do primeiro período da tarefa, `ordem`, `id`, e o período dentro da tarefa.
- `agenda_tarefas`: idem, uma linha por tarefa e período.
- `_missao`: cada período conta como uma tarefa no total e no obtido (escovar = 2 por dia, como hoje com as duas tarefas). Pendentes contam por período (já contam linhas de `tarefa_dia` e `recursos`).
- `trocar_responsavel`: segue pelo dia inteiro; continua recusando se **qualquer** período já foi marcado naquele dia.
- `responsaveis`: não muda.

### Tarefa editada
Se pai ou mãe tiram um período de uma tarefa, as marcações já feitas desse período continuam aparecendo (lista e Agenda) e podem ser decididas e contestadas; só não dá para marcar período novo que a tarefa não tem.

### Dados de produção (na própria migração, conferidos antes por leitura)
- Tarefa 6 "Escovar os dentes (manhã)" → nome "Escovar os dentes", `periodos = {manha,noite}`. As 4 marcações antigas ficam como "manhã".
- Tarefa 7 "Escovar os dentes (noite)" → `ativa = false` (nunca foi marcada; `trocas`, `revez_inicios` e `substituicoes` vazias, conferir de novo antes de aplicar).
- As demais tarefas sem período viram "Dia todo" (abrem às 18h). Pai ou mãe ajustam no cadastro depois (ex.: mesa = Tarde + Noite).

### Testes
`supabase/testes/12_testes_periodos.sql` no PGlite, com as migrações 01 a 24: migração preserva marcações, recursos e `origem_ref`; trava por horário (simular hora: a função de hora atual precisa ser substituível no teste, ver "Deixado para quem constrói"); ontem livre; dois períodos validados creditam duas vezes; metade e recurso por período sem crédito duplo; recurso sobre marcação antiga não credita de novo; `dia` só sozinho; trocar recusa com um período marcado; missão conta por período; desmarcar antes da hora permitido. Rodar também 05 a 11 de novo.

## App (`index.html`)
- **Hoje (criança):** os títulos por período (Manhã / Tarde / Noite / Durante o dia) saem; fica uma lista só, "Tarefas de casa". Cada tarefa é **uma linha** com um botão por período (☀️ Manhã, 🌤️ Tarde, 🌙 Noite, 🌙 Dia todo), cada um com seu estado (a fazer, ⏳ aguardando, ✓, ½, ✕) e, antes de abrir, 🔒 "às 12h" / "às 18h" desabilitado. Recurso por período (o "Não concordo" fica junto do período decidido). Tarefa com um período só mostra um botão, igual às outras. A trava na tela usa `abre_em` vindo do banco (não o relógio do aparelho), e o Hoje recarrega a lista quando passa de 12h ou 18h com a tela aberta.
- **Ontem:** pendências de ontem listadas por período.
- **Aprovar (pais):** cada pendência mostra o período ("Escovar os dentes · Noite"); validar, ½ e rejeitar mandam o período. Recursos idem.
- **Agenda:** uma linha por tarefa com os períodos e o estado de cada um.
- **Cadastro › Tarefas e Tarefa avulsa:** no lugar do seletor de período, caixas Manhã / Tarde / Noite e a opção Dia todo (marcar Dia todo desmarca as outras; ao menos uma). Presets ajustados (`data-p`). O resumo "pontos possíveis por semana" multiplica pelos períodos.
- Contagem "x de y feitas" no Hoje conta por período.
- Teste de tela sem banco `testes-app/periodos.mjs` no padrão dos outros (linha única com vários botões, cadeado, Aprovar com período). Rodar de novo `adiantar`, `missao`, `avulsa`, `erro-rede`.

## Decisões da pessoa usuária
- Abordagem A.
- Horários: manhã 0h, tarde 12h, noite e dia todo 18h.
- "Dia todo" = uma marcação no dia, liberada às 18h; todas as tarefas sem período viram "Dia todo".
- Pontos por período; validar, ½, rejeitar e recurso por período; trocar e revezamento pelo dia inteiro.
- Ontem: qualquer período pode ser marcado.
- Juntar as duas tarefas de escovar numa só.

## Decisões minhas (para conferir)
- A trava vale também para pai e mãe ao marcar pela criança; desmarcar é sempre permitido antes da decisão.
- Sem títulos por período no Hoje; ordenação pelo primeiro período da tarefa.
- Extrato mostra o período no nome da tarefa (exceto "dia").
- `tarefas.periodo` é apagada (em vez de ficar sem uso).
- Período removido da tarefa: marcações antigas continuam visíveis e decidíveis.

## Deixado para quem constrói
- Como simular a hora nos testes do PGlite (ex.: `abre_periodo` comparado com uma função `agora_sp()` que o teste substitui).
- Nomes de campos internos, layout exato dos botões, ícones.
- Ordem das operações dentro da migração (desde que tudo numa transação).
