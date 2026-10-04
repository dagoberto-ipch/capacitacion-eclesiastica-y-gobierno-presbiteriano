<#
  Genera los iconos de la PWA y del .exe a partir del logo IPCh incrustado en
  index.html (assets-logo-original.png, blanco sobre transparente).

  Sin Node, sin ImageMagick: solo System.Drawing de .NET, que ya viene en Windows.

  Uso:
    powershell -ExecutionPolicy Bypass -File tools\generar-iconos.ps1
#>
param(
  [string]$Fuente = "$PSScriptRoot\..\assets-logo-original.png",
  [string]$Salida = "$PSScriptRoot\..\icons"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if (-not (Test-Path -LiteralPath $Fuente)) {
  Write-Host "FALTA: $Fuente" -ForegroundColor Red
  exit 1
}
New-Item -ItemType Directory -Force -Path $Salida | Out-Null

# Colores tomados del CSS de index.html
$navy = [System.Drawing.ColorTranslator]::FromHtml('#0a192f')
$azul = [System.Drawing.ColorTranslator]::FromHtml('#29abe2')

$src = [System.Drawing.Image]::FromFile($Fuente)

# El logo original es 274x445 (vertical): la cruz ocupa los ~250 px de arriba y la
# tipografia "IGLESIA PRESBITERIANA DE CHILE" el resto. Para el icono solo sirve la
# cruz, asi que se recorta un cuadrado de 250x250 del borde superior. La cruz esta
# centrada en x~137, de ahi el desplazamiento de 12 px.
$ORIGEN_X = 12
$ORIGEN_Y = 0
$CUZ_LADO = 250

# Se recorta una vez a un bitmap propio: trabajar con un solo origen de 250x250
# evita depender del overload de DrawImage con rectangulos de origen.
$cruz = New-Object System.Drawing.Bitmap($CUZ_LADO, $CUZ_LADO)
$gCruz = [System.Drawing.Graphics]::FromImage($cruz)
$gCruz.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gCruz.Clear([System.Drawing.Color]::Transparent)
$rectOrigen = [System.Drawing.Rectangle]::new($ORIGEN_X, $ORIGEN_Y, $CUZ_LADO, $CUZ_LADO)
$rectCruz   = [System.Drawing.Rectangle]::new(0, 0, $CUZ_LADO, $CUZ_LADO)
$gCruz.DrawImage($src, $rectOrigen, $rectCruz, [System.Drawing.GraphicsUnit]::Pixel)
$gCruz.Dispose()
$src.Dispose()

function New-Icono {
  param(
    [int]$Tam,
    [double]$FraccionContenido = 1.0,   # <1 deja margen (maskable)
    [string]$Nombre
  )
  $ruta = Join-Path $Salida $Nombre

  $bmp = New-Object System.Drawing.Bitmap($Tam, $Tam)
  $g   = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.Clear($navy)

  # Anillo azul sutil, para que el icono se distinga de un fondo azul plano
  $grosor = [int][Math]::Max(2, [Math]::Round($Tam * 0.012))
  $lapis = New-Object System.Drawing.Pen($azul, $grosor)
  $g.DrawRectangle($lapis, 1, 1, ($Tam - 3), ($Tam - 3))
  $lapis.Dispose()

  # Contenido centrado y escalado por FraccionContenido
  $dest = [int][Math]::Round($Tam * $FraccionContenido)
  $off  = [int][Math]::Round(($Tam - $dest) / 2)
  $g.DrawImage($cruz, $off, $off, $dest, $dest)

  $g.Dispose()
  # GDI+ no puede sobrescribir un archivo abierto (visor de imagenes, OneDrive).
  # Se escribe primero a un temporal y se mueve con reintentos.
  $tmp = Join-Path ([IO.Path]::GetTempPath()) ("icon-" + [Guid]::NewGuid().ToString('N') + ".png")
  $bmp.Save($tmp, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  Set-ArchivoConReintento $tmp $ruta
  $kb = [Math]::Round((Get-Item $ruta).Length / 1KB, 1)
  Write-Host ("  {0,-26} {1}x{1}  {2} KB" -f $Nombre, $Tam, $kb) -ForegroundColor Green
}

function Set-ArchivoConReintento {
  param([string]$Origen, [string]$Destino)
  for ($i = 1; $i -le 10; $i++) {
    try {
      if (Test-Path -LiteralPath $Destino) { Remove-Item -LiteralPath $Destino -Force -ErrorAction Stop }
      [IO.File]::Copy($Origen, $Destino, $true)
      Remove-Item -LiteralPath $Origen -Force -ErrorAction SilentlyContinue
      return
    } catch {
      Start-Sleep -Milliseconds 300
    }
  }
  Remove-Item -LiteralPath $Origen -Force -ErrorAction SilentlyContinue
  Write-Host "  ERROR: no se pudo escribir $Destino (esta bloqueado por otro programa)" -ForegroundColor Red
  exit 1
}

Write-Host "Generando iconos en $Salida"
New-Icono -Tam 512 -FraccionContenido 0.92 -Nombre 'icon-512.png'
New-Icono -Tam 192 -FraccionContenido 0.92 -Nombre 'icon-192.png'
New-Icono -Tam 180 -FraccionContenido 0.92 -Nombre 'apple-touch-icon.png'
# maskable: el sistema recorta hasta un 20% por lado, asi que el contenido va al 62%
New-Icono -Tam 512 -FraccionContenido 0.62 -Nombre 'icon-maskable-512.png'
# icono cuadrado que electron-builder usa para el .ico del .exe
New-Icono -Tam 256 -FraccionContenido 0.92 -Nombre 'icon-256.png'

$cruz.Dispose()
Write-Host "Listo." -ForegroundColor Cyan