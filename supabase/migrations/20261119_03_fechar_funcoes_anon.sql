-- Migração 03: funções só para quem está logado (aplicada em 18/11/2026 após a 01/02)
alter function hoje_sp() set search_path = public;
do $$ declare f text; begin
  foreach f in array array[
    'abrir_recurso(bigint,date,text)','corrigir_prova(text,jsonb)','decidir_tarefa(bigint,date,uuid,text)','dia_pausado(date)',
    'inicio_janela(uuid,text,date)','is_aluno(uuid)','is_familia()','is_responsavel()','lancar(uuid,text,numeric,text,date,text,text)',
    'marcar_tarefa(bigint,date,text,uuid)','pode_ver(uuid)','prova_liberada(uuid,text)','resgatar(bigint)','resolver_recurso(bigint,text,text)',
    'responsaveis(bigint,date)','saldo(uuid,text,date)','tarefas_do_dia(uuid,date)','hoje_sp()'] loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
  execute 'revoke execute on function public.tg_perfil_aluno() from public, anon, authenticated';
  execute 'revoke execute on function public.inicio_janela(uuid,text,date) from authenticated';
end $$;
