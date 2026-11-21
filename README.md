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
6. `supabase/migrations/20261119_06_perda_pontos_estudo.sql`: pai ou mãe retiram os pontos de estudo e treino de uma matéria quando a média da escola fica abaixo do mínimo.
7. `supabase/migrations/20261119_07_concluir_treino.sql`: **Concluir treino** (ver abaixo).
8. `supabase/migrations/20261121_08_trocar_responsavel.sql`: **trocar quem faz a tarefa** (ver abaixo).
9. `supabase/migrations/20261121_09_compra_pais.sql`: **pai e mãe lançam compras que já aconteceram** (ver abaixo).

Rodar a 05 no SQL Editor **junto com a publicação do novo `index.html`**: o app antigo não entende o banco novo. Lançamentos que já existirem são convertidos para pontos (tarefas × 2, 1 min de tela = 2 pontos, R$ 1 = 10 pontos).

### Regras principais
- Cada criança vê só os próprios dados; pai e mãe veem tudo (RLS + `pode_ver()`).
- **Uma moeda só: pontos, sem validade.** Referência: 10 pontos = R$ 1; 2 pontos = 1 minuto de tela. O saldo é `saldo_total(aluno)`, a soma do livro-razão.
- Como ganhar: tarefa de casa (valor de cada tarefa, validada por pai ou mãe), tópico concluído (30), treino com 70% ou mais (40, uma vez por matéria por dia), prova valendo com 80% ou mais (100), missão (bronze 150, prata 250, ouro 400, lançada pelos pais) e média do bimestre (70 por matéria com 8 ou mais, +90 se nenhuma abaixo de 7, máximo 1.000, lançada pelos pais). Os valores de estudo e notas ficam em `grupos.config` e se editam em Mais › Cadastros › Pontos.
- **Teto semanal de ganho nas tarefas** (`grupos.teto_semana`, hoje 490): cadastrar tarefa nova não aumenta o custo; o que passa do teto na semana (segunda a domingo) não é creditado. O estorno reabre espaço.
- **Loja** (`premios` + `resgates`): tipos tela, experiência e dinheiro, com limite por semana ou mês (`limite`, `limite_periodo`), limite compartilhado entre itens (`limite_grupo`, ex.: cinema e jantar dividem 1 passeio por semana) e item dividido (`divide`, ex.: jantar fora, cada criança paga a sua metade). Toda troca vira pedido; no item dividido o pedido espera todos pagarem (`aguardando` → `pedido`). Pais marcam como combinado (`entregar_resgate`) ou cancelam e devolvem os pontos (`cancelar_resgate`). A criança cancela o que ainda aguarda a outra metade.
- **Compra lançada pelos pais** (Mais › Lançar médias e pontos, função `lancar_compra`): item da loja ou compra livre, na data escolhida (até hoje), para uma ou mais crianças; o total é dividido igualmente (aceita meio ponto). Não checa saldo nem limite (o app avisa); vira pedido `entregue` com `resgates.dia` = data da compra, que é a data usada no limite da semana/mês. Compra livre tem `premio` nulo.
- **Plano de estudo marcado sozinho:** na criança, um item do plano que cita a matéria (ex.: "Inglês: ... + treino") é marcado quando ela faz o estudo ou o treino no app naquele dia; "Treinos das N matérias (70%+)" exige treino com 70% ou mais em cada uma da missão; "Prova valendo" exige uma prova no dia. Itens sem matéria (livro, por exemplo) continuam manuais.
- **Concluir treino:** na matéria, a criança repassa as questões que errou e as que ainda não respondeu, em rodadas de 10 (erradas primeiro). Uma questão está "certa" quando a última resposta dela, em qualquer treino, bate com o gabarito (o banco compara; o campo `c` enviado pelo aparelho é ignorado). Quando todas as questões de treino da matéria estão certas e ela tem pelo menos 50 (`concluir_min_questoes`), vale +150 (`pts_conclusao`), uma vez por matéria e por quantidade de questões (se entrarem questões novas e ela concluir de novo, vale de novo). As rodadas ficam em `tentativas` com tipo `revisao` e não entram na "melhor nota" do treino nem na missão. Perder pontos pela nota também retira esse bônus.
- **Perda de pontos pela nota:** em Mais › Lançar médias, ao lado de cada matéria aparece o total de pontos de tópico e treino ainda valendo, com o botão "Tirar" (destacado quando a média está abaixo do mínimo). Retira só tópico e treino, não a prova valendo, e cada crédito só é retirado uma vez. O saldo pode ficar negativo se a criança já gastou.
- Lançamentos não se editam nem se apagam; correção é estorno. Cada um grava o valor do momento.
- Tarefa marcada como feita só vale depois de validada; os pontos caem na data da tarefa. Decisão só muda por recurso (até 5 dias, um por tarefa/dia; decisão dos pais é final).
- Criança marca hoje ou ontem; depois disso, sem marcação = não feito (calculado, sem rotina agendada).
- Tarefas têm dias da semana e período do dia (manhã, tarde, noite). Revezamento: contagem de dias em que a tarefa acontece desde `tarefas.base` (ou desde o último recomeço), pulando dias pausados; fuso America/Sao_Paulo.
- **Trocar quem faz** (Agenda › Trocar, só pai ou mãe, função `trocar_responsavel`): só aquele dia ou daquele dia em diante. Revezamento: um dia vai para `trocas`; em diante grava um recomeço em `revez_inicios` (a vez recomeça pela criança escolhida). "Todos": a escolhida faz no lugar da outra (`substituicoes`), só se ainda não faz a tarefa no dia. Não se troca dia já marcado.
- Tarefas, prêmios e matérias se desativam, não se excluem.
- **Tema:** Automático (segue o aparelho), Claro ou Escuro, guardado no aparelho (`localStorage.tema`). Pais escolhem em Mais; crianças, no fim da tela Hoje.

### Testes do banco
`supabase/testes/`: um Postgres local com uma imitação mínima do Supabase (`00_stub.sql`). Carregar `banco.sql`, um backup dos dados, `01_questoes_amostra.sql` e as migrações 01 a 04; rodar `02_testes.sql`; aplicar a 05 e rodar `03_testes_cofrinho.sql` (teto semanal, limites da loja, jantar dividido, pontos automáticos, agenda e segurança); aplicar a 06 e rodar `04_testes_perda_estudo.sql`. Os testes da 07 (`05_testes_concluir_treino.sql`) criam os próprios dados: rodar num banco novo com as migrações 01 a 07. Num banco novo, carregar `00_stub.sql`, `banco.sql` e `00_perfis.sql` (perfis com os mesmos ids da produção) antes das migrações. Sem Postgres instalado, dá para rodar no PGlite (Postgres em Node), ignorando as linhas `\set`/`\pset` do psql. `06_testes_trocar_responsavel.sql` testa a 08 (banco novo com 01 a 08). `07_testes_compra_pais.sql` testa a 09 (banco novo com 01 a 09). Cada linha impressa traz o esperado no rótulo.
