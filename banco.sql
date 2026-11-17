-- =====================================================
-- App de Estudos do Davi — estrutura do banco (Supabase)
-- Colar inteiro no SQL Editor do Supabase e clicar em RUN
-- =====================================================

create table if not exists perfis (
  user_id uuid primary key references auth.users(id) on delete cascade,
  papel text not null check (papel in ('responsavel','aluno')),
  nome text not null
);

create table if not exists progresso (
  chave text primary key,
  estudou boolean default false,
  exercicios boolean default false,
  dominio int check (dominio between 1 and 5),
  duvida text,
  feito boolean default false,
  concluido_em timestamptz,
  atualizado timestamptz default now()
);

create table if not exists questoes (
  id text primary key,
  materia text not null,
  topico text,
  tipo text not null check (tipo in ('treino','prova')),
  enunciado text not null,
  alternativas jsonb not null
);

create table if not exists gabarito (
  questao_id text primary key references questoes(id) on delete cascade,
  correta int not null,
  explicacao text
);

create table if not exists liberacoes (
  materia text primary key,
  ate timestamptz not null,
  liberada_por uuid references auth.users(id)
);

create table if not exists tentativas (
  id bigint generated always as identity primary key,
  materia text not null,
  tipo text not null check (tipo in ('treino','prova')),
  acertos int not null,
  total int not null,
  pct numeric not null,
  detalhes jsonb,
  criado timestamptz default now()
);

create table if not exists notas_p2 (
  materia text primary key,
  nota numeric check (nota between 0 and 10)
);

create table if not exists uso_gta (
  id bigint generated always as identity primary key,
  dia date not null,
  horas numeric not null check (horas > 0),
  registrado_por uuid default auth.uid(),
  criado timestamptz default now()
);

-- Funções de permissão
create or replace function is_familia() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from perfis where user_id = auth.uid())
$$;

create or replace function is_responsavel() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from perfis where user_id = auth.uid() and papel = 'responsavel')
$$;

create or replace function prova_liberada(m text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from liberacoes where materia = m and ate > now())
$$;

-- Liga a segurança por linha em tudo
alter table perfis     enable row level security;
alter table progresso  enable row level security;
alter table questoes   enable row level security;
alter table gabarito   enable row level security;
alter table liberacoes enable row level security;
alter table tentativas enable row level security;
alter table notas_p2   enable row level security;
alter table uso_gta    enable row level security;

-- Regras
create policy perfis_ler on perfis for select using (is_familia());

create policy progresso_tudo on progresso for all using (is_familia()) with check (is_familia());

create policy questoes_ler on questoes for select
  using (is_responsavel() or tipo = 'treino' or (tipo = 'prova' and prova_liberada(materia)));
create policy questoes_admin on questoes for all using (is_responsavel()) with check (is_responsavel());

create policy gabarito_ler on gabarito for select
  using (is_responsavel() or exists (select 1 from questoes q where q.id = questao_id and q.tipo = 'treino'));
create policy gabarito_admin on gabarito for all using (is_responsavel()) with check (is_responsavel());

create policy liberacoes_ler on liberacoes for select using (is_familia());
create policy liberacoes_admin on liberacoes for all using (is_responsavel()) with check (is_responsavel());

create policy tentativas_ler on tentativas for select using (is_familia());
create policy tentativas_treino on tentativas for insert with check (is_familia() and tipo = 'treino');
create policy tentativas_apagar on tentativas for delete using (is_responsavel());

create policy notas_ler on notas_p2 for select using (is_familia());
create policy notas_admin on notas_p2 for all using (is_responsavel()) with check (is_responsavel());

create policy gta_ler on uso_gta for select using (is_familia());
create policy gta_admin on uso_gta for all using (is_responsavel()) with check (is_responsavel());

-- Correção da prova valendo (o gabarito nunca vai para o aparelho do aluno antes de enviar)
create or replace function corrigir_prova(p_materia text, p_respostas jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_total int; v_acertos int; v_det jsonb; v_pct numeric;
begin
  if not is_familia() then raise exception 'Sem acesso'; end if;
  if not exists (select 1 from liberacoes where materia = p_materia and ate > now() - interval '2 minutes') then
    raise exception 'Prova não liberada ou tempo esgotado';
  end if;
  select count(*),
         count(*) filter (where (p_respostas ->> q.id)::int = g.correta),
         jsonb_agg(jsonb_build_object('id', q.id, 'enunciado', q.enunciado, 'alternativas', q.alternativas,
                   'resposta', (p_respostas ->> q.id)::int, 'correta', g.correta, 'explicacao', g.explicacao))
    into v_total, v_acertos, v_det
    from questoes q join gabarito g on g.questao_id = q.id
   where q.materia = p_materia and q.tipo = 'prova';
  if v_total = 0 then raise exception 'Sem questões de prova para esta matéria'; end if;
  v_pct := round(100.0 * v_acertos / v_total, 1);
  insert into tentativas (materia, tipo, acertos, total, pct, detalhes)
       values (p_materia, 'prova', v_acertos, v_total, v_pct, v_det);
  update liberacoes set ate = now() where materia = p_materia;
  return jsonb_build_object('acertos', v_acertos, 'total', v_total, 'pct', v_pct, 'detalhes', v_det);
end $$;

grant execute on function corrigir_prova(text, jsonb) to authenticated;
