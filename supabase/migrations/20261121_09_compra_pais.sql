-- =====================================================
-- Migração 09 — Pai e mãe lançam compras que já aconteceram
--   • item da loja ou compra livre (descrição), na data escolhida, para uma ou mais crianças
--   • o total é dividido igualmente (aceita meio ponto: 95 ÷ 2 = 47,5)
--   • não checa saldo nem limite (o app avisa antes); o saldo pode ficar negativo
--   • vira pedido já combinado (entregue) e conta no limite da semana/mês da data escolhida
-- Pré-requisito: migrações 01 a 08. Só acrescenta: o app antigo continua funcionando.
-- =====================================================
begin;

alter table resgates alter column premio drop not null;               -- compra livre não tem item da loja
alter table resgates add column dia date;                              -- data do fato (nula = data do pedido)
comment on column resgates.dia is 'Data em que a compra aconteceu (lançada pelos pais); nula = data do pedido';

-- unidades já trocadas no período (compartilhado por limite_grupo), pela data do fato
create or replace function _usado_loja(a uuid, p premios) returns int
language plpgsql stable security definer set search_path = public as $$
declare ini date; fim date; hoje date := hoje_sp();
begin
  if p.limite is null then return 0; end if;
  if p.limite_periodo = 'semana' then ini := date_trunc('week', hoje)::date; fim := ini + 6;
  else ini := date_trunc('month', hoje)::date; fim := (ini + interval '1 month')::date - 1; end if;
  return coalesce((select sum(r.quantidade) from resgates r join premios q on q.id = r.premio
                    where r.aluno = a and r.status <> 'cancelado'
                      and coalesce(r.dia, (r.criado at time zone 'America/Sao_Paulo')::date) between ini and fim
                      and coalesce(q.limite_grupo, 'p' || q.id) = coalesce(p.limite_grupo, 'p' || p.id)), 0)::int;
end $$;
revoke execute on function _usado_loja(uuid, premios) from public, anon, authenticated;

create or replace function lancar_compra(p_alunos uuid[], p_premio bigint, p_qtd int, p_descricao text, p_total numeric, p_dia date)
returns int language plpgsql security definer set search_path = public as $$
declare p premios; n int := coalesce(cardinality(p_alunos), 0); parte numeric; nome_c text; a uuid; lid bigint;
        q int := coalesce(p_qtd, 1);
begin
  if not is_responsavel() then raise exception 'Só pai ou mãe'; end if;
  if n = 0 then raise exception 'Marque ao menos uma criança'; end if;
  if (select count(distinct x) from unnest(p_alunos) x) <> n then raise exception 'Criança repetida'; end if;
  if exists (select 1 from unnest(p_alunos) x where not is_aluno(x)) then raise exception 'Escolha só crianças'; end if;
  if p_total is null or p_total <= 0 then raise exception 'O total precisa ser maior que zero'; end if;
  if p_dia is null then raise exception 'Escolha a data da compra'; end if;
  if p_dia > hoje_sp() then raise exception 'A data da compra não pode ser no futuro'; end if;
  if q < 1 then raise exception 'Quantidade inválida'; end if;
  if p_premio is not null then
    select * into p from premios where id = p_premio;
    if p.id is null then raise exception 'Item da loja inexistente'; end if;
  end if;
  nome_c := coalesce(nullif(trim(p_descricao), ''), p.nome);
  if nome_c is null then raise exception 'Escreva o que foi comprado'; end if;
  parte := round(p_total / n, 1);
  if parte <= 0 then raise exception 'O total é pequeno demais para dividir'; end if;
  foreach a in array p_alunos loop
    lid := _lancar(a, 'loja', -parte, 'Loja: ' || nome_c || case when q > 1 then ' × ' || q else '' end
                   || case when n > 1 then ' (dividido por ' || n || ')' else '' end,
                   p_dia, 'resgate', coalesce(p_premio::text, 'compra'));
    insert into resgates (aluno, premio, nome, quantidade, custo, semana, status, lancamento, dia, decidido_em, decidido_por)
         values (a, p_premio, nome_c, q, parte, date_trunc('week', p_dia)::date, 'entregue', lid, p_dia, now(), auth.uid());
  end loop;
  return n;
end $$;
revoke execute on function lancar_compra(uuid[], bigint, int, text, numeric, date) from public, anon;
grant execute on function lancar_compra(uuid[], bigint, int, text, numeric, date) to authenticated;

commit;
