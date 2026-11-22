# Plano de estudo: marcar o que foi adiantado (plano de implementação)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** o item do plano de estudo é marcado sozinho também quando a criança fez o estudo ou o treino até 7 dias antes, um item por atividade.

**Architecture:** uma função nova `marcasAuto()` no `index.html` calcula, a partir de `S.crono`, `S.tent` e `S.prog`, quais itens estão marcados sozinhos (no dia ou adiantados). `autoFeito` passa a consultar esse resultado. Nada é gravado no banco.

**Tech Stack:** JS puro no `index.html`; teste em Node com `vm` (padrão de `testes-app/missao.mjs`).

**Spec:** `docs/superpowers/specs/2026-11-21-adiantar-plano-design.md`

## Global Constraints
- Janela: atividade feita do dia d−7 ao d−1 do item.
- Uma atividade adiantada marca um item só; treino só marca item de treino, tópico só marca item de estudo.
- No próprio dia, comportamento igual ao de hoje.
- Prova valendo: só no dia, como hoje.
- Treinos da mesma matéria com menos de 60 s de diferença contam como um.
- Só na visão da criança (`ehResp()` → nada é marcado sozinho).
- Textos: "Marcado sozinho: você adiantou em DD/MM"; "Tarefas de casa: você marca só hoje e ontem."

## Review Focus
- Item manual (marcado à mão) não gasta atividade adiantada.
- Item com duas matérias só gasta as atividades se as duas forem cumpridas.
- Treino abaixo do mínimo pedido no item ("70") não marca adiantado.
- Treino com menos de 5 questões não conta (como hoje).
- Tópico desativado ou matéria desativada não conta (usar `S.mats` e `m.topicos`, como hoje).

---

### Task 1: `marcasAuto()` e uso em `autoFeito`, `linhaCrono`, Hoje e Agenda

**Files:**
- Modify: `index.html` (perto de `autoFeito`, linhas 263-280; `linhaCrono`, 557-560; `hojeAluno`, 585; `telaAgenda`, 737)
- Create: `testes-app/adiantar.mjs`

**Interfaces:**
- Produces: `marcasAuto(): Map<string, { adiantado: string|null }>` com chave `"AAAA-MM-DD:i"` (dia e posição do item); `adiantado` = dia mais antigo de atividade adiantada usada, ou `null` se tudo foi no dia.
- `autoFeito(d, i)` → `boolean` (assinatura muda: antes `autoFeito(texto, d)`).

- [ ] **Passo 1: testes que falham** em `testes-app/adiantar.mjs` (uso: `node testes-app/adiantar.mjs index.html`; cada linha OK/FALHA):
  1. treino de Português em 23/11 marca todos os itens de Português de 23/11 (no dia, como hoje), sem "adiantou";
  2. treino 21/11 (100%) marca "🎯 Português: treino" de 23/11 com adiantado = 21/11; 24/11 e 26/11 e o item de estudo de 22/11 não;
  3. treinos 21/11 e 22/11 → 23 e 24/11 marcados, 26/11 não;
  4. dois treinos com 46 ms de diferença → só 23/11;
  5. treino 8 dias antes não marca; 7 dias antes marca;
  6. item "Inglês: treino (70%+)": treino adiantado de 60% não marca, de 80% marca;
  7. dois tópicos de Física concluídos em 18/11 → itens de estudo de Física de 19 e 20/11 marcados; treino de Física adiantado não marca item de estudo;
  8. reserva do dia: treino de Português em 18/11 com item "Português: ... + treino" em 18/11 fica com 18/11 e não adianta 19/11;
  9. "Revisão final: Português e Inglês": marcado com tópicos livres das duas; com só Português, não marca e o tópico vai para o item de estudo de Português seguinte;
  10. item marcado à mão não gasta a atividade (vai para o próximo);
  11. prova em 24/11 não marca "prova valendo" de 25/11; prova em 25/11 marca;
  12. `linhaCrono` do item adiantado mostra "você adiantou em 21/11";
  13. pai ou mãe: `autoFeito` falso;
  14. `telaAgenda` da criança em dia futuro mostra "Tarefas de casa: você marca só hoje e ontem.".
- [ ] **Passo 2:** rodar e ver falhar.
- [ ] **Passo 3:** implementar `marcasAuto()` (requisitos do item com a mesma leitura de texto de hoje; atividades = treinos com 5+ questões, sem duplicados de 60 s, e tópicos concluídos; reserva do dia; itens do mais antigo para o mais novo, cada matéria pega a atividade livre mais antiga da janela; gasta só se todas as matérias forem cumpridas), trocar as chamadas de `autoFeito`, o subtítulo em `linhaCrono` e a frase da Agenda.
- [ ] **Passo 4:** rodar `adiantar.mjs`, `missao.mjs` e `avulsa.mjs`: tudo OK.
- [ ] **Passo 5:** conferir com os dados reais (só lendo): Juju 21/11 → 23/11; Johann 18/11 → 19/11 (Física, Biologia) e 23/11 (revisão).
- [ ] **Passo 6:** atualizar README.md e PENDENCIAS.md; commit (push só com confirmação).
