-- Prova valendo: 1 hora contada do início.
-- Pai ou mãe liberam (o app grava liberacoes.ate = fim da janela, 12h do dia da prova da escola, e iniciada_em nula).
-- A criança começa com iniciar_prova: a partir daí tem 1 hora (ate = início + 1h). Se o app fechar, ela volta
-- com o tempo que sobrou. As questões de prova só aparecem depois de começar. Só acrescenta; pode rodar de novo.
-- Entra no ar junto com o index.html novo (o app antigo não chama iniciar_prova).

alter table liberacoes add column if not exists iniciada_em timestamptz;

-- questões de prova visíveis para a criança só com a prova começada e dentro do tempo
create or replace function prova_liberada(a uuid, m text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from liberacoes where aluno = a and materia = m and iniciada_em is not null and ate > now())
$$;

-- a criança começa (ou retoma) a prova; devolve até quando ela vai
create or replace function iniciar_prova(p_materia text) returns timestamptz
language plpgsql security definer set search_path = public as $$
declare a uuid := auth.uid(); l liberacoes;
begin
  if not is_aluno(a) then raise exception 'Sem acesso'; end if;
  if exists (select 1 from tentativas where aluno = a and materia = p_materia and tipo = 'prova') then
    raise exception 'Prova já feita';
  end if;
  select * into l from liberacoes where aluno = a and materia = p_materia for update;
  if not found or (l.iniciada_em is null and l.ate <= now()) then raise exception 'Prova não liberada'; end if;
  if l.iniciada_em is null then
    update liberacoes set iniciada_em = now(), ate = now() + interval '1 hour'
     where aluno = a and materia = p_materia returning * into l;
  elsif l.ate <= now() then
    raise exception 'Tempo esgotado';
  end if;
  return l.ate;
end $$;
revoke all on function iniciar_prova(text) from public, anon;
grant execute on function iniciar_prova(text) to authenticated;

-- corrigir exige a prova começada (2 minutos de folga para o envio automático no fim do tempo)
create or replace function corrigir_prova(p_materia text, p_respostas jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_total int; v_acertos int; v_det jsonb; v_pct numeric; a uuid := auth.uid();
begin
  if not is_aluno(a) then raise exception 'Sem acesso'; end if;
  if not exists (select 1 from liberacoes where aluno = a and materia = p_materia and iniciada_em is not null
                  and ate > now() - interval '2 minutes') then
    raise exception 'Prova não liberada ou tempo esgotado';
  end if;
  select count(*),
         count(*) filter (where (p_respostas ->> q.id)::int = g.correta),
         jsonb_agg(jsonb_build_object('id', q.id, 'enunciado', q.enunciado, 'alternativas', q.alternativas,
                   'resposta', (p_respostas ->> q.id)::int, 'correta', g.correta, 'explicacao', g.explicacao))
    into v_total, v_acertos, v_det
    from questoes q join gabarito g on g.questao_id = q.id
   where q.aluno = a and q.materia = p_materia and q.tipo = 'prova';
  if v_total = 0 then raise exception 'Sem questões de prova para esta matéria'; end if;
  v_pct := round(100.0 * v_acertos / v_total, 1);
  insert into tentativas (aluno, materia, tipo, acertos, total, pct, detalhes)
       values (a, p_materia, 'prova', v_acertos, v_total, v_pct, v_det);
  update liberacoes set ate = now() where aluno = a and materia = p_materia;
  return jsonb_build_object('acertos', v_acertos, 'total', v_total, 'pct', v_pct, 'detalhes', v_det);
end $$;
