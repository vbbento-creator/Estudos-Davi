// Teste das telas da tarefa avulsa: carrega o script do index.html com o banco simulado e desenha Agenda, Hoje e cadastro.
// Uso (na raiz): node testes-app/avulsa.mjs index.html saida-cadastro.html
import fs from 'fs'; import vm from 'vm';
const html = fs.readFileSync(process.argv[2], 'utf8');
const mod = [...html.matchAll(/<script type="module"[^>]*>([\s\S]*?)<\/script>/g)].map(x => x[1]).join('\n')
  .replace(/^import .*$/m, '');
const noop = () => {};
const gravado = [];   // o que o app mandou para tarefas (insert/update)
const cadeia = () => new Proxy(function(){}, { get:(_, k) => k === 'then' ? (ok => ok({ data:[], error:null })) : (...args) => { if (k === 'insert' || k === 'update') gravado.push({ k, reg:args[0] }); return cadeia(); } });
const campos = {};    // valores dos campos do formulário (id → value/checked)
const el = { append:noop, appendChild:noop, remove:noop, addEventListener:noop, dataset:{}, classList:{ add:noop, remove:noop, toggle:noop }, style:{} };
const sandbox = { console, setTimeout, setInterval:noop, clearTimeout, Date, Intl, Math, JSON, Promise, Object, Array, Number, String,
  matchMedia:() => ({ matches:false, addEventListener:noop }), localStorage:{ getItem:() => null, setItem:noop },
  document:{ getElementById:id => id === 'app' ? el : (id in campos ? campos[id] : { ...el }), createElement:() => ({ ...el, remove:noop }), querySelector:() => null, querySelectorAll:() => [], addEventListener:noop, documentElement:el, body:el },
  createClient:() => ({ auth:{ onAuthStateChange:noop, getSession:async () => ({ data:{ session:null } }) }, from:() => cadeia(), rpc:async () => ({ data:[] }) }),
  confirm:() => true, alert:noop };
sandbox.window = sandbox; sandbox.addEventListener = noop;
vm.createContext(sandbox);
vm.runInContext(mod + '\n;globalThis.__t = { acoes, S, telaAgenda, cadTarefas, linhaTarefa, possivelSemana, hojeISO, addDias };', sandbox);
const { acoes, S, telaAgenda, cadTarefas, linhaTarefa, possivelSemana, hojeISO, addDias } = sandbox.__t;
const J = 'j', U = 'u', hoje = hojeISO();
Object.assign(S, { perfil:{ papel:'responsavel' }, user:{ id:'p' }, alunos:[{ user_id:J, nome:'Johann' }, { user_id:U, nome:'Juju' }], agFiltro:'todos', agView:'semana',
  grupos:{ casa:{ teto_semana:490 } }, pausas:[{ inicio:addDias(hoje, 2), fim:addDias(hoje, 2), motivo:'viagem' }], fam:{ provas:[], crono:{}, progCrono:{} },
  tarefasCad:[
    { id:1, nome:'Lavar carro', emoji:'🚗', pontos:10, modo:'todos', alunos:[J, U], base:hoje, ate:hoje, ativa:true, dias_semana:null, periodo:null },
    { id:2, nome:'Arrumar quarto', emoji:'🧹', pontos:10, modo:'todos', alunos:[J], base:addDias(hoje, -30), ate:null, ativa:true, dias_semana:null, periodo:null },
    { id:3, nome:'Feira', emoji:'🥕', pontos:8, modo:'todos', alunos:[U], base:addDias(hoje, -5), ate:addDias(hoje, -5), ativa:true, dias_semana:null, periodo:null },
    { id:4, nome:'Regar', emoji:'🌱', pontos:4, modo:'todos', alunos:[J], base:hoje, ate:hoje, ativa:true, dias_semana:null, periodo:null } ],
  agenda:{ [J]:[ { dia:hoje, tarefa:1, nome:'Lavar carro', emoji:'🚗', pontos:10, status:'a_fazer' }, { dia:hoje, tarefa:2, nome:'Arrumar quarto', emoji:'🧹', pontos:10, status:'a_fazer' },
                 { dia:hoje, tarefa:4, nome:'Regar', emoji:'🌱', pontos:4, status:'feito' } ],
           [U]:[ { dia:hoje, tarefa:1, nome:'Lavar carro', emoji:'🚗', pontos:10, status:'a_fazer' } ] } });
const txt = s => s.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ');
const ok = (c, m) => console.log((c ? 'OK   ' : 'FALHA') + ' ' + m);
let a = telaAgenda();
ok(a.includes('data-a="avAbrir"'), 'hoje: botão + Tarefa avulsa');
ok((a.match(/data-a="avRemover" data-v="1"/g) || []).length === 2, 'Lavar carro (ninguém marcou): Remover nas 2 linhas');
ok(!a.includes('data-a="avRemover" data-v="4"'), 'Regar (marcada): sem Remover');
ok(!a.includes('data-a="avRemover" data-v="2"'), 'tarefa comum: sem Remover');
ok((txt(a).match(/avulsa/g) || []).length >= 3, 'etiqueta avulsa nas linhas das avulsas');
S.avulsaAberta = hoje; a = telaAgenda();
ok(a.includes('id="av-nome"') && a.includes('id="av-al-j" checked') && a.includes('id="av-al-u" checked'), 'formulário aberto, Todos: as duas crianças marcadas');
S.agFiltro = U; a = telaAgenda();
ok(a.includes('id="av-al-u" checked') && !a.includes('id="av-al-j" checked'), 'filtro Juju: só Juju marcada');
S.agFiltro = 'todos'; S.agSel = addDias(hoje, 2); a = telaAgenda();
ok(!a.includes('avAbrir'), 'dia pausado: sem botão');
S.agSel = addDias(hoje, -8); a = telaAgenda(); ok(!a.includes('avAbrir'), '8 dias atrás: sem botão');
S.agSel = addDias(hoje, 27); a = telaAgenda(); ok(a.includes('avAbrir'), '+27: com botão');
S.agSel = addDias(hoje, 28); a = telaAgenda(); ok(!a.includes('avAbrir'), '+28: sem botão');
S.agSel = hoje; S.trocaAberta = `1|${hoje}|${U}`; S.agenda[U] = []; a = telaAgenda();
S.agenda[U] = [ { dia:hoje, tarefa:1, nome:'Lavar carro', emoji:'🚗', pontos:10, status:'a_fazer' } ];
S.trocaAberta = `4|${hoje}|${J}`; S.agenda[J].find(x => x.tarefa === 4).status = 'a_fazer'; a = telaAgenda();
ok(a.includes('Só este dia') && !a.includes('Deste dia em diante'), 'Trocar na avulsa: só "Só este dia"');
S.trocaAberta = `2|${hoje}|${J}`; a = telaAgenda(); ok(a.includes('Deste dia em diante'), 'Trocar na comum: tem "Deste dia em diante"');
S.perfil = { papel:'aluno' }; S.aluno = J;
const l = linhaTarefa({ tarefa:1, nome:'Lavar carro', emoji:'🚗', pontos:10, status:'a_fazer', pode_marcar:true }, hoje);
ok(txt(l).includes('avulsa'), 'criança: etiqueta avulsa no Hoje');
S.perfil = { papel:'responsavel' };
const c = cadTarefas(); fs.writeFileSync(process.argv[3], c);
const fmt = iso => iso.slice(8) + '/' + iso.slice(5, 7);
ok(txt(c).includes('avulsa · ' + fmt(hoje)), 'cadastro: etiqueta "avulsa · dd/mm"');
const enc = c.split('<details')[1] || '';
ok(c.includes('Encerradas (1)') && enc.includes('Feira') && !enc.includes('Lavar carro'), 'cadastro: Feira (passou) em Encerradas (1)');
const f1 = c.split('id="t1-nome"')[1].split('id="t2-nome"')[0] || '';
ok(!c.includes('id="t1-modo"') && !c.includes('id="t1-ds-0"') && c.includes('id="t1-base"'), 'cadastro: avulsa sem modo e dias da semana, com Dia');
ok(c.includes('id="t2-modo"') && c.includes('id="t2-ds-0"'), 'cadastro: comum continua com modo e dias');
ok(possivelSemana(J) === 70, `possível por semana ignora avulsas (70): ${possivelSemana(J)}`);
// salvar a avulsa pelo cadastro: grava base = ate = dia escolhido, sem mexer em modo e dias
const nd = addDias(hoje, 1);
Object.assign(campos, { 't1-nome':{ value:'Lavar carro' }, 't1-emoji':{ value:'🚗' }, 't1-pontos':{ value:'12' }, 't1-periodo':{ value:'' }, 't1-base':{ value:nd },
  't1-al-j':{ checked:true }, 't1-al-u':{ checked:true } });
await acoes.cTarefaSalvar({ dataset:{ v:'1' } });
const g = gravado.find(x => x.k === 'update')?.reg || {};
ok(g.base === nd && g.ate === nd && !('modo' in g) && !('dias_semana' in g) && g.pontos === 12, 'salvar avulsa: base = ate = ' + nd + ' ' + JSON.stringify(g));
