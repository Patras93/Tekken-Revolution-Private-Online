$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$rpcnDir = Join-Path $repo 'local_rpcn'
$rpcn = Join-Path $rpcnDir 'rpcn.exe'
$rpcnVersionFile = Join-Path $rpcnDir 'rpcn_version.txt'
$rpcnCert = Join-Path $rpcnDir 'cert.pem'
$rpcnKey = Join-Path $rpcnDir 'key.pem'
$requiredRpcnVersion = '1.10.0'
$logDir = Join-Path $PSScriptRoot 'logs'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$rpcnOutLog = Join-Path $logDir 'rpcn.out.log'
$rpcnErrLog = Join-Path $logDir 'rpcn.err.log'

function Get-RpcnActualVersion {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $tmp=Join-Path $env:TEMP ('Patras1993-RPCN-Version-'+[guid]::NewGuid().ToString('N'))
    $out=Join-Path $tmp 'stdout.txt'; $err=Join-Path $tmp 'stderr.txt'
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    try {
        $p=Start-Process -FilePath $Path -WorkingDirectory $tmp -ArgumentList '--cert-gen' -PassThru -WindowStyle Hidden -RedirectStandardOutput $out -RedirectStandardError $err
        if(-not $p.WaitForExit(8000)){try{Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue}catch{}}
        $text=''
        if(Test-Path $out){$text+=[IO.File]::ReadAllText($out)}
        if(Test-Path $err){$text+=[Environment]::NewLine+[IO.File]::ReadAllText($err)}
        $m=[regex]::Match($text,'RPCN\s+v(?<v>[0-9]+\.[0-9]+\.[0-9]+)','IgnoreCase')
        if($m.Success){return $m.Groups['v'].Value}
        return $null
    } finally { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }
}

function TcpPortOpen([int]$Port) {
    try { return [bool](Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction Stop) } catch { return $false }
}
function UdpPortOpen([int]$Port) {
    try { return [bool](Get-NetUDPEndpoint -LocalPort $Port -ErrorAction Stop) } catch { return $false }
}

Write-Host '=== PATRAS1993 HOST v2.2.0 ==='
Write-Host "Katalog: $repo"

$tailscaleCmd=Get-Command tailscale.exe -ErrorAction SilentlyContinue
if($tailscaleCmd){
    $tailscaleIp=(& $tailscaleCmd.Source ip -4 2>$null | Select-Object -First 1)
    if($tailscaleIp){Write-Host "Tailscale IPv4: $tailscaleIp"}else{Write-Host 'Tailscale IPv4: BRAK'}
}else{Write-Host 'Tailscale: nie znaleziono tailscale.exe.'}

if(-not(Test-Path -LiteralPath $rpcn)){throw "Brak: $rpcn"}
$actual=Get-RpcnActualVersion -Path $rpcn
if($actual -ne $requiredRpcnVersion){
    throw "RPCN rzeczywisty to v$actual, wymagany v$requiredRpcnVersion. Uruchom Setup Patras1993 Host.cmd jako administrator."
}
[IO.File]::WriteAllText($rpcnVersionFile,$actual,[Text.UTF8Encoding]::new($false))
Write-Host "RPCN rzeczywista wersja: $actual (protocol 32)"

if(-not(Test-Path $rpcnCert) -or -not(Test-Path $rpcnKey)){
    Write-Host 'RPCN: generowanie cert.pem/key.pem...'
    $p=Start-Process -FilePath $rpcn -WorkingDirectory $rpcnDir -ArgumentList '--cert-gen' -Wait -PassThru -NoNewWindow
    if($p.ExitCode -ne 0 -or -not(Test-Path $rpcnCert) -or -not(Test-Path $rpcnKey)){throw 'Nie udalo sie wygenerowac certyfikatu RPCN.'}
}

$tcp=TcpPortOpen 31313
$udp=UdpPortOpen 3657
if(-not $tcp){
    if($udp){throw 'UDP 3657 jest zajety, ale TCP 31313 nie nasluchuje. Zatrzymaj stary RPCN.'}
    Write-Host 'RPCN: uruchamianie TCP 31313 / UDP 3657...'
    Start-Process -FilePath $rpcn -WorkingDirectory $rpcnDir -WindowStyle Hidden -RedirectStandardOutput $rpcnOutLog -RedirectStandardError $rpcnErrLog
}else{
    Write-Host 'RPCN: TCP 31313 juz dziala.'
}

$deadline=(Get-Date).AddSeconds(15)
while((Get-Date)-lt $deadline){
    $tcp=TcpPortOpen 31313; $udp=UdpPortOpen 3657
    if($tcp -and $udp){break}
    Start-Sleep -Milliseconds 250
}

$tcp=TcpPortOpen 31313; $udp=UdpPortOpen 3657
Write-Host ''
Write-Host '=== STATUS ==='
Write-Host ('RPCN TCP 31313: '+$(if($tcp){'OK'}else{'BLAD'}))
Write-Host ('RPCN UDP 3657 : '+$(if($udp){'OK'}else{'BLAD'}))
Write-Host 'Backend HTTPS 443: NIEPOTRZEBNY'
Write-Host ''
Write-Host 'Patras1993 Host v2.2.0 uruchomiony.'
Write-Host 'Architektura: RPCN DIRECT + Tailscale.'
Write-Host ('Logi: '+$logDir)

if(-not $tcp -or -not $udp){exit 2}
