\set ON_ERROR_STOP 1
\pset format unaligned
\pset tuples_only on
-- Testes da migração 11 (tarefa avulsa: data de fim nas tarefas). Rodar num banco novo com as migrações 01 a 11 (cria os próprios dados).
create schema if not exists t; grant usage on schema t to authenticated;
create or replace function t.erro(q text) returns text language plpgsql as $$
begin execute q; return 'OK (sem erro)'; exception when others then return 'ERRO: ' || sqlerrm; end $$;
create or replace function t.como(u text) returns void language sql as $$ select set_config('request.jwt.claim.sub', u, false) $$;
grant execute on all functions in schema t to authenticated;
create temp table ids as select 'd5c2215c-797c-435b-859b-09be1fe3efbf'::uuid johann, '014341f0-99f3-4e14-b21d-6b4efc9bafbd'::uuid juju,
  '78768c03-68d4-420f-ba5d-c7fe46434042'::uuid pai, hoje_sp() h;
grant select on ids to authenticated;
-- avulsas (base = ate = dia, modo todos) e uma tarefa comum, todas valendo 20
insert into tarefas (nome, pontos, modo, alunos, base, ate) select 'AV',  20, 'todos', array[johann, juju], h,     h     from ids;
insert into tarefas (nome, pontos, modo, alunos, base, ate) select 'ONT', 20, 'todos', array[johann],       h - 3, h - 3 from ids;
insert into tarefas (nome, pontos, modo, alunos, base, ate) select 'PZ',  20, 'todos', array[johann],       h + 2, h + 2 from ids;
insert into tarefas (nome, pontos, modo, alunos, base, ate) select x,     20, 'todos', array[johann],       h,     h     from ids, unnest(array['RM','MK','TT','TR']) x;
insert into tarefas (nome, pontos, modo, alunos, base)      select 'COMUM', 20, 'todos', array[johann],     h - 10        from ids;
insert into pausas (inicio, fim, motivo) select h + 2, h + 2, 'viagem' from ids;
create function pg_temp.tk(n text) returns bigint language sql as $$ select id from tarefas where nome = n $$;
grant execute on function pg_temp.tk(text) to authenticated;
-- quanto a tarefa rendeu à criança naquele dia (crédito menos estorno)
create function pg_temp.rendeu(n text, a uuid, d date) returns numeric language sql as $$
  select coalesce(sum(valor), 0) from lancamentos where origem in ('tarefa','estorno') and aluno = a and origem_ref = pg_temp.tk(n) || ':' || d $$;
grant execute on function pg_temp.rendeu(text, uuid, date) to authenticated;
-- em quantos dias a tarefa aparece na agenda da criança, de d1 a d2
create function pg_temp.dias(n text, a uuid, d1 date, d2 date) returns text language sql as $$
  select coalesce(string_agg((dia - hoje_sp())::text, ',' order by dia), '-') from agenda_tarefas(a, d1, d2) where nome = n $$;
grant execute on function pg_temp.dias(text, uuid, date, date) to authenticated;
set role authenticated;
select t.como(pai::text) from ids;

\echo '--- 1. Avulsa aparece só no dia (dias relativos a hoje: 0)'
select 'AV Johann, de -3 a +3 (0)', pg_temp.dias('AV', johann, h - 3, h + 3) from ids;
select 'AV Juju, de -3 a +3 (0)', pg_temp.dias('AV', juju, h - 3, h + 3) from ids;
select 'responsaveis AV amanhã ({})', responsaveis(pg_temp.tk('AV'), h + 1) from ids;
select 'responsaveis AV ontem ({})', responsaveis(pg_temp.tk('AV'), h - 1) from ids;

\echo '--- 2. Lista do dia de amanhã não traz a avulsa (0 linhas)'
select 'tarefas_do_dia amanhã com AV', count(*) from ids, tarefas_do_dia(johann, h + 1) x where x.nome = 'AV';

\echo '--- 3. Marcar, validar e metade funcionam como numa tarefa comum'
select t.como(johann::text) from ids;
select 'Johann marca AV', t.erro(format('select marcar_tarefa(%s, %L, %L)', pg_temp.tk('AV'), h, 'feito')) from ids;
select t.como(juju::text) from ids;
select 'Juju marca AV', t.erro(format('select marcar_tarefa(%s, %L, %L)', pg_temp.tk('AV'), h, 'feito')) from ids;
select t.como(pai::text) from ids;
select 'validar Johann', t.erro(format('select decidir_tarefa(%s, %L, %L, %L)', pg_temp.tk('AV'), h, johann, 'validado')) from ids;
select 'metade Juju', t.erro(format('select decidir_tarefa(%s, %L, %L, %L, %L)', pg_temp.tk('AV'), h, juju, 'metade', 'enrolou')) from ids;
select 'AV rendeu Johann 20, Juju 10', pg_temp.rendeu('AV', johann, h), pg_temp.rendeu('AV', juju, h) from ids;
select 'Johann tenta marcar AV amanhã: ERRO', t.erro(format('select marcar_tarefa(%s, %L, %L, %L)', pg_temp.tk('AV'), h + 1, 'feito', johann)) from ids;

\echo '--- 4. Avulsa num dia que já passou: a criança não marca, pai marca e valida'
select t.como(johann::text) from ids;
select 'Johann marca ONT (-3): ERRO', t.erro(format('select marcar_tarefa(%s, %L, %L)', pg_temp.tk('ONT'), h - 3, 'feito')) from ids;
select t.como(pai::text) from ids;
select 'pai marca ONT', t.erro(format('select marcar_tarefa(%s, %L, %L, %L)', pg_temp.tk('ONT'), h - 3, 'feito', johann)) from ids;
select 'pai valida ONT', t.erro(format('select decidir_tarefa(%s, %L, %L, %L)', pg_temp.tk('ONT'), h - 3, johann, 'validado')) from ids;
select 'ONT rendeu (20)', pg_temp.rendeu('ONT', johann, h - 3) from ids;
select 'ONT na agenda de -7 a +7 (-3)', pg_temp.dias('ONT', johann, h - 7, h + 7) from ids;

\echo '--- 5. Avulsa em dia pausado não aparece'
select 'PZ na agenda de 0 a +7 (-)', pg_temp.dias('PZ', johann, h, h + 7) from ids;

\echo '--- 6. Desativar: some se ninguém marcou; continua se já foi marcada'
select t.como(johann::text) from ids;
select 'Johann marca MK', t.erro(format('select marcar_tarefa(%s, %L, %L)', pg_temp.tk('MK'), h, 'feito')) from ids;
select t.como(pai::text) from ids;
select 'desativar RM e MK', t.erro('update tarefas set ativa = false where nome in (''RM'', ''MK'')');
select 'RM na agenda (-)', pg_temp.dias('RM', johann, h, h) from ids;
select 'MK na agenda (0)', pg_temp.dias('MK', johann, h, h) from ids;

\echo '--- 7. Trocar só este dia numa avulsa: Juju faz TR no lugar do Johann'
select 'trocar TR', t.erro(format('select trocar_responsavel(%s, %L, %L, %L, false)', pg_temp.tk('TR'), h, johann, juju)) from ids;
select 'TR Johann (-), Juju (0)', pg_temp.dias('TR', johann, h, h), pg_temp.dias('TR', juju, h, h) from ids;

\echo '--- 8. Tarefa comum (sem fim) continua todos os dias'
select 'COMUM de 0 a +3 (0,1,3: o +2 é pausado)', pg_temp.dias('COMUM', johann, h, h + 3) from ids;

\echo '--- 9. Fim antes do início: ERRO'
select 'ate < base: ERRO', t.erro(format('insert into tarefas (nome, pontos, modo, alunos, base, ate) values (%L, 5, %L, array[%L]::uuid[], %L, %L)', 'X', 'todos', johann, h, h - 1)) from ids;

\echo '--- 10. Criança não cria tarefa'
select t.como(johann::text) from ids;
select 'Johann cria tarefa: ERRO', t.erro(format('insert into tarefas (nome, pontos, modo, alunos, base, ate) values (%L, 5, %L, array[%L]::uuid[], %L, %L)', 'Y', 'todos', johann, h, h)) from ids;
select t.como(pai::text) from ids;

\echo '--- 11. Teto cheio: validar avulsa credita 0'
reset role;
update grupos set teto_semana = (select coalesce(sum(valor), 0) from lancamentos l, ids where l.aluno = johann and grupo = 'casa'
                                   and data_ref between date_trunc('week', h)::date and date_trunc('week', h)::date + 6)
 where grupo = 'casa' and aluno = (select johann from ids);
set role authenticated; select t.como(johann::text) from ids;
select 'Johann marca TT', t.erro(format('select marcar_tarefa(%s, %L, %L)', pg_temp.tk('TT'), h, 'feito')) from ids;
select t.como(pai::text) from ids;
select 'validar TT', t.erro(format('select decidir_tarefa(%s, %L, %L, %L)', pg_temp.tk('TT'), h, johann, 'validado')) from ids;
select 'TT rendeu (0)', pg_temp.rendeu('TT', johann, h) from ids;
