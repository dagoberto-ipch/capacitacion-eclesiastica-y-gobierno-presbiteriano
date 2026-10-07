/*
  Service worker de la Presentacion de la Leccion 2.

  No hace nada: no cachea, no precarga, no intercepta.

  Esta aqui por una sola razon. El libro de ensenanza, que vive en la raiz del
  mismo repositorio, tiene un service worker cuyo alcance es toda la carpeta
  del proyecto. Sin este archivo, el service worker del libro tambien
  interceptaria las peticiones de la presentacion, y si alguien la abria sin
  internet el navegador le serviria el libro en vez de la presentacion.

  Al registrar este, que tiene un alcance mas estrecho, el navegador elige el
  mas especifico para las direcciones de /presentacion-leccion2/ y la
  presentacion queda independiente del libro.

  La presentacion es un solo HTML con los logos dentro, asi que no necesita
  cache para funcionar sin conexion: el archivo ya esta completo.
*/

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));