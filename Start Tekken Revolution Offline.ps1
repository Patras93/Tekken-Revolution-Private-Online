$ErrorActionPreference='Stop'
$root=Split-Path -Parent $MyInvocation.MyCommand.Path

# Allow the currently installed RPCS3 build.
$rpcs3Exe=Join-Path $root 'rpcs3.exe'
$launcherCfg=Join-Path $root 'local_backend\launcher_config.json'
if((Test-Path $rpcs3Exe) -and (Test-Path $launcherCfg)){
  try {
    $currentRpcs3Hash=(Get-FileHash $rpcs3Exe -Algorithm SHA256).Hash.ToLowerInvariant()
    $cfg=Get-Content -LiteralPath $launcherCfg -Raw | ConvertFrom-Json
    if($cfg.required_rpcs3_hash -ne $currentRpcs3Hash){
      $cfg.required_rpcs3_hash=$currentRpcs3Hash
      [IO.File]::WriteAllText(
        $launcherCfg,
        ($cfg | ConvertTo-Json -Depth 8 -Compress),
        [Text.UTF8Encoding]::new($false)
      )
    }
  } catch {
    Write-Host ('Nie udalo sie zaktualizowac hasha RPCS3: '+$_.Exception.Message)
  }
}

$game=Join-Path $root 'dev_hdd0\game\NPUB31250\USRDIR\EBOOT.BIN'
if(-not (Test-Path $game)){
  Write-Host ''
  Write-Host 'BRAK GRY.'
  Write-Host 'Skopiuj swoja kopie Tekken Revolution NPUB31250 do:'
  Write-Host (Join-Path $root 'dev_hdd0\game\NPUB31250')
  Write-Host ''
  Read-Host 'Nacisnij Enter'
  exit 2
}

$hosts=[IO.File]::ReadAllText("$env:SystemRoot\System32\drivers\etc\hosts")
if($hosts -notmatch '(?im)^\s*127\.0\.0\.1\s+patch\.tekkenbtb\.online' -or $hosts -notmatch '(?im)^\s*127\.0\.0\.1\s+rpcn\.tekkenbtb\.online'){
  Write-Host 'Najpierw uruchom Setup Offline.cmd jako administrator.'
  Read-Host 'Nacisnij Enter'
  exit 3
}

function PortOpen([int]$p){
  try { return [bool](Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction Stop) } catch { return $false }
}

$backend=Join-Path $root 'local_backend\server.ps1'
if(-not (PortOpen 443)){
  Start-Process powershell.exe -WindowStyle Hidden -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$backend+'"')
}

$rpcnDir=Join-Path $root 'local_rpcn'
$rpcnExe=Join-Path $rpcnDir 'rpcn.exe'
if(-not (PortOpen 31313)){
  Start-Process -FilePath $rpcnExe -WorkingDirectory $rpcnDir -WindowStyle Hidden
}
$deadline=(Get-Date).AddSeconds(8)
while((Get-Date) -lt $deadline -and ((-not (PortOpen 443)) -or (-not (PortOpen 31313)))){
  Start-Sleep -Milliseconds 250
}
if((-not (PortOpen 443)) -or (-not (PortOpen 31313))){
  Write-Host 'Nie udalo sie uruchomic lokalnego backendu albo RPCN.'
  Write-Host ('Port 443 backend: '+(PortOpen 443))
  Write-Host ('Port 31313 RPCN: '+(PortOpen 31313))
  Read-Host 'Nacisnij Enter'
  exit 4
}

Start-Process -FilePath $rpcs3Exe -ArgumentList ('"'+$game+'"') -WorkingDirectory $root
