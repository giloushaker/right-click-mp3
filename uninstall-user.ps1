Param()

$exts = '.mp4', '.m4a', '.mkv', '.wav', '.flac', '.aac', '.mov', '.wmv', '.ogg', '.wma', '.mp3', '.avi', '.webm', '.opus'

foreach ($ext in $exts) {
    foreach ($key in @(
        "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\RightClickMP3",
        # keys left behind by pre-release builds
        "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\UsableConverter",
        "HKCU:\Software\Classes\$ext\shell\ConvertTo"
    )) {
        if (Test-Path $key) { Remove-Item -Path $key -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

$start = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
foreach ($lnk in 'Right Click MP3.lnk', 'Usable Converter.lnk') {
    Remove-Item -LiteralPath (Join-Path $start $lnk) -Force -ErrorAction SilentlyContinue
}

foreach ($dir in 'Programs\RightClickMP3', 'Programs\Usable-Converter') {
    $p = Join-Path $env:LOCALAPPDATA $dir
    if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Output 'Right Click MP3 removed. The right-click menu is gone.'
