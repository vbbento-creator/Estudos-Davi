# Ideias 2.1 a 2.4 do Cofrinho: design

Data: 21/11/2026. Fonte: PENDENCIAS.md (seção 2) + decisões tomadas na conversa de 21/11.

## Por quê
O app já está em uso pelas crianças. Pai e mãe precisam de quatro ajustes do dia a dia: trocar quem faz uma tarefa,
validar pela metade quem fez reclamando ou enrolando, descontar compras que já aconteceram fora da loja e escolher o tema.

## Restrições
- Banco de produção, usado pelas crianças. Migração só com confirmação; nada é apagado.
- Mudança que o app antigo não entende entra no ar junto com o novo `index.html`.
- Lançamentos não se editam nem se apagam; correção é estorno. Tarefas/prêmios se desativam, não se excluem.
- Testes em `supabase/testes`, no padrão dos existentes (`t.erro`, `t.como`, rótulo com o esperado).
  Sem Postgres local: roda no PGlite (Node, na pasta temporária), retirando os comandos `\set`/`\pset` do psql.

## Ordem e entregas
Uma migração por item, cada uma com seu teste, publicada junto com o `index.html`, e PENDENCIAS.md + README.md atualizados ao fim de cada item:
1. **2.4 Tema** (só app)
2. **2.1 Trocar o responsável** → `20261121_08_trocar_responsavel.sql`, `06_testes_trocar_responsavel.sql`
3. **2.3 Compra lançada pelos pais** → `20261121_09_compra_pais.sql`, `07_testes_compra_pais.sql`
4. **2.2 Validar pela metade** → `20261121_10_metade.sql`, `08_testes_metade.sql` (o app antigo não entende: obrigatório publicar junto)

## 2.4 Tema claro ou escuro
- Mais › "🎨 Tema": Automático (segue o aparelho), Claro, Escuro. Guardado em `localStorage('tema')`, aplicado em `<html data-theme>` antes do primeiro desenho (sem piscar).
- CSS: as cores escuras passam a valer também para `:root[data-theme="dark"]`; `data-theme="light"` já bloqueia a escura.
- Também aparece na tela de login? **Não** (escolha minha: o Mais só existe logado; o automático cobre o login).

## 2.1 Trocar o responsável pela tarefa
**Decidido:** pai ou mãe trocam direto da tela do dia, em tarefas de revezamento e "todos", escolhendo "só aquele dia" ou "daquele dia em diante".
- Revezamento + daquele dia em diante: **o revezamento recomeça pela criança escolhida** (Juju, Johann, Juju…).
- "Todos": a criança escolhida **faz no lugar** da outra (a original fica sem a tarefa). **Só para quem ainda não faz essa tarefa naquele dia**; se já faz, o app avisa e não troca.

**Banco**
- Revezamento, só aquele dia: continua na tabela `trocas` (o app antigo usa).
- Nova `revez_inicios (tarefa, desde, aluno, por, criado; pk tarefa+desde)`: a partir de `desde`, a vez começa por `aluno` e alterna dali (contando só dias válidos, pulando pausas, como hoje). `responsaveis()` usa o recomeço mais recente ≤ dia; se a criança saiu da tarefa, ignora o recomeço.
- Nova `substituicoes (id, tarefa, de, para, desde, ate (null = em diante), por, criado)` para "todos": no dia, `de` sai e `para` entra.
- RPC `trocar_responsavel(p_tarefa, p_dia, p_de, p_para, p_em_diante)` (só pai/mãe) grava no lugar certo e recusa: tarefa inativa; `para` igual a `de` ou não é criança; em "todos", `para` já faz naquele dia; **`de` já marcou** a tarefa num dia afetado (só aquele dia, ou de `p_dia` até hoje se em diante).
- Tabelas novas: leitura por família (`is_familia()`), escrita só pela RPC.

**App**
- Agenda (pai/mãe): botão "Trocar" em cada tarefa ainda não marcada → escolher criança + "Só este dia" / "Deste dia em diante".
- Cadastros: o "Trocar o responsável de um dia" atual some (fica tudo na Agenda).
- "Revezamento" no Hoje dos pais já reflete (usa `responsaveis`).

## 2.3 Pai e mãe lançarem compras
**Decidido:** valor por item da loja (custo vira total sugerido, editável) ou descrição + pontos livres; data escolhida; uma ou mais crianças, **total dividido igualmente, aceitando meio ponto** (95 ÷ 2 = 47,5); sem saldo ou acima do limite o app avisa mas deixa; para a criança aparece como compra já combinada (entregue); estorno = lançamento ao contrário (Ajuste manual).

**Banco**
- `resgates.premio` passa a aceitar nulo (compra livre); nova coluna `resgates.dia` (data do fato; nula = data do pedido).
- `_usado_loja` conta pela data do fato (`coalesce(dia, criado)`), então a compra entra no limite da semana/mês dela.
- RPC `lancar_compra(p_alunos uuid[], p_premio bigint, p_qtd int, p_descricao text, p_total numeric, p_dia date)` (só pai/mãe): para cada criança, `_lancar(-total/n, 'loja', p_dia, 'resgate', ...)` sem checar saldo e um `resgates` com status `entregue`, `dia = p_dia`. Recusa: total ≤ 0, nenhuma criança, data no futuro, item inexistente.

**App**
- Em Mais › Lançar médias e pontos, card novo "🛍️ Compra que já aconteceu": item da loja (ou "Outro"), quantidade (para itens com unidade), total sugerido = custo × quantidade (× `divide` no item dividido), editável; descrição; data (qualquer dia até hoje, sem valor pré-preenchido: pai ou mãe escolhem); crianças marcadas. Mostra quanto cada uma paga e avisa (antes de confirmar) quem fica negativo ou passa do limite.
- Na Loja da criança e nos pedidos dos pais, compra sem item aparece com 🧾.

## 2.2 Validar pela metade
**Decidido:** terceira decisão "metade" = 50% dos pontos; motivo obrigatório **reclamou** ou **enrolou**, comentário opcional, a criança vê; criança pode recorrer; no teto conta só o que foi creditado. No recurso contra metade, pai/mãe escolhem **validar inteira** ou **manter a metade**; no recurso contra rejeição, também podem dar **metade**.

**Banco**
- `tarefa_dia.decisao` e `recursos.decisao_final` aceitam `metade`; colunas novas `tarefa_dia.motivo` (`reclamou`/`enrolou`) e `tarefa_dia.motivo_comentario`.
- `_aplicar_decisao` passa a acertar pela diferença: alvo (valor, valor/2 ou 0) menos o já creditado para aquela tarefa/dia/criança; diferença positiva vira crédito (`tarefa`, sujeito ao teto), negativa vira `estorno`.
- `decidir_tarefa(..., p_motivo default null, p_comentario default null)`: `metade` exige motivo. Mantém a chamada antiga funcionando.
- `resolver_recurso(..., p_motivo default null)`: se a decisão atual é metade, só aceita validado ou metade; metade vinda de rejeição exige motivo.
- `tarefas_do_dia` e `agenda_tarefas` devolvem também `motivo` e `motivo_comentario`.

**App**
- Pai/mãe (Aprovar e Agenda): botões Rejeitar · ½ Metade · Validar; "½ Metade" abre Reclamou / Enrolou + comentário.
- Criança: tarefa "validado pela metade · +10 · reclamou: …", com o recurso "Não concordo".
- Recursos: botões conforme a decisão atual (Validar inteira / Manter metade; ou Validar / Metade / Manter rejeitada).
- Cor/ícone próprio para metade (½, tom de aviso).

## Fora do escopo
Missão automática (2.5); mudar a chave de `tarefa_dia`; editar/apagar lançamentos.
