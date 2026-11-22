-- O app passou a gerar sozinho o item "🏛️ Matéria: prova valendo" de 2 dias antes da prova até o dia da prova (migração 35
-- e index.html). Tira do plano da Juju os itens escritos à mão pela migração 23, para não aparecerem em dobro.
-- Só tira o item quando ele é o último do dia e cita "prova valendo" com uma matéria ("Português: prova valendo");
-- assim as posições dos outros itens (chaves crono:dia:posição em progresso) não mudam. Pode rodar de novo.
update cronograma c
   set itens = c.itens - (jsonb_array_length(c.itens) - 1)
 where c.aluno = '014341f0-99f3-4e14-b21d-6b4efc9bafbd'
   and jsonb_array_length(c.itens) > 0
   and c.itens ->> (jsonb_array_length(c.itens) - 1) ~ '^🏛️ [^:]+: prova valendo';
