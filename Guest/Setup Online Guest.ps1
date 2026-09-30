$ErrorActionPreference='Stop'
Write-Host ''
Write-Host 'TEKKEN REVOLUTION ONLINE - GUEST'
$hostIp=Read-Host 'Podaj adres Tailscale hosta (np. 100.x.x.x)'
if($hostIp -notmatch '^100\.(?:[0-9]{1,3}\.){2}[0-9]{1,3}$'){throw 'Nieprawidlowy adres Tailscale.'}
$candidates=@(
  (Get-Command rpcs3.exe -ErrorAction SilentlyContinue).Source,
  (Join-Path $env:ProgramFiles 'RPCS3\rpcs3.exe'),
  (Join-Path ${env:ProgramFiles(x86)} 'RPCS3\rpcs3.exe'),
  (Join-Path $env:LOCALAPPDATA 'Programs\RPCS3\rpcs3.exe'),
  (Join-Path $env:USERPROFILE 'Downloads\rpcs3\rpcs3.exe'),
  (Join-Path $env:USERPROFILE 'Desktop\RPCS3\rpcs3.exe')
) | Where-Object {$_}
$rpcs3Exe=$candidates | Where-Object {Test-Path $_} | Select-Object -First 1
if(-not $rpcs3Exe){
  Write-Host 'Nie znaleziono RPCS3 w typowych lokalizacjach. Przeszukuję dyski lokalne.'
  $roots=Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root
  foreach($drive in $roots){
    $found=Get-ChildItem $drive -Filter 'rpcs3.exe' -File -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {$_.FullName -notmatch '\\(Windows|ProgramData)\\'} | Select-Object -First 1
    if($found){$rpcs3Exe=$found.FullName;break}
  }
}
if(-not $rpcs3Exe){throw 'Nie znaleziono rpcs3.exe.'}
$rpcs3=[IO.Path]::GetDirectoryName($rpcs3Exe)
Write-Host "Znaleziono RPCS3: $rpcs3"
$game=Join-Path $rpcs3 'dev_hdd0\game\NPUB31250\USRDIR\EBOOT.BIN'
if(-not (Test-Path $game)){throw 'Znaleziono RPCS3, ale nie znaleziono Tekken Revolution NPUB31250.'}
$hosts="$env:SystemRoot\System32\drivers\etc\hosts"
$lines=Get-Content $hosts | Where-Object {$_ -notmatch '(?i)\s+(patch|rpcn)\.tekkenbtb\.online\s*$'}
$lines += "$hostIp patch.tekkenbtb.online"
$lines += "$hostIp rpcn.tekkenbtb.online"
Set-Content $hosts $lines -Encoding ascii
ipconfig /flushdns | Out-Null
Write-Host 'GUEST GOTOWY. RPCS3 zostal znaleziony automatycznie.'
