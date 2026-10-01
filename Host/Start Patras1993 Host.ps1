$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$backend = Join-Path $repo 'local_backend\server.ps1'
$rpcnDir = Join-Path $repo 'local_rpcn'
$rpcn = Join-Path $rpcnDir 'rpcn.exe'
$rpcnCert = Join-Path $rpcnDir 'cert.pem'
$rpcnKey = Join-Path $rpcnDir 'key.pem'

Write-Host '=== PATRAS1993 HOST ==='
Write-Host "Katalog: $repo"

if (-not (Test-Path -LiteralPath $backend)) { throw "Brak: $backend" }
if (-not (Test-Path -LiteralPath $rpcn)) { throw "Brak: $rpcn" }

Push-Location $rpcnDir
try {
    $rpcnVersionText = (& $rpcn --version 2>&1 | Out-String).Trim()
}
finally {
    Pop-Location
}
if ($rpcnVersionText -notmatch '1\.10\.0') {
    throw "RPCN musi miec wersje 1.10.0 (protocol 32). Uruchom Host\\Setup Patras1993 Host.cmd jako administrator. Wykryto: $rpcnVersionText"
}
Write-Host "RPCN wersja: $rpcnVersionText (protocol 32)"

function PortOpen([int]$Port) {
    try {
        return [bool](Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction Stop)
    } catch {
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
} else {
    Write-Host 'RPCN: cert.pem/key.pem OK.'
}

if (-not (PortOpen 443)) {
    Write-Host 'Backend: uruchamianie na TCP 443...'
    Start-Process -FilePath 'powershell.exe' -WorkingDirectory $repo -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',$backend
} else {
    Write-Host 'Backend: TCP 443 juz dziala.'
}

if (-not (PortOpen 31313)) {
    Write-Host 'RPCN: uruchamianie na TCP 31313...'
    Start-Process -FilePath $rpcn -WorkingDirectory $rpcnDir -WindowStyle Normal
} else {
    Write-Host 'RPCN: TCP 31313 juz dziala.'
}

$deadline = (Get-Date).AddSeconds(15)
while ((Get-Date) -lt $deadline) {
    $https = PortOpen 443
    $rpcnTcp = PortOpen 31313
    if ($https -and $rpcnTcp) { break }
    Start-Sleep -Milliseconds 250
}

$https = PortOpen 443
$rpcnTcp = PortOpen 31313

Write-Host ''
Write-Host '=== STATUS ==='
Write-Host ("HTTPS 443 : " + ($(if($https){'OK'}else{'BLAD'})))
Write-Host ("RPCN 31313: " + ($(if($rpcnTcp){'OK'}else{'BLAD'})))
Write-Host 'RPCN UDP 3657: sprawdzany przez log RPCN.'
Write-Host ''
Write-Host 'Patras1993 Host zakonczyl start.'
if (-not $https -or -not $rpcnTcp) {
    Write-Host 'UWAGA: jeden z wymaganych portow nie nasluchuje.'
    exit 2
}
