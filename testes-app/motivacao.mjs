// Teste das mensagens de motivação: faixas de nota, frases por criança, uma vez por dia, tarefas do dia, treino e prova.
// Uso (na raiz): node testes-app/motivacao.mjs index.html
import fs from 'fs'; import vm from 'vm';
const html = fs.readFileSync(process.argv[2], 'utf8');
const mod = [...html.matchAll(/<script type="module"[^>]*>([\s\S]*?)<\/script>/g)].map(x => x[1]).join('\n')
  .replace(/^import .*$/m, '');
const noop = () => {};
const cadeia = () => new Proxy(function(){}, { get:(_, k) => k === 'then' ? (ok => ok({ data:[], error:null })) : () => cadeia() });
const respRpc = {};   // nome da função do banco → data devolvida
const guardado = new Map();
const el = { append:noop, appendChild:noop, remove:noop, addEventListener:noop, dataset:{}, classList:{ add:noop, remove:noop, toggle:noop }, style:{} };
const sandbox = { console, setTimeout:noop, setInterval:noop, clearTimeout:noop, Date, Intl, Math, JSON, Promise, Object, Array, Number, String, Set, Map,
  matchMedia:() => ({ matches:false, addEventListener:noop }),
  localStorage:{ getItem:k => guardado.get(k) ?? null, setItem:(k, v) => guardado.set(k, String(v)) },
  document:{ getElementById:() => ({ ...el, value:'' }), createElement:() => ({ ...el }), querySelector:() => null, querySelectorAll:() => [], addEventListener:noop, documentElement:el, body:el, visibilityState:'visible' },
  createClient:() => ({ auth:{ onAuthStateChange:noop, getSession:async () => ({ data:{ session:null } }) }, from:() => cadeia(),
    rpc:async nome => ({ data:respRpc[nome] ?? [], error:null }) }),
  confirm:() => true, alert:noop };
sandbox.window = sandbox; sandbox.addEventListener = noop; sandbox.scrollTo = noop;
vm.createContext(sandbox);
vm.runInContext(mod + '\n;globalThis.__t = { acoes, S, hojeISO, render, faixaNota, mensagemMotiv, MOTIV, umaVezHoje, motivarDia, tarefasHojeFeitas, motivHtml };', sandbox);
const T = sandbox.__t; const { acoes, S, hojeISO } = T;
const ok = (c, m) => console.log((c ? 'OK   ' : 'FALHA') + ' ' + m);
const JOHANN = 'd5c2215c-797c-435b-859b-09be1fe3efbf', JUJU = '014341f0-99f3-4e14-b21d-6b4efc9bafbd';

// faixas: até 69 · 70 a 90 · acima de 90
for (const [p, f] of [[0, 'baixa'], [50, 'baixa'], [69, 'baixa'], [69.9, 'baixa'], [70, 'boa'], [83.3, 'boa'], [90, 'boa'], [90.5, 'otima'], [91.7, 'otima'], [100, 'otima'], ['100', 'otima']])
  ok(T.faixaNota(p) === f, `nota ${p}% → ${f}`);

// frases: Juju usa a lista "menor", Johann a "maior"; {x} e {nome} trocados
const tipos = ['dia', 'baixa', 'boa', 'otima', 'tarefas'];
ok(tipos.every(t => T.MOTIV[t].maior.length >= 20 && T.MOTIV[t].menor.length >= 20), 'cada situação tem pelo menos 20 frases para cada criança');
ok(tipos.every(t => T.MOTIV[t].maior.every(f => !T.MOTIV[t].menor.includes(f))), 'listas da Juju e do Johann são diferentes');
const mj = T.mensagemMotiv('otima', JUJU, 'Juju', 'prova', 0);
ok(T.MOTIV.otima.menor.includes(mj.texto), 'Juju recebe frase da lista dela');
const mo = T.mensagemMotiv('otima', JOHANN, 'Johann', 'prova', 0);
ok(mo.texto === 'Mais de 90% nesta prova! Você dominou esse conteúdo.', 'Johann recebe frase da lista dele, com {x} trocado por "nesta prova"');
ok(T.mensagemMotiv('dia', JOHANN, 'Johann', null, 0).titulo === 'Bom dia, Johann!', 'título do dia leva o nome');
ok(T.mensagemMotiv('boa', JOHANN, 'Johann', 'treino', 0.9999).texto === T.MOTIV.boa.maior.at(-1).replaceAll('{x}', 'neste treino'), 'sorteio perto de 1 pega a última frase');
ok(tipos.every(t => [...T.MOTIV[t].maior, ...T.MOTIV[t].menor].every(f => !/\{(?!x\})/.test(f))), 'nenhuma frase com marcador desconhecido');

// tarefas do dia
const f = (status, decisao = null) => ({ status, decisao });
ok(!T.tarefasHojeFeitas([]), 'sem tarefa hoje: não conta como completo');
ok(T.tarefasHojeFeitas([f('feito'), f('feito', 'validado'), f('feito', 'metade')]), 'todas marcadas (aguardando, validada, metade): completo');
ok(!T.tarefasHojeFeitas([f('feito'), f('a_fazer')]), 'uma a fazer: incompleto');
ok(!T.tarefasHojeFeitas([f('feito'), f('feito', 'rejeitado')]), 'uma rejeitada: incompleto');

// primeiro acesso do dia: uma vez por aparelho e criança
Object.assign(S, { user:{ id:JOHANN }, perfil:{ papel:'aluno', nome:'Johann', user_id:JOHANN }, aluno:JOHANN, alunos:[{ user_id:JOHANN, nome:'Johann' }] });
ok(T.motivarDia() && S.motiv?.titulo === 'Bom dia, Johann!', 'primeiro acesso do dia mostra a mensagem');
ok(T.motivHtml().includes('data-a="fecharMotiv"') && T.motivHtml().includes('Bom dia, Johann!'), 'cartão com botão Valeu!');
acoes.fecharMotiv(); ok(S.motiv === null, 'Valeu! fecha o cartão');
ok(!T.motivarDia() && S.motiv === null, 'segundo acesso no mesmo dia: nada');
guardado.set(`motiv-dia:${JOHANN}`, '2000-01-01');
ok(T.motivarDia(), 'dia seguinte: aparece de novo');
S.motiv = null;
S.aluno = JUJU; S.perfil = { papel:'aluno', nome:'Juju', user_id:JUJU };
ok(T.motivarDia() && T.MOTIV.dia.menor.includes(S.motiv.texto), 'outra criança no mesmo aparelho tem o seu primeiro acesso');
S.motiv = null;
S.perfil = { papel:'responsavel', nome:'Pai' }; S.aluno = JOHANN; guardado.clear();
ok(!T.motivarDia() && S.motiv === null, 'pai ou mãe não veem mensagem');

// tarefas: aparece ao marcar a última de hoje, uma vez por dia
S.perfil = { papel:'aluno', nome:'Johann', user_id:JOHANN }; S.aluno = JOHANN; S.tarefasCad = []; S.motiv = null;
const hoje = hojeISO();
S.tarefas = { [hoje]:[f('feito'), f('a_fazer')] };
respRpc.tarefas_do_dia = [f('feito'), f('a_fazer')];
await acoes.tMarcar({ dataset:{ t:'1', d:hoje, p:'manha' } });
ok(S.motiv === null, 'marcou uma, ainda falta outra: sem mensagem');
respRpc.tarefas_do_dia = [f('feito'), f('feito')];
await acoes.tMarcar({ dataset:{ t:'2', d:hoje, p:'noite' } });
ok(S.motiv?.titulo === 'Tarefas do dia feitas!', 'marcou a última de hoje: mensagem das tarefas');
S.motiv = null;
S.tarefas = { [hoje]:[f('feito'), f('a_fazer')] };
await acoes.tMarcar({ dataset:{ t:'2', d:hoje, p:'noite' } });
ok(S.motiv === null, 'desmarcou e marcou de novo no mesmo dia: não repete');
guardado.clear(); S.tarefas = { [hoje]:[f('feito'), f('a_fazer')] };
await acoes.tMarcar({ dataset:{ t:'2', d:'2000-01-01', p:'noite' } });
ok(S.motiv === null, 'marcar tarefa de ontem não dispara a mensagem de hoje');

// treino e prova
S.mats = [{ id:'fisica', emoji:'🌌', nome:'Física' }];
const quiz = (acertos, total, modo) => { S.quiz = { materia:'fisica', lista:Array.from({ length:total }, (_, i) => ({ id:'q' + i, enunciado:'?', alternativas:['a', 'b', 'c', 'd'], correta:0 })), i:total - 1, acertos, resp:0, det:[], modo }; S.tent = []; S.motiv = null; };
for (const [a, t, tit] of [[0, 10, 'Valeu o esforço!'], [6, 10, 'Valeu o esforço!'], [7, 10, 'Mandou bem!'], [9, 10, 'Mandou bem!'], [10, 11, 'Incrível!'], [11, 12, 'Incrível!'], [10, 10, 'Incrível!']]){
  quiz(a, t); await acoes.proxima();
  ok(S.motiv?.titulo === tit, `treino ${a} de ${t} (${Math.round(1000 * a / t) / 10}%) → ${tit}`);
}
quiz(10, 10, 'revisao'); await acoes.proxima();
ok(S.motiv === null, 'rodada de "Concluir treino" não mostra mensagem');
quiz(5, 10); S.quiz.i = 3; await acoes.proxima();
ok(S.motiv === null, 'no meio do treino: nada');
for (const [pct, tit] of [[40, 'Valeu o esforço!'], [75, 'Mandou bem!'], [92, 'Incrível!']]){
  S.motiv = null; S.prova = { materia:'fisica', lista:[{ id:'a' }], resp:{ a:0 }, auto:true };
  respRpc.corrigir_prova = { acertos:1, total:1, pct, detalhes:[] };
  await acoes.enviarProva();
  ok(S.motiv?.titulo === tit && S.motiv.texto.length > 0, `prova ${pct}% → ${tit}`);
}
ok(!/\{x\}/.test(S.motiv.texto), 'prova: frase sem {x}');
ok(T.mensagemMotiv('boa', JOHANN, 'Johann', 'treino', 0).texto === 'Bom resultado neste treino! Mais um pouco e chega no topo.', 'treino: {x} vira "neste treino"');
ok(tipos.every(t => [...T.MOTIV[t].maior, ...T.MOTIV[t].menor].every(f => !/\b(no|na) \{x\}/.test(f))), 'nenhuma frase com "no {x}" ou "na {x}" (concordância)');
ok(tipos.every(t => new Set([...T.MOTIV[t].maior, ...T.MOTIV[t].menor]).size === T.MOTIV[t].maior.length + T.MOTIV[t].menor.length), 'nenhuma frase repetida dentro da mesma situação');
S.prova = null; quiz(10, 10); S.quiz.i = 10; S.motiv = T.mensagemMotiv('otima', JOHANN, 'Johann', 'treino', 0); S.aba = 'materias';
try { T.render(); ok(true, 'render com o cartão aberto não quebra'); } catch (e) { ok(false, 'render quebrou: ' + e.message); }
