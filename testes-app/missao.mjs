// Teste das telas da missão automática: carrega o script do index.html com o banco simulado.
// Uso (na raiz): node testes-app/missao.mjs index.html
import fs from 'fs'; import vm from 'vm';
const html = fs.readFileSync(process.argv[2], 'utf8');
const mod = [...html.matchAll(/<script type="module"[^>]*>([\s\S]*?)<\/script>/g)].map(x => x[1]).join('\n')
  .replace(/^import .*$/m, '');
const noop = () => {};
const gravado = [];   // o que o app mandou gravar (insert/update)
const chamadas = [];  // nomes das funções do banco chamadas, em ordem
let missaoBanco = null; // o que o banco simulado devolve em missao()
const cadeia = () => new Proxy(function(){}, { get:(_, k) => k === 'then' ? (ok => ok({ data:[], error:null })) : (...args) => { if (k === 'insert' || k === 'update') gravado.push({ k, reg:args[0] }); return cadeia(); } });
const campos = {};
let ultimoToast = '';
const el = { append:noop, appendChild:noop, remove:noop, addEventListener:noop, dataset:{}, classList:{ add:noop, remove:noop, toggle:noop }, style:{} };
const sandbox = { console, setTimeout, setInterval:noop, clearTimeout, Date, Intl, Math, JSON, Promise, Object, Array, Number, String,
  matchMedia:() => ({ matches:false, addEventListener:noop }), localStorage:{ getItem:() => null, setItem:noop },
  document:{ getElementById:id => id === 'app' ? el : (id in campos ? campos[id] : { ...el }),
    createElement:() => { const e = { ...el, remove:noop }; Object.defineProperty(e, 'textContent', { set:v => { ultimoToast = v; }, get:() => ultimoToast }); return e; },
    querySelector:() => null, querySelectorAll:() => [], addEventListener:noop, documentElement:el, body:el },
  createClient:() => ({ auth:{ onAuthStateChange:noop, getSession:async () => ({ data:{ session:null } }) }, from:() => cadeia(),
    rpc:async (nome, args) => { chamadas.push(nome); if (nome === 'missao') return { data:missaoBanco, error:null }; if (nome === 'fechar_missoes') return { data:0, error:null }; return { data:[], error:null }; } }),
  confirm:() => true, alert:noop };
sandbox.window = sandbox; sandbox.addEventListener = noop;
vm.createContext(sandbox);
vm.runInContext(mod + '\n;globalThis.__t = { acoes, S, carregar, calcMeta, comoGanhar, painelLancar, hojeISO, addDias, ' +
  '_e: typeof estadoMissao === "function" ? estadoMissao : null };', sandbox);
const { acoes, S, carregar, calcMeta, comoGanhar, painelLancar } = sandbox.__t;
const estadoMissao = sandbox.__t._e || (() => '(estadoMissao não existe)');
const txt = s => s.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ');
const ok = (c, m) => console.log((c ? 'OK   ' : 'FALHA') + ' ' + m);
const J = 'j';
// resultado de missao() como o banco devolve (bronze: 78.6% das tarefas, mínimo da prata 80)
const M0 = { prazo:'2026-11-18T01:00:00+00:00', dia_prazo:'2026-11-17', inicio:'2026-11-10', treino_min:70, prova_min:80, qtd:2,
  pontos:{ bronze:150, prata:250, ouro:400 }, tarefas_min:{ bronze:70, prata:80, ouro:90 },
  det:[ { mid:'xa', bronze:true, treino:80, prova:90 }, { mid:'xb', bronze:true, treino:75, prova:85 } ],
  tarefas:{ total:7, obtido:5.5, pct:78.6, pendentes:0 }, bronze:true, prata:false, ouro:false, nivel:'bronze', valor:150,
  ref:'meta:2026-11-17 22:00', encerrada:true, lancada:false, pode_fechar:true };
const grupos = { casa:{ grupo:'casa', moeda:'pontos', teto_semana:490, config:{} },
  estudos:{ grupo:'estudos', moeda:'pontos', config:{ prazo:'2026-11-17T22:00:00-03:00', inicio:'2026-11-10', materias:['xa','xb'], treino_min:70, prova_min:80, prova_qtd:3,
    pontos:{ bronze:150, prata:250, ouro:400 }, pts_topico:30, pts_treino:40, pts_prova:100, pts_conclusao:150, concluir_min_questoes:50 } },
  notas:{ grupo:'notas', moeda:'pontos', config:{ por_materia:70, nota_min:8, bonus:90, bonus_min:7, maximo:1000 } },
  loja:{ grupo:'loja', moeda:'pontos', config:{} } };
const mats = [ { id:'xa', nome:'Matéria A', emoji:'🅰️', ativa:true, topicos:[] }, { id:'xb', nome:'Matéria B', emoji:'🅱️', ativa:true, topicos:[] } ];
const prepara = (m, papel = 'aluno') => Object.assign(S, { perfil:{ papel }, user:{ id:papel === 'aluno' ? J : 'p' }, aluno:J,
  alunos:[{ user_id:J, nome:'Johann' }, { user_id:'u', nome:'Juju' }], grupos:JSON.parse(JSON.stringify(grupos)), mats, todasMats:mats,
  missao:m && JSON.parse(JSON.stringify(m)), lanc:[], notas:{}, prog:{}, tent:[] });

// --- Tarefa 2: missão vinda do banco, fechamento ao abrir
prepara(M0); S.missao = null; missaoBanco = M0; chamadas.length = 0;
try { await carregar(); } catch (e) { console.log('(carregar lançou: ' + e.message + ')'); }
const iF = chamadas.indexOf('fechar_missoes'), iM = chamadas.indexOf('missao');
ok(iF >= 0 && iM > iF, `carregar chama fechar_missoes antes de missao (${chamadas.join(',')})`);
ok(S.missao?.nivel === 'bronze', 'carregar guarda o resultado de missao em S.missao');

prepara({ ...M0, nivel:'ouro', valor:400, ouro:true, prata:true });
let g = calcMeta();
ok(g?.nivel === 'ouro' && g.valor === 400 && g.ouro && g.prata && g.bronze, 'calcMeta usa o nível e o valor do banco');
ok(g?.prazo instanceof sandbox.Date && g.prataDet[1].v === 75 && g.ouroDet[0].v === 90 && g.bronzeDet[0].ok === true, 'calcMeta: prazo Date e detalhes por matéria do banco');
ok(g?.c.treino_min === 70 && g.qtd === 2 && g.M.ouro === 400 && g.mats.join() === 'xa,xb', 'calcMeta: mínimos, qtd, pontos e matérias');
prepara(null); ok(calcMeta() === null, 'sem missão no banco: calcMeta nulo');

prepara(M0); let c = txt(comoGanhar());
ok(c.includes('Tarefas validadas: 78,6%') && c.includes('70 / 80 / 90'), 'Como ganhar: linha das tarefas com os mínimos');
ok(!c.includes('O pai ou a mãe lançam'), 'Como ganhar: sem "O pai ou a mãe lançam"');
prepara({ ...M0, tarefas:null, inicio:null }); c = txt(comoGanhar());
ok(!c.includes('Tarefas validadas'), 'missão sem início: sem linha de tarefas');

const est = m => { prepara(m); return estadoMissao(calcMeta()); };
ok(est({ ...M0, lancada:true }) === 'Lançada ✓ Bronze +150', 'estado: lançada — ' + est({ ...M0, lancada:true }));
ok(est({ ...M0, encerrada:false, pode_fechar:false }) === 'Os pontos entram sozinhos depois do prazo.', 'estado: prazo não acabou');
ok(est({ ...M0, pode_fechar:false, tarefas:{ ...M0.tarefas, pendentes:3 } }) === 'Esperando validação de 3 tarefas', 'estado: esperando 3 — ' + est({ ...M0, pode_fechar:false, tarefas:{ ...M0.tarefas, pendentes:3 } }));
ok(est({ ...M0, pode_fechar:false, tarefas:{ ...M0.tarefas, pendentes:1 } }) === 'Esperando validação de 1 tarefa', 'estado: esperando 1 (singular)');
ok(est({ ...M0, nivel:null, valor:0, bronze:false }) === 'Nenhum nível conquistado', 'estado: nenhum nível');
ok(est({ ...M0, pode_fechar:false }) === 'Os pontos entram em até 2 dias depois do prazo.', 'estado: aguardando a espera');

prepara(M0, 'responsavel'); const pl = painelLancar();
ok(!pl.includes('data-a="lMeta"') && txt(pl).includes('Os pontos entram em até 2 dias depois do prazo.'), 'Mais › Lançar: sem botão da missão, com o estado');
ok(!('lMeta' in acoes), 'ação lMeta removida');

