param(
    [Parameter(Mandatory=$false)]
    [string]$BackupZip
)

$ErrorActionPreference = 'Stop'

$hostDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $hostDir

Write-Host '=== PATRAS1993 RESTORE ==='
Write-Host ''

if (-not $BackupZip) {
    $backupDir = Join-Path $repoRoot 'Backups'
    $latest = Get-ChildItem -LiteralPath $backupDir -Filter 'Patras1993-Full-Backup-*.zip' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if (-not $latest) {
        throw "Nie znaleziono backupu w: $backupDir"
    }
    $BackupZip = $latest.FullName
}

if (-not (Test-Path -LiteralPath $BackupZip)) {
    throw "Brak backupu: $BackupZip"
}

if (Get-Process rpcs3 -ErrorAction SilentlyContinue) {
    throw 'RPCS3 jest uruchomiony. Zamknij emulator przed Restore.'
}

$stopScript = Join-Path $hostDir 'Stop Patras1993 Host.ps1'
if (Test-Path -LiteralPath $stopScript) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $stopScript | Out-Host
    Start-Sleep -Milliseconds 500
}

$stage = Join-Path $env:TEMP ('Patras1993-Restore-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null

try {
    Expand-Archive -LiteralPath $BackupZip -DestinationPath $stage -Force

    foreach ($name in @('local_rpcn','local_patch')) {
        $src = Join-Path $stage $name
        if (Test-Path -LiteralPath $src) {
            $dst = Join-Path $repoRoot $name
            New-Item -ItemType Directory -Path $dst -Force | Out-Null
            Copy-Item -Path (Join-Path $src '*') -Destination $dst -Recurse -Force
        }
    }

    $srcHostConfig = Join-Path $stage 'Host\host_config.json'
    if (Test-Path -LiteralPath $srcHostConfig) {
        Copy-Item -LiteralPath $srcHostConfig -Destination (Join-Path $hostDir 'host_config.json') -Force
    }

    # RPCS3_STATE jest przywracany do sciezki zapisanej w host_config.json.
    $hostConfig = Join-Path $hostDir 'host_config.json'
    if (Test-Path -LiteralPath $hostConfig) {
        $cfg = Get-Content -LiteralPath $hostConfig -Raw | ConvertFrom-Json
        $rpcs3Dir = [string]$cfg.rpcs3_directory
        $state = Join-Path $stage 'RPCS3_STATE'
        if ($rpcs3Dir -and (Test-Path -LiteralPath $rpcs3Dir) -and (Test-Path -LiteralPath $state)) {
            Copy-Item -Path (Join-Path $state '*') -Destination $rpcs3Dir -Recurse -Force
        }
        elseif (Test-Path -LiteralPath $state) {
            Write-Host 'UWAGA: RPCS3 ma inna lub nieistniejaca sciezke. Stan RPCS3 nie zostal automatycznie skopiowany.'
        }
    }

    Write-Host ''
    Write-Host 'RESTORE GOTOWY.'
    Write-Host 'Teraz uruchom Host\Setup Patras1993 Host.cmd jako administrator, a potem Start.'
    Write-Host 'Tailscale: zaloguj komputer do tego samego tailnetu. Adres 100.x moze sie zmienic po ponownej rejestracji.'
}
finally {
    Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
}
