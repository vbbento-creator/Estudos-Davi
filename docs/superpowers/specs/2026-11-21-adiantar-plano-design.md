# Plano de estudo: marcar sozinho o que a criança adiantou (design curto)

21/11/2026. Pedido: a criança pode fazer estudo e treino antes do dia previsto no plano, e o app deve reconhecer.

## Por quê
Hoje o item do plano só é marcado sozinho se o estudo ou o treino foi feito **no próprio dia** do item (`autoFeito` em `index.html`). Quem adianta fica com o item em aberto. Ex.: a Juju fez treino de Português em 21/11 (100%) e o plano tem "🎯 Português: treino" em 23, 24 e 26/11; o Johann concluiu tópicos e treinou Física e Biologia em 18/11, que o plano punha em 19/11.

## Regras (decididas com a pessoa usuária)
- **Um treino ou tópico adiantado marca um item só**, e não os demais.
- **Vale até 7 dias antes** do dia do item (do dia d−7 ao d−1).
- No próprio dia, nada muda: um treino feito no dia continua marcando todos os itens daquela matéria naquele dia.

## Calls minhas (a corrigir se preciso)
- **Mesmo tipo:** treino adiantado marca o próximo item de **treino** da matéria (texto com "treino"), se a nota alcançar o mínimo do item (70% quando o texto pede "70"); tópico concluído adiantado marca o próximo item de **estudo** da matéria (texto sem "treino"). Treino adiantado não marca item de estudo.
- **Reserva do dia:** em cada dia, o primeiro treino e o primeiro tópico de cada matéria ficam com os itens daquele dia, se houver item daquela matéria que eles cumpram; os outros ficam livres para adiantar.
- **Ordem:** os itens são vistos do mais antigo para o mais novo; cada item pega a atividade livre mais antiga que serve. Item com mais de uma matéria ("Revisão final: História e Geografia") precisa de uma atividade para cada matéria; só gasta as atividades se todas as matérias forem cumpridas.
- **Reserva do dia, na prática:** um treino feito num dia que tem item de estudo daquela matéria marca esse item e não adianta o seguinte (ex.: treino de Português em 22/11 marca "Português: verbos" de 22/11, e não o treino de 23/11). Para adiantar, é preciso um segundo treino.
- **Treino repetido por duplo toque:** dois treinos da mesma matéria, com a mesma nota e menos de 60 segundos de diferença, contam como um (há casos assim no banco, em 18/11).
- **Prova valendo** continua só no dia (depende de pai ou mãe liberarem).
- Só na visão da criança, como hoje (pai e mãe veem o que está gravado). Itens do plano não dão pontos; é só o ✓.
- Subtítulo do item marcado adiantado: "Marcado sozinho: você adiantou em DD/MM".
- Na Agenda da criança, em dia futuro, a frase "Você marca só hoje e ontem." vira "Tarefas de casa: você marca só hoje e ontem.".

## Efeito conhecido
Os tópicos de Português e Inglês do Johann em 18/11 (não usados naquele dia) passam a marcar a "Revisão final: Português e Inglês" de 23/11 (5 dias). A pessoa usuária aceitou ao escolher 7 dias. Conferido com os dados reais depois de pronto: os 2 tópicos de Física e os 2 de Biologia de 18/11 marcam os itens de 19/11 e também a "Revisão Física e Biologia" de 23/11. Item marcado sozinho não se desmarca.

## Abordagem
Só `index.html`: o app calcula as marcas uma vez por tela a partir de `S.crono`, `S.tent` e `S.prog` (que ele já carrega), sem gravar nada. Alternativas descartadas: gravar as marcas no banco (mais escritas e risco de divergir) ou calcular no banco (migração para algo que não dá pontos).

## Testes
`testes-app/adiantar.mjs` (sem banco), no padrão de `testes-app/missao.mjs`.
