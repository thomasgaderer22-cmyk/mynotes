# MyNotes – setup & build for Windows x64 (based on Meetily v0.4.1, MIT)
#
# Usage (PowerShell, inside the extracted MyNotes source folder):
#   powershell -ExecutionPolicy Bypass -File .\setup-and-build-mynotes.ps1           # install tools + build installer
#   powershell -ExecutionPolicy Bypass -File .\setup-and-build-mynotes.ps1 -Dev      # install tools + run in dev mode
#   powershell -ExecutionPolicy Bypass -File .\setup-and-build-mynotes.ps1 -Vulkan   # GPU build (needs Vulkan SDK)
#
# Installs (via winget, only if missing; all free): Git, Node.js LTS, Rustup, CMake, LLVM,
# Visual Studio 2022 Build Tools (C++ workload, ~6 GB, needs admin prompt).

param(
    [switch]$Dev,
    [switch]$Vulkan,
    [switch]$SkipInstall
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Frontend = Join-Path $Root 'frontend'

function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Have($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }
function Refresh-Path {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User') + ';' +
                "$env:USERPROFILE\.cargo\bin"
}
function Winget-Install($id, $extra = @()) {
    Write-Host "   installing $id ..."
    winget install --id $id -e --accept-source-agreements --accept-package-agreements --silent @extra
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) {  # -1978335189 = already installed
        throw "winget failed for $id (exit $LASTEXITCODE)"
    }
}

# ---------------------------------------------------------------- hardware info
Step 'System'
$cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name
$gpu = (Get-CimInstance Win32_VideoController | ForEach-Object Name) -join ', '
$ramGb = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
Write-Host "   CPU: $cpu"
Write-Host "   GPU: $gpu"
Write-Host "   RAM: $ramGb GB"
if ($ramGb -lt 8) { Write-Warning 'Less than 8 GB RAM: use small models (Whisper base/small, a 1-3B Ollama model).' }

# ---------------------------------------------------------------- toolchain
if (-not $SkipInstall) {
    Step 'Checking build tools'
    if (-not (Have 'winget')) { throw 'winget not found. Install "App Installer" from the Microsoft Store first.' }

    if (-not (Have 'git'))   { Winget-Install 'Git.Git' }
    if (-not (Have 'node'))  { Winget-Install 'OpenJS.NodeJS.LTS' }
    if (-not (Have 'cmake')) { Winget-Install 'Kitware.CMake' }
    if (-not (Test-Path 'C:\Program Files\LLVM\bin\libclang.dll')) { Winget-Install 'LLVM.LLVM' }
    if (-not (Have 'rustup') -and -not (Test-Path "$env:USERPROFILE\.cargo\bin\rustup.exe")) { Winget-Install 'Rustlang.Rustup' }

    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $hasVc = $false
    if (Test-Path $vswhere) {
        $hasVc = [bool](& $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath)
    }
    if (-not $hasVc) {
        Winget-Install 'Microsoft.VisualStudio.2022.BuildTools' @('--override', '--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended')
    }
    Refresh-Path
}

Refresh-Path
$env:LIBCLANG_PATH = 'C:\Program Files\LLVM\bin'
rustup default stable | Out-Null
foreach ($c in 'git', 'node', 'cargo', 'cmake') {
    if (-not (Have $c)) { throw "$c still not on PATH. Open a NEW PowerShell window and run this script again." }
}
Write-Host "   node $(node -v) | $(cargo --version) | $(cmake --version | Select-Object -First 1)"

if (-not (Have 'pnpm')) { npm install -g pnpm@9.15.9 }

# ---------------------------------------------------------------- dependencies
Step 'Installing frontend dependencies (pnpm, frozen lockfile)'
Push-Location $Frontend
pnpm install --frozen-lockfile
if ($LASTEXITCODE -ne 0) { throw 'pnpm install failed (exit ' + $LASTEXITCODE + ')' }
Pop-Location

# ---------------------------------------------------------------- llama-helper sidecar (local summaries)
Step 'Building llama-helper sidecar (CPU)'
Push-Location $Root
cargo build --release -p llama-helper
if ($LASTEXITCODE -ne 0) { throw 'llama-helper build failed (exit ' + $LASTEXITCODE + ')' }
New-Item -ItemType Directory -Force -Path "$Frontend\src-tauri\binaries" | Out-Null
Copy-Item "$Root\target\release\llama-helper.exe" "$Frontend\src-tauri\binaries\llama-helper-x86_64-pc-windows-msvc.exe" -Force
Pop-Location

# ---------------------------------------------------------------- build / run
Push-Location $Frontend
if ($Dev) {
    Step 'Starting MyNotes in dev mode (first compile takes 10-30 min)'
    if ($Vulkan) { pnpm tauri:dev:vulkan } else { pnpm tauri:dev:cpu }
} else {
    Step 'Building MyNotes installer (first compile takes 15-40 min)'
    if ($Vulkan) { pnpm tauri:build:vulkan } else { pnpm tauri:build:cpu }
    if ($LASTEXITCODE -ne 0) { throw 'tauri build failed (exit ' + $LASTEXITCODE + ')' }
    $out = Join-Path $Root 'target\release\bundle'
    Write-Host "`nDone. Installers:" -ForegroundColor Green
    Get-ChildItem -Recurse $out -Include *.exe, *.msi | ForEach-Object { Write-Host "   $($_.FullName)" }
}
Pop-Location
