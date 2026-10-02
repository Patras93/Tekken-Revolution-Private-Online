$ErrorActionPreference = 'Stop'

$hostDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $hostDir
$configPath = Join-Path $hostDir 'host_config.json'
$rpcnExe = Join-Path $repoRoot 'local_rpcn\rpcn.exe'

Write-Host '=== TEST PATRAS1993 v2.2.0 / RPCS3 20161 ==='
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
$rpcnConfig = Join-Path $rpcs3Dir 'config\rpcn.yml'

function Result([string]$Name,[bool]$Ok,[string]$Detail='') {
    $state = if ($Ok) { 'PASS' } else { 'FAIL' }
    if ($Detail) { Write-Host "$Name : $state - $Detail" } else { Write-Host "$Name : $state" }
}

function Get-GzipText([string]$Path) {
    try {
        $fs=[IO.File]::OpenRead($Path)
        try {
            $gz=New-Object IO.Compression.GZipStream($fs,[IO.Compression.CompressionMode]::Decompress)
            try {
                $sr=New-Object IO.StreamReader($gz)
                try { return $sr.ReadToEnd() } finally { $sr.Dispose() }
            } finally { $gz.Dispose() }
        } finally { $fs.Dispose() }
    } catch { return '' }
}

function Get-Rpcs3Evidence {
    $parts=New-Object 'System.Collections.Generic.List[string]'
    try {
        $vi=(Get-Item -LiteralPath $rpcs3Exe).VersionInfo
        [void]$parts.Add([string]$vi.FileVersion)
        [void]$parts.Add([string]$vi.ProductVersion)
    } catch {}
    $p=Get-Process rpcs3 -ErrorAction SilentlyContinue | Select-Object -First 1
    if($p -and $p.MainWindowTitle){[void]$parts.Add([string]$p.MainWindowTitle)}
    $raw=Join-Path $rpcs3Dir 'RPCS3.log'
    if(Test-Path $raw){try{[void]$parts.Add((Get-Content $raw -Raw))}catch{}}
    $gz=Join-Path $rpcs3Dir 'RPCS3.log.gz'
    if(Test-Path $gz){$txt=Get-GzipText $gz;if($txt){[void]$parts.Add($txt)}}
    return ($parts -join [Environment]::NewLine)
}

function Get-RpcnActualVersion([string]$Path) {
    if(-not(Test-Path $Path)){return $null}
    $tmp=Join-Path $env:TEMP ('Patras1993-RPCN-Test-'+[guid]::NewGuid().ToString('N'))
    $out=Join-Path $tmp 'out.txt'; $err=Join-Path $tmp 'err.txt'
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    try {
        $p=Start-Process -FilePath $Path -WorkingDirectory $tmp -ArgumentList '--cert-gen' -PassThru -WindowStyle Hidden -RedirectStandardOutput $out -RedirectStandardError $err
        if(-not $p.WaitForExit(8000)){try{Stop-Process -Id $p.Id -Force}catch{}}
        $text=''
        if(Test-Path $out){$text+=[IO.File]::ReadAllText($out)}
        if(Test-Path $err){$text+=[IO.File]::ReadAllText($err)}
        $m=[regex]::Match($text,'RPCN\s+v(?<v>[0-9]+\.[0-9]+\.[0-9]+)','IgnoreCase')
        if($m.Success){return $m.Groups['v'].Value}
        return $null
    } finally { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
}

function TcpPortOpen([int]$Port) {
    try { return [bool](Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction Stop) } catch { return $false }
}
function UdpPortOpen([int]$Port) {
    try { return [bool](Get-NetUDPEndpoint -LocalPort $Port -ErrorAction Stop) } catch { return $false }
}

Result 'RPCS3 EXE' (Test-Path $rpcs3Exe) $rpcs3Exe
if(-not(Test-Path $rpcs3Exe)){exit 2}

$started=$false
if(-not(Get-Process rpcs3 -ErrorAction SilentlyContinue)){
    Start-Process -FilePath $rpcs3Exe -WorkingDirectory $rpcs3Dir | Out-Null
    $started=$true
    Start-Sleep -Seconds 3
}
$evidence=Get-Rpcs3Evidence
$versionOk=$evidence -match '0\.0\.43-20161-96ccd89c|20161-96ccd89c'
Result 'RPCS3 20161' $versionOk
if($started){Get-Process rpcs3 -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue}

Result 'Tekken Revolution NPUB31250' (Test-Path $game)
Result 'Patch NPUB31250' (Test-Path $patch)

$privateMatchOk=$false
if(Test-Path $patchConfig){
    $txt=Get-Content $patchConfig -Raw
    $privateMatchOk=$txt -match '(?ms)Patras1993 Private Match - Infinite Time \+ 5 Wins / 9 Rounds.*?Enabled:\s*true'
}
Result 'Private Match ON' $privateMatchOk

$rpcnVersion=Get-RpcnActualVersion $rpcnExe
Result 'RPCN 1.10.0 / protocol 32' ($rpcnVersion -eq '1.10.0') $rpcnVersion

$rpcnDirect=$false
if(Test-Path $rpcnConfig){
    $txt=Get-Content $rpcnConfig -Raw
    $rpcnDirect=$txt -match '(?m)^Host:\s*127\.0\.0\.1\s*$'
}
Result 'RPCN direct 127.0.0.1' $rpcnDirect

$tcp=TcpPortOpen 31313; $udp=UdpPortOpen 3657
if(-not($tcp -and $udp)){
    Write-Host ''
    Write-Host 'Host nie dziala. Probuje uruchomic...'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $hostDir 'Start Patras1993 Host.ps1') | Out-Host
    Start-Sleep -Seconds 1
    $tcp=TcpPortOpen 31313; $udp=UdpPortOpen 3657
}
Result 'RPCN TCP 31313' $tcp
Result 'RPCN UDP 3657' $udp

$tailscale=Get-Command tailscale.exe -ErrorAction SilentlyContinue
$tailscaleIp=''
if($tailscale){try{$tailscaleIp=(& $tailscale.Source ip -4 2>$null | Select-Object -First 1)}catch{}}
Result 'Tailscale' ([bool]$tailscaleIp) $tailscaleIp

$ok=$versionOk -and (Test-Path $game) -and (Test-Path $patch) -and $privateMatchOk -and
    ($rpcnVersion -eq '1.10.0') -and $rpcnDirect -and $tcp -and $udp -and [bool]$tailscaleIp

Write-Host ''
if($ok){
    [IO.File]::WriteAllText((Join-Path $rpcs3Dir 'patras1993_rpc3_build.txt'),'0.0.43-20161-96ccd89c',[Text.UTF8Encoding]::new($false))
    Write-Host 'TEST PATRAS1993 v2.2.0: PASS.'
    Write-Host 'Backend HTTPS 443 nie jest wymagany.'
    exit 0
}
Write-Host 'TEST PATRAS1993 v2.2.0: FAIL.'
exit 2
