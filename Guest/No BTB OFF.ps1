$ErrorActionPreference = 'Stop'

$configPath = Join-Path $PSScriptRoot 'guest_config.json'
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Uruchom No BTB OFF.cmd jako administrator.'
}
if (Get-Process rpcs3 -ErrorAction SilentlyContinue) {
    throw 'RPCS3 jest uruchomiony. Zamknij emulator i uruchom No BTB OFF.cmd ponownie.'
}
if (-not (Test-Path -LiteralPath $configPath)) { throw 'Brak guest_config.json.' }

$cfg=Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$rpcs3=[string]$cfg.rpcs3_directory
$gameRoot=Join-Path $rpcs3 'dev_hdd0\game\NPUB31250'

$restored=0
Get-ChildItem -LiteralPath $gameRoot -Filter '*.patras1993-no-btb.bak' -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    $original=$_.FullName.Substring(0,$_.FullName.Length-'.patras1993-no-btb.bak'.Length)
    [IO.File]::Copy($_.FullName,$original,$true)
    Write-Host "RESTORED: $original"
    $restored++
}

$hostsPath="$env:SystemRoot\System32\drivers\etc\hosts"
$hostsBackup="$hostsPath.patras1993.no-btb.guest.bak"
if(Test-Path -LiteralPath $hostsBackup){
    [IO.File]::Copy($hostsBackup,$hostsPath,$true)
    ipconfig /flushdns | Out-Null
}

Write-Host ''
Write-Host '=== NO-BTB GUEST: OFF ==='
Write-Host "Przywrocone pliki gry: $restored"
Write-Host 'Przywrocono HOSTS sprzed eksperymentu.'
Write-Host 'Dla pelnego powrotu uruchom ponownie Setup Online Guest.cmd jako administrator.'
