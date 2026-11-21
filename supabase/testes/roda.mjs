// Roda arquivos SQL em ordem num Postgres em memória (PGlite), sem precisar instalar Postgres.
// Instalar uma vez, nesta pasta: npm i --no-save @electric-sql/pglite
// Uso (de dentro de supabase/testes): node roda.mjs 00_stub.sql ../../banco.sql 00_perfis.sql ../migrations/*.sql 06_testes_trocar_responsavel.sql
// Arquivos com "_testes" no nome imprimem o resultado de cada select; os demais só carregam (e param no primeiro erro).
// Linhas do psql que começam com barra invertida são ignoradas, exceto echo, que vira um título na saída.
import { PGlite } from '@electric-sql/pglite';
import { readFileSync } from 'fs';
const db = new PGlite();
const fmt = v => v === null ? '' : (v instanceof Date ? v.toISOString() : typeof v === 'object' ? JSON.stringify(v) : String(v));
for (const arq of process.argv.slice(2)){
  const txt = readFileSync(arq, 'utf8').replace(/^﻿/, '');
  const ehTeste = /_testes/.test(arq);
  let bloco = [];
  const roda = async () => {
    const sql = bloco.join('\n'); bloco = [];
    if (!sql.trim()) return;
    try {
      const res = await db.exec(sql, { rowMode:'array' });
      if (ehTeste) for (const r of res) for (const row of r.rows){ const vs = row; if (vs.length === 1 && (vs[0] === '' || vs[0] === null)) continue; console.log(vs.map(fmt).join('|')); }
    } catch (e) { console.log(`!! ERRO em ${arq}: ${e.message}`); process.exitCode = 1; if (!ehTeste) process.exit(1); }
  };
  for (const linha of txt.split(/\r?\n/)){
    const m = linha.match(/^\\echo\s+'?(.*?)'?\s*$/);
    if (m){ await roda(); console.log(m[1]); continue; }
    if (linha.startsWith('\\')) continue;
    bloco.push(linha);
  }
  await roda();
}
