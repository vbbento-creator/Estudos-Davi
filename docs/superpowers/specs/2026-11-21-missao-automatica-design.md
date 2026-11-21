# 2.5 Missão automática — design

## Por quê
O bônus da missão (bronze/prata/ouro) depende de pai ou mãe lembrarem de tocar em **Lançar** depois do prazo. A missão do Johann acabou em 19/11 e ficou sem lançar. Além disso, pai e mãe querem que as **tarefas de casa** contem para a missão, só depois de validadas.

## Objetivo
- Depois do prazo, os pontos da missão **caem sozinhos** no extrato, sem ninguém tocar em Lançar.
- O nível passa a considerar também as **tarefas de casa validadas** no período da missão.
- Só fecha a conta quando não sobra nada da missão esperando pai ou mãe (tarefa marcada sem decisão, recurso aberto).

## Regras (decididas com pai/mãe)
| Item | Como entra |
|---|---|
| Tópicos (Estudei + Fiz exercícios) | automático, como hoje (`concluido_em` até o prazo); os +30 do tópico continuam na hora |
| Treinos e provas do app | automático, como hoje: melhor treino ≥ `treino_min` (treino com 5+ questões), melhor prova ≥ `prova_min` em `prova_qtd` matérias, só tentativas até o prazo |
| Tarefas de casa | **novo**: porcentagem mínima por nível das tarefas do período, só decisões dos pais contam |
| Médias da escola | **fora da missão**, como hoje (lançamento "Médias" à parte) |

- Níveis continuam encadeados: prata exige bronze, ouro exige prata. Vale só o mais alto.
- **Tarefas (opção A escolhida):** cada nível tem um mínimo próprio, padrão bronze 70%, prata 80%, ouro 90%, editável em Cadastros › Pontos.
  - Conta de cada tarefa do período: validada = 1, ½ metade = 0,5, rejeitada / não feita / não marcada = 0. Recurso decidido vale a decisão final.
  - Período: de **Começa em** (novo campo, data) até o **dia do prazo**, inclusive. Tarefas do período = as que a criança tinha naquele dia (mesma regra da Agenda: `responsaveis`, pausas, trocas, avulsas), mais as que já estão em `tarefa_dia`.
  - Sem nenhuma tarefa no período: o critério de tarefas é cumprido.
- **Missão sem "Começa em"** (regras antigas, caso da missão do Johann de 19/11): não tem critério de tarefas. Por isso a do Johann fecha sozinha com **bronze +150** assim que o app novo abrir (decisão: fechar pelas regras antigas).

## Quando os pontos caem
- **Missão com tarefas:** a partir de **2 dias depois do dia do prazo** (a criança ainda pode marcar o dia do prazo no dia seguinte) e sem pendências no período: nenhuma tarefa `feito` sem decisão e nenhum recurso sem decisão final.
- **Missão sem tarefas:** logo depois do prazo (data e hora).
- O fechamento roda quando qualquer pessoa da família abre o app (e a cada recarregar). Lança no grupo `estudos`, `origem = 'nivel'`, data de referência = dia do prazo, descrição "Missão: nível <nível>".
- Nenhum nível: nada é lançado.
- Um lançamento só por missão: `origem_ref = 'meta:' || <prazo em São Paulo, 'YYYY-MM-DD HH24:MI'>`, protegido pelo índice único `lancamentos_unico`. Salvar de novo a mesma data em Cadastros não muda mais a referência (hoje muda, porque o texto do prazo é regravado em UTC).
- O teto do grupo continua valendo (como no lançamento manual de hoje).

## Abordagens
- **1) Cálculo no banco, fechamento ao abrir o app (escolhida).** Uma função calcula o nível (tópicos, treinos, provas, tarefas); outra fecha as missões vencidas. App e banco usam o mesmo cálculo.
- 2) Igual à 1 com pg_cron de hora em hora: exige ligar pg_cron no projeto; sem ganho real para uma família que abre o app todo dia. Pode ser somado depois.
- 3) Cálculo no aparelho com lançamento ao abrir: só pai/mãe podem lançar (dependeria deles abrirem) e a regra ficaria duplicada. Descartada.
- Fora: tabela própria de missões com histórico (continua uma missão por vez por criança, em `grupos.config`).

## Banco (migração 12)
- `missao(p_aluno uuid) returns jsonb` — `security definer`, exige `pode_ver(p_aluno)`. Lê `grupos.config` do grupo `estudos` e devolve tudo que a tela precisa: prazo, início, matérias, mínimos, pontos, detalhe por matéria (bronze ok, melhor treino, melhor prova), tarefas (total, pontos obtidos, porcentagem, pendentes), nível, valor, `pode_fechar`, `lancada` (existe o lançamento com a referência). Nulo se não há prazo ou matérias.
- `fechar_missoes() returns int` — `security definer`, exige `is_familia()`. Para cada criança com missão em que `pode_fechar` e nível com valor > 0 e ainda não lançada, chama `_lancar` (ignora conflito do índice único). Devolve quantas lançou.
- Config nova em `grupos.config` (estudos): `inicio` (data `YYYY-MM-DD` ou nulo), `tarefas_min` (`{"bronze":70,"prata":80,"ouro":90}`). Sem `drop`; só funções novas. O app antigo continua funcionando, mas entra no ar junto com o novo `index.html` (o botão Lançar antigo usaria a referência antiga).
- Execução: `revoke ... from public, anon; grant ... to authenticated`.
- Testes: `supabase/testes/10_testes_missao.sql` (banco novo, migrações 01 a 12): níveis por tópicos/treino/prova iguais ao app; porcentagem de tarefas (validada, metade, rejeitada, não marcada, pausa, troca, avulsa); pendência segura o fechamento; espera de 2 dias; missão sem início fecha logo após o prazo; não lança duas vezes (inclusive após regravar o prazo no mesmo minuto); nenhum nível não lança; criança abrindo o app fecha; anon não executa.

## App (`index.html`)
- `calcMeta()` passa a usar o resultado de `missao()` (carregado junto com os dados da criança) — mesma forma de objeto para não mexer nas telas que já o usam.
- Ao carregar (`recarregar`), chama `fechar_missoes()` antes de buscar o extrato.
- **Criança (tela de pontos):** mostra também "Tarefas: 76% (mínimo 70 / 80 / 90)". Depois do prazo: "Aguardando validação de N tarefas", ou "Lançada ✓ prata +250", ou "Nenhum nível". Some o texto "O pai ou a mãe lançam…".
- **Mais › Lançar:** sai o botão Lançar da missão; fica o estado (lançada / aguardando N tarefas / prazo ainda não acabou / nenhum nível).
- **Precisa de você (pais):** quando uma missão vencida está esperando validação, aviso "Missão de <nome> esperando N tarefas" que leva à aba de validar.
- **Cadastros › Pontos:** campos **Começa em** (data) e **Tarefas mínimas (%)** por nível. Ao salvar com prazo, "Começa em" é obrigatório e anterior ao prazo.
- Teste de telas: `testes-app/missao.mjs`, no padrão de `testes-app/avulsa.mjs`.

## Decisões minhas (para conferir)
- Tarefas contam por quantidade (cada tarefa vale 1), não pelo valor em pontos.
- Sem tarefas no período, o critério de tarefas é cumprido.
- Missão sem "Começa em" = regras antigas, sem critério de tarefas (resolve a do Johann sem lançamento manual).
- Espera de 2 dias depois do prazo quando há tarefas.
- Recurso aberto depois do fechamento não muda o que já foi lançado (ajuste manual, se precisar).
- Fechamento só ao abrir o app (sem pg_cron).
