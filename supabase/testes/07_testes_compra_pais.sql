\set ON_ERROR_STOP 1
\pset format unaligned
\pset tuples_only on
-- Testes da migração 09 (pai e mãe lançam compras que já aconteceram). Rodar num banco novo com as migrações 01 a 09 (cria os próprios dados).
create schema if not exists t; grant usage on schema t to authenticated;
create or replace function t.erro(q text) returns text language plpgsql as $$
begin execute q; return 'OK (sem erro)'; exception when others then return 'ERRO: ' || sqlerrm; end $$;
create or replace function t.como(u text) returns void language sql as $$ select set_config('request.jwt.claim.sub', u, false) $$;
grant execute on all functions in schema t to authenticated;
create temp table ids as select 'd5c2215c-797c-435b-859b-09be1fe3efbf'::uuid johann, '014341f0-99f3-4e14-b21d-6b4efc9bafbd'::uuid juju,
  '78768c03-68d4-420f-ba5d-c7fe46434042'::uuid pai, hoje_sp() h,
  (select id from premios where nome = 'Sorvete') sorvete, (select id from premios where nome like 'Ir ao cinema%') cinema;
grant select on ids to authenticated;
-- saldo inicial: Johann 100, Juju 0
select 'crédito inicial lançado', _lancar(johann, 'casa', 100, 'inicial', h, 'manual', null) is not null from ids;
set role authenticated;
select t.como(pai::text) from ids;

\echo '--- 1. Sorvete de 95 para os dois, ontem (esperado: OK; −47,5 cada; dois pedidos entregues com a data de ontem)'
select 'compra', t.erro(format('select lancar_compra(%L, %s, 1, null, 95, %L)', array[johann, juju], sorvete, h - 1)) from ids;
select 'lançamentos', p.nome, l.valor, l.data_ref = (select h - 1 from ids), l.descricao, l.origem from lancamentos l join perfis p on p.user_id = l.aluno where l.grupo = 'loja' order by p.nome;
select 'pedidos', p.nome, r.nome, r.custo, r.status, r.dia = (select h - 1 from ids), r.lancamento is not null from resgates r join perfis p on p.user_id = r.aluno order by p.nome;
select 'saldos (52,5 e −47,5: pode ficar negativo)', saldo_total(johann), saldo_total(juju) from ids;

\echo '--- 2. Compra livre (sem item), só a Juju, semana passada'
select 'compra livre', t.erro(format('select lancar_compra(%L, null, 1, %L, 30, %L)', array[juju], 'Almoço fora', h - 7)) from ids;
select 'pedido livre', r.nome, r.premio is null, r.custo, r.semana = date_trunc('week', (select h - 7 from ids))::date from resgates r where r.nome = 'Almoço fora';

\echo '--- 3. Conta no limite da semana da data escolhida (sorvete: 2 por semana)'
select 'limite do sorvete do Johann (usado 1 se ontem foi nesta semana)', usado, (select (h - 1) >= date_trunc('week', h)::date from ids) from limites_loja((select johann from ids)) where premio = (select sorvete from ids);
select 'compra passando do limite (avisa no app, mas lança)', t.erro(format('select lancar_compra(%L, %s, 3, null, 285, %L)', array[johann], sorvete, h)) from ids;
select 'limite do sorvete do Johann agora (usado 4 ou 3)', usado from limites_loja((select johann from ids)) where premio = (select sorvete from ids);

\echo '--- 4. Recusas'
select 'total zero: ERRO', t.erro(format('select lancar_compra(%L, null, 1, %L, 0, %L)', array[juju], 'x', h)) from ids;
select 'sem criança: ERRO', t.erro(format('select lancar_compra(%L, null, 1, %L, 10, %L)', '{}'::uuid[], 'x', h)) from ids;
select 'para o pai: ERRO', t.erro(format('select lancar_compra(%L, null, 1, %L, 10, %L)', array[pai], 'x', h)) from ids;
select 'data no futuro: ERRO', t.erro(format('select lancar_compra(%L, null, 1, %L, 10, %L)', array[juju], 'x', h + 1)) from ids;
select 'sem data: ERRO', t.erro(format('select lancar_compra(%L, null, 1, %L, 10, null)', array[juju], 'x')) from ids;
select 'sem item e sem descrição: ERRO', t.erro(format('select lancar_compra(%L, null, 1, null, 10, %L)', array[juju], h)) from ids;
select 'item inexistente: ERRO', t.erro(format('select lancar_compra(%L, 99999, 1, null, 10, %L)', array[juju], h)) from ids;
select 'criança repetida: ERRO', t.erro(format('select lancar_compra(%L, null, 1, %L, 10, %L)', array[juju, juju], 'x', h)) from ids;

\echo '--- 5. Divisão exata: 10 para os dois = 5 cada'
select 'compra 10', t.erro(format('select lancar_compra(%L, null, 1, %L, 10, %L)', array[johann, juju], 'Pipoca', h)) from ids;
select 'parte de cada (5 e 5)', string_agg(custo::text, ' e ' order by aluno) from resgates where nome = 'Pipoca';

\echo '--- 6. Segurança e app antigo'
select 'pai dá 200 à Juju', t.erro(format('select lancar(%L, %L, 200, %L)', juju, 'casa', 'crédito')) from ids;
select t.como(juju::text) from ids;
select 'criança lança compra: ERRO', t.erro(format('select lancar_compra(%L, null, 1, %L, 10, %L)', array[juju], 'x', h)) from ids;
select 'criança vê só os próprios pedidos (3)', count(*) from resgates;
select 'pedido normal da criança continua funcionando', t.erro(format('select resgatar(%s, 1)', (select id from premios where nome like 'Escolher o filme%'))) from ids;
