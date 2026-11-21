-- perfis mínimos para um banco novo (mesmos ids da produção)
insert into perfis (user_id, papel, nome) values
 ('78768c03-68d4-420f-ba5d-c7fe46434042','responsavel','Pai'),
 ('24409def-6870-4624-828a-84e9d6884de0','responsavel','Mãe'),
 ('d5c2215c-797c-435b-859b-09be1fe3efbf','aluno','Johann'),
 ('014341f0-99f3-4e14-b21d-6b4efc9bafbd','aluno','Juju') on conflict do nothing;
