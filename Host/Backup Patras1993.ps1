$ErrorActionPreference = 'Stop'

$hostDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $hostDir
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $repoRoot 'Backups'
$stage = Join-Path $env:TEMP ('Patras1993-Backup-' + [guid]::NewGuid().ToString('N'))
$zip = Join-Path $backupRoot ("Patras1993-Full-Backup-$timestamp.zip")

Write-Host '=== PATRAS1993 FULL BACKUP ==='
Write-Host ''

New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
New-Item -ItemType Directory -Path $stage -Force | Out-Null

try {
    # Zatrzymaj tylko procesy naszego hosta, jesli sa aktywne.
    $stopScript = Join-Path $hostDir 'Stop Patras1993 Host.ps1'
    if (Test-Path -LiteralPath $stopScript) {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $stopScript | Out-Host
        Start-Sleep -Milliseconds 500
    }

    foreach ($name in @('Host','local_backend','local_rpcn','local_patch')) {
        $src = Join-Path $repoRoot $name
        if (Test-Path -LiteralPath $src) {
            Copy-Item -LiteralPath $src -Destination (Join-Path $stage $name) -Recurse -Force
        }
    }

    # Usuń z kopii rzeczy odtwarzalne / niepotrzebne.
    Remove-Item -LiteralPath (Join-Path $stage 'Host\logs') -Recurse -Force -ErrorAction SilentlyContinue

    # Zachowaj najważniejsze ustawienia RPCS3 i dane użytkownika.
    $hostConfig = Join-Path $hostDir 'host_config.json'
    $rpcs3Dir = $null
    if (Test-Path -LiteralPath $hostConfig) {
        $cfg = Get-Content -LiteralPath $hostConfig -Raw | ConvertFrom-Json
        $rpcs3Dir = [string]$cfg.rpcs3_directory
    }

    if ($rpcs3Dir -and (Test-Path -LiteralPath $rpcs3Dir)) {
        $rpcs3Backup = Join-Path $stage 'RPCS3_STATE'
        New-Item -ItemType Directory -Path $rpcs3Backup -Force | Out-Null

        foreach ($rel in @(
            'config\rpcn.yml',
            'config\patch_config.yml',
            'config\config_NPUB31250.yml',
            'patches\NPUB31250_patch.yml'
        )) {
            $src = Join-Path $rpcs3Dir $rel
            if (Test-Path -LiteralPath $src) {
                $dst = Join-Path $rpcs3Backup $rel
                New-Item -ItemType Directory -Path (Split-Path -Parent $dst) -Force | Out-Null
                Copy-Item -LiteralPath $src -Destination $dst -Force
            }
        }

        $rpcs3HomeDir = Join-Path $rpcs3Dir 'dev_hdd0\home'
        if (Test-Path -LiteralPath $rpcs3HomeDir) {
            $homeParent = Join-Path $rpcs3Backup 'dev_hdd0'
            New-Item -ItemType Directory -Path $homeParent -Force | Out-Null
            Copy-Item -LiteralPath $rpcs3HomeDir -Destination $homeParent -Recurse -Force
        }
    }

    # Eksport certyfikatu backendu z kluczem prywatnym.
    $thumbFile = Join-Path $repoRoot 'local_backend\server_cert_thumbprint.txt'
    if (Test-Path -LiteralPath $thumbFile) {
        $thumb = (Get-Content -LiteralPath $thumbFile -Raw).Trim()
        if ($thumb) {
            $cert = Get-Item ("Cert:\CurrentUser\My\$thumb") -ErrorAction SilentlyContinue
            if ($cert -and $cert.HasPrivateKey) {
                $chars = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%*-_'
                $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
                $bytes = New-Object byte[] 32
                $rng.GetBytes($bytes)
                $password = -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
                $secure = ConvertTo-SecureString -String $password -AsPlainText -Force
                Export-PfxCertificate -Cert $cert -FilePath (Join-Path $stage 'backend-cert.pfx') -Password $secure -Force | Out-Null
                [IO.File]::WriteAllText((Join-Path $stage 'backend-cert-password.txt'), $password, [Text.UTF8Encoding]::new($false))
            }
        }
    }

    # Informacja o Tailscale - sam tailnet jest przechowywany po stronie Tailscale.
    $tailscale = Get-Command tailscale.exe -ErrorAction SilentlyContinue
    if ($tailscale) {
        try { & $tailscale.Source status --json | Set-Content -LiteralPath (Join-Path $stage 'tailscale-status.json') -Encoding utf8 } catch {}
        try { & $tailscale.Source ip -4 | Set-Content -LiteralPath (Join-Path $stage 'tailscale-ipv4.txt') -Encoding ascii } catch {}
    }

    $manifest = @"
PATRAS1993 FULL BACKUP
Data: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Wersja: v2.1.0 stable

Zawiera:
- Host i jego konfiguracje,
- caly local_rpcn (baza kont, cert.pem/key.pem i dane RPCN),
- local_backend,
- local_patch,
- najwazniejsze ustawienia RPCS3,
- dev_hdd0\home z danymi uzytkownika,
- certyfikat backendu wraz z kluczem prywatnym, jesli byl dostepny,
- informacje o aktualnym Tailscale.

Nie zawiera:
- plikow samej gry NPUB31250,
- calego RPCS3,
- danych logowania do konta Tailscale.

UWAGA:
Backup zawiera prywatne dane RPCN i klucze. Trzymaj ZIP prywatnie.
"@
    [IO.File]::WriteAllText((Join-Path $stage 'BACKUP_INFO.txt'), $manifest, [Text.UTF8Encoding]::new($false))

    Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -CompressionLevel Optimal -Force

    $hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
    Write-Host ''
    Write-Host 'BACKUP GOTOWY.'
    Write-Host "Plik: $zip"
    Write-Host "SHA256: $hash"
    Write-Host ''
    Write-Host 'Ten ZIP zawiera prywatna baze kont RPCN i klucze. Nie wysylaj go innym.'
}
finally {
    Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
}
