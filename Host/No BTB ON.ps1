$ErrorActionPreference = 'Stop'

$hostDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $hostDir 'host_config.json'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Uruchom No BTB ON.cmd jako administrator.'
}
if (Get-Process rpcs3 -ErrorAction SilentlyContinue) {
    throw 'RPCS3 jest uruchomiony. Zamknij emulator i uruchom No BTB ON.cmd ponownie.'
}
if (-not (Test-Path -LiteralPath $configPath)) {
    throw 'Brak host_config.json. Uruchom najpierw Setup Patras1993 Host.cmd.'
}

$cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$rpcs3 = [string]$cfg.rpcs3_directory
$rpcnPath = Join-Path $rpcs3 'config\rpcn.yml'
if (-not (Test-Path -LiteralPath $rpcnPath)) {
    throw "Brak rpcn.yml: $rpcnPath"
}

$rpcnBackup = "$rpcnPath.patras1993.no-btb.bak"
if (-not (Test-Path -LiteralPath $rpcnBackup)) {
    [IO.File]::Copy($rpcnPath, $rpcnBackup, $false)
}

$lines = @([IO.File]::ReadAllLines($rpcnPath))
$hasHost = $false
$hasHosts = $false

for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^Host:\s*') {
        $lines[$i] = 'Host: 127.0.0.1'
        $hasHost = $true
    }
    elseif ($lines[$i] -match '^Hosts:\s*') {
        $lines[$i] = 'Hosts: "Patras1993|127.0.0.1"'
        $hasHosts = $true
    }
}
if (-not $hasHost) { $lines += 'Host: 127.0.0.1' }
if (-not $hasHosts) { $lines += 'Hosts: "Patras1993|127.0.0.1"' }

[IO.File]::WriteAllLines($rpcnPath, $lines, [Text.UTF8Encoding]::new($false))

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsBackup = "$hostsPath.patras1993.no-btb.bak"
if (-not (Test-Path -LiteralPath $hostsBackup)) {
    [IO.File]::Copy($hostsPath, $hostsBackup, $false)
}

$hostLines = @([IO.File]::ReadAllLines($hostsPath) | Where-Object {
    $_ -notmatch '(?i)\s+(patch|rpcn)\.tekkenbtb\.online\s*$' -and
    $_ -notmatch '(?i)\s+(patch|rpcn)\.patras93\.invalid\s*$'
})
[IO.File]::WriteAllLines($hostsPath, $hostLines, [Text.Encoding]::ASCII)
ipconfig /flushdns | Out-Null

@{
    mode = 'NO-BTB'
    rpcn_host = '127.0.0.1'
    changed_game_files = 0
    note = 'No game patching required; BTB references existed only in RPCS3 config/rpcn.yml.'
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $hostDir 'no_btb_config.json') -Encoding UTF8

Write-Host ''
Write-Host '=== NO-BTB HOST: ON ==='
Write-Host 'Pliki gry: NIE ZMIENIONE'
Write-Host 'RPCN: 127.0.0.1'
Write-Host 'rpcn.yml: usunieto adres/nazwe BTB'
Write-Host 'Windows HOSTS: usunieto patch/rpcn.tekkenbtb.online'
Write-Host 'Backend pozostaje uruchamialny lokalnie, ale bez wpisow domen BTB w HOSTS.'
Write-Host ''
Write-Host 'Teraz uruchom Start Patras1993 Host.cmd, potem Tekken Revolution.'
