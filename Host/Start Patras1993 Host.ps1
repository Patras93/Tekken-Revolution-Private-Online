$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$backend = Join-Path $repo 'local_backend\server.ps1'
$rpcnDir = Join-Path $repo 'local_rpcn'
$rpcn = Join-Path $rpcnDir 'rpcn.exe'
$rpcnVersionFile = Join-Path $rpcnDir 'rpcn_version.txt'
$rpcnCert = Join-Path $rpcnDir 'cert.pem'
$rpcnKey = Join-Path $rpcnDir 'key.pem'
$requiredRpcnVersion = '1.10.0'
$logDir = Join-Path $PSScriptRoot 'logs'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$backendOutLog = Join-Path $logDir 'backend.out.log'
$backendErrLog = Join-Path $logDir 'backend.err.log'
$rpcnOutLog = Join-Path $logDir 'rpcn.out.log'
$rpcnErrLog = Join-Path $logDir 'rpcn.err.log'

Write-Host '=== PATRAS1993 HOST ==='
Write-Host "Katalog: $repo"

if (-not (Test-Path -LiteralPath $backend)) { throw "Brak: $backend" }
if (-not (Test-Path -LiteralPath $rpcn)) { throw "Brak: $rpcn" }
if (-not (Test-Path -LiteralPath $rpcnVersionFile)) {
    throw 'Brak local_rpcn\rpcn_version.txt. Uruchom Host\Setup Patras1993 Host.cmd jako administrator.'
}

$rpcnVersion = (Get-Content -LiteralPath $rpcnVersionFile -Raw).Trim()
if ($rpcnVersion -ne $requiredRpcnVersion) {
    throw "RPCN musi miec wersje $requiredRpcnVersion (protocol 32). Uruchom Host\Setup Patras1993 Host.cmd jako administrator. Zapisana wersja: $rpcnVersion"
}
Write-Host "RPCN wersja: $rpcnVersion (protocol 32)"

function TcpPortOpen([int]$Port) {
    try {
        return [bool](Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction Stop)
    }
    catch {
        return $false
    }
}

function UdpPortOpen([int]$Port) {
    try {
        return [bool](Get-NetUDPEndpoint -LocalPort $Port -ErrorAction Stop)
    }
    catch {
        return $false
    }
}

if (-not (Test-Path -LiteralPath $rpcnCert) -or -not (Test-Path -LiteralPath $rpcnKey)) {
    Write-Host 'RPCN: brak cert.pem/key.pem - generowanie...'
    $p = Start-Process -FilePath $rpcn -WorkingDirectory $rpcnDir -ArgumentList '--cert-gen' -Wait -PassThru -NoNewWindow
    if ($p.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $rpcnCert) -or -not (Test-Path -LiteralPath $rpcnKey)) {
        throw 'Nie udalo sie wygenerowac cert.pem/key.pem RPCN.'
    }
    Write-Host 'RPCN: certyfikat wygenerowany.'
}
else {
    Write-Host 'RPCN: cert.pem/key.pem OK.'
}

if (-not (TcpPortOpen 443)) {
    Write-Host 'Backend: uruchamianie w tle na TCP 443...'
    Start-Process -FilePath 'powershell.exe' -WorkingDirectory $repo -WindowStyle Hidden -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',$backend -RedirectStandardOutput $backendOutLog -RedirectStandardError $backendErrLog
}
else {
    Write-Host 'Backend: TCP 443 juz dziala.'
}

$rpcnTcpBefore = TcpPortOpen 31313
$rpcnUdpBefore = UdpPortOpen 3657

if (-not $rpcnTcpBefore) {
    if ($rpcnUdpBefore) {
        throw 'UDP 3657 jest juz zajety, ale TCP 31313 nie nasluchuje. Zamknij stary proces RPCN i uruchom Host ponownie.'
    }

    Write-Host 'RPCN: uruchamianie w tle TCP 31313 / UDP 3657...'
    Start-Process -FilePath $rpcn -WorkingDirectory $rpcnDir -WindowStyle Hidden -RedirectStandardOutput $rpcnOutLog -RedirectStandardError $rpcnErrLog
}
else {
    Write-Host 'RPCN: TCP 31313 juz dziala.'
}

$deadline = (Get-Date).AddSeconds(15)
while ((Get-Date) -lt $deadline) {
    $https = TcpPortOpen 443
    $rpcnTcp = TcpPortOpen 31313
    $rpcnUdp = UdpPortOpen 3657
    if ($https -and $rpcnTcp -and $rpcnUdp) { break }
    Start-Sleep -Milliseconds 250
}

$https = TcpPortOpen 443
$rpcnTcp = TcpPortOpen 31313
$rpcnUdp = UdpPortOpen 3657

Write-Host ''
Write-Host '=== STATUS ==='
Write-Host ("HTTPS TCP 443 : " + ($(if($https){'OK'}else{'BLAD'})))
Write-Host ("RPCN TCP 31313: " + ($(if($rpcnTcp){'OK'}else{'BLAD'})))
Write-Host ("RPCN UDP 3657 : " + ($(if($rpcnUdp){'OK'}else{'BLAD'})))
Write-Host ''
Write-Host 'Patras1993 Host zakonczyl start.'
Write-Host 'Backend i RPCN dzialaja w tle bez dodatkowych okien.'
Write-Host ('Logi: ' + $logDir)

if (-not $https -or -not $rpcnTcp -or -not $rpcnUdp) {
    Write-Host 'UWAGA: jeden z wymaganych portow nie nasluchuje.'
    exit 2
}
