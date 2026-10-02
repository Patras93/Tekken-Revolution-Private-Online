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

function Get-GzipText([string]$Path) {
    try {
        $fs = [IO.File]::OpenRead($Path)
        try {
            $gz = New-Object IO.Compression.GZipStream($fs,[IO.Compression.CompressionMode]::Decompress)
            try {
                $sr = New-Object IO.StreamReader($gz)
                try { return $sr.ReadToEnd() }
                finally { $sr.Dispose() }
            }
            finally { $gz.Dispose() }
        }
        finally { $fs.Dispose() }
    }
    catch { return '' }
}

function Get-Rpcs3VersionEvidence {
    param([string]$Exe,[string]$Dir)

    $pieces = New-Object 'System.Collections.Generic.List[string]'

    try {
        $vi = (Get-Item -LiteralPath $Exe).VersionInfo
        [void]$pieces.Add([string]$vi.FileVersion)
        [void]$pieces.Add([string]$vi.ProductVersion)
    } catch {}

    $proc = Get-Process rpcs3 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($proc -and $proc.MainWindowTitle) {
        [void]$pieces.Add([string]$proc.MainWindowTitle)
    }

    $rawLog = Join-Path $Dir 'RPCS3.log'
    if (Test-Path -LiteralPath $rawLog) {
        try {
            $txt = Get-Content -LiteralPath $rawLog -Raw -ErrorAction Stop
            if ($txt) { [void]$pieces.Add($txt) }
        } catch {}
    }

    $gzLog = Join-Path $Dir 'RPCS3.log.gz'
    if (Test-Path -LiteralPath $gzLog) {
        $txt = Get-GzipText $gzLog
        if ($txt) { [void]$pieces.Add($txt) }
    }

    return ($pieces -join [Environment]::NewLine)
}

function TcpPortOpen([int]$Port) {
    try { return [bool](Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction Stop) }
    catch { return $false }
}

function UdpPortOpen([int]$Port) {
    try { return [bool](Get-NetUDPEndpoint -LocalPort $Port -ErrorAction Stop) }
    catch { return $false }
}

Result 'RPCS3 EXE' (Test-Path -LiteralPath $rpcs3Exe) $rpcs3Exe
if (-not (Test-Path -LiteralPath $rpcs3Exe)) { exit 2 }

$startedForVersionCheck = $false
$runningRpcs3 = Get-Process rpcs3 -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $runningRpcs3) {
    Write-Host 'RPCS3 nie jest uruchomiony. Uruchamiam emulator tylko do odczytu wersji...'
    Start-Process -FilePath $rpcs3Exe -WorkingDirectory $rpcs3Dir | Out-Null
    $startedForVersionCheck = $true

    $deadline = (Get-Date).AddSeconds(20)
    do {
        Start-Sleep -Milliseconds 500
        $runningRpcs3 = Get-Process rpcs3 -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($runningRpcs3) {
            try { $runningRpcs3.Refresh() } catch {}
        }
    } while ((Get-Date) -lt $deadline -and (-not $runningRpcs3 -or [string]::IsNullOrWhiteSpace($runningRpcs3.MainWindowTitle)))
}

$evidence = Get-Rpcs3VersionEvidence -Exe $rpcs3Exe -Dir $rpcs3Dir
$versionOk = $evidence -match '0\.0\.43-20161|\b20161\b'
$versionDetail = ''
if ($versionOk) {
    $m = [regex]::Match($evidence, '0\.0\.43-20161(?:-[A-Za-z0-9]+)?')
    if ($m.Success) { $versionDetail = $m.Value }
    else { $versionDetail = '20161 wykryty' }
}
else {
    $title = ''
    $p = Get-Process rpcs3 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($p) { try { $p.Refresh(); $title = [string]$p.MainWindowTitle } catch {} }
    if ($title) { $versionDetail = "tytul okna: $title" }
    else { $versionDetail = 'nie wykryto numeru wersji' }
}
Result 'RPCS3 20161' $versionOk $versionDetail

Result 'Tekken Revolution NPUB31250' (Test-Path -LiteralPath $game)
Result 'Patch NPUB31250' (Test-Path -LiteralPath $patch)

$privateMatchOk = $false
if (Test-Path -LiteralPath $patchConfig) {
    $txt = Get-Content -LiteralPath $patchConfig -Raw
    $privateMatchOk = $txt -match '(?ms)Patras1993 Private Match - Infinite Time \+ 5 Wins / 9 Rounds.*?Enabled:\s*true'
}
Result 'Private Match ON' $privateMatchOk

$rpcnTcp = TcpPortOpen 31313
$https = TcpPortOpen 443
$rpcnUdp = UdpPortOpen 3657

if (-not ($rpcnTcp -and $https -and $rpcnUdp)) {
    Write-Host ''
    Write-Host 'Host jest zatrzymany lub niekompletny. Probuje go uruchomic...'
    $startScript = Join-Path $hostDir 'Start Patras1993 Host.ps1'
    if (Test-Path -LiteralPath $startScript) {
        try {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $startScript | Out-Host
            Start-Sleep -Seconds 1
        } catch {
            Write-Host ('Automatyczny start hosta nie udal sie: ' + $_.Exception.Message)
        }
    }

    $rpcnTcp = TcpPortOpen 31313
    $https = TcpPortOpen 443
    $rpcnUdp = UdpPortOpen 3657
}

Result 'RPCN TCP 31313' $rpcnTcp
Result 'RPCN UDP 3657' $rpcnUdp
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
$localOk = $versionOk -and
           (Test-Path -LiteralPath $game) -and
           (Test-Path -LiteralPath $patch) -and
           $privateMatchOk -and
           $rpcnTcp -and $rpcnUdp -and $https -and $tailscaleOk

if ($localOk) {
    [IO.File]::WriteAllText((Join-Path $rpcs3Dir 'patras1993_rpc3_build.txt'), '0.0.43-20161', (New-Object System.Text.UTF8Encoding($false)))
    Write-Host 'LOKALNY TEST 20161: PASS.'
    Write-Host 'Nastepny etap: realny test online z Guest.'
    exit 0
}

Write-Host 'LOKALNY TEST 20161: NIEPRZEJSCIONY.'
if (-not $versionOk) {
    Write-Host 'Wersja nie zostala rozpoznana. Sprawdz tytul okna RPCS3 pokazany wyzej.'
}
exit 2
