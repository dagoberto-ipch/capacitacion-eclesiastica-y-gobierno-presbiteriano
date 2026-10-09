/* Service worker de la Presentacion de la Leccion 15.

  Dos funciones. La primera es util: guarda los archivos para que la leccion abra
  sin internet. Al instalar la aplicacion, se guarda todo; despues se sirve primero
  la copia guardada y en segundo plano se baja la nueva, asi una actualizacion
  llega sola.

  La segunda es la razon por la que este archivo existia antes de guardar nada: el
  libro de ensenanza, que vive en la raiz del mismo repositorio, tiene un service
  worker cuyo alcance es toda la carpeta del proyecto. Sin este archivo, el del libro
  tambien interceptaria las peticiones de la presentacion, y sin internet el
  navegador le serviria el libro en vez de la leccion. Al registrar este, que tiene
  un alcance mas estrecho, el navegador elige el mas especifico para las direcciones
  de /presentacion-leccion15/ y la presentacion queda independiente del libro.

  La presentacion es un solo HTML con todo el texto dentro, asi que con una copia
  guardada alcanza.

  Para forzar una version nueva hay que subir CACHE. */
const CACHE = 'ipch-leccion15-v2';
const APP = [ './', 'Presentacion-Leccion15-recursos-reivindicacion-prescripcion-y-restaur.html', 'index.html', 'manifest.json', 'icono-180.png', 'icono-192.png', 'icono-512.png', 'sw-standalone.js' ];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE)
      .then((cache) => cache.addAll(APP))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((names) => Promise.all(
        names.filter((n) => n !== CACHE).map((n) => caches.delete(n))
      ))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  if (new URL(req.url).origin !== self.location.origin) return;

  event.respondWith(
    caches.match(req).then((cacheada) => {
      // Hay copia: se sirve esa al instante y se actualiza por detras.
      if (cacheada) {
        fetch(req).then((res) => {
          if (res && res.ok) caches.open(CACHE).then((c) => c.put(req, res));
        }).catch(() => {});
        return cacheada;
      }
      // No hay copia: se pide a la red, y si no hay red se sirve la leccion guardada.
      return fetch(req)
        .then((res) => {
          if (res && res.ok && res.type === 'basic') {
            const copia = res.clone();
            caches.open(CACHE).then((c) => c.put(req, copia));
          }
          return res;
        })
        .catch(() => caches.match('./'));
    })
  );
});