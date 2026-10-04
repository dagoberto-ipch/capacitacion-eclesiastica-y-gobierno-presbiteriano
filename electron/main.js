/*
  Ventana de escritorio del Libro de Ensenanza IPCh.

  Por que un protocolo propio (app://) y no un loadFile() normal:
  con file:// el origen es opaco y Chromium bloquea localStorage, que es justo
  donde la app guarda las notas y el progreso de lectura. Registrando app:// como
  esquema estandar y seguro, el origen queda fijo y las notas persisten entre
  sesiones, igual que en la version web.

  La app se empaqueta en un solo archivo .exe (electron-builder, target portable).
*/
const { app, BrowserWindow, Menu, protocol, shell } = require('electron');
const fs = require('node:fs/promises');
const path = require('node:path');

const ESQUEMA = 'app';
const HOST = 'libro';
const RAIZ = path.join(__dirname, '..');

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.webmanifest': 'application/manifest+json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.webp': 'image/webp',
  '.woff2': 'font/woff2',
  '.txt': 'text/plain; charset=utf-8'
};

protocol.registerSchemesAsPrivileged([
  {
    scheme: ESQUEMA,
    privileges: { standard: true, secure: true, supportFetchAPI: true, corsEnabled: true }
  }
]);

/* Sirve los archivos de la app desde el disco, sin salirse de la carpeta. */
async function servir(req) {
  let relativo = decodeURIComponent(new URL(req.url).pathname);
  if (relativo === '/' || relativo === '') relativo = '/index.html';

  // El service worker no hace falta dentro del .exe y puede servir contenido
  // viejo si se cambia index.html sin subir el numero de version del cache.
  if (relativo === '/sw.js') return new Response('No disponible', { status: 404 });

  const destino = path.normalize(path.join(RAIZ, relativo));
  if (destino !== RAIZ && !destino.startsWith(RAIZ + path.sep)) {
    return new Response('Prohibido', { status: 403 });
  }

  try {
    const datos = await fs.readFile(destino);
    const tipo = MIME[path.extname(destino).toLowerCase()] || 'application/octet-stream';
    return new Response(datos, { headers: { 'content-type': tipo } });
  } catch {
    return new Response('No encontrado', { status: 404 });
  }
}

function crearVentana() {
  const win = new BrowserWindow({
    width: 1280,
    height: 860,
    minWidth: 420,
    minHeight: 480,
    backgroundColor: '#0a192f',
    show: false,
    autoHideMenuBar: true,
    icon: path.join(RAIZ, 'icons', 'icon-256.png'),
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true
    }
  });

  win.once('ready-to-show', () => win.show());
  win.loadURL(`${ESQUEMA}://${HOST}/index.html`);

  // Los enlaces externos se abren en el navegador del sistema, no dentro de la app.
  win.webContents.setWindowOpenHandler(({ url }) => {
    if (/^https?:/i.test(url)) shell.openExternal(url);
    return { action: 'deny' };
  });

  return win;
}

app.whenReady().then(() => {
  protocol.handle(ESQUEMA, servir);

  // La app es un libro de lectura: la barra de menu sobra.
  Menu.setApplicationMenu(null);

  crearVentana();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) crearVentana();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});