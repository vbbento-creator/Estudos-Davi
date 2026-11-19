\set ON_ERROR_STOP 1
\pset format unaligned
\pset tuples_only on
-- Testes da migração 05 (Cofrinho). Rodar DEPOIS da 02_testes.sql, com as migrações 01 a 05 aplicadas.
-- Cada linha imprime "rótulo | resultado" e o esperado vem no próprio rótulo.
create schema if not exists t; grant usage on schema t to authenticated;
create or replace function t.erro(q text) returns text language plpgsql as $$
begin execute q; return 'OK (sem erro)'; exception when others then return 'ERRO: ' || sqlerrm; end $$;
create or replace function t.como(u text) returns void language sql as $$ select set_config('request.jwt.claim.sub', u, false) $$;
grant execute on all functions in schema t to authenticated;

create temp table ids as select 'd5c2215c-797c-435b-859b-09be1fe3efbf'::uuid johann, '014341f0-99f3-4e14-b21d-6b4efc9bafbd'::uuid juju,
  '78768c03-68d4-420f-ba5d-c7fe46434042'::uuid pai;
grant select on ids to authenticated;
delete from premios;   -- usa os itens padrão da migração: recria abaixo
insert into premios (nome, emoji, custo, tipo, unidade, limite, limite_periodo, limite_grupo, divide) values
  ('Tela 30', '🎮', 60, 'tela', 30, 28, 'semana', 'tela', 1),
  ('Sorvete', '🍦', 95, 'experiencia', null, 2, 'semana', 'sorvete', 1),
  ('Cinema', '🎬', 400, 'experiencia', null, 1, 'semana', 'passeio', 1),
  ('Jantar metade', '🍽️', 300, 'experiencia', null, 1, 'semana', 'passeio', 2),
  ('Filme', '🍿', 100, 'experiencia', null, null, null, null, 1);
create temp table pr as select
  (select id from premios where nome='Tela 30') tela, (select id from premios where nome='Sorvete') sorvete,
  (select id from premios where nome='Cinema') cinema, (select id from premios where nome='Jantar metade') jantar,
  (select id from premios where nome='Filme') filme;
grant select on pr to authenticated;
-- tarefas de exemplo: 5 tarefas de 100 pontos para estourar o teto de 490 no mesmo dia
insert into tarefas (nome, pontos, modo, alunos, base)
  select 'T' || g, 100, 'todos', array[johann, juju], hoje_sp() - 30 from ids, generate_series(1, 6) g;
set role authenticated;

\echo '--- 1. Configuração migrada (esperado: pontos, teto_semana 490 só na casa)'
select t.como(pai::text) from ids;
select 'grupos', grupo, moeda, expira, teto_semana from grupos where aluno = (select johann from ids) order by grupo;
select 'config estudos', config->'pontos', config->>'pts_topico' from grupos where aluno = (select johann from ids) and grupo = 'estudos';

\echo '--- 2. Teto semanal de 490 (Kika 20 + 6 tarefas de 100, todas validadas no mesmo dia; esperado: saldo 490, a última ignorada)'
select t.como(johann::text) from ids;
select 'Johann marca as 7 (Kika + T1..T6)', count(*) filter (where t.erro(format($$select marcar_tarefa(%s,hoje_sp(),'feito')$$, id)) like 'OK%') from tarefas;
select t.como(pai::text) from ids;
select 'Pai valida as 7', count(*) filter (where t.erro(format($$select decidir_tarefa(%s,hoje_sp(),%L,'validado')$$, id, (select johann from ids))) like 'OK%') from tarefas;
select 'saldo_total Johann (490)', saldo_total(johann) from ids;
select 'lançamentos de tarefa', count(*), sum(valor) from lancamentos where origem = 'tarefa';

\echo '--- 3. Pais ajustam saldo; saldo único não expira (esperado: 490 + 1000 = 1490 hoje e daqui a 400 dias)'
select 'Pai credita 1000 (estudos)', lancar(johann, 'estudos', 1000, 'Missão ouro', null, 'manual') is not null from ids;
select 'saldo hoje', saldo_total(johann) from ids;
select 'Pai debita além do saldo', t.erro($$select lancar('d5c2215c-797c-435b-859b-09be1fe3efbf','estudos',-99999,'x',null,'uso')$$);
select t.como(johann::text) from ids;
select 'Johann lança sozinho', t.erro($$select lancar(auth.uid(),'estudos',50,'hack')$$);
select 'Johann vê saldo da Juju', t.erro($$select saldo_total('014341f0-99f3-4e14-b21d-6b4efc9bafbd')$$);

\echo '--- 4. Loja: limites por semana (sorvete 2, passeio 1, tela 28 unidades)'
select t.como(johann::text) from ids;
select 'sorvete 1', t.erro(format($$select resgatar(%s)$$, sorvete)) from pr;
select 'sorvete 2', t.erro(format($$select resgatar(%s)$$, sorvete)) from pr;
select 'sorvete 3 (limite)', t.erro(format($$select resgatar(%s)$$, sorvete)) from pr;
select 'saldo após 2 sorvetes (1490-190=1300)', saldo_total(johann) from ids;
select 'cinema', t.erro(format($$select resgatar(%s)$$, cinema)) from pr;
select 'jantar após cinema (passeio dividido, limite)', t.erro(format($$select resgatar(%s)$$, jantar)) from pr;
select 'tela 29 unidades (limite 28)', t.erro(format($$select resgatar(%s, 29)$$, tela)) from pr;
select 'tela 5 (300 pts)', t.erro(format($$select resgatar(%s, 5)$$, tela)) from pr;
select 'saldo (1300-400-300=600)', saldo_total(johann) from ids;
select 'limites', p.nome, l.usado, l.limite from limites_loja((select johann from ids)) l join premios p on p.id = l.premio order by p.nome;
select 'quantidade 0', t.erro(format($$select resgatar(%s, 0)$$, filme)) from pr;
select 'filme (sem limite)', t.erro(format($$select resgatar(%s)$$, filme)) from pr;

\echo '--- 5. Jantar dividido entre os dois (Juju recebe crédito; Johann já gastou o passeio, então usa um dia limpo)'
select t.como(pai::text) from ids;
select 'Pai credita Juju 700', lancar(juju, 'estudos', 700, 'Crédito', null, 'manual') is not null from ids;
select 'Pai desfaz o cinema do Johann (estorna)', t.erro(format($$select cancelar_resgate(%s)$$, (select id from resgates where nome='Cinema'))) ;
select 'saldo Johann após estorno (600-100 do filme+400=900)', saldo_total(johann) from ids;
select t.como(johann::text) from ids;
select 'Johann paga metade', t.erro(format($$select resgatar(%s)$$, jantar)) from pr;
select 'status Johann', status from resgates where nome = 'Jantar metade';
select 'Johann paga 2x', t.erro(format($$select resgatar(%s)$$, jantar)) from pr;
select t.como(juju::text) from ids;
select 'Juju vê pedido do Johann', count(*) from resgates where aluno <> auth.uid();
select 'Juju paga metade', t.erro(format($$select resgatar(%s)$$, jantar)) from pr;
select 'status dos dois (ambos pedido)', string_agg(status, ',') from resgates where nome = 'Jantar metade';
select 'Juju entrega', t.erro(format($$select entregar_resgate(%s)$$, (select id from resgates where nome='Jantar metade' limit 1)));
select 'Juju cancela (já está pedido)', t.erro(format($$select cancelar_resgate(%s)$$, (select id from resgates where nome='Jantar metade' and aluno = auth.uid())));
select t.como(pai::text) from ids;
select 'Pai cancela a metade da Juju (a do Johann volta a aguardar)', t.erro(format($$select cancelar_resgate(%s)$$, (select id from resgates where nome='Jantar metade' and aluno = (select juju from ids))));
select 'status após cancelar', string_agg(aluno::text || ':' || status, ' ' order by status) from resgates where nome = 'Jantar metade';
select 'saldo Juju (700 devolvido)', saldo_total(juju) from ids;
select t.como(juju::text) from ids;
select 'Juju paga de novo', t.erro(format($$select resgatar(%s)$$, jantar)) from pr;
select 'Juju paga de novo (3ª)', t.erro(format($$select resgatar(%s)$$, jantar)) from pr;
select t.como(pai::text) from ids;
select 'Pai entrega os dois', t.erro(format($$select entregar_resgate(%s)$$, (select id from resgates where nome='Jantar metade' and status = 'pedido' limit 1)));
select 'status final', string_agg(status, ',' order by id) from resgates where nome = 'Jantar metade';
select 'Pai entrega de novo', t.erro(format($$select entregar_resgate(%s)$$, (select id from resgates where nome='Jantar metade' limit 1)));

\echo '--- 6. Segurança da loja (esperado: tudo com ERRO)'
select t.como(johann::text) from ids;
select 'insert direto em resgates', t.erro($$insert into resgates (aluno,premio,nome,quantidade,custo,semana,status) values (auth.uid(),1,'x',1,1,hoje_sp(),'pedido')$$);
select 'update direto em resgates', t.erro($$update resgates set status='entregue'$$);
select 'Johann entrega', t.erro(format($$select entregar_resgate(%s)$$, (select id from resgates limit 1)));
select t.como(pai::text) from ids;
select 'Pai resgata', t.erro(format($$select resgatar(%s)$$, filme)) from pr;

\echo '--- 7. Pontos de estudo automáticos (esperado: +30 uma vez, +40 uma vez por dia, +100 na prova)'
select t.como(johann::text) from ids;
select 'saldo antes', saldo_total(johann) from ids;
select 'tópico concluído', t.erro($$insert into progresso (chave, estudou, exercicios) values ('fisica:1', true, true)$$);
select 'saldo +30', saldo_total(johann) from ids;
select 'reenvia o mesmo tópico', t.erro($$update progresso set duvida = 'oi' where chave = 'fisica:1'$$), saldo_total(johann) from ids;
select 'desmarca e marca de novo', t.erro($$update progresso set exercicios = false where chave = 'fisica:1'$$), t.erro($$update progresso set exercicios = true where chave = 'fisica:1'$$), saldo_total(johann) from ids;
select 'só estudou (sem exercícios)', t.erro($$insert into progresso (chave, estudou, exercicios) values ('fisica:2', true, false)$$), saldo_total(johann) from ids;
select 'chave da agenda não paga', t.erro($$insert into progresso (chave, estudou, exercicios) values ('crono:2026-11-20:0', true, true)$$), saldo_total(johann) from ids;
select 'treino 80% de 10 (+40)', t.erro($$insert into tentativas (materia, tipo, acertos, total, pct) values ('fisica','treino',8,10,80)$$), saldo_total(johann) from ids;
select 'treino de novo no dia (sem pontos)', t.erro($$insert into tentativas (materia, tipo, acertos, total, pct) values ('fisica','treino',9,10,90)$$), saldo_total(johann) from ids;
select 'treino 60% (sem pontos)', t.erro($$insert into tentativas (materia, tipo, acertos, total, pct) values ('portugues','treino',6,10,60)$$), saldo_total(johann) from ids;
select 'treino curto 100% de 3 (sem pontos)', t.erro($$insert into tentativas (materia, tipo, acertos, total, pct) values ('ingles','treino',3,3,100)$$), saldo_total(johann) from ids;
select 'Johann insere prova na mão', t.erro($$insert into tentativas (materia, tipo, acertos, total, pct) values ('fisica','prova',10,10,100)$$);
select t.como(pai::text) from ids;
insert into questoes (id, aluno, materia, topico, tipo, enunciado, alternativas) values ('x-p1', (select johann from ids), 'fisica', 't', 'prova', 'Q', '["a","b"]'), ('x-p2', (select johann from ids), 'fisica', 't', 'prova', 'Q', '["a","b"]');
insert into gabarito values ('x-p1', 0, ''), ('x-p2', 1, '');
insert into liberacoes (aluno, materia, ate) select johann, 'fisica', now() + interval '30 min' from ids;
select t.como(johann::text) from ids;
select 'prova 100% (+100)', corrigir_prova('fisica', '{"x-p1":0,"x-p2":1}')->>'pct', saldo_total(johann) from ids;
select 'lançamentos de estudo', origem, count(*), sum(valor) from lancamentos where origem in ('topico','treino','prova') group by origem order by origem;

\echo '--- 8. Agenda de tarefas (a Juju tem Kika em dias alternados + T1..T6; dia futuro = futuro)'
select t.como(juju::text) from ids;
select 'dias (4), linhas (8 tarefas por dia dela = 32 menos o que ainda não existe)', count(distinct dia), count(*) from agenda_tarefas((select juju from ids), hoje_sp() - 1, hoje_sp() + 2);
select 'status por dia', dia - hoje_sp(), string_agg(distinct status, ',') from agenda_tarefas((select juju from ids), hoje_sp() - 3, hoje_sp() + 1) group by dia order by dia;
select 'Juju vê agenda do Johann', t.erro($$select * from agenda_tarefas('d5c2215c-797c-435b-859b-09be1fe3efbf', hoje_sp(), hoje_sp())$$);
select 'intervalo grande', t.erro($$select * from agenda_tarefas((select auth.uid()), hoje_sp(), hoje_sp() + 100)$$);
select t.como(pai::text) from ids;
select 'Pai vê agenda da Juju', count(*) from agenda_tarefas((select juju from ids), hoje_sp(), hoje_sp());

\echo '--- 9. Período do dia nas tarefas (manhã antes de noite)'
reset role;
insert into tarefas (nome, pontos, modo, alunos, base, periodo, ordem) select 'Escovar os dentes (noite)', 5, 'todos', array[juju], hoje_sp(), 'noite', 1 from ids;
insert into tarefas (nome, pontos, modo, alunos, base, periodo, ordem) select 'Escovar os dentes (manhã)', 5, 'todos', array[juju], hoje_sp(), 'manha', 2 from ids;
set role authenticated; select t.como((select juju::text from ids));
select 'ordem do dia', string_agg(nome, ' > ' order by ord) from (select nome, row_number() over () ord from tarefas_do_dia((select juju from ids), hoje_sp()) where nome like 'Escovar%') q;
select 'período inválido', t.erro($$update tarefas set periodo = 'madrugada' where false$$);
reset role;
select 'período inválido (admin)', t.erro($$update tarefas set periodo = 'madrugada' where nome like 'Escovar%'$$);
