$ErrorActionPreference = 'Stop'

$hostDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $hostDir 'host_config.json'

Write-Host '=== TEST RPCS3 0.0.43-20161 ==='
Write-Host ''

if (-not (Test-Path -LiteralPath $configPath)) {
    throw 'Brak host_config.json. Uruchom najpierw Setup Patras1993 Host.cmd.'
}

$cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$rpcs3Dir = [string]$cfg.rpcs3_directory
$rpcs3Exe = Join-Path $rpcs3Dir 'rpcs3.exe'
$game = Join-Path $rpcs3Dir 'dev_hdd0\game\NPUB31250\USRDIR\EBOOT.BIN'
$patch = Join-Path $rpcs3Dir 'patches\NPUB31250_patch.yml'
$patchConfig = Join-Path $rpcs3Dir 'config\patch_config.yml'

function Result([string]$Name,[bool]$Ok,[string]$Detail='') {
    $state = if ($Ok) { 'PASS' } else { 'FAIL' }
    if ($Detail) { Write-Host "$Name : $state - $Detail" }
    else { Write-Host "$Name : $state" }
}

Result 'RPCS3 EXE' (Test-Path -LiteralPath $rpcs3Exe) $rpcs3Exe
if (-not (Test-Path -LiteralPath $rpcs3Exe)) { exit 2 }

$vi = (Get-Item -LiteralPath $rpcs3Exe).VersionInfo
$combined = "$($vi.FileVersion) $($vi.ProductVersion)"
$versionOk = $combined -like '*20161*'

if (-not $versionOk) {
    $log = Join-Path $rpcs3Dir 'RPCS3.log'
    if (Test-Path -LiteralPath $log) {
        $firstLine = Get-Content -LiteralPath $log -TotalCount 1
        if ($firstLine -like '*20161*') {
            $versionOk = $true
            $combined = $firstLine
        }
    }
}

Result 'RPCS3 20161' $versionOk $combined
Result 'Tekken Revolution NPUB31250' (Test-Path -LiteralPath $game)
Result 'Patch NPUB31250' (Test-Path -LiteralPath $patch)

$privateMatchOk = $false
if (Test-Path -LiteralPath $patchConfig) {
    $txt = Get-Content -LiteralPath $patchConfig -Raw
    $privateMatchOk = $txt -match '(?ms)Patras1993 Private Match - Infinite Time \+ 5 Wins / 9 Rounds.*?Enabled:\s*true'
}
Result 'Private Match ON' $privateMatchOk

$rpcnTcp = $false
try { $rpcnTcp = [bool](Get-NetTCPConnection -LocalPort 31313 -State Listen -ErrorAction Stop) } catch {}
Result 'RPCN TCP 31313' $rpcnTcp

$https = $false
try { $https = [bool](Get-NetTCPConnection -LocalPort 443 -State Listen -ErrorAction Stop) } catch {}
Result 'Backend HTTPS 443' $https

$tailscale = Get-Command tailscale.exe -ErrorAction SilentlyContinue
$tailscaleOk = $false
$tailscaleIp = ''
if ($tailscale) {
    try {
        $tailscaleIp = (& $tailscale.Source ip -4 2>$null | Select-Object -First 1)
        $tailscaleOk = [bool]$tailscaleIp
    } catch {}
}
Result 'Tailscale' $tailscaleOk $tailscaleIp

Write-Host ''
if ($versionOk -and (Test-Path -LiteralPath $game) -and (Test-Path -LiteralPath $patch)) {
    [IO.File]::WriteAllText((Join-Path $rpcs3Dir 'patras1993_rpc3_build.txt'), '0.0.43-20161', (New-Object System.Text.UTF8Encoding($false)))
    Write-Host 'LOKALNY TEST 20161: GOTOWY DO URUCHOMIENIA GRY.'
    Write-Host 'Nastepnie uruchom Private Match ON.cmd i Tekken Revolution.'
}
else {
    Write-Host 'LOKALNY TEST 20161: NIEPRZEJSCIONY.'
    exit 2
}
