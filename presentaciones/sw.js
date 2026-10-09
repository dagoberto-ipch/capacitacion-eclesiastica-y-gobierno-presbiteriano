/* Service worker del indice del curso.

  Guarda los archivos del indice para que abra sin internet. El modelo es el del
  Estatuto: primero se sirve la copia guardada, y en segundo plano se baja la
  nueva, para que una actualizacion llegue sola.

  Para forzar una version nueva hay que subir CACHE. */
const CACHE = 'ipch-indice-v2';
const APP = [ './', './index.html', './manifest.json', './icono-180.png', './icono-192.png', './icono-512.png' ];

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
      if (cacheada) {
        fetch(req).then((res) => {
          if (res && res.ok) caches.open(CACHE).then((c) => c.put(req, res));
        }).catch(() => {});
        return cacheada;
      }
      return fetch(req)
        .then((res) => {
          if (res && res.ok && res.type === 'basic') {
            const copia = res.clone();
            caches.open(CACHE).then((c) => c.put(req, copia));
          }
          return res;
        })
        .catch(() => caches.match('./index.html'));
    })
  );
});