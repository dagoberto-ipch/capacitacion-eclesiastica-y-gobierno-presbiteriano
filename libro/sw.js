/*
  Service worker del Libro de Ensenanza IPCh.

  Precarga el app completo para que abra sin internet. Las notas y el progreso
  de lectura ya se guardan en localStorage, asi que no hay nada mas que
  sincronizar ni que proteger con contrasena.

  Para forzar una version nueva hay que cambiar CACHE (numero de version).
*/
const CACHE = 'libro-ipch-v1';

const APP = [
  './',
  './index.html',
  './manifest.webmanifest',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/icon-maskable-512.png',
  './icons/apple-touch-icon.png'
];

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
        names.filter((name) => name !== CACHE).map((name) => caches.delete(name))
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
        // Revalidar en segundo plano: una actualizacion llega en la siguiente
        // apertura sin dejar de funcionar sin conexion.
        fetch(req).then((res) => {
          if (res && res.ok) {
            caches.open(CACHE).then((cache) => cache.put(req, res));
          }
        }).catch(() => {});
        return cacheada;
      }

      return fetch(req)
        .then((res) => {
          if (res && res.ok && res.type === 'basic') {
            const copia = res.clone();
            caches.open(CACHE).then((cache) => cache.put(req, copia));
          }
          return res;
        })
        .catch(() => caches.match('./index.html'));
    })
  );
});