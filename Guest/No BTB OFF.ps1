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

$cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$rpcs3 = [string]$cfg.rpcs3_directory
$rpcnPath = Join-Path $rpcs3 'config\rpcn.yml'
$rpcnBackup = "$rpcnPath.patras1993.no-btb.guest.bak"

if (Test-Path -LiteralPath $rpcnBackup) {
    [IO.File]::Copy($rpcnBackup, $rpcnPath, $true)
    Write-Host 'rpcn.yml: przywrocony.'
}

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsBackup = "$hostsPath.patras1993.no-btb.guest.bak"
if (Test-Path -LiteralPath $hostsBackup) {
    [IO.File]::Copy($hostsBackup, $hostsPath, $true)
    ipconfig /flushdns | Out-Null
    Write-Host 'HOSTS: przywrocony.'
}

Write-Host ''
Write-Host '=== NO-BTB GUEST: OFF ==='
Write-Host 'Pliki gry nie wymagaly przywracania.'
Write-Host 'Dla pelnego powrotu uruchom Setup Online Guest.cmd jako administrator.'
