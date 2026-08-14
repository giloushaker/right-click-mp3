Param(
    [string]$Repo = 'right-click-mp3',
    [string]$Tag = 'v1.0.0'
)

# Pushes this folder to GitHub and tags a release. The Actions workflow builds
# and attaches Usable-Converter-Setup.exe. Needs git + gh, already authenticated.

$ErrorActionPreference = 'Stop'
foreach ($c in 'git', 'gh') {
    if (-not (Get-Command $c -ErrorAction SilentlyContinue)) { throw "$c not found." }
}

if (-not (Test-Path .git)) {
    git init -b main
    git add .
    git commit -m 'Usable Converter: right-click convert in Windows Explorer'
    gh repo create $Repo --public --source=. --remote=origin --push
} else {
    git add .
    git commit -m "Update $Tag" --allow-empty
    git push
}

git tag -a $Tag -m $Tag
git push origin $Tag

Write-Output "Tag $Tag pushed. Watch the build: gh run watch"
Write-Output "Then turn on GitHub Pages: Settings -> Pages -> Deploy from branch -> main / docs"
