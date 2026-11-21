-- =====================================================
-- Migração 08 — Trocar o responsável pela tarefa
--   • revezamento, só aquele dia: continua na tabela trocas (o app antigo também usa)
--   • revezamento, daquele dia em diante: o revezamento recomeça pela criança escolhida (revez_inicios)
--   • "todos": outra criança faz no lugar, só aquele dia ou daquele dia em diante (substituicoes);
--     só para quem ainda não faz essa tarefa no dia
--   • não se troca dia que a criança já marcou
-- Pré-requisito: migrações 01 a 07. Só acrescenta: o app antigo continua funcionando.
-- =====================================================
begin;

create table revez_inicios (
  tarefa bigint not null references tarefas(id),
  desde  date   not null,
  aluno  uuid   not null references perfis(user_id),   -- a vez começa por ela neste dia
  por    uuid default auth.uid(),
  criado timestamptz not null default now(),
  primary key (tarefa, desde)
);

create table substituicoes (
  id     bigint generated always as identity primary key,
  tarefa bigint not null references tarefas(id),
  de     uuid   not null references perfis(user_id),
  para   uuid   not null references perfis(user_id),
  desde  date   not null,
  ate    date,                                          -- null = daquele dia em diante
  por    uuid default auth.uid(),
  criado timestamptz not null default now(),
  check (de <> para), check (ate is null or ate >= desde)
);
create index on substituicoes (tarefa, desde);

alter table revez_inicios enable row level security;
alter table substituicoes enable row level security;
create policy revez_inicios_ler on revez_inicios for select using (is_familia());
create policy substituicoes_ler on substituicoes for select using (is_familia());
revoke insert, update, delete on revez_inicios, substituicoes from anon, authenticated;   -- escrita só pela função

-- quem faz a tarefa no dia d
create or replace function responsaveis(p_tarefa bigint, d date) returns uuid[]
language plpgsql stable security definer set search_path = public as $$
declare t tarefas; n int; k int; tr uuid; ini revez_inicios; b date; i0 int; res uuid[]; s substituicoes;
begin
  select * into t from tarefas where id = p_tarefa;
  if t is null or d < t.base or dia_pausado(d) then return '{}'; end if;
  if t.dias_semana is not null and not (extract(dow from d)::int = any (t.dias_semana)) then return '{}'; end if;
  if t.modo = 'todos' then
    res := t.alunos;
    for s in select * from substituicoes where tarefa = p_tarefa and desde <= d and (ate is null or ate >= d) order by criado, id loop
      if s.de = any (res) then
        res := array_remove(res, s.de);
        if not (s.para = any (res)) then res := res || s.para; end if;
      end if;
    end loop;
    return res;
  end if;
  select aluno into tr from trocas where tarefa = p_tarefa and dia = d;
  if tr is not null then return array[tr]; end if;
  -- recomeço mais recente (ignorado se a criança saiu do revezamento)
  select * into ini from revez_inicios where tarefa = p_tarefa and desde <= d and aluno = any (t.alunos)
   order by desde desc limit 1;
  b  := coalesce(greatest(ini.desde, t.base), t.base);
  i0 := coalesce(array_position(t.alunos, ini.aluno), 1) - 1;
  n  := cardinality(t.alunos);
  k  := (select count(*) from generate_series(b, d - 1, interval '1 day') g
          where (t.dias_semana is null or extract(dow from g)::int = any (t.dias_semana))
            and not dia_pausado(g::date))::int;
  return array[t.alunos[((i0 + k) % n) + 1]];
end $$;

-- pai ou mãe trocam quem faz: só aquele dia (p_em_diante = false) ou daquele dia em diante
create or replace function trocar_responsavel(p_tarefa bigint, p_dia date, p_de uuid, p_para uuid, p_em_diante boolean default false)
returns void language plpgsql security definer set search_path = public as $$
declare t tarefas;
begin
  if not is_responsavel() then raise exception 'Só pai ou mãe'; end if;
  select * into t from tarefas where id = p_tarefa;
  if t is null or not t.ativa then raise exception 'Tarefa inexistente ou desativada'; end if;
  if p_dia is null or p_de is null or p_para is null then raise exception 'Faltam dados para a troca'; end if;
  if not is_aluno(p_para) then raise exception 'Escolha uma criança'; end if;
  if p_de = p_para then raise exception 'Escolha outra criança'; end if;
  if not (p_de = any (responsaveis(p_tarefa, p_dia))) then raise exception 'Essa criança não faz essa tarefa neste dia'; end if;
  if p_para = any (responsaveis(p_tarefa, p_dia)) then raise exception 'Essa criança já faz essa tarefa neste dia'; end if;
  if exists (select 1 from tarefa_dia where tarefa = p_tarefa and aluno = p_de
              and (dia = p_dia or (p_em_diante and dia > p_dia))) then
    raise exception 'A tarefa já foi marcada nesse dia: não dá para trocar';
  end if;
  if t.modo = 'todos' then
    insert into substituicoes (tarefa, de, para, desde, ate)
         values (p_tarefa, p_de, p_para, p_dia, case when p_em_diante then null else p_dia end);
  elsif not p_em_diante then
    insert into trocas (tarefa, dia, aluno, por) values (p_tarefa, p_dia, p_para, auth.uid())
    on conflict (tarefa, dia) do update set aluno = excluded.aluno, por = excluded.por;
  else
    if not (p_para = any (t.alunos)) then raise exception 'Para recomeçar o revezamento, a criança precisa estar na tarefa'; end if;
    insert into revez_inicios (tarefa, desde, aluno, por) values (p_tarefa, p_dia, p_para, auth.uid())
    on conflict (tarefa, desde) do update set aluno = excluded.aluno, por = excluded.por, criado = now();
    -- uma troca de um dia marcada justamente para esse dia deixaria de fazer sentido
    update trocas set aluno = p_para, por = auth.uid() where tarefa = p_tarefa and dia = p_dia;
  end if;
end $$;

revoke execute on function responsaveis(bigint, date), trocar_responsavel(bigint, date, uuid, uuid, boolean) from public, anon;
grant execute on function responsaveis(bigint, date), trocar_responsavel(bigint, date, uuid, uuid, boolean) to authenticated;

commit;
