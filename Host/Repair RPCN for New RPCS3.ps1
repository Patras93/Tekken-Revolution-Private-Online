$ErrorActionPreference = 'Stop'
$hostDir = $PSScriptRoot
$root = Split-Path -Parent $hostDir
$dir = Join-Path $root 'local_rpcn'
$exe = Join-Path $dir 'rpcn.exe'
$expectedHash = 'fd2fb79056ce228b4f26cf6597e7f8d8bfec044565e6ffe1e87f324de9219b2e'
$url = 'https://github.com/RipleyTom/rpcn/releases/download/1.12.1/rpcn-win.zip'
$tmp = Join-Path $env:TEMP ('rpcn-repair-' + [guid]::NewGuid().ToString('N'))
$unpack = Join-Path $tmp 'extract'
New-Item -ItemType Directory -Path $unpack -Force | Out-Null
try {
  $listeners = @(Get-NetTCPConnection -State Listen -LocalPort 31313 -ErrorAction SilentlyContinue)
  foreach ($listener in $listeners) {
    $proc = Get-CimInstance Win32_Process -Filter ("ProcessId=" + $listener.OwningProcess) -ErrorAction SilentlyContinue
    if (-not $proc -or -not $proc.ExecutablePath) { throw "Nie mozna ustalic procesu na porcie 31313 (PID $($listener.OwningProcess))." }
    if ([IO.Path]::GetFileName($proc.ExecutablePath) -ine 'rpcn.exe') { throw "Port 31313 zajety przez inny program: $($proc.ExecutablePath)" }
    Write-Host "Zatrzymywanie starego RPCN: PID $($listener.OwningProcess) / $($proc.ExecutablePath)"
    Stop-Process -Id $listener.OwningProcess -Force -ErrorAction Stop
  }
  Write-Host 'Pobieranie RPCN 1.12.1...'
  $zip = Join-Path $tmp 'rpcn-win.zip'
  Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
  $actualHash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($actualHash -ne $expectedHash) { throw "SHA256 niezgodny: $actualHash. Nie zmieniono pliku serwera." }
  Expand-Archive -LiteralPath $zip -DestinationPath $unpack -Force
  $newExe = Get-ChildItem -LiteralPath $unpack -Filter rpcn.exe -Recurse -File | Select-Object -First 1
  if (-not $newExe) { throw 'Brak rpcn.exe w archiwum.' }
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  if (Test-Path -LiteralPath $exe) {
    $backup = Join-Path $dir ('rpcn.exe.backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    Copy-Item -LiteralPath $exe -Destination $backup -Force
    Write-Host "Kopia starego exe: $backup"
  }
  Copy-Item -LiteralPath $newExe.FullName -Destination $exe -Force
  [IO.File]::WriteAllText((Join-Path $dir 'rpcn_version.txt'),'1.12.1',[Text.UTF8Encoding]::new($false))
  Write-Host 'Serwer RPCN 1.12.1 wgrany. Baza kont, certyfikaty i klucze zostaly zachowane.'
  Write-Host 'Uruchom teraz Host\Start Patras1993 Host.cmd z aktualnego repozytorium.'
} finally {
  Remove-Item -LiteralPath $tmp -Force -Recurse -ErrorAction SilentlyContinue
}
