# Capacitación Eclesiástica y Gobierno Presbiteriano

Libro de Enseñanza interactivo para la Escuela Bíblica Dominical (Adultos 2026).
**Iglesia Presbiteriana Divino Salvador** — Pr. Dagoberto Peñaloza A.

---

## Lo que se reparte

👉 **[Libro Interactivo](https://dagoberto-ipch.github.io/capacitacion-eclesiastica-y-gobierno-presbiteriano/)**

A los alumnos se les manda **un link de WhatsApp**, no un archivo.

| | Link (PWA) | Archivo `.exe` |
|---|---|---|
| Peso en el chat | 0 KB | 1 MB (mínimo viable) |
| Funciona en iPhone | Sí | No |
| Se actualiza | Solo, al día siguiente | Hay que reenviar el archivo |
| Instalar | Un toque | Descomprimir y abrir |

Si algún alumno necesita leerlo **sin internet**, que lo abra una vez mientras
tenga datos: queda guardado en el teléfono y después funciona igual sin señal.

### Mensaje para el grupo de WhatsApp

```
📖 Libro de Enseñanza — Capacitación Eclesiástica y Gobierno Presbiteriano
Escuela Bíblica Dominical · Adultos 2026

Abrir el libro:
https://dagoberto-ipch.github.io/capacitacion-eclesiastica-y-gobierno-presbiteriano/

👉 Para instalarlo como aplicación en el teléfono:
   · Android: menú ⋮ → "Instalar aplicación"
   · iPhone: botón compartir → "Añadir a pantalla de inicio"
   · Computador (Chrome/Edge): ícono de instalar en la barra de direcciones

⚠️ Ábrelo una vez con internet para que quede guardado en el teléfono.
   Después podés leerlo sin datos, y tus notas quedan guardadas en tu aparato.
```

### Cómo se instala, según el aparato

- **Android** — Chrome o el navegador del sistema: menú **⋮** → **Instalar aplicación**.
- **iPhone / iPad** — Safari: botón de compartir → **Añadir a pantalla de inicio**.
- **Computador (Chrome/Edge)** — ícono de instalar en la barra de direcciones.
- **Firefox** — no instala, pero se abre y usa igual en una pestaña.

---

## Estructura

| Ruta | Qué es |
|---|---|
| `index.html` | La app completa: CSS, JS y datos van en línea. Sin CDN, sin peticiones externas. |
| `manifest.webmanifest` | Datos de la PWA: nombre, íconos, ventana propia. |
| `sw.js` | Service worker: deja el libro en caché para usarlo sin conexión. |
| `icons/` | Íconos 192 / 256 / 512 / maskable y el de iOS. |
| `tools/generar-iconos.ps1` | Regenera `icons/` desde el logo, sin Node ni ImageMagick. |
| `tools/servir.ps1` | Servidor local para probar antes de publicar. |
| `publicar.ps1` | Sube todo al repo de GitHub Pages. |
| `assets-logo-original.png` | Logo IPCh tal como viene incrustado en el HTML. Solo fuente para los íconos; no se publica. |

No hay `package.json` ni `node_modules`: no hay build. Lo que se edita es lo que
se sirve.

### Por qué `index.html` pesa 160 KB y no usa librerías

El libro se armó en el chat de Gemini y quedó en un solo archivo. Así no depende
de internet, no hay `npm install`, no hay `node_modules` que actualizar y no hay
CDN que se caiga. El costo es que todo hay que editarlo dentro del HTML; para
cambios grandes conviene un proyecto con build.

---

## Publicar cambios

```bash
powershell -ExecutionPolicy Bypass -File publicar.ps1 -SinPush   # revisa el commit
powershell -ExecutionPolicy Bypass -File publicar.ps1             # sube a main
```

GitHub Pages sirve la rama `main` desde la raíz, así que el push publica la web
directamente. Tarda entre 1 y 3 minutos.

## Probar en local

```bash
powershell -ExecutionPolicy Bypass -File tools\servir.ps1
```

Abre <http://localhost:8123>. Hace falta porque el service worker no funciona
con `file://`. Para ver cómo queda sin conexión: deja de ejecutar el script y
recarga; la página tiene que seguir apareciendo.

## Regenerar los íconos

```bash
powershell -ExecutionPolicy Bypass -File tools\generar-iconos.ps1
```

Recorta la cruz del logo original y la compone sobre el azul marino `#0a192f`
con un marco azul `#29abe2`. Si cambia el logo, se edita `assets-logo-original.png`
y se vuelve a correr el script.

> Después de regenerarlos, hay que subir `CACHE` en `sw.js` (de `libro-ipch-v1`
> a `libro-ipch-v2`) para que los teléfonos que ya instalaron la app reciban los
> íconos nuevos.

---

## Por qué no hay un `.exe`

El proyecto empezó como un ejecutable de Windows y se descartó a favor de repartir
un link. Las razones concretas:

- **No sirve para WhatsApp.** El `.exe` más chico posible (WebView2, que ya viene
  en Windows 10 y 11) pesaba 1-3 MB; el de Electron, unos 100 MB. Ninguno es
  cómodo mandar a cada alumno en un chat, sobre todo con datos móviles.
- **No corre en iPhone ni en Android.** Hubo alumnos sin acceso a un computador.
- **Hay que reenviarlo.** Si cambia el temario, con el link todos lo ven al día
  siguiente; con el archivo, hay que mandarlo de nuevo a todos.
- **Las notas.** El libro guarda apuntes y avance de lectura en `localStorage`. Un
  ejecutable que sirviera los archivos con `file://` perdería todo eso, porque
  Chromium bloquea `localStorage` en orígenes opacos. Hacerlo bien exigía un
  origen propio (C++/WinRT o un protocolo como `app://`), y en la máquina donde se
  desarrollaba no había compilador de C++ ni de .NET. El link no tiene ese
  problema.

Si alguna vez hace falta de verdad —un aula sin internet, por ejemplo— lo
correcto es un `.exe` nativo con WebView2 y un origen propio para las notas,
compilado en GitHub Actions. No es un `.exe` que se pueda generar sin un
compilador, ni aunque el libro sea un solo HTML.

---

## Archivo duplicado

`2 - Libro Interactivo (HTML).html` es una copia byte a byte de `index.html` que
ya existía en el repo. Se dejó intacta. Si nadie la usa, se puede borrar.