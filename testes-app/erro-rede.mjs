// Teste da mensagem de erro: falha de rede vira texto em português; erro do banco continua como veio.
// Uso (na raiz): node testes-app/erro-rede.mjs index.html
import fs from 'fs'; import vm from 'vm';
const html = fs.readFileSync(process.argv[2], 'utf8');
const linhas = html.split('\n').filter(l => /^const (FALHA_REDE|msgErro) =/.test(l)).join('\n');
const sb = {}; vm.createContext(sb); vm.runInContext(linhas + '\n;globalThis.msgErro = msgErro;', sb);
const ok = (c, m) => console.log((c ? 'OK   ' : 'FALHA') + ' ' + m);
const REDE = 'Sem conexão com o servidor. Tente de novo.';
ok(sb.msgErro({ message:'TypeError: Failed to fetch' }) === REDE, 'Chrome: TypeError: Failed to fetch');
ok(sb.msgErro({ message:'Failed to fetch' }) === REDE, 'Chrome: Failed to fetch');
ok(sb.msgErro({ message:'NetworkError when attempting to fetch resource.' }) === REDE, 'Firefox: NetworkError');
ok(sb.msgErro({ message:'Load failed' }) === REDE, 'Safari: Load failed');
ok(sb.msgErro({ message:'Essa criança já faz essa tarefa neste dia' }) === 'Essa criança já faz essa tarefa neste dia', 'erro do banco fica igual');
ok(sb.msgErro({ message:'P0001: Só pai ou mãe' }) === 'Só pai ou mãe', 'prefixo "código: " continua sendo tirado');
