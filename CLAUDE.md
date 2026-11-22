# Cofrinho — regras de trabalho

- O app usa o banco de PRODUÇÃO no Supabase, usado pelas crianças. Pedir confirmação antes de: aplicar migração, apagar qualquer coisa (dados, arquivos, ramos) e dar push (o push publica no GitHub Pages).
- Começar lendo PENDENCIAS.md (fonte da verdade) e conferindo o Supabase só lendo. Ao fim de cada item, atualizar PENDENCIAS.md e README.md.
- Perguntar pontos em aberto antes de programar.
- Mudança que o app antigo não entende entra no ar junto com o novo index.html.
- Sem Postgres local: testes do banco em supabase/testes, no padrão existente, rodados com supabase/testes/roda.mjs (PGlite).
- apply_migration recusa migrações com `drop`: pedir para aplicar pelo SQL Editor e depois conferir lendo.
- Questões de treino são criadas do zero; o material escolar só indica conteúdo e nível. Nunca copiar exercícios, textos ou frases do livro.
