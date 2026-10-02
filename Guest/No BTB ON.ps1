$ErrorActionPreference = 'Stop'

$configPath = Join-Path $PSScriptRoot 'guest_config.json'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Uruchom No BTB ON.cmd jako administrator.'
}
if (Get-Process rpcs3 -ErrorAction SilentlyContinue) {
    throw 'RPCS3 jest uruchomiony. Zamknij emulator i uruchom No BTB ON.cmd ponownie.'
}
if (-not (Test-Path -LiteralPath $configPath)) {
    throw 'Brak guest_config.json. Uruchom najpierw Setup Online Guest.cmd.'
}

$cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$rpcs3 = [string]$cfg.rpcs3_directory
$hostIp = [string]$cfg.host_tailscale_ip

$rpcnPath = Join-Path $rpcs3 'config\rpcn.yml'
if (-not (Test-Path -LiteralPath $rpcnPath)) {
    throw "Brak rpcn.yml: $rpcnPath"
}

$rpcnBackup = "$rpcnPath.patras1993.no-btb.guest.bak"
if (-not (Test-Path -LiteralPath $rpcnBackup)) {
    [IO.File]::Copy($rpcnPath, $rpcnBackup, $false)
}

$lines = @([IO.File]::ReadAllLines($rpcnPath))
$hasHost = $false
$hasHosts = $false
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^Host:\s*') {
        $lines[$i] = 'Host: ' + $hostIp
        $hasHost = $true
    }
    elseif ($lines[$i] -match '^Hosts:\s*') {
        $lines[$i] = 'Hosts: "Patras1993|' + $hostIp + '"'
        $hasHosts = $true
    }
}
if (-not $hasHost) { $lines += 'Host: ' + $hostIp }
if (-not $hasHosts) { $lines += 'Hosts: "Patras1993|' + $hostIp + '"' }

[IO.File]::WriteAllLines($rpcnPath, $lines, [Text.UTF8Encoding]::new($false))

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsBackup = "$hostsPath.patras1993.no-btb.guest.bak"
if (-not (Test-Path -LiteralPath $hostsBackup)) {
    [IO.File]::Copy($hostsPath, $hostsBackup, $false)
}
$hostLines = @([IO.File]::ReadAllLines($hostsPath) | Where-Object {
    $_ -notmatch '(?i)\s+(patch|rpcn)\.tekkenbtb\.online\s*$' -and
    $_ -notmatch '(?i)\s+(patch|rpcn)\.patras93\.invalid\s*$'
})
[IO.File]::WriteAllLines($hostsPath, $hostLines, [Text.Encoding]::ASCII)
ipconfig /flushdns | Out-Null

Write-Host ''
Write-Host '=== NO-BTB GUEST: ON ==='
Write-Host 'Pliki gry: NIE ZMIENIONE'
Write-Host "RPCN: $hostIp"
Write-Host 'rpcn.yml: usunieto adres/nazwe BTB'
Write-Host 'Windows HOSTS: usunieto patch/rpcn.tekkenbtb.online'
