Param(
    [string]$Out = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) 'docs')
)

# Renders site/template.html once per language in site/i18n into docs/.
# English is the root page; every other language gets docs/<code>/index.html.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$site = Join-Path $root 'site'
$template = Get-Content -LiteralPath (Join-Path $site 'template.html') -Raw -Encoding UTF8
$base = 'https://giloushaker.github.io/right-click-mp3/'

$order = 'en', 'fr', 'es', 'de', 'it', 'pt', 'nl', 'pl', 'ru', 'tr', 'ja', 'zh', 'ar'
$langs = [ordered]@{}
foreach ($code in $order) {
    $langs[$code] = Get-Content -LiteralPath (Join-Path $site "i18n\$code.json") -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Get-Path($code) { if ($code -eq 'en') { '' } else { "$code/" } }

# hreflang tags let Google serve the right language for the same page
$alternates = ($order | ForEach-Object {
    "<link rel=`"alternate`" hreflang=`"$_`" href=`"$base$(Get-Path $_)`">"
}) -join "`n"
$alternates += "`n<link rel=`"alternate`" hreflang=`"x-default`" href=`"$base`">"

foreach ($code in $order) {
    $t = $langs[$code]

    $switcher = ($order | ForEach-Object {
        $current = if ($_ -eq $code) { ' aria-current="page"' } else { '' }
        "<a href=`"$base$(Get-Path $_)`" lang=`"$_`"$current>$($langs[$_].name)</a>"
    }) -join "`n"

    $html = $template
    foreach ($key in $t.PSObject.Properties.Name) {
        $html = $html.Replace("{{$key}}", [string]$t.$key)
    }
    $html = $html.Replace('{{lang}}', $code).
                  Replace('{{dir}}', $(if ($t.dir) { $t.dir } else { 'ltr' })).
                  Replace('{{path}}', (Get-Path $code)).
                  Replace('{{alternates}}', $alternates).
                  Replace('{{switcher}}', $switcher)

    if ($html -match '\{\{(\w+)\}\}') {
        throw "$code.json is missing a value for {{$($Matches[1])}}"
    }

    $dir = if ($code -eq 'en') { $Out } else { Join-Path $Out $code }
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $dir 'index.html'), $html, (New-Object Text.UTF8Encoding($false)))
    Write-Output "wrote $((Get-Path $code))index.html"
}

$urls = ($order | ForEach-Object { "  <url><loc>$base$(Get-Path $_)</loc></url>" }) -join "`n"
@"
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
$urls
</urlset>
"@ | Set-Content -LiteralPath (Join-Path $Out 'sitemap.xml') -Encoding utf8

"User-agent: *`nAllow: /`nSitemap: ${base}sitemap.xml" |
    Set-Content -LiteralPath (Join-Path $Out 'robots.txt') -Encoding utf8

Write-Output 'wrote sitemap.xml and robots.txt'
