$ErrorActionPreference='Stop'
$repo=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$backend=Join-Path $repo 'local_backend\server.ps1'
$rpcnDir=Join-Path $repo 'local_rpcn'
$rpcn=Join-Path $rpcnDir 'rpcn.exe'

if(-not (Test-Path $backend)){throw "Brak local_backend\server.ps1"}
if(-not (Test-Path $rpcn)){throw "Brak local_rpcn\rpcn.exe"}

$rpcnCert=Join-Path $rpcnDir 'cert.pem'
if(-not (Test-Path $rpcnCert)){
  Write-Host 'Brak cert.pem RPCN - generowanie certyfikatu...'
  $p=Start-Process -FilePath $rpcn -WorkingDirectory $rpcnDir -ArgumentList '--cert-gen' -Wait -PassThru -NoNewWindow
  if($p.ExitCode -ne 0 -or -not (Test-Path $rpcnCert)){
    throw 'Nie udało się wygenerować cert.pem dla RPCN.'
  }
}

function PortOpen([int]$p){
  try { return [bool](Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction Stop) } catch { return $false }
}

if(-not (PortOpen 443)){
  Start-Process powershell.exe -WindowStyle Hidden -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$backend+'"')
}
if(-not (PortOpen 31313)){
  Start-Process -FilePath $rpcn -WorkingDirectory $rpcnDir -WindowStyle Hidden
}

$deadline=(Get-Date).AddSeconds(10)
while((Get-Date) -lt $deadline -and ((-not (PortOpen 443)) -or (-not (PortOpen 31313)))){
  Start-Sleep -Milliseconds 250
}

Write-Host "Patras1993 Host"
Write-Host ("HTTPS 443: "+(PortOpen 443))
Write-Host ("RPCN 31313: "+(PortOpen 31313))
Write-Host "Adres Tailscale hosta podasz kolezance."
if((-not (PortOpen 443)) -or (-not (PortOpen 31313))){exit 2}
