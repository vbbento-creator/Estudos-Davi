# 2.6 Tarefa avulsa (um dia só) — design

## Por quê
Pai e mãe querem pedir uma tarefa que vale só para um dia (ex.: "ajudar a lavar o carro" no sábado), com pontos, sem que ela se repita. Hoje toda tarefa se repete até ser desativada; desativar antes da marcação impede a criança de marcar.

## Objetivo
- Pai ou mãe criam, **na Agenda**, uma tarefa avulsa para o dia selecionado, para uma ou mais crianças.
- Ela se comporta como qualquer tarefa naquele dia: marcar, validar, ½ metade, rejeitar, recurso, teto semanal, extrato.
- Depois do dia ela não aparece mais (o que foi marcado continua na Agenda e no extrato).

## Fora do escopo
- Campo "Termina em" no cadastro para tarefas comuns (o banco já fica pronto para isso, a tela não).
- Criança criar tarefa (só pai e mãe; a RLS de `tarefas` já garante: `tarefas_admin` = `is_responsavel()`).
- Revezamento em avulsa (um dia só: cada criança marcada faz a sua).

## Abordagens
- **A) Data de fim em `tarefas` (escolhida).** Coluna `ate date` opcional; avulsa = `base = ate = dia`, `modo = 'todos'`, `dias_semana = null`. `responsaveis()` devolve vazio quando `d > ate`. Tudo que passa por `responsaveis` (agenda, tarefas do dia, marcar, trocar) respeita sem mais mudanças. Migração pequena, sem `drop`.
- B) Campo "dia único": mesmo efeito, menos geral. Descartada.
- C) Tabela própria de avulsas: refaria marcar/decidir/metade/recurso/teto. Descartada.

## Banco (migração 11)
- `alter table tarefas add column ate date` + `check (ate is null or ate >= base)`.
- `responsaveis()`: `if t is null or d < t.base or (t.ate is not null and d > t.ate) or dia_pausado(d) then return '{}'`.
- Compatível com o app antigo (ignora a coluna; o update do cadastro antigo não mexe em `ate`). Mesmo assim, entra no ar junto com o novo `index.html`.
- Testes: `supabase/testes/09_testes_tarefa_avulsa.sql` (banco novo, migrações 01 a 11): aparece só no dia, some antes e depois, várias crianças, marcar/validar/metade creditam e respeitam o teto, dia pausado, check `ate >= base`, desativar esconde se não marcada, criança não consegue inserir.

## App (`index.html`)
- **Agenda (só pais):** botão **+ Tarefa avulsa** no card do dia selecionado. Formulário inline: emoji, nome, pontos (padrão 5), período (padrão "o dia todo"), crianças (pré-marcadas pelo filtro: todas em "Todos", senão a filtrada). Insere em `tarefas` com `base = ate = dia`, `modo = 'todos'`.
- **Dias permitidos:** de 7 dias atrás até o fim da janela da Agenda (+27), exceto dia pausado (aviso em vez do botão).
- **Remover:** na linha da avulsa, enquanto nenhuma criança marcou naquele dia, botão Remover = desativar (`ativa = false`).
- **Trocar** numa avulsa: só "Só este dia".
- **Etiqueta "avulsa"** na linha, para pais e crianças (Agenda e Hoje).
- **Cadastro › Tarefas:** avulsas ainda por vir com etiqueta "avulsa · dd/mm" e formulário reduzido (dia em vez de "Começa em", sem modo e dias da semana); tarefas encerradas (`ate < hoje`) numa lista **Encerradas** recolhida no fim; o resumo "pontos possíveis por semana" ignora tarefas com `ate`.

## Decisões minhas (para conferir)
- Janela de dias permitida (−7 a +27) e bloqueio em dia pausado.
- Remover só enquanto ninguém marcou.
- Etiqueta "avulsa" visível também para a criança.
- Formulário reduzido no cadastro para avulsas.
