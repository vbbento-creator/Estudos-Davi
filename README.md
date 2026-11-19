# Cofrinho

App web da família para estudos, tarefas da casa e recompensas. É uma página só (`index.html`, JS puro + supabase-js via CDN) com backend no Supabase.

## Rodar localmente
```
python3 -m http.server 8000   # abrir http://localhost:8000
```
Atenção: o app aponta para o banco de **produção** (URL e chave pública no `index.html`).

## Banco
1. `banco.sql`: estrutura original (v1).
2. `supabase/migrations/20261119_01_multi_alunos.sql`: vários alunos, matérias por aluno, tarefas da casa, revezamento, pausas, recursos, prêmios e livro-razão de recompensas.
3. `supabase/migrations/20261119_02_seed_davi.sql`: matérias, tópicos e cronograma do Davi.
4. `supabase/migrations/20261119_03_fechar_funcoes_anon.sql` e `..._04_dias_da_semana.sql`.
5. `supabase/migrations/20261119_05_cofrinho.sql`: **Cofrinho**, pontos como moeda única (ver abaixo).

Rodar a 05 no SQL Editor **junto com a publicação do novo `index.html`**: o app antigo não entende o banco novo. Lançamentos que já existirem são convertidos para pontos (tarefas × 2, 1 min de tela = 2 pontos, R$ 1 = 10 pontos).

### Regras principais
- Cada criança vê só os próprios dados; pai e mãe veem tudo (RLS + `pode_ver()`).
- **Uma moeda só: pontos, sem validade.** Referência: 10 pontos = R$ 1; 2 pontos = 1 minuto de tela. O saldo é `saldo_total(aluno)`, a soma do livro-razão.
- Como ganhar: tarefa de casa (valor de cada tarefa, validada por pai ou mãe), tópico concluído (30), treino com 70% ou mais (40, uma vez por matéria por dia), prova valendo com 80% ou mais (100), missão (bronze 150, prata 250, ouro 400, lançada pelos pais) e média do bimestre (70 por matéria com 8 ou mais, +90 se nenhuma abaixo de 7, máximo 1.000, lançada pelos pais). Os valores de estudo e notas ficam em `grupos.config` e se editam em Mais › Cadastros › Pontos.
- **Teto semanal de ganho nas tarefas** (`grupos.teto_semana`, hoje 490): cadastrar tarefa nova não aumenta o custo; o que passa do teto na semana (segunda a domingo) não é creditado. O estorno reabre espaço.
- **Loja** (`premios` + `resgates`): tipos tela, experiência e dinheiro, com limite por semana ou mês (`limite`, `limite_periodo`), limite compartilhado entre itens (`limite_grupo`, ex.: cinema e jantar dividem 1 passeio por semana) e item dividido (`divide`, ex.: jantar fora, cada criança paga a sua metade). Toda troca vira pedido; no item dividido o pedido espera todos pagarem (`aguardando` → `pedido`). Pais marcam como combinado (`entregar_resgate`) ou cancelam e devolvem os pontos (`cancelar_resgate`). A criança cancela o que ainda aguarda a outra metade.
- Lançamentos não se editam nem se apagam; correção é estorno. Cada um grava o valor do momento.
- Tarefa marcada como feita só vale depois de validada; os pontos caem na data da tarefa. Decisão só muda por recurso (até 5 dias, um por tarefa/dia; decisão dos pais é final).
- Criança marca hoje ou ontem; depois disso, sem marcação = não feito (calculado, sem rotina agendada).
- Tarefas têm dias da semana e período do dia (manhã, tarde, noite). Revezamento: contagem de dias em que a tarefa acontece desde `tarefas.base`, pulando dias pausados; fuso America/Sao_Paulo. Trocas manuais em `trocas`.
- Tarefas, prêmios e matérias se desativam, não se excluem.

### Testes do banco
`supabase/testes/`: um Postgres local com uma imitação mínima do Supabase (`00_stub.sql`). Carregar `banco.sql`, um backup dos dados, `01_questoes_amostra.sql` e as migrações 01 a 04; rodar `02_testes.sql`; aplicar a 05 e rodar `03_testes_cofrinho.sql` (teto semanal, limites da loja, jantar dividido, pontos automáticos, agenda e segurança). Cada linha impressa traz o esperado no rótulo.
