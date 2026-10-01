$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host 'PATRAS1993 - DECRYPT TEKKEN REVOLUTION EBOOT'
Write-Host 'NPUB31250 / APP_VER 01.05'
Write-Host ''

if (Get-Process -Name 'rpcs3','rpcs3-avx2' -ErrorAction SilentlyContinue) {
    throw 'RPCS3 jest uruchomiony. Zamknij emulator i uruchom ten skrypt ponownie.'
}

$configPath = Join-Path $PSScriptRoot 'host_config.json'
if (-not (Test-Path -LiteralPath $configPath)) {
    throw 'Brak Host\host_config.json. Najpierw uruchom Host Setup.'
}

$cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$rpcs3Dir = [string]$cfg.rpcs3_directory
if (-not $rpcs3Dir) {
    throw 'Brak rpcs3_directory w host_config.json.'
}

$rpcs3Exe = Join-Path $rpcs3Dir 'rpcs3.exe'
$eboot = Join-Path $rpcs3Dir 'dev_hdd0\game\NPUB31250\USRDIR\EBOOT.BIN'
$outElf = Join-Path $rpcs3Dir 'dev_hdd0\game\NPUB31250\USRDIR\EBOOT.elf'
$rapName = 'UP0700-NPUB31250_00-TEKKENREVOLUTION.rap'
$homeDir = Join-Path $rpcs3Dir 'dev_hdd0\home'

if (-not (Test-Path -LiteralPath $rpcs3Exe)) {
    throw "Nie znaleziono rpcs3.exe: $rpcs3Exe"
}
if (-not (Test-Path -LiteralPath $eboot)) {
    throw "Nie znaleziono EBOOT.BIN: $eboot"
}

$rap = Get-ChildItem -LiteralPath $homeDir -Filter $rapName -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $rap) {
    throw "Nie znaleziono Twojego RAP-a: $rapName w $homeDir\*\exdata\"
}

Write-Host ('RPCS3: ' + $rpcs3Exe)
Write-Host ('EBOOT: ' + $eboot)
Write-Host ('RAP:   ' + $rap.FullName)
Write-Host ''

$diagDir = Join-Path $PSScriptRoot 'diagnostics'
New-Item -ItemType Directory -Path $diagDir -Force | Out-Null

if (Test-Path -LiteralPath $outElf) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $old = Join-Path $diagDir ("EBOOT-before-decrypt-$stamp.elf")
    Copy-Item -LiteralPath $outElf -Destination $old -Force
    Remove-Item -LiteralPath $outElf -Force
}

Write-Host 'Uruchamiam oficjalny decrypter RPCS3...'
Write-Host ''

$proc = Start-Process -FilePath $rpcs3Exe -ArgumentList @('--decrypt', $eboot) -Wait -PassThru
if ($proc.ExitCode -ne 0) {
    throw ('RPCS3 --decrypt zakonczyl sie kodem ' + $proc.ExitCode + '.')
}

if (-not (Test-Path -LiteralPath $outElf)) {
    throw 'RPCS3 zakonczyl prace, ale EBOOT.elf nie powstal.'
}

$target = Join-Path $diagDir 'NPUB31250_01.05_decrypted_EBOOT.elf'
Copy-Item -LiteralPath $outElf -Destination $target -Force

$hash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
$size = (Get-Item -LiteralPath $target).Length

Write-Host ''
Write-Host 'GOTOWE.'
Write-Host ('Rozmiar: ' + $size + ' bajtow')
Write-Host ('SHA256: ' + $hash)
Write-Host ('Plik do wyslania: ' + $target)
Write-Host ''
Write-Host 'Wyslij mi NPUB31250_01.05_decrypted_EBOOT.elf.'
