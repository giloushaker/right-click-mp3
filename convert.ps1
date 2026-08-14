# PositionalBinding=$false: without it a bare file path lands in -Bitrate
# whenever the caller omits it (the WAV and FLAC menu entries do).
[CmdletBinding(PositionalBinding = $false)]
Param(
    [string]$Format = 'mp3',
    [string]$Bitrate = '192k',
    [switch]$NoGui,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Paths
)

$ErrorActionPreference = 'Stop'
$Format = $Format.ToLower()
$here = Split-Path -Parent $MyInvocation.MyCommand.Definition
$appName = 'Right Click MP3'

# ---------------------------------------------------------------- ffmpeg
function Get-Ffmpeg {
    $c = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
    if ($c) { return $c }
    foreach ($p in @(
        (Join-Path $env:LOCALAPPDATA 'Programs\RightClickMP3\ffmpeg\bin\ffmpeg.exe'),
        (Join-Path $here 'ffmpeg\bin\ffmpeg.exe'),
        (Join-Path $env:ProgramFiles 'ffmpeg\bin\ffmpeg.exe')
    )) { if (Test-Path -LiteralPath $p) { return $p } }
    return $null
}

$ffmpeg = Get-Ffmpeg
if (-not $ffmpeg) {
    Add-Type -AssemblyName System.Windows.Forms
    $ans = [System.Windows.Forms.MessageBox]::Show(
        "The conversion engine (ffmpeg) is not installed yet.`r`n`r`nDownload it now? (about 30 MB, no admin rights needed)",
        $appName, 'YesNo', 'Question')
    if ($ans -ne 'Yes') { exit 2 }
    & (Join-Path $here 'ffmpeg-get.ps1')
    $ffmpeg = Get-Ffmpeg
    if (-not $ffmpeg) {
        [void][System.Windows.Forms.MessageBox]::Show('Download failed. Please install ffmpeg manually.', $appName, 'OK', 'Error')
        exit 2
    }
}

# ---------------------------------------------------------------- conversion
$extOf = @{ mp3 = '.mp3'; wav = '.wav'; flac = '.flac'; aac = '.m4a' }

function Get-CodecArgs($fmt, $br) {
    switch ($fmt) {
        'wav'  { return @('-acodec', 'pcm_s16le') }
        'flac' { return @('-c:a', 'flac') }
        'aac'  { return @('-c:a', 'aac', '-b:a', $br) }
        default { return @('-acodec', 'libmp3lame', '-b:a', $br) }
    }
}

# Windows filenames cannot contain a quote, so quoting everything is enough.
function Get-CommandLine($items) {
    ($items | ForEach-Object { '"' + $_ + '"' }) -join ' '
}

function Convert-One($path) {
    if (-not (Test-Path -LiteralPath $path)) { return 'not found' }
    $in = (Resolve-Path -LiteralPath $path).Path
    $dir = [IO.Path]::GetDirectoryName($in)
    $name = [IO.Path]::GetFileNameWithoutExtension($in)
    $ext = $extOf[$Format]
    if (-not $ext) { $ext = '.mp3' }
    $out = Join-Path $dir ($name + $ext)
    $i = 1
    while (Test-Path -LiteralPath $out) { $out = Join-Path $dir ("$name ($i)$ext"); $i++ }

    $a = @('-hide_banner', '-loglevel', 'error', '-nostdin', '-nostats', '-y', '-i', $in, '-vn') +
         (Get-CodecArgs $Format $Bitrate) + @($out)

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ffmpeg
    $psi.Arguments = Get-CommandLine $a
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $p = [System.Diagnostics.Process]::Start($psi)

    # Wait without blocking: a frozen window reads as a crashed program.
    while (-not $p.WaitForExit(120)) {
        Update-Ui
        if ($script:cancel) { $p.Kill(); $p.WaitForExit() ; break }
    }
    $code = if ($script:cancel) { -1 } else { $p.ExitCode }
    $p.Dispose()

    if ($code -ne 0) {
        Remove-Item -LiteralPath $out -Force -ErrorAction SilentlyContinue
        if ($script:cancel) { return $null }
        return "ffmpeg exit $code"
    }
    return $null
}

# ---------------------------------------------------------------- file picker
if (-not $Paths -and -not $NoGui) {
    Add-Type -AssemblyName System.Windows.Forms
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Multiselect = $true
    $ofd.Title = "Pick the files to convert to $($Format.ToUpper())"
    $ofd.Filter = 'Audio and video|*.mp4;*.m4a;*.mkv;*.wav;*.flac;*.aac;*.mov;*.wmv;*.ogg;*.wma;*.mp3;*.avi;*.webm|All files|*.*'
    if ($ofd.ShowDialog() -ne 'OK') { exit 0 }
    $Paths = $ofd.FileNames
}
if (-not $Paths) { exit 1 }

# ---------------------------------------------------------------- work queue
# Explorer runs the command once per selected file. The first process becomes
# the worker and converts the whole selection; the rest hand over their file
# and exit, so 30 files give one window instead of 30.
$tag = ($Format + '-' + $Bitrate) -replace '[^a-zA-Z0-9-]', ''
$queue = Join-Path $env:TEMP "rightclickmp3-$tag.txt"
$qLock = New-Object System.Threading.Mutex($false, "Local\rcm3q-$tag")
$worker = New-Object System.Threading.Mutex($false, "Local\rcm3w-$tag")

# A killed process leaves the mutex abandoned; that still counts as acquired.
function Wait-Mutex($m, $ms) {
    try { return $m.WaitOne($ms) } catch [System.Threading.AbandonedMutexException] { return $true }
}

function Add-ToQueue($items) {
    [void](Wait-Mutex $qLock -1)
    try { Add-Content -LiteralPath $queue -Value $items -Encoding UTF8 }
    finally { $qLock.ReleaseMutex() }
}

function Get-QueueBatch {
    [void](Wait-Mutex $qLock -1)
    try {
        if (-not (Test-Path -LiteralPath $queue)) { return @() }
        $b = @(Get-Content -LiteralPath $queue -Encoding UTF8 | Where-Object { $_ })
        Remove-Item -LiteralPath $queue -Force
        return $b
    } finally { $qLock.ReleaseMutex() }
}

Add-ToQueue $Paths
if (-not (Wait-Mutex $worker 0)) { exit 0 }   # someone else is already converting

# ---------------------------------------------------------------- progress UI
$script:cancel = $false
$ui = $null
if (-not $NoGui) {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $ui = New-Object System.Windows.Forms.Form
    $ui.Text = $appName
    $ui.ClientSize = New-Object System.Drawing.Size(440, 132)
    $ui.FormBorderStyle = 'FixedDialog'
    $ui.MaximizeBox = $false
    $ui.MinimizeBox = $false
    $ui.StartPosition = 'CenterScreen'
    $ui.TopMost = $true

    $label = New-Object System.Windows.Forms.Label
    $label.SetBounds(15, 15, 410, 40)
    $label.Text = 'Starting...'
    $ui.Controls.Add($label)

    $bar = New-Object System.Windows.Forms.ProgressBar
    $bar.SetBounds(15, 62, 410, 20)
    $bar.Style = 'Marquee'      # ffmpeg gives no reliable per-file percentage
    $bar.MarqueeAnimationSpeed = 25
    $ui.Controls.Add($bar)

    $btn = New-Object System.Windows.Forms.Button
    $btn.SetBounds(335, 94, 90, 26)
    $btn.Text = 'Cancel'
    $btn.Add_Click({ $script:cancel = $true; $btn.Enabled = $false; $btn.Text = 'Stopping' })
    $ui.Controls.Add($btn)
    $ui.Add_FormClosing({ $script:cancel = $true })

    $ui.Show()
    $ui.Activate()
    $ui.Refresh()
    [System.Windows.Forms.Application]::UseWaitCursor = $true
}

function Update-Ui {
    if ($ui) { [System.Windows.Forms.Application]::DoEvents() }
}

function Set-Status($text) {
    if (-not $ui) { Write-Output $text; return }
    $label.Text = $text
    Update-Ui
}

$failed = @()
$done = 0
$total = 0
try {
    while ($true) {
        $batch = Get-QueueBatch
        if (-not $batch) { break }
        $total += $batch.Count
        foreach ($f in $batch) {
            if ($script:cancel) { break }
            Set-Status "Converting $($done + 1) of $total to $($Format.ToUpper())`r`n$([IO.Path]::GetFileName($f))"
            $err = Convert-One $f
            if ($err) { $failed += "$([IO.Path]::GetFileName($f)) - $err" }
            $done++
        }
        if ($script:cancel) { break }
        # Explorer starts the per-file processes in a trickle, so wait a beat
        # after an empty-looking queue before deciding the job is over.
        Set-Status 'Finishing...'
        $wait = [Diagnostics.Stopwatch]::StartNew()
        while ($wait.ElapsedMilliseconds -lt 800) { Update-Ui; Start-Sleep -Milliseconds 60 }
    }
} finally {
    Remove-Item -LiteralPath $queue -Force -ErrorAction SilentlyContinue
    if ($ui) { $ui.Close(); $ui.Dispose() }
    $worker.ReleaseMutex()
}

$msg = if ($script:cancel) { "Stopped. $done file(s) converted." }
       elseif ($failed) { "$($done - $failed.Count) of $done converted.`r`n`r`nFailed:`r`n" + ($failed -join "`r`n") }
       else { "Done. $done file(s) converted to $($Format.ToUpper()), saved next to the originals." }

if ($NoGui) { Write-Output $msg }
elseif ($failed) { [void][System.Windows.Forms.MessageBox]::Show($msg, $appName, 'OK', 'Warning') }
# ponytail: success is silent (the files just appear). Add a toast if users ask.
