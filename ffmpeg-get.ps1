Param(
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\RightClickMP3"
)

function Write-Info($m) { Write-Output "[ffmpeg-get] $m" }

$targetBin = Join-Path $InstallDir 'ffmpeg\bin'
if (-not (Test-Path $targetBin)) { New-Item -ItemType Directory -Path $targetBin -Force | Out-Null }

# Known reputable build (Gyan Dev 'essentials' build)
$url = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip'
$tmp = Join-Path $env:TEMP 'ffmpeg-download.zip'

Write-Info "Downloading ffmpeg from $url"
try {
    Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Error "Download failed: $_"
    exit 1
}

$extractDir = Join-Path $env:TEMP 'ffmpeg-extract'
if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
New-Item -ItemType Directory -Path $extractDir | Out-Null

Write-Info "Extracting..."
try {
    Expand-Archive -Path $tmp -DestinationPath $extractDir -Force
} catch {
    Write-Error "Extraction failed: $_"
    exit 1
}

# Find bin
$bin = Get-ChildItem -Path $extractDir -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $bin) { Write-Error "ffmpeg.exe not found in archive"; exit 1 }

$foundBinDir = Split-Path $bin.FullName -Parent
Write-Info "Copying ffmpeg binaries to $targetBin"
Get-ChildItem -Path $foundBinDir -Filter *.exe | ForEach-Object { Copy-Item -Path $_.FullName -Destination $targetBin -Force }

Write-Info "Cleaning up"
Remove-Item $tmp -Force -ErrorAction SilentlyContinue
Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Output "ffmpeg installed to: $targetBin"
