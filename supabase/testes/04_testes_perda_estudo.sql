\set ON_ERROR_STOP 1
\pset format unaligned
\pset tuples_only on
-- Testes da migração 06. Rodar depois da 03_testes_cofrinho.sql (usa o banco no estado em que ela deixa).
create or replace function t.erro(q text) returns text language plpgsql as $$
begin execute q; return 'OK (sem erro)'; exception when others then return 'ERRO: ' || sqlerrm; end $$;
create or replace function t.como(u text) returns void language sql as $$ select set_config('request.jwt.claim.sub', u, false) $$;
grant execute on all functions in schema t to authenticated;
create temp table ids as select 'd5c2215c-797c-435b-859b-09be1fe3efbf'::uuid johann, '014341f0-99f3-4e14-b21d-6b4efc9bafbd'::uuid juju, '78768c03-68d4-420f-ba5d-c7fe46434042'::uuid pai;
grant select on ids to authenticated;
set role authenticated;

\echo '--- 1. Pontos de estudo por matéria (esperado: fisica 70 = tópico 30 + treino 40)'
select t.como(pai::text) from ids;
select 'por matéria', materia, pontos from pontos_estudo_por_materia((select johann from ids)) order by materia;
select t.como(johann::text) from ids;
select 'Johann vê o dele', count(*) from pontos_estudo_por_materia((select johann from ids));
select 'Johann vê o da Juju', t.erro($$select * from pontos_estudo_por_materia('014341f0-99f3-4e14-b21d-6b4efc9bafbd')$$);

\echo '--- 2. Perder os pontos de uma matéria'
select t.como(johann::text) from ids;
select 'Johann tenta tirar os próprios pontos', t.erro($$select perder_pontos_estudo(auth.uid(), 'fisica')$$);
select 'saldo antes', saldo_total(johann) from ids;
select t.como(pai::text) from ids;
select 'Pai tira os pontos de física (70)', perder_pontos_estudo((select johann from ids), 'fisica');
select 'saldo depois (antes - 70)', saldo_total(johann) from ids;
select 'Pai tira de novo (0, nunca em dobro)', perder_pontos_estudo((select johann from ids), 'fisica');
select 'saldo igual', saldo_total(johann) from ids;
select 'por matéria agora', count(*) from pontos_estudo_por_materia((select johann from ids)) where materia = 'fisica';
select 'prova valendo (100) não foi tocada', sum(valor) from lancamentos where origem = 'prova';
select 'extrato da perda', descricao, valor from lancamentos where origem = 'estorno' and origem_ref like 'perda:%' order by id;
select 'matéria sem pontos', perder_pontos_estudo((select johann from ids), 'quimica');
select 'aluno inválido', t.erro($$select perder_pontos_estudo('99999999-9999-9999-9999-999999999999', 'fisica')$$);

\echo '--- 3. Estudar de novo depois da perda volta a render (tópico novo)'
select t.como(johann::text) from ids;
select 'novo tópico', t.erro($$insert into progresso (chave, estudou, exercicios) values ('fisica:5', true, true)$$);
select t.como(pai::text) from ids;
select 'por matéria (30 novos)', materia, pontos from pontos_estudo_por_materia((select johann from ids)) where materia = 'fisica';
