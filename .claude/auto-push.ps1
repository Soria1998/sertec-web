# Hace commit y push automático de los cambios pendientes (lo ejecuta el hook Stop de Claude Code)
$ErrorActionPreference = 'Stop'
$git = 'C:\Program Files\Git\cmd\git.exe'
if (-not (Test-Path $git)) { $git = 'git' }

$dir = $env:CLAUDE_PROJECT_DIR
if (-not $dir) { $dir = Split-Path -Parent $PSScriptRoot }
Set-Location $dir

$changes = & $git status --porcelain
if (-not $changes) { exit 0 }

& $git add -A
& $git commit -q -m "Auto: cambios $(Get-Date -Format 'yyyy-MM-dd HH:mm')"

$remote = & $git remote
if ($remote) {
    & $git push -q origin HEAD 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Output '{"systemMessage": "Auto-push: commit hecho, pero no se pudo subir a GitHub."}'
        exit 0
    }
    Write-Output '{"systemMessage": "Cambios subidos a GitHub."}'
}
