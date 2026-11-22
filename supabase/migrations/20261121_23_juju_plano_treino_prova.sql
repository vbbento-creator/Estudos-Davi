-- Migração 23 — itens de treino e de prova valendo no plano de estudo da Juju (P2 do 3º ano).
-- O plano da migração 14 foi feito sem treino; agora ela tem questões de treino e de prova em todas as matérias.
-- Os itens novos entram no FIM da lista de cada dia: as marcações manuais (crono:<dia>:<posição>) dos itens antigos não mudam.
-- Textos que o app marca sozinho (autoFeito no index.html):
--   "<Matéria>: treino"        → um treino daquela matéria no dia (qualquer nota);
--   "... prova valendo ..."    → qualquer prova feita no dia (por isso, no máximo uma por dia).
-- Só muda dados. Pode rodar de novo: não repete item que já está no dia.
begin;
with novos(dia, item) as (values
  ('2026-11-23'::date, '🎯 Português: treino'),
  ('2026-11-24', '🎯 Português: treino'),
  ('2026-11-25', '🏛️ Português: prova valendo (com pai ou mãe)'),
  ('2026-11-26', '🎯 Português: treino'),
  ('2026-11-27', '🎯 Ciências: treino'),
  ('2026-11-28', '🏛️ Ciências: prova valendo (com pai ou mãe)'),
  ('2026-11-29', '🎯 Inglês: treino'),
  ('2026-11-30', '🏛️ Inglês: prova valendo (com pai ou mãe)'),
  ('2026-12-01', '🏛️ História: prova valendo (com pai ou mãe)'),
  ('2026-12-02', '🏛️ Geografia: prova valendo (com pai ou mãe)'),
  ('2026-12-03', '🎯 Matemática: treino'),
  ('2026-12-03', '🏛️ Matemática: prova valendo (com pai ou mãe)')
), por_dia as (
  -- no mesmo dia, o treino vem antes da prova valendo (só 03/12 tem dois itens novos)
  select dia, jsonb_agg(item order by item like '🎯%' desc) itens
  from novos
  group by dia
)
update cronograma c
   set itens = c.itens || (select coalesce(jsonb_agg(x order by o), '[]'::jsonb)
                             from jsonb_array_elements_text(p.itens) with ordinality e(x, o)
                            where not c.itens ? x)
  from por_dia p
 where c.aluno = '014341f0-99f3-4e14-b21d-6b4efc9bafbd'
   and c.dia = p.dia;
commit;
