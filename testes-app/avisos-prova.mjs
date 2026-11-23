// Teste dos avisos da prova valendo: sem cronômetro na tela; faixa quando faltam 30, 15 e 5 minutos (uma vez cada),
// aviso único do que falta ao voltar com menos tempo, envio sozinho no fim da hora, e a regra do botão Liberar (treino 70%+ com 10 questões ou mais).
// Uso (na raiz): node testes-app/avisos-prova.mjs index.html
import fs from 'fs'; import vm from 'vm';
const html = fs.readFileSync(process.argv[2], 'utf8');
const mod = [...html.matchAll(/<script type="module"[^>]*>([\s\S]*?)<\/script>/g)].map(x => x[1]).join('\n')
  .replace(/^import .*$/m, '');
const noop = () => {};
const cadeia = () => new Proxy(function(){}, { get:(_, k) => k === 'then' ? (ok => ok({ data:[], error:null })) : () => cadeia() });
const intervalos = []; const faixas = []; let aberta = null; let rpcs = [];
const el = { append:noop, appendChild:noop, remove:noop, addEventListener:noop, dataset:{}, classList:{ add:noop, remove:noop, toggle:noop }, style:{} };
const body = { ...el, insertAdjacentHTML:(_, x) => { if (x.includes('aviso-prova')){ faixas.push(x); aberta = x; } } };
const sandbox = { console, setTimeout:noop, setInterval:f => intervalos.push(f), clearTimeout:noop, Date, Intl, Math, JSON, Promise, Object, Array, Number, String, Set, Map,
  matchMedia:() => ({ matches:false, addEventListener:noop }),
  localStorage:{ getItem:() => null, setItem:noop, removeItem:noop },
  document:{ getElementById:id => id === 'avprova' ? (aberta ? { remove:() => { aberta = null; } } : null) : { ...el, value:'' },
    createElement:() => ({ ...el }), querySelector:() => null, querySelectorAll:() => [], addEventListener:noop, documentElement:el, body, visibilityState:'visible' },
  createClient:() => ({ auth:{ onAuthStateChange:noop, getSession:async () => ({ data:{ session:null } }) }, from:() => cadeia(),
    rpc:async nome => { rpcs.push(nome); return { data:nome === 'corrigir_prova' ? { pct:80, acertos:8, total:10, detalhes:[] } : [], error:null }; } }),
  confirm:() => true, alert:noop };
sandbox.window = sandbox; sandbox.addEventListener = noop; sandbox.scrollTo = noop;
vm.createContext(sandbox);
vm.runInContext(mod + '\n;globalThis.__t = { S, telaProva:typeof telaProva === "function" ? telaProva : null, estadoProva, txtProva, cardLiberarProvas };', sandbox);
const T = sandbox.__t; const { S } = T;
const ok = (c, m) => console.log((c ? 'OK   ' : 'FALHA') + ' ' + m);
const tick = () => intervalos.forEach(f => f());
const prova = minRest => { S.prova = { materia:'mat', ate:new Date(Date.now() + minRest * 6e4).toISOString(), ini:'x', lista:[{ id:'q1', enunciado:'?', alternativas:['a', 'b'] }], resp:{} }; faixas.length = 0; aberta = null; };

// faixas na hora certa, uma vez cada
prova(45); tick(); ok(faixas.length === 0, 'com 45 minutos: nenhum aviso');
S.prova.ate = new Date(Date.now() + 30 * 6e4 - 500).toISOString(); tick();
ok(faixas.length === 1 && faixas[0].includes('Faltam 30 minutos'), 'ao passar de 30 minutos: "Faltam 30 minutos"');
tick(); tick(); ok(faixas.length === 1, 'não repete o aviso dos 30');
ok(aberta, 'a faixa fica aberta até tocar em OK');
S.prova.ate = new Date(Date.now() + 15 * 6e4 - 500).toISOString(); tick();
ok(faixas.length === 2 && faixas[1].includes('Faltam 15 minutos'), 'ao passar de 15 minutos: "Faltam 15 minutos"');
S.prova.ate = new Date(Date.now() + 5 * 6e4 - 500).toISOString(); tick();
ok(faixas.length === 3 && faixas[2].includes('Faltam 5 minutos') && faixas[2].includes('envie'), 'ao passar de 5 minutos: "Faltam 5 minutos", com lembrete de enviar');
tick(); ok(faixas.length === 3, 'depois dos 5, nada mais até o fim');

// voltar ao app com menos tempo: um aviso só, com o que falta
prova(20.5); tick(); ok(faixas.length === 1 && faixas[0].includes('Faltam 21 minutos'), 'voltou com 20,5 minutos: um aviso só, "Faltam 21 minutos"');
tick(); ok(faixas.length === 1, 'e não avisa de novo os 30');
prova(3); tick(); ok(faixas.length === 1 && faixas[0].includes('Faltam 3 minutos'), 'voltou com 3 minutos: um aviso só');
prova(0.5); tick(); ok(faixas[0].includes('Faltam 1 minuto!'), 'singular com 1 minuto');

// fim da hora: envia sozinha e fecha a faixa
prova(10); tick(); rpcs = [];
S.prova.ate = new Date(Date.now() - 1000).toISOString(); tick();
await new Promise(r => setImmediate(r));
ok(rpcs.includes('corrigir_prova'), 'no fim da hora a prova é enviada sozinha');
ok(!aberta, 'a faixa some quando a prova acaba');

// tela da prova sem relógio
prova(40);
const tela = mod.match(/return `<div class="card hero" style="position:sticky[\s\S]*?Enviar prova/)[0];
ok(!/relogio|6e4/.test(tela), 'tela da prova sem cronômetro');

// botão Liberar só com treino 70%+ (na janela); antes disso, "Falta treino"
const hoje = new Date().toLocaleDateString('en-CA', { timeZone:'America/Sao_Paulo' });
const amanha = new Date(Date.now() + 864e5).toLocaleDateString('en-CA', { timeZone:'America/Sao_Paulo' });
S.prova = null; S.perfil = { papel:'responsavel', user_id:'p' }; S.mats = [{ id:'ing', nome:'Inglês', emoji:'🇬🇧', prova:amanha }]; S.lib = {};
S.grupos = { estudos:{ config:{ treino_min:70 } } };
// (treino só vale com 10 questões ou mais)
for (const [pct, total, pode] of [[null, 10, false], [55, 10, false], [69.9, 10, false], [70, 10, true], [90, 10, true], [100, 9, false], [100, 5, false], [80, 12, true]]){
  S.tent = pct === null ? [] : [{ materia:'ing', tipo:'treino', pct, total, criado:new Date().toISOString() }];
  const e = T.estadoProva('ing'); const card = T.cardLiberarProvas();
  ok((e.st === 'pode') === pode && card.includes('data-a="liberar"') === pode && (pode || card.includes('Falta treino com 70%+')),
    `treino ${pct === null ? 'nenhum' : `${pct}% em ${total} questões`}: ${pode ? 'botão Liberar' : '"Falta treino com 70%+", sem botão'}`);
}
