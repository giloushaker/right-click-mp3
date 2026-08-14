Param(
    [switch]$NoCopy,    # register only, run the app from where it already is
    [switch]$ShowDone   # the setup exe has no finish page, so say it worked
)

$ErrorActionPreference = 'Stop'
$source = Split-Path -Parent $MyInvocation.MyCommand.Definition
$installDir = Join-Path $env:LOCALAPPDATA 'Programs\RightClickMP3'

if ($NoCopy) {
    $installDir = $source
} else {
    Write-Output "Installing to $installDir"
    New-Item -Path $installDir -ItemType Directory -Force | Out-Null
    foreach ($f in 'convert.ps1', 'convert.vbs', 'lang.ps1', 'ffmpeg-get.ps1', 'uninstall-user.ps1', 'README.md', 'LICENSE') {
        Copy-Item -Path (Join-Path $source $f) -Destination $installDir -Force
    }
}

$launcher = Join-Path $installDir 'convert.vbs'

# Menu labels follow the Windows display language at install time.
. (Join-Path $source 'lang.ps1')

$exts = '.mp4', '.m4a', '.mkv', '.wav', '.flac', '.aac', '.mov', '.wmv', '.ogg', '.wma', '.mp3', '.avi', '.webm', '.opus'

$formats = @(
    @{ Key = '10mp3-192'; Label = (Get-Text 'mp3_192'); Args = '-Format mp3 -Bitrate 192k' }
    @{ Key = '20mp3-320'; Label = (Get-Text 'mp3_320'); Args = '-Format mp3 -Bitrate 320k' }
    @{ Key = '30m4a';     Label = (Get-Text 'aac');     Args = '-Format aac -Bitrate 128k' }
    @{ Key = '40wav';     Label = (Get-Text 'wav');     Args = '-Format wav' }
    @{ Key = '50flac';    Label = (Get-Text 'flac');    Args = '-Format flac' }
)

foreach ($ext in $exts) {
    # SystemFileAssociations adds verbs without changing which app opens the file.
    $menu = "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\RightClickMP3"
    New-Item -Path $menu -Force | Out-Null
    Set-ItemProperty -Path $menu -Name 'MUIVerb' -Value (Get-Text 'menuTitle')
    Set-ItemProperty -Path $menu -Name 'Icon' -Value 'shell32.dll,116'
    # An empty SubCommands is what makes Explorer draw the flyout from the shell subkeys.
    Set-ItemProperty -Path $menu -Name 'SubCommands' -Value ''

    foreach ($f in $formats) {
        $item = "$menu\shell\$($f.Key)"
        New-Item -Path "$item\command" -Force | Out-Null
        Set-ItemProperty -Path $item -Name 'MUIVerb' -Value $f.Label
        # Document = Explorer runs the command once per selected file with %1.
        # (%* expands to nothing here.) convert.ps1 merges those into one job.
        Set-ItemProperty -Path $item -Name 'MultiSelectModel' -Value 'Document'
        Set-ItemProperty -Path "$item\command" -Name '(Default)' `
            -Value "wscript.exe `"$launcher`" $($f.Args) `"%1`""
    }
}

# Start menu shortcut, for picking files by hand
$sm = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Right Click MP3.lnk'
$sc = (New-Object -ComObject WScript.Shell).CreateShortcut($sm)
$sc.TargetPath = 'wscript.exe'
$sc.Arguments = "`"$launcher`""
$sc.WorkingDirectory = $installDir
$sc.IconLocation = 'shell32.dll,116'
$sc.Save()

Write-Output 'Done. Right-click any audio or video file -> Convert To.'
Write-Output 'On Windows 11 the menu is under "Show more options" (or press Shift+F10).'

if ($ShowDone) {
    Add-Type -AssemblyName System.Windows.Forms
    [void][System.Windows.Forms.MessageBox]::Show((Get-Text 'installed'), 'Right Click MP3', 'OK', 'Information')
}
