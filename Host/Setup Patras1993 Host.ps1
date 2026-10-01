$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $root
$backendDir = Join-Path $repoRoot 'local_backend'
$rpcnDir = Join-Path $repoRoot 'local_rpcn'
$rpcnExe = Join-Path $rpcnDir 'rpcn.exe'
$rpcnVersionFile = Join-Path $rpcnDir 'rpcn_version.txt'
$envFile = Join-Path $backendDir 'server_cert_thumbprint.txt'
$hookSource = Join-Path $backendDir 'version.dll.original'
$hostConfigFile = Join-Path $root 'host_config.json'
$preferredRpcs3 = 'E:\instalacje gier\rpcs3-v0.0.43-20146-4d88114c_win64\rpcs3.exe'

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


if (-not (Test-Path -LiteralPath $hookSource)) {
    throw "Brak hooka Patras1993: $hookSource"
}

$candidates = @(
    $preferredRpcs3,
    (Get-Command rpcs3.exe -ErrorAction SilentlyContinue).Source,
    (Join-Path $env:ProgramFiles 'RPCS3\rpcs3.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\RPCS3\rpcs3.exe')
) | Where-Object { $_ }

$rpcs3Exe = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $rpcs3Exe) {
    Write-Host 'RPCS3: nie znaleziono w typowych lokalizacjach. Przeszukuje dyski lokalne...'
    foreach ($drive in (Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root)) {
        $found = Get-ChildItem -LiteralPath $drive -Filter 'rpcs3.exe' -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\\(Windows|ProgramData)\\' } |
            Select-Object -First 1
        if ($found) { $rpcs3Exe = $found.FullName; break }
    }
}
if (-not $rpcs3Exe) { throw 'Nie znaleziono rpcs3.exe.' }

$rpcs3Dir = Split-Path -Parent $rpcs3Exe
$gameEboot = Join-Path $rpcs3Dir 'dev_hdd0\game\NPUB31250\USRDIR\EBOOT.BIN'
if (-not (Test-Path -LiteralPath $gameEboot)) {
    throw "Znaleziono RPCS3, ale nie znaleziono Tekken Revolution NPUB31250: $gameEboot"
}

@{
    rpcs3_directory = $rpcs3Dir
    rpcs3_exe = $rpcs3Exe
    game = 'NPUB31250'
} | ConvertTo-Json | Set-Content -LiteralPath $hostConfigFile -Encoding utf8

$hookTarget = Join-Path $rpcs3Dir 'version.dll'
$sourceHash = (Get-FileHash -LiteralPath $hookSource -Algorithm SHA256).Hash
$targetHash = if (Test-Path -LiteralPath $hookTarget) { (Get-FileHash -LiteralPath $hookTarget -Algorithm SHA256).Hash } else { $null }

if ($targetHash -ne $sourceHash) {
    $runningRpcs3 = Get-Process rpcs3 -ErrorAction SilentlyContinue
    if ($runningRpcs3) {
        Write-Host 'RPCS3: zamykanie przed instalacja hooka...'
        $runningRpcs3 | Stop-Process -Force
        Start-Sleep -Milliseconds 500
    }

    if (Test-Path -LiteralPath $hookTarget) {
        $backup = Join-Path $rpcs3Dir 'version.dll.pre-patras1993.bak'
        if (-not (Test-Path -LiteralPath $backup)) {
            Copy-Item -LiteralPath $hookTarget -Destination $backup -Force
            Write-Host "Hook: kopia starego version.dll -> $backup"
        }
    }

    Copy-Item -LiteralPath $hookSource -Destination $hookTarget -Force
    Write-Host "Hook: zainstalowany -> $hookTarget"
}
else {
    Write-Host 'Hook: version.dll Patras1993 juz zainstalowany.'
}

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostLines = Get-Content -LiteralPath $hostsPath -ErrorAction Stop |
    Where-Object { $_ -notmatch '(?i)\s+(patch|rpcn)\.tekkenbtb\.online\s*$' }

$hostLines += '127.0.0.1 patch.tekkenbtb.online'
$hostLines += '127.0.0.1 rpcn.tekkenbtb.online'

Set-Content -LiteralPath $hostsPath -Value $hostLines -Encoding ASCII
ipconfig /flushdns | Out-Null
Write-Host 'HOSTS: patch/rpcn.tekkenbtb.online -> 127.0.0.1'

$subject = 'CN=patch.tekkenbtb.online'
$cert = Get-ChildItem 'Cert:\CurrentUser\My' |
    Where-Object {
        $_.Subject -eq $subject -and
        $_.HasPrivateKey -and
        $_.NotAfter -gt (Get-Date)
    } |
    Sort-Object NotAfter -Descending |
    Select-Object -First 1

if (-not $cert) {
    $certParams = @{
        DnsName = 'patch.tekkenbtb.online'
        CertStoreLocation = 'Cert:\CurrentUser\My'
        FriendlyName = 'Patras1993 Tekken Revolution Backend'
        NotAfter = (Get-Date).AddYears(5)
    }
    $cert = New-SelfSignedCertificate @certParams
}

$thumb = $cert.Thumbprint.ToUpperInvariant()
[IO.File]::WriteAllText($envFile, $thumb, (New-Object System.Text.UTF8Encoding($false)))

$trusted = Get-ChildItem 'Cert:\CurrentUser\Root' |
    Where-Object { $_.Thumbprint -eq $thumb } |
    Select-Object -First 1

if (-not $trusted) {
    $tmpCert = Join-Path $env:TEMP 'patras1993-backend.cer'
    try {
        Export-Certificate -Cert $cert -FilePath $tmpCert -Force | Out-Null
        Import-Certificate -FilePath $tmpCert -CertStoreLocation 'Cert:\CurrentUser\Root' | Out-Null
        Write-Host 'Certyfikat backendu: dodany do zaufanych glownych urzedow biezacego uzytkownika.'
    }
    finally {
        Remove-Item -LiteralPath $tmpCert -Force -ErrorAction SilentlyContinue
    }
}
else {
    Write-Host 'Certyfikat backendu: juz zaufany.'
}

New-NetFirewallRule -DisplayName 'Patras1993 Tekken Revolution HTTPS' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 443 -Profile Any -ErrorAction SilentlyContinue | Out-Null
New-NetFirewallRule -DisplayName 'Patras1993 RPCN TCP' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 31313 -Profile Any -ErrorAction SilentlyContinue | Out-Null
New-NetFirewallRule -DisplayName 'Patras1993 RPCN UDP' -Direction Inbound -Action Allow -Protocol UDP -LocalPort 3657 -Profile Any -ErrorAction SilentlyContinue | Out-Null

Write-Host "Certyfikat: $thumb"
Write-Host "Plik certyfikatu: $envFile"
Write-Host 'TCP 443: OK'
Write-Host 'TCP 31313: OK'
Write-Host 'UDP 3657: OK'
Write-Host "RPCS3: $rpcs3Exe"
Write-Host "Hook: $hookTarget"
Write-Host "Tekken Revolution: $gameEboot"
Write-Host 'BTB Launcher nie jest instalowany ani uruchamiany.'
Write-Host 'PATRAS1993 HOST SETUP GOTOWY.'
