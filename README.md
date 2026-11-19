# Estudos

App web da família para estudos, tarefas da casa e recompensas. É uma página só (`index.html`, JS puro + supabase-js via CDN) com backend no Supabase.

## Rodar localmente
```
python3 -m http.server 8000   # abrir http://localhost:8000
```
Atenção: o app aponta para o banco de **produção** (URL e chave pública no `index.html`).

## Banco
1. `banco.sql`: estrutura original (v1).
2. `supabase/migrations/20261119_01_multi_alunos.sql`: vários alunos, matérias por aluno, tarefas da casa, revezamento, pausas, recursos, prêmios e livro-razão de recompensas.
3. `supabase/migrations/20261119_02_seed_davi.sql`: matérias, tópicos e cronograma do Davi, que antes estavam no código.

Rodar 2 e 3 no SQL Editor, nessa ordem, junto com a publicação do novo `index.html`. Cada arquivo é uma transação: se falhar, nada muda.

### Regras principais
- Cada criança vê só os próprios dados; pai e mãe veem tudo (RLS + `pode_ver()`).
- Recompensas por grupo (`grupos`): notas → R$, estudos → minutos de tela, casa → pontos para a loja. Tipo, teto e expiração são editáveis pelos pais.
- Saldo = soma de `lancamentos`. Lançamentos não se editam nem se apagam; correção é estorno. Cada um grava o valor do momento.
- Tarefa marcada como feita só vale depois de validada; os pontos caem na data da tarefa. Decisão só muda por recurso (até 5 dias, um por tarefa/dia; decisão dos pais é final).
- Criança marca hoje ou ontem; depois disso, sem marcação = não feito (calculado, sem rotina agendada).
- Revezamento: contagem absoluta de dias desde `tarefas.base`, pulando dias pausados; fuso America/Sao_Paulo. Trocas manuais em `trocas`.
- Tarefas, prêmios e matérias se desativam, não se excluem.

### Testes do banco
`supabase/testes/`: um Postgres local com uma imitação mínima do Supabase (`00_stub.sql`). Carregar `banco.sql`, um backup dos dados, `01_questoes_amostra.sql`, as migrações e depois `02_testes.sql`, que entra como cada pessoa e confere as regras.
