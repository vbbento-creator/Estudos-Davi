-- Relógio fixo às 20h de hoje (horário de Brasília) para os testes antigos (05 a 11) depois da migração 24:
-- com ele, todos os períodos de hoje já abriram. Rodar depois das migrações e antes do arquivo de testes.
create or replace function agora_sp() returns timestamp language sql stable as $$ select hoje_sp() + time '20:00' $$;
