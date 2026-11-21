-- =====================================================
-- Migração 13 — Missão só pelo fechamento automático
--   • lancar() deixa de aceitar origem 'nivel': o bônus da missão é lançado por fechar_missoes() (migração 12).
--     Impede que o botão Lançar do app antigo (aba aberta sem recarregar) lance a missão uma segunda vez,
--     com a referência antiga ('meta:' + texto do prazo), que o índice único não pega.
-- Pré-requisito: migrações 01 a 12. Igual à versão da migração 05, só sem 'nivel'.
-- =====================================================
begin;

create or replace function lancar(p_aluno uuid, p_grupo text, p_valor numeric, p_descricao text,
                                  p_data_ref date default null, p_origem text default 'manual',
                                  p_origem_ref text default null) returns bigint
language plpgsql security definer set search_path = public as $$
begin
  if not is_responsavel() then raise exception 'Só pai ou mãe'; end if;
  if not is_aluno(p_aluno) then raise exception 'Aluno inválido'; end if;
  if p_origem = 'nivel' then raise exception 'A missão é lançada sozinha depois do prazo. Recarregue o app.'; end if;
  if p_origem not in ('manual','uso','notas') then raise exception 'Origem inválida'; end if;
  if p_valor < 0 and p_valor + saldo_total(p_aluno) < 0 then raise exception 'Saldo insuficiente'; end if;
  return _lancar(p_aluno, p_grupo, p_valor, p_descricao, coalesce(p_data_ref, hoje_sp()), p_origem, p_origem_ref);
end $$;

commit;
