# Script que vigila cambios en archivos y hace auto-push automáticamente
# Uso: powershell -File .claude/auto-watch.ps1
# Presiona Ctrl+C para detener

$carpeta = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$repo = $carpeta

Write-Host "🔍 Vigilando cambios en: $repo"
Write-Host "⏹️  Presiona Ctrl+C para detener`n"

# Crear FileSystemWatcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $repo
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# Filtrar archivos a vigilar (excluir .git y node_modules)
$watcher.Filter = "*"

# Variable para evitar múltiples eventos
$ultimaActualizacion = Get-Date
$retardo = 2  # segundos de espera antes de hacer commit

# Acción cuando se detecta cambio
$action = {
    $tiempo = (Get-Date).ToString("HH:mm:ss")
    $archivo = $Event.SourceEventArgs.Name

    # Evitar archivos del sistema y .git
    if ($archivo -match '\\\.git|node_modules|\.vs') {
        return
    }

    # Evitar múltiples eventos en corto tiempo
    if ((Get-Date) - $ultimaActualizacion -lt [TimeSpan]::FromSeconds($retardo)) {
        return
    }

    Set-Variable -Name ultimaActualizacion -Value (Get-Date) -Scope Global

    Write-Host "[$tiempo] 📝 Cambio detectado: $archivo" -ForegroundColor Cyan

    # Esperar un poco para que se complete la escritura
    Start-Sleep -Seconds 1

    # Cambiar a la carpeta del repo
    Push-Location $repo

    try {
        # Verificar si hay cambios
        $cambios = git status --porcelain 2>$null

        if ($cambios) {
            Write-Host "[$tiempo] ⏳ Realizando commit..." -ForegroundColor Yellow

            # Agregar cambios
            git add -A 2>$null

            # Crear commit con timestamp
            $mensaje = "Auto: cambios $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            git commit -m $mensaje 2>$null

            if ($?) {
                Write-Host "[$tiempo] 📤 Enviando a GitHub..." -ForegroundColor Yellow
                git push origin main 2>$null

                if ($?) {
                    Write-Host "[$tiempo] ✅ Publicado en GitHub y Vercel" -ForegroundColor Green
                } else {
                    Write-Host "[$tiempo] ⚠️  Error al hacer push" -ForegroundColor Red
                }
            }
        }
    } catch {
        Write-Host "[$tiempo] ❌ Error: $_" -ForegroundColor Red
    } finally {
        Pop-Location
    }
}

# Registrar eventos
Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $action | Out-Null
Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $action | Out-Null

# Mantener el script corriendo
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
} catch {
    Write-Host "`n⏹️  Script detenido"
} finally {
    $watcher.Dispose()
}
