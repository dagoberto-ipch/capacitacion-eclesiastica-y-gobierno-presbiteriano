# Capacitación Eclesiástica y Gobierno Presbiteriano

Libro de Enseñanza interactivo para la Escuela Bíblica Dominical (Adultos 2026).
**Iglesia Presbiteriana Divino Salvador** — Pr. Dagoberto Peñaloza A.

---

## Dónde está publicado

- 🌐 Web / PWA 👉 **[Libro Interactivo](https://dagoberto-ipch.github.io/capacitacion-eclesiastica-y-gobierno-presbiteriano/)**
- 🖥️ `.exe` para Windows: se compila en la pestaña **Actions** del repo.

## Cómo se instala

### Celular o tablet (Android / iPhone / iPad)

1. Abrir el link de arriba con el navegador.
2. Menú **⋮** → **Instalar aplicación** / **Agregar a pantalla de inicio**.

Queda un ícono como cualquier app y **funciona sin internet** (las notas y el
avance de lectura se guardan en el propio teléfono).

### Computador (Windows, Mac o Linux)

- **Chrome / Edge**: ícono de instalar en la barra de direcciones (o
  ⋮ → Instalar). Crea un acceso directo y abre en su propia ventana.
- **Firefox**: no instala, pero funciona igual en una pestaña.

### Windows como programa de escritorio (`.exe`)

Ver más abajo, sección **Generar el .exe**.

---

## Estructura

| Ruta | Qué es |
|---|---|
| `index.html` | La app completa: CSS, JS y datos van en línea. Sin CDN, sin peticiones externas. |
| `manifest.webmanifest` | Datos de la PWA: nombre, íconos, ventana propia. |
| `sw.js` | Service worker: deja el libro en caché para usarlo sin conexión. |
| `icons/` | Íconos 192 / 256 / 512 / maskable y el de iOS. |
| `assets-logo-original.png` | Logo IPCh tal como viene incrustado en el HTML. Solo fuente para los íconos; no se publica. |
| `electron/main.js` | Ventana de escritorio del `.exe`. |
| `tools/generar-iconos.ps1` | Regenera `icons/` desde el logo, sin Node ni ImageMagick. |
| `generar-exe.ps1` | Compila el `.exe` en local (requiere Node.js). |
| `publicar.ps1` | Sube todo al repo de GitHub Pages. |

### Por qué `index.html` pesa 160 KB y no usa librerías

El libro se armó en el chat de Gemini y quedó en un solo archivo. Así no depende
de internet, no hay `npm install`, no hay `node_modules` que actualizar y no hay
CDN que se caiga. El costo es que todo hay que editarlo dentro del HTML; para
cambios grandes conviene un proyecto con build.

---

## Regenerar los íconos

```bash
powershell -ExecutionPolicy Bypass -File tools\generar-iconos.ps1
```

Recorta la cruz del logo original y la compone sobre el azul marino `#0a192f`
con un marco azul `#29abe2`. Si cambia el logo, se edita `assets-logo-original.png`
y se vuelve a correr el script.

> Después de regenerarlos, hay que subir `CACHE` en `sw.js` (por ejemplo de
> `libro-ipch-v1` a `libro-ipch-v2`) y cambiar la versión en `package.json`, para
> que los teléfonos que ya instalaron la app reciban los íconos nuevos.

---

## Generar el `.exe`

El `.exe` **solo corre en Windows**. Se genera con Electron, así que el archivo
pesa del orden de 100 MB (pesa Electron, no el libro, que son 160 KB).

### Opción A — GitHub Actions (la que funciona sin instalar nada)

1. Pestaña **Actions** del repo → **Build .exe** → **Run workflow**.
2. Al terminar, descargar el artefacto `Libro-IPCh-portable`.

Para además tener un **Release** con link de descarga, hay que etiquetar:

```bash
git tag v1.0.0
git push --tags
```

### Opción B — En local (requiere Node.js LTS)

```bash
powershell -ExecutionPolicy Bypass -File generar-exe.ps1
```

Sale en `dist/Libro-IPCh-1.0.0-portable.exe`. Es **portable**: se copia a una
USB o se manda por correo y abre con doble clic, sin instalar nada.

Con `-Instalador` genera en vez el `.exe` con asistente de instalación.

### Nota sobre el origen de la app dentro del `.exe`

`electron/main.js` sirve los archivos con un protocolo propio (`app://`) en vez de
`file://`. No es un detalle: con `file://` el origen es opaco y Chromium bloquea
`localStorage`, que es donde la app guarda las notas y el avance de lectura. Con
`app://` las notas se mantienen al cerrar y reabrir el programa.

---

## Publicar cambios

```bash
powershell -ExecutionPolicy Bypass -File publicar.ps1 -SinPush   # revisa el commit
powershell -ExecutionPolicy Bypass -File publicar.ps1             # sube a main
```

GitHub Pages sirve la rama `main` desde la raíz, así que el push publica la web
directamente. Tarda entre 1 y 3 minutos.

---

## Archivo duplicado

`2 - Libro Interactivo (HTML).html` es una copia byte a byte de `index.html` que
ya existía en el repo. Se dejó intacta y no se incluye en el `.exe`. Si nadie la
usa, se puede borrar.