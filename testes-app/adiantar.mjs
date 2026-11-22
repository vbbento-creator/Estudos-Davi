// Teste do plano de estudo marcado sozinho, inclusive o que a criança adiantou (até 7 dias antes, um item por atividade).
// Carrega o script do index.html com o banco simulado (nada vai para o Supabase).
// Uso (na raiz): node testes-app/adiantar.mjs index.html
import fs from 'fs'; import vm from 'vm';
const html = fs.readFileSync(process.argv[2], 'utf8');
const mod = [...html.matchAll(/<script type="module"[^>]*>([\s\S]*?)<\/script>/g)].map(x => x[1]).join('\n')
  .replace(/^import .*$/m, '');
const noop = () => {};
const cadeia = () => new Proxy(function(){}, { get:(_, k) => k === 'then' ? (ok => ok({ data:[], error:null })) : () => cadeia() });
const el = { append:noop, appendChild:noop, remove:noop, addEventListener:noop, dataset:{}, classList:{ add:noop, remove:noop, toggle:noop }, style:{} };
const sandbox = { console, setTimeout, setInterval:noop, clearTimeout, Date, Intl, Math, JSON, Promise, Object, Array, Number, String,
  matchMedia:() => ({ matches:false, addEventListener:noop }), localStorage:{ getItem:() => null, setItem:noop },
  document:{ getElementById:() => ({ ...el }), createElement:() => ({ ...el }), querySelector:() => null, querySelectorAll:() => [], addEventListener:noop, documentElement:el, body:el },
  createClient:() => ({ auth:{ onAuthStateChange:noop, getSession:async () => ({ data:{ session:null } }) }, from:() => cadeia(), rpc:async () => ({ data:[], error:null }) }),
  confirm:() => true, alert:noop };
sandbox.window = sandbox; sandbox.addEventListener = noop;
vm.createContext(sandbox);
vm.runInContext(mod + '\n;globalThis.__t = { S, autoFeito, linhaCrono, telaAgenda, hojeISO, addDias, ' +
  'marcasAuto: typeof marcasAuto === "function" ? marcasAuto : null };', sandbox);
const { S, autoFeito, linhaCrono, telaAgenda, hojeISO, addDias } = sandbox.__t;
const marcasAuto = sandbox.__t.marcasAuto || (() => new Map());
const txt = s => s.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ');
const ok = (c, m) => console.log((c ? 'OK   ' : 'FALHA') + ' ' + m);

const topicos = (mid, n) => Array.from({ length:n }, (_, i) => ({ materia:mid, idx:i, nome:`T${i}`, ativo:true }));
const mats = [
  { id:'portugues', nome:'Português', emoji:'📝', ativa:true, topicos:topicos('portugues', 6) },
  { id:'ingles', nome:'Inglês', emoji:'🇬🇧', ativa:true, topicos:topicos('ingles', 6) },
  { id:'fisica', nome:'Física', emoji:'🔭', ativa:true, topicos:topicos('fisica', 6) },
];
let nT = 0;
// treino (ou prova) em "AAAA-MM-DD HH:MM:SS.mmm" no horário de São Paulo
const tr = (mid, quando, pct = 100, tipo = 'treino', total = 10) => ({ id:++nT, materia:mid, tipo, acertos:Math.round(pct / 10), total, pct:String(pct),
  criado:new Date(quando.replace(' ', 'T') + '-03:00').toISOString() });
// tópico concluído em "AAAA-MM-DD"
const tp = (mid, idx, dia) => [`${mid}:${idx}`, { chave:`${mid}:${idx}`, estudou:true, exercicios:true, concluido_em:new Date(dia + 'T15:00:00-03:00').toISOString() }];
const prepara = ({ crono, tent = [], prog = [], papel = 'aluno' }) => Object.assign(S, {
  perfil:{ papel }, user:{ id:'j' }, aluno:'j', mats, todasMats:mats,
  grupos:{ estudos:{ grupo:'estudos', config:{ treino_min:70, materias:['portugues', 'ingles'] } } },
  crono:crono.map(([d, itens]) => ({ d, t:'', itens })), tent, prog:Object.fromEntries(prog), missao:null });
const marca = (d, i) => marcasAuto().get(`${d}:${i}`);
const PLANO_JUJU = [
  ['2026-11-22', ['Português: verbos e tempos verbais']],
  ['2026-11-23', ['Português: pontuação do diálogo', 'Português: ler 1 texto e responder (interpretação)', '🎯 Português: treino']],
  ['2026-11-24', ['Ciências: som', '🎯 Português: treino']],
  ['2026-11-25', ['Ditado de S e SS', '🏛️ Português: prova valendo (com pai ou mãe)']],
  ['2026-11-26', ['Revisão final: Português (verbos)', '🎯 Português: treino']],
];

// 1. no dia, como hoje
prepara({ crono:PLANO_JUJU, tent:[tr('portugues', '2026-11-23 18:00:00.000')] });
ok(autoFeito('2026-11-23', 0) && autoFeito('2026-11-23', 1) && autoFeito('2026-11-23', 2), '1. treino no dia marca os 3 itens de Português do dia');
ok(marca('2026-11-23', 2)?.adiantado === null, '1. no dia: sem "adiantou"');

// 2. treino adiantado marca só o próximo item de treino
prepara({ crono:PLANO_JUJU, tent:[tr('portugues', '2026-11-21 20:44:54.954')] });
ok(autoFeito('2026-11-23', 2) && marca('2026-11-23', 2)?.adiantado === '2026-11-21', '2. treino de 21/11 marca o treino de 23/11 (adiantado 21/11)');
ok(!autoFeito('2026-11-24', 1) && !autoFeito('2026-11-26', 1), '2. não marca os treinos de 24 e 26/11');
ok(!autoFeito('2026-11-22', 0) && !autoFeito('2026-11-23', 0), '2. treino adiantado não marca item de estudo');

// 3. dois treinos adiantados, dois itens
prepara({ crono:PLANO_JUJU, tent:[tr('portugues', '2026-11-21 21:00:00.000', 90), tr('portugues', '2026-11-20 20:00:00.000')] });
ok(autoFeito('2026-11-23', 2) && autoFeito('2026-11-24', 1) && !autoFeito('2026-11-26', 1), '3. dois treinos adiantados marcam 23 e 24/11, não 26/11');
ok(marca('2026-11-23', 2)?.adiantado === '2026-11-20' && marca('2026-11-24', 1)?.adiantado === '2026-11-21', '3. o mais antigo vai para o primeiro item');
// o treino de 22/11 cumpre o item de estudo de Português do próprio dia 22/11: fica com o dia
prepara({ crono:PLANO_JUJU, tent:[tr('portugues', '2026-11-22 10:00:00.000')] });
ok(autoFeito('2026-11-22', 0) && !autoFeito('2026-11-23', 2), '3. treino em 22/11 fica com o item de 22/11 e não adianta 23/11');

// 4. duplo toque conta como um
prepara({ crono:PLANO_JUJU, tent:[tr('portugues', '2026-11-21 20:34:46.379'), tr('portugues', '2026-11-21 20:34:46.425')] });
ok(autoFeito('2026-11-23', 2) && !autoFeito('2026-11-24', 1), '4. dois treinos com 46 ms de diferença marcam um item só');

// 5. janela de 7 dias
prepara({ crono:PLANO_JUJU, tent:[tr('portugues', '2026-11-15 10:00:00.000')] });
ok(!autoFeito('2026-11-23', 2), '5. treino 8 dias antes não marca');
prepara({ crono:PLANO_JUJU, tent:[tr('portugues', '2026-11-16 10:00:00.000')] });
ok(autoFeito('2026-11-23', 2), '5. treino 7 dias antes marca');

// 6. nota mínima pedida no item
const P70 = [['2026-11-23', ['Inglês: treino (70%+)']]];
prepara({ crono:P70, tent:[tr('ingles', '2026-11-21 10:00:00.000', 60)] });
ok(!autoFeito('2026-11-23', 0), '6. treino adiantado de 60% não marca item de 70%');
prepara({ crono:P70, tent:[tr('ingles', '2026-11-21 10:00:00.000', 80)] });
ok(autoFeito('2026-11-23', 0), '6. treino adiantado de 80% marca item de 70%');
prepara({ crono:P70, tent:[tr('ingles', '2026-11-21 10:00:00.000', 100, 'treino', 4)] });
ok(!autoFeito('2026-11-23', 0), '6. treino com menos de 5 questões não conta');

// 7. tópicos adiantados marcam itens de estudo, um cada
const PF = [['2026-11-19', ['Física: constelações']], ['2026-11-20', ['Física: evolução estelar']], ['2026-11-21', ['Física: revisão']]];
prepara({ crono:PF, prog:[tp('fisica', 0, '2026-11-18'), tp('fisica', 1, '2026-11-18')] });
ok(autoFeito('2026-11-19', 0) && autoFeito('2026-11-20', 0) && !autoFeito('2026-11-21', 0), '7. dois tópicos de 18/11 marcam 19 e 20/11, não 21/11');
prepara({ crono:PF, tent:[tr('fisica', '2026-11-18 20:00:00.000')] });
ok(!autoFeito('2026-11-19', 0), '7. treino adiantado não marca item de estudo');

// 8. reserva do dia
const PR = [['2026-11-18', ['Português: crase + treino']], ['2026-11-19', ['Português: treino']]];
prepara({ crono:PR, tent:[tr('portugues', '2026-11-18 20:00:00.000')] });
ok(autoFeito('2026-11-18', 0) && !autoFeito('2026-11-19', 0), '8. o treino do dia fica com o item do dia e não adianta o seguinte');
prepara({ crono:PR, tent:[tr('portugues', '2026-11-18 20:00:00.000'), tr('portugues', '2026-11-18 21:00:00.000')] });
ok(autoFeito('2026-11-18', 0) && autoFeito('2026-11-19', 0), '8. o segundo treino do dia adianta o seguinte');

// 9. item com duas matérias
const PD = [['2026-11-23', ['Revisão final: Português e Inglês']], ['2026-11-24', ['Português: verbos']]];
prepara({ crono:PD, prog:[tp('portugues', 0, '2026-11-18'), tp('ingles', 0, '2026-11-18')] });
ok(autoFeito('2026-11-23', 0) && marca('2026-11-23', 0)?.adiantado === '2026-11-18', '9. revisão de duas matérias marcada com um tópico de cada');
prepara({ crono:PD, prog:[tp('portugues', 0, '2026-11-18')] });
ok(!autoFeito('2026-11-23', 0) && autoFeito('2026-11-24', 0), '9. só Português: a revisão não marca e o tópico vai para o item seguinte');

// 10. item marcado à mão não gasta a atividade
prepara({ crono:PLANO_JUJU, tent:[tr('portugues', '2026-11-21 20:00:00.000')], prog:[['crono:2026-11-23:2', { chave:'crono:2026-11-23:2', feito:true }]] });
ok(!marca('2026-11-23', 2) && autoFeito('2026-11-24', 1), '10. item marcado à mão não gasta: o treino vai para 24/11');

// 11. prova valendo só no dia
prepara({ crono:PLANO_JUJU, tent:[tr('portugues', '2026-11-24 19:00:00.000', 90, 'prova')] });
ok(!autoFeito('2026-11-25', 1), '11. prova em 24/11 não marca a prova valendo de 25/11');
prepara({ crono:PLANO_JUJU, tent:[tr('portugues', '2026-11-25 19:00:00.000', 90, 'prova')] });
ok(autoFeito('2026-11-25', 1), '11. prova em 25/11 marca a prova valendo de 25/11');

// 12. subtítulo
prepara({ crono:PLANO_JUJU, tent:[tr('portugues', '2026-11-21 20:00:00.000')] });
const l12 = txt(linhaCrono('2026-11-23', 2, '🎯 Português: treino'));
ok(l12.includes('você adiantou em 21/11') && l12.includes('✓'), '12. item adiantado: "você adiantou em 21/11" (' + l12.trim() + ')');
const l12b = txt(linhaCrono('2026-11-24', 1, '🎯 Português: treino'));
ok(!l12b.includes('✓') && l12b.includes('Plano de estudo'), '12. item não marcado continua manual');

// 13. pai ou mãe
prepara({ crono:PLANO_JUJU, tent:[tr('portugues', '2026-11-23 18:00:00.000')], papel:'responsavel' });
ok(!autoFeito('2026-11-23', 2), '13. pai ou mãe: nada marcado sozinho');

// 14. frase da Agenda em dia futuro
prepara({ crono:[] });
Object.assign(S, { agSel:addDias(hojeISO(), 3), agIni:null, agView:'semana', agFiltro:'todos', agenda:{}, pausas:[], tarefasCad:[], fam:{ provas:[], crono:{ j:[] }, progCrono:{} } });
let ag = ''; try { ag = txt(telaAgenda()); } catch (e) { ag = 'ERRO ' + e.message; }
ok(ag.includes('Tarefas de casa: você marca só hoje e ontem.'), '14. Agenda em dia futuro: "Tarefas de casa: você marca só hoje e ontem."');
