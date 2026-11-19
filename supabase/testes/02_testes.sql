\set ON_ERROR_STOP 1
\pset format unaligned
\pset tuples_only on
create schema t; grant usage on schema t to authenticated;
create function t.erro(q text) returns text language plpgsql as $$
begin execute q; return 'OK (sem erro)'; exception when others then return 'ERRO: ' || sqlerrm; end $$;
create function t.como(u text) returns void language sql as $$ select set_config('request.jwt.claim.sub', u, false) $$;
grant execute on all functions in schema t to authenticated;
create temp table ids as select 'd5c2215c-797c-435b-859b-09be1fe3efbf'::uuid davi, '014341f0-99f3-4e14-b21d-6b4efc9bafbd'::uuid juju,
  '78768c03-68d4-420f-ba5d-c7fe46434042'::uuid pai, (select id from tarefas limit 1) kika;
grant select on ids to authenticated;
insert into premios (nome, custo) values ('Sorvete', 5), ('Viagem', 100);
insert into tarefas (nome, pontos, modo, alunos, base) select 'Arrumar a cama', 3, 'todos', array[davi, juju], hoje_sp()-5 from ids;
create temp table ids2 as select id cama from tarefas where nome='Arrumar a cama'; grant select on ids2 to authenticated;
set role authenticated;

\echo '--- 1. Isolamento do progresso (esperado: Davi 13, Juju 0, Pai 13, intruso 0)'
select t.como(davi::text) from ids; select 'Davi vê', count(*) from progresso;
select t.como(juju::text) from ids; select 'Juju vê', count(*) from progresso;
select t.como(pai::text) from ids;  select 'Pai vê', count(*) from progresso;
select t.como('99999999-9999-9999-9999-999999999999'); select 'Intruso vê', count(*) from progresso;
select 'Intruso grava', t.erro($$insert into progresso (chave, estudou) values ('x:0', true)$$);

\echo '--- 2. Juju grava o próprio progresso; não grava no do Davi'
select t.como(juju::text) from ids;
select 'Juju própria', t.erro($$insert into progresso (chave, estudou) values ('portugues:0', true)$$);
select 'Juju no Davi', t.erro($$insert into progresso (aluno, chave) values ('d5c2215c-797c-435b-859b-09be1fe3efbf','fisica:9')$$);
with u as (update progresso set duvida='hack' where aluno <> auth.uid() returning 1) select 'Juju altera Davi (linhas)', count(*) from u;

\echo '--- 3. Questões e gabarito (esperado: Davi 1 treino + 1 gabarito; Juju 0)'
select t.como(davi::text) from ids; select 'Davi questões', count(*), 'gabarito', (select count(*) from gabarito) from questoes;
select t.como(juju::text) from ids; select 'Juju questões', count(*), 'gabarito', (select count(*) from gabarito) from questoes;
select 'Juju matérias', count(*) from materias; select 'Juju grupos', count(*) from grupos;

\echo '--- 4. Prova valendo por aluno'
select t.como(pai::text) from ids;
insert into liberacoes (aluno, materia, ate) select davi, 'fisica', now() + interval '30 min' from ids;
select t.como(davi::text) from ids; select 'Davi vê questões após liberar', count(*) from questoes;
select 'Davi corrige', corrigir_prova('fisica', '{"fis-p01":2,"fis-p02":1}')->>'pct';
select t.como(juju::text) from ids; select 'Juju vê questões', count(*) from questoes;
select 'Juju corrige', t.erro($$select corrigir_prova('fisica','{}')$$);

\echo '--- 5. Revezamento da Kika (base 18/11 = Juju)'
select t.como(pai::text) from ids;
select 'dia ' || to_char(d,'DD/MM'), (select nome from perfis where user_id = (responsaveis(kika, d))[1]) from ids, generate_series('2026-11-18'::date, '2026-11-21', '1 day') g, lateral (select g::date d) x;
select 'virada 30/11, 01/12', (select nome from perfis where user_id=(responsaveis(kika,'2026-11-30'))[1]), (select nome from perfis where user_id=(responsaveis(kika,'2026-12-01'))[1]) from ids;
insert into pausas (inicio, fim, motivo) values ('2026-11-21','2026-11-22','viagem');
select 'com pausa 21-22/11: 20,21,22,23 =', (select nome from perfis where user_id=(responsaveis(kika,'2026-11-20'))[1]),
  coalesce((select nome from perfis where user_id=(responsaveis(kika,'2026-11-21'))[1]),'(pausado)'),
  coalesce((select nome from perfis where user_id=(responsaveis(kika,'2026-11-22'))[1]),'(pausado)'),
  (select nome from perfis where user_id=(responsaveis(kika,'2026-11-23'))[1]) from ids;
delete from pausas;
insert into trocas (tarefa, dia, aluno) select kika, '2026-11-20', juju from ids;
select 'troca manual 20/11 →', (select nome from perfis where user_id=(responsaveis(kika,'2026-11-20'))[1]), '21/11 continua', (select nome from perfis where user_id=(responsaveis(kika,'2026-11-21'))[1]) from ids;
delete from trocas;

\echo '--- 6. Marcar, validar, saldo (hoje SP =' `date +%F`')'
create temp table dias as select
  (select d::date from ids, generate_series(hoje_sp()-1, hoje_sp(), '1 day') d where (responsaveis(kika,d::date))[1]=juju limit 1) dj,
  (select d::date from ids, generate_series(hoje_sp()-1, hoje_sp(), '1 day') d where (responsaveis(kika,d::date))[1]=davi limit 1) dd;
select 'dia da Juju', dj, 'dia do Davi', dd from dias;
select t.como(davi::text) from ids;
select 'Davi marca dia da Juju', t.erro(format($$select marcar_tarefa(%s,%L,'feito')$$, kika, dj)) from ids, dias;
select 'Davi marca futuro', t.erro(format($$select marcar_tarefa(%s,%L,'feito')$$, kika, hoje_sp()+2)) from ids;
select 'Davi marca dia antigo', t.erro(format($$select marcar_tarefa(%s,%L,'feito')$$, kika, hoje_sp()-4)) from ids;
select 'Davi lança minutos', t.erro($$select lancar(auth.uid(),'estudos',60,'hack')$$);
select 'Davi insere no livro', t.erro($$insert into lancamentos (aluno,grupo,moeda,valor,descricao) values (auth.uid(),'casa','pontos',99,'hack')$$);
select t.como(juju::text) from ids;
select 'Juju marca o dela', t.erro(format($$select marcar_tarefa(%s,%L,'feito')$$, kika, dj)) from ids, dias;
select 'Juju saldo antes de validar', saldo(juju,'casa') from ids;
select 'Juju status', status, decisao, pode_marcar from ids, dias, tarefas_do_dia(juju, dj);
select t.como(pai::text) from ids;
select 'Pai valida', t.erro(format($$select decidir_tarefa(%s,%L,%L,'validado')$$, kika, dj, juju)) from ids, dias;
select 'Pai muda decisão', t.erro(format($$select decidir_tarefa(%s,%L,%L,'rejeitado')$$, kika, dj, juju)) from ids, dias;
select 'Juju saldo', saldo(juju,'casa'), 'lançamento na data', (select data_ref = dj from lancamentos where aluno = juju and origem='tarefa') from ids, dias;
select t.como(juju::text) from ids;
select 'Juju desmarca decidida', t.erro(format($$select marcar_tarefa(%s,%L,null)$$, kika, dj)) from ids, dias;
select 'Juju resgata sorvete(5)', t.erro($$select resgatar((select id from premios where nome='Sorvete'))$$);
select 'saldo após resgate', saldo(juju,'casa') from ids;
select 'Juju resgata viagem(100)', t.erro($$select resgatar((select id from premios where nome='Viagem'))$$);

\echo '--- 7. Recurso (Davi: rejeitado → recurso → validado)'
select t.como(davi::text) from ids;
select 'Davi marca', t.erro(format($$select marcar_tarefa(%s,%L,'feito')$$, cama, hoje_sp())) from ids, ids2;
select t.como(pai::text) from ids;
select 'Pai rejeita', t.erro(format($$select decidir_tarefa(%s,%L,%L,'rejeitado')$$, cama, hoje_sp(), davi)) from ids, ids2;
select t.como(davi::text) from ids;
select 'pode recorrer?', pode_recorrer from ids, ids2, tarefas_do_dia(davi, hoje_sp()) where tarefa = cama;
select 'Davi recorre', t.erro(format($$select abrir_recurso(%s,%L,'Eu passeei sim, a mãe viu')$$, cama, hoje_sp())) from ids, ids2;
select 'Davi recorre 2x', t.erro(format($$select abrir_recurso(%s,%L,'de novo')$$, cama, hoje_sp())) from ids, ids2;
select t.como(pai::text) from ids;
select 'Pai resolve', t.erro($$select resolver_recurso((select id from recursos limit 1),'validado','ok, confirmei')$$);
select 'Pai resolve 2x', t.erro($$select resolver_recurso((select id from recursos limit 1),'rejeitado')$$);
select 'Davi saldo casa', saldo(davi,'casa') from ids;
select t.como(juju::text) from ids; select 'Juju vê recursos/lançamentos do Davi', (select count(*) from recursos), (select count(*) from lancamentos where aluno <> auth.uid());

\echo '--- 8. Teto semanal de minutos (840) e uso'
select t.como(pai::text) from ids;
select 'Pai lança 900 min', lancar(davi,'estudos',900,'Ouro') is not null from ids;
select 'saldo (teto 840)', saldo(davi,'estudos') from ids;
select 'Pai lança mais 60', coalesce(lancar(davi,'estudos',60,'extra')::text,'ignorado pelo teto') from ids;
select 'Uso -60', lancar(davi,'estudos',-60,'GTA sábado','2026-11-21','uso') is not null from ids;
select 'saldo após uso', saldo(davi,'estudos') from ids;
select 'ganha +60 após usar', coalesce(lancar(davi,'estudos',60,'extra')::text,'ignorado pelo teto') from ids;
select 'Uso além do saldo', t.erro($$select lancar('d5c2215c-797c-435b-859b-09be1fe3efbf','estudos',-9999,'x',null,'uso')$$);
select 'Semana seguinte (expirou)', saldo(davi,'estudos', hoje_sp()+7) from ids;
select 'Nível 2x', t.erro($$select lancar('d5c2215c-797c-435b-859b-09be1fe3efbf','notas',10,'P2',null,'notas','P2-2026')$$), t.erro($$select lancar('d5c2215c-797c-435b-859b-09be1fe3efbf','notas',10,'P2',null,'notas','P2-2026')$$);

\echo '--- 9. Não-feito automático e exclusões'
select 'Davi cama há 3 dias / ontem / hoje', (select status from tarefas_do_dia(davi, hoje_sp()-3) where tarefa=cama), (select status from tarefas_do_dia(davi, hoje_sp()-1) where tarefa=cama), (select status from tarefas_do_dia(davi, hoje_sp()) where tarefa=cama) from ids, ids2;
insert into pausas (inicio, fim) values (hoje_sp()-3, hoje_sp()-3);
select 'dia pausado: tarefas cobradas', count(*) from ids, tarefas_do_dia(davi, hoje_sp()-3);
select 'Pai exclui tarefa', t.erro($$delete from tarefas$$);
select 'Pai exclui lançamento', t.erro($$delete from lancamentos$$);
select 'Pai desativa tarefa', t.erro($$update tarefas set ativa = false$$);
