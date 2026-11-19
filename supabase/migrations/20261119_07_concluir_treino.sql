-- =====================================================
-- Migração 07 — Concluir treino
-- A criança repassa as questões que errou e as que ainda não respondeu (rodadas de 10). Quando TODAS as questões
-- de treino da matéria estão certas na última vez em que foram respondidas, e a matéria tem pelo menos 50 questões
-- de treino, ganha um bônus (uma vez por matéria; se entrarem questões novas e ela concluir de novo, ganha de novo).
-- A correção é feita aqui no banco, comparando a resposta com o gabarito (o campo "c" que o aparelho manda é ignorado).
-- Perder pontos pela nota (migração 06) também retira esse bônus.
-- Pré-requisito: migrações 05 e 06.
-- =====================================================
begin;

-- tipos novos
do $$ declare c record; begin
  for c in select conname from pg_constraint where contype = 'c' and conrelid = 'tentativas'::regclass
            and pg_get_constraintdef(oid) ilike '%tipo = any%' loop
    execute format('alter table tentativas drop constraint %I', c.conname);
  end loop;
  for c in select conname from pg_constraint where contype = 'c' and conrelid = 'lancamentos'::regclass
            and pg_get_constraintdef(oid) ilike '%origem = any%' loop
    execute format('alter table lancamentos drop constraint %I', c.conname);
  end loop;
end $$;
alter table tentativas add constraint tentativas_tipo_check check (tipo in ('treino', 'prova', 'revisao'));
alter table lancamentos add constraint lancamentos_origem_check
  check (origem in ('manual','uso','tarefa','estorno','resgate','nivel','notas','topico','treino','prova','conclusao'));
drop policy tentativas_treino on tentativas;
create policy tentativas_treino on tentativas for insert
  with check (aluno = auth.uid() and is_aluno(aluno) and tipo in ('treino', 'revisao'));
create unique index lancamentos_unico_conclusao on lancamentos (aluno, origem_ref) where origem = 'conclusao';

-- regras novas (por aluno)
update grupos set config = config || '{"pts_conclusao":150,"concluir_min_questoes":50}' where grupo = 'estudos';
create or replace function criar_grupos(a uuid) returns void
language sql security definer set search_path = public as $$
  insert into grupos (aluno, grupo, moeda, teto_semana, config) values
    (a, 'notas',   'pontos', null, '{"por_materia":70,"nota_min":8,"bonus":90,"bonus_min":7,"maximo":1000}'),
    (a, 'estudos', 'pontos', null, '{"prazo":null,"materias":[],"treino_min":70,"prova_min":80,"prova_qtd":3,"pontos":{"bronze":150,"prata":250,"ouro":400},"pts_topico":30,"pts_treino":40,"pts_prova":100,"pts_conclusao":150,"concluir_min_questoes":50}'),
    (a, 'casa',    'pontos', 490,  '{}'),
    (a, 'loja',    'pontos', null, '{}')
  on conflict do nothing
$$;

-- por questão de treino: true = última resposta certa, false = última resposta errada, null = nunca respondida
create function _dominio_treino(a uuid, m text) returns table (qid text, ok boolean)
language sql stable security definer set search_path = public as $$
  select q.id,
         (select (e.value ->> 'r')::int = g.correta
            from tentativas t cross join lateral jsonb_array_elements(t.detalhes) e
           where t.aluno = a and t.materia = m and t.tipo in ('treino', 'revisao') and e.value ->> 'id' = q.id
           order by t.criado desc, t.id desc limit 1)
    from questoes q join gabarito g on g.questao_id = q.id
   where q.aluno = a and q.materia = m and q.tipo = 'treino'
$$;
revoke execute on function _dominio_treino(uuid, text) from public, anon, authenticated;

create function treino_estado(p_aluno uuid, p_materia text)
returns table (total int, dominadas int, erradas text[], novas text[], minimo int, pontos numeric, bonus_dado boolean)
language plpgsql stable security definer set search_path = public as $$
declare c jsonb; v_total int;
begin
  if not pode_ver(p_aluno) then raise exception 'Sem acesso'; end if;
  select config into c from grupos where aluno = p_aluno and grupo = 'estudos';
  select count(*)::int into v_total from _dominio_treino(p_aluno, p_materia);
  return query
  select v_total,
         (count(*) filter (where d.ok))::int,
         coalesce(array_agg(d.qid order by d.qid) filter (where d.ok is false), '{}'),
         coalesce(array_agg(d.qid order by d.qid) filter (where d.ok is null), '{}'),
         coalesce((c ->> 'concluir_min_questoes')::int, 50),
         coalesce((c ->> 'pts_conclusao')::numeric, 150),
         exists (select 1 from lancamentos l where l.aluno = p_aluno and l.origem = 'conclusao' and l.origem_ref = p_materia || ':' || v_total)
    from _dominio_treino(p_aluno, p_materia) d;
end $$;

create function _checar_conclusao(a uuid, m text) returns void
language plpgsql security definer set search_path = public as $$
declare c jsonb; v_total int; v_dom int;
begin
  select config into c from grupos where aluno = a and grupo = 'estudos';
  select count(*)::int, (count(*) filter (where ok))::int into v_total, v_dom from _dominio_treino(a, m);
  if v_total >= coalesce((c ->> 'concluir_min_questoes')::int, 50) and v_dom = v_total then
    perform _credito_estudo(a, 'pts_conclusao', 150, 'Treino concluído: ' || m, 'conclusao', m || ':' || v_total);
  end if;
end $$;
revoke execute on function _checar_conclusao(uuid, text) from public, anon, authenticated;

create or replace function tg_tentativa_pontos() returns trigger
language plpgsql security definer set search_path = public as $$
declare c jsonb;
begin
  select config into c from grupos where aluno = new.aluno and grupo = 'estudos';
  if new.tipo = 'treino' and new.total >= 5 and new.pct >= coalesce((c ->> 'treino_min')::numeric, 70) then
    perform _credito_estudo(new.aluno, 'pts_treino', 40, 'Treino ' || new.materia || ' ' || new.pct || '%',
                            'treino', new.materia || ':' || hoje_sp());      -- 1 por matéria por dia
  elsif new.tipo = 'prova' and new.pct >= coalesce((c ->> 'prova_min')::numeric, 80) then
    perform _credito_estudo(new.aluno, 'pts_prova', 100, 'Prova ' || new.materia || ' ' || new.pct || '%', 'prova', new.id::text);
  end if;
  if new.tipo in ('treino', 'revisao') then perform _checar_conclusao(new.aluno, new.materia); end if;
  return new;
end $$;

-- perder pontos pela nota: agora inclui o bônus de treino concluído
create or replace function pontos_estudo_por_materia(p_aluno uuid) returns table (materia text, pontos numeric)
language plpgsql stable security definer set search_path = public as $$
begin
  if not pode_ver(p_aluno) then raise exception 'Sem acesso'; end if;
  return query
  select split_part(l.origem_ref, ':', 1), sum(l.valor)
    from lancamentos l
   where l.aluno = p_aluno and l.origem in ('topico', 'treino', 'conclusao') and l.valor > 0
     and not exists (select 1 from lancamentos e where e.aluno = l.aluno and e.origem = 'estorno' and e.origem_ref = 'perda:' || l.id)
   group by 1;
end $$;

create or replace function perder_pontos_estudo(p_aluno uuid, p_materia text) returns numeric
language plpgsql security definer set search_path = public as $$
declare r record; total numeric := 0;
begin
  if not is_responsavel() then raise exception 'Só pai ou mãe'; end if;
  if not is_aluno(p_aluno) then raise exception 'Aluno inválido'; end if;
  for r in
    select l.id, l.valor, l.descricao from lancamentos l
     where l.aluno = p_aluno and l.origem in ('topico', 'treino', 'conclusao') and l.valor > 0
       and split_part(l.origem_ref, ':', 1) = p_materia
       and not exists (select 1 from lancamentos e where e.aluno = l.aluno and e.origem = 'estorno' and e.origem_ref = 'perda:' || l.id)
     order by l.id
  loop
    perform _lancar(p_aluno, 'estudos', -r.valor, 'Perdeu: ' || r.descricao, hoje_sp(), 'estorno', 'perda:' || r.id);
    total := total + r.valor;
  end loop;
  return total;
end $$;

revoke execute on function public.treino_estado(uuid, text) from public, anon;
grant execute on function public.treino_estado(uuid, text) to authenticated;

commit;
