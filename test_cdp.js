const { spawn } = require('child_process');
const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');

const CHROME_PATH = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const PORT = 9222;
const RESULTS_DIR = path.join(__dirname, 'test_results');
if (!fs.existsSync(RESULTS_DIR)) fs.mkdirSync(RESULTS_DIR, { recursive: true });

async function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

async function getJson(url) {
  return new Promise((resolve, reject) => {
    http.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try { resolve(JSON.parse(data)); } catch (e) { reject(e); }
      });
    }).on('error', reject);
  });
}

async function main() {
  console.log('Iniciando Chrome headless com CDP...');
  const tmpProfile = path.join(os.tmpdir(), 'cdp_prof_' + Date.now());
  const chrome = spawn(CHROME_PATH, [
    `--remote-debugging-port=${PORT}`,
    `--user-data-dir=${tmpProfile}`,
    '--headless=new',
    '--no-sandbox',
    '--disable-gpu',
    '--disable-extensions',
    '--window-size=1440,900',
    'http://localhost:8080/index.html'
  ]);

  let cdpUrl = null;
  for (let i = 0; i < 30; i++) {
    await sleep(300);
    try {
      const list = await getJson(`http://127.0.0.1:${PORT}/json/list`);
      const target = (list && list.length) ? (list.find(t => t.url && t.url.includes('localhost:8080')) || list[0]) : null;
      if (target && target.webSocketDebuggerUrl) {
        cdpUrl = target.webSocketDebuggerUrl;
        break;
      }
    } catch (e) {}
  }

  if (!cdpUrl) {
    console.error('Falha ao conectar no Chrome CDP');
    chrome.kill();
    process.exit(1);
  }

  console.log('Conectado ao Chrome CDP:', cdpUrl);
  const ws = new WebSocket(cdpUrl);

  let id = 1;
  const callbacks = new Map();
  function send(method, params = {}) {
    return new Promise((resolve, reject) => {
      const msgId = id++;
      callbacks.set(msgId, { resolve, reject });
      ws.send(JSON.stringify({ id: msgId, method, params }));
    });
  }

  await new Promise(r => ws.onopen = r);

  ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    if (data.id && callbacks.has(data.id)) {
      const cb = callbacks.get(data.id);
      callbacks.delete(data.id);
      if (data.error) cb.reject(data.error);
      else cb.resolve(data.result);
    } else if (data.method === 'Runtime.consoleAPICalled') {
      console.log('[Console Browser]:', data.params.type, data.params.args.map(a => a.value || a.description).join(' '));
    } else if (data.method === 'Runtime.exceptionThrown') {
      console.error('[Browser Exception]:', data.params.exceptionDetails.text, data.params.exceptionDetails.exception?.description);
    }
  };

  await send('Page.enable');
  await send('Runtime.enable');

  console.log('Aguardando página e renderização...');
  for (let i = 0; i < 30; i++) {
    await sleep(300);
    try {
      const ok = await evalJs('document.readyState === "complete" && !!document.querySelector(".titlerow")');
      if (ok) {
        console.log('Página carregada e renderizada com sucesso.');
        break;
      }
    } catch (e) {}
  }
  await sleep(1000);

  // Helper para avaliar JS no navegador
  async function evalJs(expr) {
    const res = await send('Runtime.evaluate', { expression: expr, returnByValue: true, awaitPromise: true });
    return res.result.value;
  }

  // Helper para captura de tela
  async function screenshot(name, width, height) {
    try {
      await send('Emulation.setDeviceMetricsOverride', {
        width,
        height,
        deviceScaleFactor: 1,
        mobile: width < 600
      });
      await sleep(500);
      const res = await send('Page.captureScreenshot', { format: 'png' });
      const buf = Buffer.from(res.data, 'base64');
      const outPath = path.join(RESULTS_DIR, name);
      fs.writeFileSync(outPath, buf);
      console.log(`Screenshot salva: ${name} (${width}x${height})`);
    } catch (err) {
      console.error(`Erro ao capturar ${name}:`, err);
    }
  }

  // 1. Estado inicial e logo
  const title = await evalJs('document.title');
  const hasLogoSidebar = await evalJs('!!document.querySelector(".brand-logo-img")');
  const hasLogoMbar = await evalJs('!!document.querySelector(".mbar-logo-img")');
  console.log('Título:', title);
  console.log('Logo na sidebar:', hasLogoSidebar);
  console.log('Logo na barra mobile:', hasLogoMbar);

  // Captura inicial 1440px
  await screenshot('01_visao_geral_1440px.png', 1440, 900);

  // 2. Teste de Concluir Etapa
  console.log('\n--- TESTE 1: Concluir uma etapa ---');
  // Localiza a primeira escola e abre a ficha dela
  await evalJs(`
    const primeiroLinkEscola = document.querySelector("#nav-esc a");
    if (primeiroLinkEscola) primeiroLinkEscola.click();
  `);
  await sleep(800);

  const viewEscolaName = await evalJs('document.querySelector(".titlerow h1")?.textContent');
  console.log('Ficha aberta:', viewEscolaName);

  // Clica no botão Done da primeira etapa
  const stepBefore = await evalJs('document.querySelector(".steps > li input[type=number]")?.value');
  console.log('Percentual antes da conclusão:', stepBefore);

  await evalJs(`
    const btnDone = document.querySelector(".steps > li .done");
    if (btnDone) btnDone.click();
  `);
  await sleep(600);

  const stepAfter = await evalJs('document.querySelector(".steps > li input[type=number]")?.value');
  const isDoneClass = await evalJs('document.querySelector(".steps > li")?.classList.contains("is-done")');
  console.log('Percentual após clicar em concluir:', stepAfter);
  console.log('Classe is-done aplicada:', isDoneClass);

  await screenshot('02_escola_etapa_concluida_1440px.png', 1440, 900);

  // 3. Teste de Marcar Etapa Paralisada com Justificativa Obrigatória
  console.log('\n--- TESTE 2: Marcar etapa como paralisada com justificativa ---');
  // Clica no botão Paralisar da segunda etapa
  await evalJs(`
    const btnPause = document.querySelectorAll(".steps > li .btn-pause")[1];
    if (btnPause) btnPause.click();
  `);
  await sleep(500);

  const modalOpen = await evalJs('document.querySelector("#dlg-pause")?.open');
  console.log('Modal de paralisação aberto:', modalOpen);

  // Tenta submeter vazio para checar validação obrigatória
  await evalJs(`
    document.querySelector("#pause-justificativa").value = "";
    document.querySelector("#pause-go").click();
  `);
  await sleep(300);
  const errShown = await evalJs('!document.querySelector("#err-pause")?.hidden');
  console.log('Erro de justificativa obrigatória exibido quando vazio:', errShown);

  // Preenche a justificativa obrigatória e submete
  await evalJs(`
    document.querySelector("#pause-justificativa").value = "Aguardando entrega de perfis metálicos pelo fornecedor devido a atraso no transporte fluvial.";
    document.querySelector("#pause-go").click();
  `);
  await sleep(800);

  const isParalisada = await evalJs(`
    const li = document.querySelectorAll(".steps > li")[1];
    li.classList.contains("is-paralisada")
  `);
  console.log('Etapa assinalada como paralisada:', isParalisada);

  await screenshot('03_escola_etapa_paralisada_1440px.png', 1440, 900);

  // 4. Teste de visualização do destaque no topo da Visão Geral
  console.log('\n--- TESTE 3: Destaque "Paralisadas — solução urgente" no topo ---');
  await evalJs('location.hash = "#/";');
  await sleep(800);

  const urgentBlockExists = await evalJs('!!document.querySelector(".panel-urgent")');
  const urgentTitle = await evalJs('document.querySelector("#h-paralisadas")?.textContent');
  const urgentCount = await evalJs('document.querySelector(".panel-urgent .pill.neg")?.textContent');
  const urgentEtapa = await evalJs('document.querySelector(".urgent-card-nm")?.textContent');
  const urgentJust = await evalJs('document.querySelector(".urgent-card-just")?.textContent');

  console.log('Bloco urgente presente:', urgentBlockExists);
  console.log('Título do bloco:', urgentTitle);
  console.log('Contagem:', urgentCount);
  console.log('Nome da etapa em destaque:', urgentEtapa);
  console.log('Justificativa exibida:', urgentJust);

  // 5. Capturas nas três larguras requeridas: 1440px, 768px, 390px
  console.log('\n--- TESTE 4: Teste responsivo nas 3 larguras (1440, 768 e 390px) ---');
  await screenshot('04_destaque_paralisadas_1440px.png', 1440, 900);
  await screenshot('05_destaque_paralisadas_768px.png', 768, 1024);
  await screenshot('06_destaque_paralisadas_390px.png', 390, 844);

  // Também testa cronograma com o novo prazo de 20/12/2026
  await evalJs('location.hash = "#/cronograma";');
  await sleep(800);
  const cronoText = await evalJs('document.querySelector(".titlerow .lead")?.textContent');
  const prazoLineText = await evalJs('document.querySelector(".g-prazo span")?.textContent');
  console.log('\nTexto do cronograma:', cronoText);
  console.log('Linha de prazo no Gantt:', prazoLineText);
  await screenshot('07_cronograma_20-12-2026_1440px.png', 1440, 900);

  ws.close();
  chrome.kill();
  console.log('\nTestes automatizados concluídos com sucesso!');
}

main().catch(err => {
  console.error('Erro na execução dos testes:', err);
  process.exit(1);
});
