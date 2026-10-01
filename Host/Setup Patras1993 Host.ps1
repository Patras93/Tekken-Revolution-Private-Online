$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $root
$backendDir = Join-Path $repoRoot 'local_backend'
$rpcnDir = Join-Path $repoRoot 'local_rpcn'
$rpcnExe = Join-Path $rpcnDir 'rpcn.exe'
$rpcnVersionFile = Join-Path $rpcnDir 'rpcn_version.txt'
$envFile = Join-Path $backendDir 'server_cert_thumbprint.txt'

$requiredRpcnVersion = '1.10.0'
$rpcnZipUrl = 'https://github.com/RipleyTom/rpcn/releases/download/1.10.0/rpcn-win.zip'
$rpcnZipSha256 = '439e4f08bd8485194b36fb33b6da86a21a97adda56c968c75872918cf64ea663'

function Install-Rpcn1100 {
    Write-Host "RPCN: instalacja wersji $requiredRpcnVersion (protocol 32)."
    Write-Host 'RPCN: pobieranie oficjalnego rpcn-win.zip...'

    $tmpRoot = Join-Path $env:TEMP ('Patras1993-RPCN-' + [guid]::NewGuid().ToString('N'))
    $zip = Join-Path $tmpRoot 'rpcn-win.zip'
    $unpack = Join-Path $tmpRoot 'unpack'
    New-Item -ItemType Directory -Path $tmpRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $unpack -Force | Out-Null

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $rpcnZipUrl -OutFile $zip -UseBasicParsing

        $hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($hash -ne $rpcnZipSha256) {
            throw "Bledny SHA256 rpcn-win.zip: $hash"
        }

        Expand-Archive -LiteralPath $zip -DestinationPath $unpack -Force
        $newExe = Get-ChildItem -LiteralPath $unpack -Filter 'rpcn.exe' -File -Recurse | Select-Object -First 1
        if (-not $newExe) {
            throw 'Nie znaleziono rpcn.exe w oficjalnym archiwum RPCN 1.10.0.'
        }

        New-Item -ItemType Directory -Path $rpcnDir -Force | Out-Null

        $runningRpcn = Get-CimInstance Win32_Process -Filter "Name='rpcn.exe'" -ErrorAction SilentlyContinue | Where-Object {
            $_.ExecutablePath -and ([IO.Path]::GetFullPath($_.ExecutablePath) -eq [IO.Path]::GetFullPath($rpcnExe))
        }
        foreach ($proc in $runningRpcn) {
            Write-Host "RPCN: zatrzymywanie starej instancji PID $($proc.ProcessId)..."
            Stop-Process -Id $proc.ProcessId -Force -ErrorAction Stop
        }

        if (Test-Path -LiteralPath $rpcnExe) {
            $backup = Join-Path $rpcnDir 'rpcn.exe.before-1.10.0.bak'
            Copy-Item -LiteralPath $rpcnExe -Destination $backup -Force
        }

        Copy-Item -LiteralPath $newExe.FullName -Destination $rpcnExe -Force
        [IO.File]::WriteAllText($rpcnVersionFile, $requiredRpcnVersion, [Text.UTF8Encoding]::new($false))
    }
    finally {
        Remove-Item -LiteralPath $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    if (-not (Test-Path -LiteralPath $rpcnExe)) {
        throw 'Brak rpcn.exe po instalacji.'
    }
    if ((Get-Content -LiteralPath $rpcnVersionFile -Raw).Trim() -ne $requiredRpcnVersion) {
        throw 'Nie udalo sie zapisac informacji o wersji RPCN.'
    }

    Write-Host "RPCN: $requiredRpcnVersion gotowy (protocol 32)."
}

$currentRpcn = $null
if (Test-Path -LiteralPath $rpcnVersionFile) {
    $currentRpcn = (Get-Content -LiteralPath $rpcnVersionFile -Raw).Trim()
}

if (-not (Test-Path -LiteralPath $rpcnExe) -or $currentRpcn -ne $requiredRpcnVersion) {
    Write-Host "RPCN: zapis wersji: $currentRpcn"
    Install-Rpcn1100
}
else {
    Write-Host "RPCN: $currentRpcn OK (protocol 32)."
}

$subject = 'CN=patch.tekkenbtb.online'
$cert = Get-ChildItem 'Cert:\CurrentUser\My' | Where-Object {
    $_.Subject -eq $subject -and $_.HasPrivateKey -and $_.NotAfter -gt (Get-Date)
} | Sort-Object NotAfter -Descending | Select-Object -First 1

if (-not $cert) {
    $cert = New-SelfSignedCertificate -DnsName 'patch.tekkenbtb.online' -CertStoreLocation 'Cert:\CurrentUser\My' -FriendlyName 'Patras1993 Tekken Revolution Backend' -NotAfter (Get-Date).AddYears(5)
}

$thumb = $cert.Thumbprint.ToUpperInvariant()
[IO.File]::WriteAllText($envFile, $thumb, [Text.UTF8Encoding]::new($false))

New-NetFirewallRule -DisplayName 'Patras1993 Tekken Revolution HTTPS' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 443 -Profile Any -ErrorAction SilentlyContinue | Out-Null
New-NetFirewallRule -DisplayName 'Patras1993 RPCN TCP' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 31313 -Profile Any -ErrorAction SilentlyContinue | Out-Null
New-NetFirewallRule -DisplayName 'Patras1993 RPCN UDP' -Direction Inbound -Action Allow -Protocol UDP -LocalPort 3657 -Profile Any -ErrorAction SilentlyContinue | Out-Null

Write-Host "Certyfikat: $thumb"
Write-Host "Plik certyfikatu: $envFile"
Write-Host 'TCP 443: OK'
Write-Host 'TCP 31313: OK'
Write-Host 'UDP 3657: OK'
Write-Host 'BTB Launcher nie jest instalowany ani uruchamiany.'
Write-Host 'PATRAS1993 HOST SETUP GOTOWY.'
