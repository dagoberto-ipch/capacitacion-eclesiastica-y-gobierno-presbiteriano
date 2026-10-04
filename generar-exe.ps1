<#
  Compila el .exe de Windows en local.

  OJO: esta maquina no tiene Node.js, asi que este script va a fallar. La via
  que si funciona hoy es compilar en GitHub: pestana Actions > Build .exe >
  Run workflow, o etiquetar el commit (git tag v1.0.0 && git push --tags).

  Uso (una vez instalado Node.js LTS):
    powershell -ExecutionPolicy Bypass -File generar-exe.ps1
    powershell -ExecutionPolicy Bypass -File generar-exe.ps1 -Instalador
#>
param(
  [string]$Destino = "$PSScriptRoot\dist",
  [switch]$Instalador     # genera el .exe con asistente en vez del portable
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Write-Host "FALTA Node.js. Descarga el LTS desde https://nodejs.org/en/download" -ForegroundColor Red
  Write-Host "        o usa GitHub Actions (pestana Actions > Build .exe > Run workflow)." -ForegroundColor Yellow
  exit 1
}

Write-Host "Node $(node --version) / npm $(npm --version)" -ForegroundColor Cyan

if (-not (Test-Path -LiteralPath "$PSScriptRoot\node_modules")) {
  Write-Host "Instalando dependencias (solo la primera vez)..."
  npm install --no-audit --no-fund
  if ($LASTEXITCODE -ne 0) { Write-Host "npm install fallo" -ForegroundColor Red; exit 1 }
}

if (Test-Path -LiteralPath $Destino) {
  Write-Host "Limpiando $Destino..."
  Remove-Item -LiteralPath $Destino -Recurse -Force
}

if ($Instalador) {
  Write-Host "Compilando el instalador..."
  npx electron-builder --win nsis
} else {
  Write-Host "Compilando el portable..."
  npx electron-builder --win portable
}

if ($LASTEXITCODE -ne 0) { Write-Host "La compilacion fallo" -ForegroundColor Red; exit 1 }

Write-Host ""
Get-ChildItem $Destino -Filter *.exe | ForEach-Object {
  Write-Host ("  {0}  ({1:N0} MB)" -f $_.Name, ($_.Length / 1MB)) -ForegroundColor Green
}
Write-Host "Listo. El .exe es portable: se copia a una USB y abre con doble clic." -ForegroundColor Cyan