\set ON_ERROR_STOP 1
\pset format unaligned
\pset tuples_only on
-- Testes da migração 35 (prova valendo com 1 hora contada do início). Banco novo com todas as migrações.
create schema if not exists t; grant usage on schema t to authenticated;
create or replace function t.erro(q text) returns text language plpgsql as $$
begin execute q; return 'OK (sem erro)'; exception when others then return 'ERRO: ' || sqlerrm; end $$;
create or replace function t.como(u text) returns void language sql as $$ select set_config('request.jwt.claim.sub', u, false) $$;
grant execute on all functions in schema t to authenticated;
create temp table ids as select 'd5c2215c-797c-435b-859b-09be1fe3efbf'::uuid johann, '014341f0-99f3-4e14-b21d-6b4efc9bafbd'::uuid juju, '78768c03-68d4-420f-ba5d-c7fe46434042'::uuid pai;
grant select on ids to authenticated;
-- duas matérias de teste com 2 questões de prova cada (certa = alternativa 0)
insert into materias (aluno, id, nome) select johann, m, m from ids, unnest(array['tpa', 'tpb']) m on conflict do nothing;
insert into questoes (id, aluno, materia, topico, tipo, enunciado, alternativas)
  select m || '-p' || g, johann, m, 't', 'prova', 'Q' || g, '["a","b"]' from ids, unnest(array['tpa', 'tpb']) m, generate_series(1, 2) g;
insert into gabarito select id, 0, '' from questoes where id ~ '^tp[ab]-p[0-9]$';
set role authenticated;

\echo '--- 1. Sem liberação (esperado: não começa, não corrige, não vê questões)'
select t.como(johann::text) from ids;
select 'começar', t.erro($$select iniciar_prova('tpa')$$);
select 'corrigir', t.erro($$select corrigir_prova('tpa', '{}')$$);
select 'questões de prova visíveis (0)', count(*) from questoes where materia = 'tpa' and tipo = 'prova';

\echo '--- 2. Criança não libera a própria prova; pai libera até o fim da janela'
select 'Johann libera', t.erro($$insert into liberacoes (aluno, materia, ate) values (auth.uid(), 'tpa', now() + interval '2 days')$$);
select t.como(pai::text) from ids;
select 'Pai libera', t.erro($$insert into liberacoes (aluno, materia, ate, liberada_por) select johann, 'tpa', now() + interval '2 days', pai from ids$$);

\echo '--- 3. Liberada mas não começada (esperado: não vê questões, não corrige)'
select t.como(johann::text) from ids;
select 'questões visíveis (0)', count(*) from questoes where materia = 'tpa' and tipo = 'prova';
select 'corrigir sem começar', t.erro($$select corrigir_prova('tpa', '{}')$$);

\echo '--- 4. Começa: 1 hora a partir de agora, e vê as questões'
select 'ate = agora + 1h', iniciar_prova('tpa') = now() + interval '1 hour';
select 'iniciada_em = agora', iniciada_em = now() from liberacoes where materia = 'tpa';
select 'questões visíveis (2)', count(*) from questoes where materia = 'tpa' and tipo = 'prova';
select t.como(juju::text) from ids;
select 'Juju não começa a do Johann', t.erro($$select iniciar_prova('tpa')$$);
select 'Juju não vê', count(*) from questoes where materia = 'tpa' and tipo = 'prova';
select t.como(johann::text) from ids;

\echo '--- 5. Fechou o app e voltou: mesmo prazo (não reinicia a hora)'
reset role;
update liberacoes set iniciada_em = now() - interval '40 minutes', ate = now() + interval '20 minutes' where materia = 'tpa';
set role authenticated;
select 'retoma com 20 min', iniciar_prova('tpa') = now() + interval '20 minutes';

\echo '--- 6. Entrega: corrige uma vez, e não começa de novo'
select 'pct (50)', corrigir_prova('tpa', '{"tpa-p1":0,"tpa-p2":1}')->>'pct';
select 'começar de novo', t.erro($$select iniciar_prova('tpa')$$);
select 'questões escondidas de novo (0)', count(*) from questoes where materia = 'tpa' and tipo = 'prova';

\echo '--- 7. Tempo esgotado depois de começar (esperado: não retoma; corrige só até 2 min depois)'
reset role;
insert into liberacoes (aluno, materia, ate, iniciada_em) select johann, 'tpb', now() - interval '1 minute', now() - interval '61 minutes' from ids;
set role authenticated;
select 'retomar', t.erro($$select iniciar_prova('tpb')$$);
select 'questões visíveis (0)', count(*) from questoes where materia = 'tpb' and tipo = 'prova';
reset role;
update liberacoes set ate = now() - interval '3 minutes' where materia = 'tpb';
set role authenticated;
select 'corrigir 3 min depois', t.erro($$select corrigir_prova('tpb', '{}')$$);

\echo '--- 8. Liberação vencida sem começar (esperado: não começa); pai libera de novo e ela começa'
reset role;
update liberacoes set ate = now() - interval '1 minute', iniciada_em = null where materia = 'tpb';
set role authenticated;
select 'começar', t.erro($$select iniciar_prova('tpb')$$);
select t.como(pai::text) from ids;
select 'Pai libera de novo', t.erro($$update liberacoes set ate = now() + interval '1 day', iniciada_em = null where materia = 'tpb'$$);
select t.como(johann::text) from ids;
select 'começa com 1h', iniciar_prova('tpb') = now() + interval '1 hour';
select 'pct (100)', corrigir_prova('tpb', '{"tpb-p1":0,"tpb-p2":0}')->>'pct';
select 'pontos de prova (100, só a de 100%)', sum(valor) from lancamentos where origem = 'prova';

\echo '--- 9. Migração 36: plano da Juju sem os itens de prova valendo escritos à mão (rodar com a 36 duas vezes)'
reset role;
select 'itens de prova valendo da Juju (0)', count(*) from cronograma c, jsonb_array_elements_text(c.itens) i
 where c.aluno = (select juju from ids) and i ilike '%prova valendo%';
select 'dia', dia, jsonb_array_length(itens), itens ->> (jsonb_array_length(itens) - 1) from cronograma
 where aluno = (select juju from ids) and dia in ('2026-11-25', '2026-11-30', '2026-12-03') order by dia;
