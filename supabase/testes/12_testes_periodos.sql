\set ON_ERROR_STOP 1
\pset format unaligned
\pset tuples_only on
-- Testes da migração 24 (tarefa com vários períodos no dia). Rodar num banco novo:
--   00_stub, banco.sql, 00_perfis, migrações 01 a 23, 12_preparo_antes_24.sql, migração 24, este arquivo.
create schema if not exists t; grant usage on schema t to authenticated;
create or replace function t.erro(q text) returns text language plpgsql as $$
begin execute q; return 'OK (sem erro)'; exception when others then return 'ERRO: ' || sqlerrm; end $$;
create or replace function t.como(u text) returns void language sql as $$ select set_config('request.jwt.claim.sub', u, false) $$;
-- muda o relógio da trava para hoje às hh horas (security definer: o dono da agora_sp recria a função)
create or replace function t.hora(hh int) returns text language plpgsql security definer as $$
begin execute format('create or replace function public.agora_sp() returns timestamp language sql stable as %L',
                     format('select hoje_sp() + time %L', hh || ':00')); return hh || 'h'; end $$;
grant execute on all functions in schema t to authenticated;
create temp table ids as select 'd5c2215c-797c-435b-859b-09be1fe3efbf'::uuid johann, '014341f0-99f3-4e14-b21d-6b4efc9bafbd'::uuid juju,
  '78768c03-68d4-420f-ba5d-c7fe46434042'::uuid pai, hoje_sp() h;
grant select on ids to authenticated;
create function pg_temp.tk(n text) returns bigint language sql as $$ select id from tarefas where nome = n $$;
grant execute on function pg_temp.tk(text) to authenticated;
-- marcar como o usuário atual (status 'feito' ou null), devolvendo OK ou a mensagem de erro
create function pg_temp.mk(n text, d date, s text, p text) returns text language sql as $$
  select t.erro(format('select marcar_tarefa(%s, %L, %L, null, %L)', pg_temp.tk(n), d, s, p)) $$;
grant execute on function pg_temp.mk(text, date, text, text) to authenticated;
-- lista do dia resumida: nome:periodo:abre_em:pode_marcar, na ordem do banco
create function pg_temp.lista(a uuid, d date) returns text language sql as $$
  select string_agg(x.nome || ':' || x.periodo || ':' || coalesce(x.abre_em::text, '-') || ':' || x.pode_marcar, ' ' order by o)
    from tarefas_do_dia(a, d) with ordinality x(tarefa, nome, emoji, pontos, status, decisao, valor, marcado_por, decidido_em,
         recurso_id, recurso_comentario, recurso_decisao, recurso_resposta, pode_marcar, pode_recorrer, periodo, motivo, motivo_comentario, abre_em, o)
   where x.nome in ('ESC','MESA','KIKA') $$;
grant execute on function pg_temp.lista(uuid, date) to authenticated;
-- quanto a tarefa rendeu à criança (crédito menos estorno), em qualquer período
create function pg_temp.rendeu(n text, a uuid) returns numeric language sql as $$
  select coalesce(sum(valor), 0) from lancamentos where origem in ('tarefa','estorno') and aluno = a and origem_ref like pg_temp.tk(n) || ':%' $$;
grant execute on function pg_temp.rendeu(text, uuid) to authenticated;

\echo '--- 1. Períodos da tarefa: check'
select 'vazio: ERRO', t.erro(format('insert into tarefas (nome, alunos, periodos) values (%L, array[%L]::uuid[], %L)', 'X', johann, '{}')) from ids;
select 'dia + manha: ERRO', t.erro(format('insert into tarefas (nome, alunos, periodos) values (%L, array[%L]::uuid[], %L)', 'X', johann, '{dia,manha}')) from ids;
select 'manha repetida: ERRO', t.erro(format('insert into tarefas (nome, alunos, periodos) values (%L, array[%L]::uuid[], %L)', 'X', johann, '{manha,manha}')) from ids;
select 'madrugada: ERRO', t.erro(format('insert into tarefas (nome, alunos, periodos) values (%L, array[%L]::uuid[], %L)', 'X', johann, '{madrugada}')) from ids;
select 'padrão sem período (OK)', t.erro(format('insert into tarefas (nome, alunos) values (%L, array[%L]::uuid[])', 'PADRAO', johann)) from ids;
select 'PADRAO.periodos ({dia})', periodos from tarefas where nome = 'PADRAO';
update tarefas set ativa = false where nome = 'PADRAO';

insert into tarefas (nome, pontos, modo, alunos, base, periodos) select 'ESC',   5, 'todos', array[johann], h - 10, '{manha,noite}' from ids;
insert into tarefas (nome, pontos, modo, alunos, base, periodos) select 'MESA', 20, 'todos', array[johann], h - 10, '{tarde,noite}' from ids;
insert into tarefas (nome, pontos, modo, alunos, base)           select 'KIKA', 20, 'todos', array[johann], h - 10 from ids;
set role authenticated;

\echo '--- 2. Trava às 10h (Johann)'
select t.hora(10);
select t.como(johann::text) from ids;
select 'ESC manha (OK)', pg_temp.mk('ESC', h, 'feito', 'manha') from ids;
select 'ESC noite (ERRO abre às 18h)', pg_temp.mk('ESC', h, 'feito', 'noite') from ids;
select 'KIKA sem período (ERRO abre às 18h)', pg_temp.mk('KIKA', h, 'feito', null) from ids;
select 'MESA tarde (ERRO abre às 12h)', pg_temp.mk('MESA', h, 'feito', 'tarde') from ids;
select 'MESA sem período (ERRO Escolha o período)', pg_temp.mk('MESA', h, 'feito', null) from ids;
select 'ESC tarde, não configurado (ERRO)', pg_temp.mk('ESC', h, 'feito', 'tarde') from ids;

\echo '--- 3. Lista do dia às 10h'
select 'hoje (ESC:manha:-:true ESC:noite:18:00:00:false MESA:tarde:12:00:00:false MESA:noite:18:00:00:false KIKA:dia:18:00:00:false)', pg_temp.lista(johann, h) from ids;
select 'ontem (ESC:manha:-:true ESC:noite:-:true MESA:tarde:-:true MESA:noite:-:true KIKA:dia:-:true)', pg_temp.lista(johann, h - 1) from ids;
select 'agenda hoje (ESC:manha ESC:noite KIKA:dia MESA:noite MESA:tarde)', string_agg(nome || ':' || periodo, ' ' order by nome, periodo) from ids, agenda_tarefas(johann, h, h) where nome in ('ESC','MESA','KIKA');
select 'agenda ordem (ESC ESC MESA MESA KIKA)', string_agg(nome, ' ' order by o) from ids, agenda_tarefas(johann, h, h) with ordinality x(dia, tarefa, nome, emoji, pontos, periodo, status, decisao, valor, motivo, motivo_comentario, o) where nome in ('ESC','MESA','KIKA');

\echo '--- 4. Ontem: qualquer período, a qualquer hora'
select 'ESC noite de ontem às 10h (OK)', pg_temp.mk('ESC', h - 1, 'feito', 'noite') from ids;
select 'KIKA de ontem às 10h (OK)', pg_temp.mk('KIKA', h - 1, 'feito', null) from ids;

\echo '--- 5. A trava vale para pai e mãe'
select t.como(pai::text) from ids;
select 'pai marca ESC noite às 10h (ERRO abre às 18h)', t.erro(format('select marcar_tarefa(%s, %L, %L, %L, %L)', pg_temp.tk('ESC'), h, 'feito', johann, 'noite')) from ids;

\echo '--- 6. Às 19h tudo abre'
select t.hora(19);
select t.como(johann::text) from ids;
select 'ESC noite (OK)', pg_temp.mk('ESC', h, 'feito', 'noite') from ids;
select 'KIKA (OK)', pg_temp.mk('KIKA', h, 'feito', null) from ids;
select 'MESA tarde (OK)', pg_temp.mk('MESA', h, 'feito', 'tarde') from ids;
select 'MESA noite (OK)', pg_temp.mk('MESA', h, 'feito', 'noite') from ids;
select 'linhas de ESC hoje (2)', count(*) from tarefa_dia, ids where tarefa = pg_temp.tk('ESC') and dia = h;

\echo '--- 7. Desmarcar antes da hora é permitido'
select t.hora(10);
select 'desmarca ESC noite às 10h (OK)', pg_temp.mk('ESC', h, null, 'noite') from ids;
select 'linhas de ESC hoje (1)', count(*) from tarefa_dia, ids where tarefa = pg_temp.tk('ESC') and dia = h;
select t.hora(19);
select 'remarca ESC noite às 19h (OK)', pg_temp.mk('ESC', h, 'feito', 'noite') from ids;

\echo '--- 8. Tarefa editada: período tirado continua com a marcação'
select t.como(pai::text) from ids;
update tarefas set periodos = '{tarde}' where nome = 'MESA';
select t.como(johann::text) from ids;
select 'linhas de MESA na lista (2)', count(*) from ids, tarefas_do_dia(johann, h) x where x.nome = 'MESA';
select 'desmarca MESA noite (OK)', pg_temp.mk('MESA', h, null, 'noite') from ids;
select 'marca MESA noite de novo (ERRO)', pg_temp.mk('MESA', h, 'feito', 'noite') from ids;
select 'linhas de MESA na lista (1)', count(*) from ids, tarefas_do_dia(johann, h) x where x.nome = 'MESA';
select 'MESA sem período agora resolve para tarde: desmarca (OK)', pg_temp.mk('MESA', h, null, null) from ids;
select 'remarca MESA tarde (OK)', pg_temp.mk('MESA', h, 'feito', 'tarde') from ids;
select t.como(pai::text) from ids;
update tarefas set periodos = '{tarde,noite}' where nome = 'MESA';
select t.como(johann::text) from ids;
select 'remarca MESA noite (OK)', pg_temp.mk('MESA', h, 'feito', 'noite') from ids;
reset role;

\echo '--- 9. Dados antigos convertidos'
select 'OLDM.periodos ({manha})', periodos from tarefas where nome = 'OLDM';
select 'OLDD.periodos ({dia})', periodos from tarefas where nome = 'OLDD';
select 'OLDM marcação (manha)', periodo from tarefa_dia where tarefa = pg_temp.tk('OLDM');
select 'OLDD marcação (dia)', periodo from tarefa_dia where tarefa = pg_temp.tk('OLDD');
select 'OLDM recurso (manha)', periodo from recursos where tarefa = pg_temp.tk('OLDM');
select 'OLDM origem_ref termina em :manha (true)', bool_and(origem_ref like '%:manha') from lancamentos where descricao like '%OLDM%';
select 'OLDD origem_ref = id:dia (true)', bool_and(origem_ref = pg_temp.tk('OLDD') || ':' || (h - 1)) from lancamentos, ids where descricao like '%OLDD%';
select 'coluna tarefas.periodo apagada (0)', count(*) from information_schema.columns where table_name = 'tarefas' and column_name = 'periodo';
select 'chave de tarefa_dia (tarefa, dia, aluno, periodo)', string_agg(a.attname, ', ' order by k.n)
  from pg_constraint c cross join lateral unnest(c.conkey) with ordinality k(att, n) join pg_attribute a on a.attrelid = c.conrelid and a.attnum = k.att
 where c.conrelid = 'tarefa_dia'::regclass and c.contype = 'p';
