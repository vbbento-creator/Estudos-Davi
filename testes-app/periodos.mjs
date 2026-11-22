// Teste das telas da tarefa com vários períodos: carrega o script do index.html com o banco simulado.
// Uso (na raiz): node testes-app/periodos.mjs index.html
import fs from 'fs'; import vm from 'vm';
const html = fs.readFileSync(process.argv[2], 'utf8');
const mod = [...html.matchAll(/<script type="module"[^>]*>([\s\S]*?)<\/script>/g)].map(x => x[1]).join('\n')
  .replace(/^import .*$/m, '');
const noop = () => {};
const gravado = [];   // o que o app mandou gravar em tabelas (insert/update)
const chamadas = [];  // [nome, args] das funções do banco
const cadeia = () => new Proxy(function(){}, { get:(_, k) => k === 'then' ? (ok => ok({ data:[], error:null })) : (...args) => { if (k === 'insert' || k === 'update') gravado.push({ k, reg:args[0] }); return cadeia(); } });
const campos = {};
let ultimoToast = '';
const el = { append:noop, appendChild:noop, remove:noop, addEventListener:noop, dataset:{}, classList:{ add:noop, remove:noop, toggle:noop }, style:{} };
const sandbox = { console, setTimeout:noop, setInterval:noop, clearTimeout:noop, Date, Intl, Math, JSON, Promise, Object, Array, Number, String,
  matchMedia:() => ({ matches:false, addEventListener:noop }), localStorage:{ getItem:() => null, setItem:noop },
  document:{ getElementById:id => id === 'app' ? el : (id in campos ? campos[id] : { ...el, value:'' }),
    createElement:() => { const e = { ...el, remove:noop }; Object.defineProperty(e, 'textContent', { set:v => { ultimoToast = v; }, get:() => ultimoToast }); return e; },
    querySelector:() => null, querySelectorAll:() => [], addEventListener:noop, documentElement:el, body:el },
  createClient:() => ({ auth:{ onAuthStateChange:noop, getSession:async () => ({ data:{ session:null } }) }, from:() => cadeia(),
    rpc:async (nome, args) => { chamadas.push([nome, args]); return { data:[], error:null }; } }),
  confirm:() => true, alert:noop };
sandbox.window = sandbox; sandbox.addEventListener = noop;
vm.createContext(sandbox);
const pega = n => `${n}: typeof ${n} !== 'undefined' ? ${n} : null`;
vm.runInContext(mod + '\n;globalThis.__t = { acoes, S, hojeISO, addDias, linhaTarefa, hojeAluno, telaAgenda, telaAprovar, cadTarefas, formTarefa, possivelSemana, blocoAvulsa, '
  + ['porTarefa', 'ICONE_P', 'PERIODO'].map(pega).join(', ') + ' };', sandbox);
const T = sandbox.__t; const { acoes, S, hojeISO, addDias } = T;
const txt = s => s.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ');
const conta = (s, re) => (s.match(re) || []).length;
const ok = (c, m) => console.log((c ? 'OK   ' : 'FALHA') + ' ' + m);
const J = 'j', U = 'u', hoje = hojeISO(), ontem = addDias(hoje, -1);
const base = { decisao:null, valor:null, recurso_id:null, pode_recorrer:false, motivo:null, motivo_comentario:null, abre_em:null };
const linha = (tarefa, nome, emoji, pontos, periodo, extra) => ({ ...base, tarefa, nome, emoji, pontos, periodo, status:'a_fazer', pode_marcar:true, ...extra });
const ESC_M = linha(1, 'Escovar os dentes', '🪥', 5, 'manha', { status:'feito', decisao:'validado', valor:5, pode_recorrer:true });
const ESC_N = linha(1, 'Escovar os dentes', '🪥', 5, 'noite', { pode_marcar:false, abre_em:'18:00:00' });
const KIKA  = linha(2, 'Cuidar da Kika', '🐶', 20, 'dia', { pode_marcar:false, abre_em:'18:00:00' });
const MESA  = linha(3, 'Tirar a mesa', '🍽️', 20, 'tarde', { status:'feito' });
const prepara = (papel = 'aluno') => Object.assign(S, { perfil:{ papel }, user:{ id:papel === 'aluno' ? J : 'p' }, aluno:J,
  alunos:[{ user_id:J, nome:'Johann' }, { user_id:U, nome:'Juju' }], grupos:{ casa:{ teto_semana:490 }, estudos:{ config:{} } }, mats:[], todasMats:[],
  missao:null, lanc:[], notas:{}, prog:{}, tent:[], crono:[], rev:[], pend:[], recAb:[], resgPend:[], fam:{ provas:[], crono:{}, progCrono:{} },
  agenda:{}, pausas:[], tarefasCad:[], saldoT:0, saldosFam:{}, missoesFam:{},
  tarefas:{ [hoje]:[ESC_M, ESC_N, MESA, KIKA], [ontem]:[ linha(1, 'Escovar os dentes', '🪥', 5, 'manha', { status:'feito' }), linha(1, 'Escovar os dentes', '🪥', 5, 'noite') ] } });

// --- Task 3: lista da criança
prepara();
ok(typeof T.porTarefa === 'function', 'existe porTarefa');
const G = T.porTarefa ? T.porTarefa(S.tarefas[hoje]) : [];
ok(G.length === 3 && G[0].itens.length === 2 && G[0].itens.map(i => i.periodo).join() === 'manha,noite', 'porTarefa junta ESC (manha, noite) e mantém a ordem: ' + G.map(g => g.nome).join(', '));
ok(T.PERIODO?.dia === 'Dia todo' && T.ICONE_P?.tarde === '🌤️', 'PERIODO tem "Dia todo" e ICONE_P existe');
let ha = ''; try { ha = T.hojeAluno(); } catch (e) { ha = 'ERRO ' + e.message; }
const hoje1 = ha.split('Ainda dá para marcar')[0];
ok(conta(hoje1, /<b>🪥 Escovar os dentes/g) === 1, "Escovar aparece em uma linha só no Hoje (" + conta(hoje1, /<b>🪥 Escovar os dentes/g) + ")");
ok(!/<h3>(Manhã|Tarde|Noite|Durante o dia)<\/h3>/.test(ha) && ha.includes('Tarefas de casa'), 'sem títulos por período; um título "Tarefas de casa"');
ok(conta(hoje1, /data-p="(manha|tarde|noite|dia)"/g) >= 2, 'botões de período com data-p');
ok(/data-p="noite"[^>]*disabled|disabled[^>]*data-p="noite"/.test(hoje1) || /<button[^>]*disabled[^>]*>[^<]*🌙[^<]*Noite/.test(hoje1), 'ESC noite desabilitado');
ok(txt(hoje1).includes('às 18h'), 'cadeado mostra "às 18h"');
ok(!new RegExp(`data-a="tMarcar"[^>]*data-d="${hoje}"[^>]*data-p="noite"`).test(hoje1), 'ESC noite de hoje não tem ação de marcar');
ok(txt(ha).includes('2 de 4'), 'contagem por período: 2 de 4 (' + (txt(ha).match(/\d+ de \d+/) || [''])[0] + ')');
ok(txt(hoje1).includes('cada'), 'pontos "cada" em tarefa com mais de um período');
ok(/Não concordo/.test(hoje1) && /id="rc-1-[\d-]+-manha"/.test(hoje1), 'recurso do período validado (rc-1-dia-manha)');
const ont = ha.split('Ainda dá para marcar')[1] || '';
ok(ont.includes('data-p="noite"') && ont.includes(`data-d="${ontem}"`), 'ontem: período pendente (noite) aparece para marcar');
await acoes.tMarcar({ dataset:{ t:'1', d:hoje, s:'feito', p:'noite' } });
const mk = chamadas.find(c => c[0] === 'marcar_tarefa');
ok(mk && mk[1].p_periodo === 'noite' && mk[1].p_tarefa === 1, 'tMarcar manda p_periodo: ' + JSON.stringify(mk?.[1]));
campos['rc-1-' + hoje + '-manha'] = { value:'escovei sim' };
await acoes.tRecurso({ dataset:{ t:'1', d:hoje, p:'manha' } });
const rc = chamadas.find(c => c[0] === 'abrir_recurso');
ok(rc && rc[1].p_periodo === 'manha' && rc[1].p_comentario === 'escovei sim', 'tRecurso manda p_periodo e lê rc-<t>-<dia>-<periodo>: ' + JSON.stringify(rc?.[1]));
// tarefa de um período só: uma linha comum, sem "cada"
const l1 = T.linhaTarefa(MESA, hoje);
ok(!txt(l1).includes('cada') && conta(l1, /data-p="tarde"/g) === 1, 'tarefa de um período: um botão, sem "cada"');
