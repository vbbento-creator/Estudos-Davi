-- Migração 15 — bônus de "Concluir treino" da Juju exige 25 questões por matéria (o Johann continua com 50).
-- Só muda dados; também dá para editar em Mais › Cadastros › Pontos.
update grupos set config = config || '{"concluir_min_questoes":25}'
 where aluno = '014341f0-99f3-4e14-b21d-6b4efc9bafbd' and grupo = 'estudos';
