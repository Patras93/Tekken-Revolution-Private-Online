$ErrorActionPreference = 'Stop'

$hostDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $hostDir 'host_config.json'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Uruchom No BTB OFF.cmd jako administrator.'
}
if (Get-Process rpcs3 -ErrorAction SilentlyContinue) {
    throw 'RPCS3 jest uruchomiony. Zamknij emulator i uruchom No BTB OFF.cmd ponownie.'
}
if (-not (Test-Path -LiteralPath $configPath)) { throw 'Brak host_config.json.' }

$cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$rpcs3 = [string]$cfg.rpcs3_directory
$rpcnPath = Join-Path $rpcs3 'config\rpcn.yml'
$rpcnBackup = "$rpcnPath.patras1993.no-btb.bak"

if (Test-Path -LiteralPath $rpcnBackup) {
    [IO.File]::Copy($rpcnBackup, $rpcnPath, $true)
    Write-Host 'rpcn.yml: przywrocony.'
}

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsBackup = "$hostsPath.patras1993.no-btb.bak"
if (Test-Path -LiteralPath $hostsBackup) {
    [IO.File]::Copy($hostsBackup, $hostsPath, $true)
    ipconfig /flushdns | Out-Null
    Write-Host 'HOSTS: przywrocony.'
}

Remove-Item -LiteralPath (Join-Path $hostDir 'no_btb_config.json') -Force -ErrorAction SilentlyContinue

Write-Host ''
Write-Host '=== NO-BTB HOST: OFF ==='
Write-Host 'Pliki gry nie wymagaly przywracania.'
Write-Host 'Dla pelnego powrotu do v2.1.1 uruchom Setup Patras1993 Host.cmd jako administrator.'
