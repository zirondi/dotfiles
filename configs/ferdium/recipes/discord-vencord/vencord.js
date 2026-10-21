// Loads Vencord into the Discord page.
//
// Vencord must run before Discord's webpack runtime starts, and a recipe's
// webview.js only runs after a round trip with the Ferdium host, which is too
// late. So webview.js registers preload.js on the service's session (through
// @electron/remote, which Ferdium enables on service webviews) and reloads
// once; from then on preload.js injects Vencord at document start, the same
// way Vencord's desktop build does. Session preloads live in memory, so this
// costs one reload per Ferdium launch.
//
// The Vencord build is the userscript one (Vencord.user.js): it carries its
// own CSS and expects the userscript manager's `unsafeWindow` and
// `GM_xmlhttpRequest`, which are provided below. It is cached outside the
// dotfiles checkout and refreshed from GitHub at most once a day; a new
// download takes effect on the next reload, so a failed download never
// leaves Discord without the cached copy.

const fs = require('fs');
const http = require('http');
const https = require('https');
const os = require('os');
const path = require('path');
const Module = require('module');
const { webFrame } = require('electron');

const SOURCE_URL =
  'https://github.com/Vendicated/Vencord/releases/download/devbuild/Vencord.user.js';
const MAX_AGE_MS = 24 * 60 * 60 * 1000;
const TIMEOUT_MS = 30_000;
const TAG = '[discord-vencord]';
const REQUEST = 'discord-vencord:request';
const RESPONSE = 'discord-vencord:response';
const PRELOAD_ID = 'discord-vencord';
const PRELOAD_FILE = path.join(__dirname, 'preload.js');

// Ferdium's userData folder (Electron's appData + app name).
const userDataDir = () =>
  process.platform === 'darwin'
    ? path.join(os.homedir(), 'Library', 'Application Support', 'Ferdium')
    : path.join(
        process.env.XDG_CONFIG_HOME || path.join(os.homedir(), '.config'),
        'Ferdium',
      );

const cacheFile = path.join(userDataDir(), 'vencord-cache', 'Vencord.user.js');

// Plain Node HTTP client: not bound by Discord's CSP, unlike the page's fetch.
const request = (url, { method = 'GET', headers = {}, body } = {}, hops = 5) =>
  new Promise((resolve, reject) => {
    const target = new URL(url);
    const client = target.protocol === 'http:' ? http : https;
    const cleanHeaders = { ...headers };
    // Node does not decompress; ask for an identity body.
    for (const key of Object.keys(cleanHeaders)) {
      if (key.toLowerCase() === 'accept-encoding') delete cleanHeaders[key];
    }

    const req = client.request(
      target,
      { method, headers: cleanHeaders, timeout: TIMEOUT_MS },
      res => {
        const { statusCode, headers: resHeaders } = res;
        if (statusCode >= 300 && statusCode < 400 && resHeaders.location) {
          res.resume();
          if (hops === 0) return reject(new Error('too many redirects'));
          const next = new URL(resHeaders.location, target).toString();
          const keepBody = statusCode === 307 || statusCode === 308;
          return resolve(
            request(
              next,
              keepBody ? { method, headers, body } : { headers },
              hops - 1,
            ),
          );
        }
        const chunks = [];
        res.on('data', chunk => chunks.push(chunk));
        res.on('end', () =>
          resolve({
            url: target.toString(),
            status: statusCode,
            statusText: res.statusMessage,
            headers: resHeaders,
            body: Buffer.concat(chunks),
          }),
        );
        res.on('error', reject);
      },
    );
    req.on('timeout', () => req.destroy(new Error('timeout')));
    req.on('error', reject);
    if (body !== undefined && body !== null) req.write(body);
    req.end();
  });

const isFresh = () => {
  try {
    return Date.now() - fs.statSync(cacheFile).mtimeMs < MAX_AGE_MS;
  } catch {
    return false;
  }
};

// Downloads a new build when the cache is missing or stale. Returns true when
// the cache changed.
const refreshCache = async () => {
  if (isFresh()) return false;
  const res = await request(SOURCE_URL);
  const code = res.body.toString('utf8');
  if (res.status !== 200 || !code.includes('Vencord') || code.length < 100_000) {
    throw new Error(`unexpected download (HTTP ${res.status}, ${code.length} bytes)`);
  }
  fs.mkdirSync(path.dirname(cacheFile), { recursive: true });
  // Write then rename, so a second Discord service never reads half a file.
  const tmp = `${cacheFile}.${process.pid}.tmp`;
  fs.writeFileSync(tmp, code);
  fs.renameSync(tmp, cacheFile);
  return true;
};

// Serves GM_xmlhttpRequest for the page. Vencord routes every fetch of its
// own through it (the userscript build replaces `fetch`), so this is what
// lets it reach hosts that Discord's CSP leaves out.
const serveRequests = () => {
  window.addEventListener('message', async event => {
    const msg = event.data;
    if (msg?.type !== REQUEST || event.origin !== window.location.origin) return;

    const reply = data =>
      window.postMessage({ type: RESPONSE, id: msg.id, ...data }, window.location.origin);

    try {
      if (new URL(msg.url).protocol !== 'https:') {
        throw new Error(`only https is allowed: ${msg.url}`);
      }
      let { body } = msg;
      if (body instanceof Blob) body = Buffer.from(await body.arrayBuffer());
      else if (body instanceof ArrayBuffer) body = Buffer.from(body);

      const res = await request(msg.url, {
        method: msg.method || 'GET',
        headers: msg.headers || {},
        body,
      });
      const headerText = Object.entries(res.headers)
        .map(([key, value]) => `${key}: ${[value].flat().join(', ')}`)
        .join('\r\n');
      const buf = res.body;
      reply({
        ok: true,
        status: res.status,
        statusText: res.statusText,
        finalUrl: res.url,
        responseHeaders: headerText,
        contentType: res.headers['content-type'] || '',
        body: buf.buffer.slice(buf.byteOffset, buf.byteOffset + buf.byteLength),
      });
    } catch (error) {
      reply({ ok: false, timeout: error.message === 'timeout', error: String(error) });
    }
  });
};

// The script run in Discord's own JS world. Vencord must run before Discord's
// webpack runtime starts, so it refuses to load once the chunk array exists.
const pageScript = code => `(() => {
  if (window.Vencord) return 'already-loaded';
  if (window.webpackChunkdiscord_app) return 'too-late';

  const unsafeWindow = window;
  const pending = new Map();
  let nextId = 0;

  window.addEventListener('message', event => {
    const msg = event.data;
    if (event.source !== window || msg?.type !== '${RESPONSE}') return;
    const options = pending.get(msg.id);
    if (!options) return;
    pending.delete(msg.id);
    if (!msg.ok) {
      (msg.timeout ? options.ontimeout : options.onerror)?.(msg.error);
      return;
    }
    options.onload?.({
      status: msg.status,
      statusText: msg.statusText,
      finalUrl: msg.finalUrl,
      responseHeaders: msg.responseHeaders,
      response: new Blob([msg.body], { type: msg.contentType }),
    });
  });

  const GM_xmlhttpRequest = options => {
    const id = ++nextId;
    pending.set(id, options);
    window.postMessage(
      {
        type: '${REQUEST}',
        id,
        url: options.url,
        method: options.method,
        headers: options.headers,
        body: options.data,
      },
      window.location.origin,
    );
  };

${code}

  return 'loaded';
})()`;

// @electron/remote lives in Ferdium's app bundle, not next to this recipe.
const remote = () => {
  try {
    return require('@electron/remote');
  } catch {
    const appRequire = Module.createRequire(
      path.join(process.resourcesPath, 'app.asar', 'package.json'),
    );
    return appRequire('@electron/remote');
  }
};

// Registers preload.js on this service's session. Returns true when it was
// not registered yet, meaning the current page loaded without it.
const registerPreload = () => {
  const { session } = remote().getCurrentWebContents();
  if (typeof session.registerPreloadScript === 'function') {
    const present = session
      .getPreloadScripts()
      .some(script => script.id === PRELOAD_ID);
    if (present) return false;
    session.registerPreloadScript({
      id: PRELOAD_ID,
      type: 'frame',
      filePath: PRELOAD_FILE,
    });
    return true;
  }
  // Electron before 35.
  const preloads = session.getPreloads();
  if (preloads.includes(PRELOAD_FILE)) return false;
  session.setPreloads([...preloads, PRELOAD_FILE]);
  return true;
};

// Called by preload.js at document start.
const inject = async () => {
  serveRequests();

  let cached;
  try {
    cached = fs.readFileSync(cacheFile, 'utf8');
  } catch {
    console.info(TAG, 'no Vencord build cached yet');
    return;
  }

  try {
    const status = await webFrame.executeJavaScript(pageScript(cached));
    (status === 'too-late' ? console.warn : console.info)(TAG, status);
  } catch (error) {
    console.error(TAG, 'injection failed', error);
  }
};

// Called by webview.js once the recipe loads.
const setup = async () => {
  try {
    if (registerPreload()) {
      console.info(TAG, 'preload registered on the session; reloading');
      window.location.reload();
      return;
    }
  } catch (error) {
    console.error(TAG, 'could not register the preload; Vencord stays off', error);
    return;
  }

  const hadCache = fs.existsSync(cacheFile);
  try {
    if (await refreshCache()) {
      if (hadCache) {
        console.info(TAG, 'new Vencord build cached; it loads on the next reload');
      } else {
        console.info(TAG, 'first Vencord build cached; reloading');
        window.location.reload();
      }
    }
  } catch (error) {
    console.warn(TAG, 'could not refresh Vencord', error);
  }
};

module.exports = { inject, setup };
