-- Preparo do teste 12: roda DEPOIS das migrações 01 a 23 e ANTES da 24.
-- Cria duas tarefas do jeito antigo (uma com período "manhã", outra sem período), marcadas ontem pelo Johann,
-- validadas pelo pai, e um recurso aberto na de manhã. O teste 12 confere como a 24 converte isso.
insert into tarefas (nome, pontos, modo, alunos, base, periodo)
  values ('OLDM', 5, 'todos', array['d5c2215c-797c-435b-859b-09be1fe3efbf']::uuid[], hoje_sp() - 10, 'manha'),
         ('OLDD', 20, 'todos', array['d5c2215c-797c-435b-859b-09be1fe3efbf']::uuid[], hoje_sp() - 10, null);
-- as duas tarefas de escovar como estão em produção (ids 6 e 7)
insert into tarefas (id, nome, pontos, modo, alunos, base, periodo) overriding system value
  values (6, 'Escovar os dentes (manhã)', 5, 'todos', array['d5c2215c-797c-435b-859b-09be1fe3efbf']::uuid[], hoje_sp() - 10, 'manha'),
         (7, 'Escovar os dentes (noite)', 5, 'todos', array['d5c2215c-797c-435b-859b-09be1fe3efbf']::uuid[], hoje_sp() - 10, 'noite');
select setval(pg_get_serial_sequence('tarefas', 'id'), 100);
set role authenticated;
select set_config('request.jwt.claim.sub', 'd5c2215c-797c-435b-859b-09be1fe3efbf', false);
select marcar_tarefa(6, hoje_sp() - 1, 'feito');
select marcar_tarefa(7, hoje_sp() - 1, 'feito');
select marcar_tarefa((select id from tarefas where nome = 'OLDM'), hoje_sp() - 1, 'feito');
select marcar_tarefa((select id from tarefas where nome = 'OLDD'), hoje_sp() - 1, 'feito');
select set_config('request.jwt.claim.sub', '78768c03-68d4-420f-ba5d-c7fe46434042', false);
select decidir_tarefa((select id from tarefas where nome = 'OLDM'), hoje_sp() - 1, 'd5c2215c-797c-435b-859b-09be1fe3efbf', 'validado');
select decidir_tarefa((select id from tarefas where nome = 'OLDD'), hoje_sp() - 1, 'd5c2215c-797c-435b-859b-09be1fe3efbf', 'validado');
select decidir_tarefa(7, hoje_sp() - 1, 'd5c2215c-797c-435b-859b-09be1fe3efbf', 'validado');
select marcar_tarefa(7, hoje_sp() - 2, 'feito', 'd5c2215c-797c-435b-859b-09be1fe3efbf');
select set_config('request.jwt.claim.sub', 'd5c2215c-797c-435b-859b-09be1fe3efbf', false);
select abrir_recurso((select id from tarefas where nome = 'OLDM'), hoje_sp() - 1, 'Escovei sim');
reset role;
