<#
  Servidor estatico minimo para probar la app en local.

  Hace falta porque el service worker no funciona con file://: hay que abrirlo
  por http. GitHub Pages ya sirve los tipos correctos; este script solo replica
  eso para poder probar antes de publicar.

  Uso:
    powershell -ExecutionPolicy Bypass -File tools\servir.ps1
    powershell -ExecutionPolicy Bypass -File tools\servir.ps1 -Port 8123
#>
param(
  [string]$Root = "$PSScriptRoot\..",
  [int]$Port = 8123
)

$ErrorActionPreference = 'Stop'

# Ruta absoluta: el proceso puede partir de otro directorio de trabajo.
$Root = (Resolve-Path -LiteralPath $Root).Path

$tipos = @{
  '.html'       = 'text/html; charset=utf-8'
  '.js'         = 'text/javascript; charset=utf-8'
  '.mjs'        = 'text/javascript; charset=utf-8'
  '.css'        = 'text/css; charset=utf-8'
  '.json'       = 'application/json; charset=utf-8'
  '.webmanifest'= 'application/manifest+json; charset=utf-8'
  '.svg'        = 'image/svg+xml'
  '.png'        = 'image/png'
  '.jpg'        = 'image/jpeg'
  '.ico'        = 'image/x-icon'
  '.txt'        = 'text/plain; charset=utf-8'
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Sirviendo $Root en http://localhost:$Port/" -ForegroundColor Cyan
Write-Host "Ctrl+C para cortar." -ForegroundColor DarkGray

try {
  while ($listener.IsListening) {
    try { $ctx = $listener.GetContext() } catch { break }
    try {
      $rel = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
      if ($rel -eq '') { $rel = 'index.html' }

      $full = Join-Path $Root ($rel -replace '/', '\')
      # No salir de la carpeta servida
      if (-not $full.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase)) {
        $ctx.Response.StatusCode = 403
        $full = $null
      } elseif (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        $ctx.Response.StatusCode = 404
        $full = $null
      }

      if ($null -eq $full) {
        $b = [Text.Encoding]::UTF8.GetBytes('no encontrado')
        $ctx.Response.OutputStream.Write($b, 0, $b.Length)
      } else {
        $ext = [IO.Path]::GetExtension($full).ToLower()
        $ct  = if ($tipos.ContainsKey($ext)) { $tipos[$ext] } else { 'application/octet-stream' }
        $bytes = [IO.File]::ReadAllBytes($full)
        $ctx.Response.ContentType   = $ct
        $ctx.Response.ContentLength64 = $bytes.Length
        $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
      }
    } catch { }
    finally { $ctx.Response.Close() }
  }
} finally {
  $listener.Stop()
}