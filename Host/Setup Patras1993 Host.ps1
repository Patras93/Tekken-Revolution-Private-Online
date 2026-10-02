$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $root
$rpcnDir = Join-Path $repoRoot 'local_rpcn'
$rpcnExe = Join-Path $rpcnDir 'rpcn.exe'
$rpcnVersionFile = Join-Path $rpcnDir 'rpcn_version.txt'
$hostConfigFile = Join-Path $root 'host_config.json'
$preferredRpcs3 = 'E:\instalacje gier\rpcs3-v0.0.43-20146-4d88114c_win64\rpcs3.exe'

$requiredRpcnVersion = '1.10.0'
$rpcnZipUrl = 'https://github.com/RipleyTom/rpcn/releases/download/1.10.0/rpcn-win.zip'
$rpcnZipSha256 = '439e4f08bd8485194b36fb33b6da86a21a97adda56c968c75872918cf64ea663'

function Get-RpcnActualVersion {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return $null }

    $tmp = Join-Path $env:TEMP ('Patras1993-RPCN-Version-' + [guid]::NewGuid().ToString('N'))
    $out = Join-Path $tmp 'stdout.txt'
    $err = Join-Path $tmp 'stderr.txt'
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null

    try {
        $p = Start-Process -FilePath $Path -WorkingDirectory $tmp -ArgumentList '--cert-gen' -PassThru -WindowStyle Hidden -RedirectStandardOutput $out -RedirectStandardError $err
        if (-not $p.WaitForExit(8000)) {
            try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch {}
        }

        $text = ''
        if (Test-Path -LiteralPath $out) { $text += [IO.File]::ReadAllText($out) }
        if (Test-Path -LiteralPath $err) { $text += [Environment]::NewLine + [IO.File]::ReadAllText($err) }

        $m = [regex]::Match($text, 'RPCN\s+v(?<v>[0-9]+\.[0-9]+\.[0-9]+)', 'IgnoreCase')
        if ($m.Success) { return $m.Groups['v'].Value }
        return $null
    }
    finally {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Install-Rpcn1100 {
    Write-Host "RPCN: instalacja wersji $requiredRpcnVersion (protocol 32)."
    Write-Host 'RPCN: pobieranie oficjalnego rpcn-win.zip...'

    $tmpRoot = Join-Path $env:TEMP ('Patras1993-RPCN-' + [guid]::NewGuid().ToString('N'))
    $zip = Join-Path $tmpRoot 'rpcn-win.zip'
    $unpack = Join-Path $tmpRoot 'unpack'
    New-Item -ItemType Directory -Path $tmpRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $unpack -Force | Out-Null

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $rpcnZipUrl -OutFile $zip -UseBasicParsing

        $hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($hash -ne $rpcnZipSha256) {
            throw "Bledny SHA256 rpcn-win.zip: $hash"
        }

        Expand-Archive -LiteralPath $zip -DestinationPath $unpack -Force
        $newExe = Get-ChildItem -LiteralPath $unpack -Filter 'rpcn.exe' -File -Recurse | Select-Object -First 1
        if (-not $newExe) {
            throw 'Nie znaleziono rpcn.exe w oficjalnym archiwum RPCN 1.10.0.'
        }

        New-Item -ItemType Directory -Path $rpcnDir -Force | Out-Null

        $runningRpcn = Get-CimInstance Win32_Process -Filter "Name='rpcn.exe'" -ErrorAction SilentlyContinue | Where-Object {
            $_.ExecutablePath -and ([IO.Path]::GetFullPath($_.ExecutablePath) -eq [IO.Path]::GetFullPath($rpcnExe))
        }
        foreach ($proc in $runningRpcn) {
            Write-Host "RPCN: zatrzymywanie starej instancji PID $($proc.ProcessId)..."
            Stop-Process -Id $proc.ProcessId -Force -ErrorAction Stop
        }

        if (Test-Path -LiteralPath $rpcnExe) {
            Copy-Item -LiteralPath $rpcnExe -Destination (Join-Path $rpcnDir 'rpcn.exe.before-1.10.0.bak') -Force
        }

        Copy-Item -LiteralPath $newExe.FullName -Destination $rpcnExe -Force
    }
    finally {
        Remove-Item -LiteralPath $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    $actual = Get-RpcnActualVersion -Path $rpcnExe
    if ($actual -ne $requiredRpcnVersion) {
        throw "Po instalacji wykryto RPCN v$actual zamiast v$requiredRpcnVersion."
    }

    [IO.File]::WriteAllText($rpcnVersionFile, $actual, [Text.UTF8Encoding]::new($false))
    Write-Host "RPCN: rzeczywista wersja $actual gotowa (protocol 32)."
}

$marker = $null
if (Test-Path -LiteralPath $rpcnVersionFile) {
    $marker = (Get-Content -LiteralPath $rpcnVersionFile -Raw).Trim()
}
$actualRpcn = Get-RpcnActualVersion -Path $rpcnExe
Write-Host "RPCN marker: $marker"
Write-Host "RPCN rzeczywisty: $actualRpcn"

if (-not (Test-Path -LiteralPath $rpcnExe) -or $actualRpcn -ne $requiredRpcnVersion) {
    Write-Host "RPCN: wymagana naprawa do v$requiredRpcnVersion (protocol 32)."
    Install-Rpcn1100
    $actualRpcn = Get-RpcnActualVersion -Path $rpcnExe
}
else {
    [IO.File]::WriteAllText($rpcnVersionFile, $actualRpcn, [Text.UTF8Encoding]::new($false))
    Write-Host "RPCN: rzeczywista wersja $actualRpcn OK (protocol 32)."
}

$candidates = @(
    $preferredRpcs3,
    (Get-Command rpcs3.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
    (Join-Path $env:ProgramFiles 'RPCS3\rpcs3.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\RPCS3\rpcs3.exe')
) | Where-Object { $_ }

$rpcs3Exe = $null
foreach ($candidate in $candidates) {
    if (-not (Test-Path -LiteralPath $candidate)) { continue }
    $candidateDir = Split-Path -Parent $candidate
    if (Test-Path -LiteralPath (Join-Path $candidateDir 'dev_hdd0\game\NPUB31250\USRDIR\EBOOT.BIN')) {
        $rpcs3Exe = $candidate
        break
    }
}

if (-not $rpcs3Exe) {
    Write-Host 'RPCS3 z Tekken Revolution: nie znaleziono w typowych lokalizacjach. Przeszukuje dyski lokalne...'
    foreach ($drive in (Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root)) {
        $foundList = Get-ChildItem -LiteralPath $drive -Filter 'rpcs3.exe' -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '(?i)\\(Windows|ProgramData|\$Recycle\.Bin|System Volume Information)\\' }

        foreach ($found in $foundList) {
            $candidateDir = Split-Path -Parent $found.FullName
            if (Test-Path -LiteralPath (Join-Path $candidateDir 'dev_hdd0\game\NPUB31250\USRDIR\EBOOT.BIN')) {
                $rpcs3Exe = $found.FullName
                break
            }
        }
        if ($rpcs3Exe) { break }
    }
}

if (-not $rpcs3Exe) {
    throw 'Nie znaleziono instalacji RPCS3 zawierajacej Tekken Revolution NPUB31250.'
}

$rpcs3Dir = Split-Path -Parent $rpcs3Exe
$gameEboot = Join-Path $rpcs3Dir 'dev_hdd0\game\NPUB31250\USRDIR\EBOOT.BIN'

@{
    rpcs3_directory = $rpcs3Dir
    rpcs3_exe = $rpcs3Exe
    game = 'NPUB31250'
    architecture = 'RPCN_DIRECT'
} | ConvertTo-Json | Set-Content -LiteralPath $hostConfigFile -Encoding utf8

# Natywny patch RPCS3.
$nativePatchSource = Join-Path $repoRoot 'local_patch\NPUB31250_patch.yml'
$patchDir = Join-Path $rpcs3Dir 'patches'
$nativePatchTarget = Join-Path $patchDir 'NPUB31250_patch.yml'
$patchConfigPath = Join-Path $rpcs3Dir 'config\patch_config.yml'
$patchConfigBackup = Join-Path $rpcs3Dir 'config\patch_config.yml.patras1993.bak'
$patchHashKey = 'PPU-1504b75ba97abccdf2d0a93dd93aaff10591a01e:'
$patchDescriptionLine = '  "Patras1993 Revolution Runtime Patches":'

if (-not (Test-Path -LiteralPath $nativePatchSource)) {
    throw "Brak natywnego patcha Revolution: $nativePatchSource"
}
New-Item -ItemType Directory -Path $patchDir -Force | Out-Null
Copy-Item -LiteralPath $nativePatchSource -Destination $nativePatchTarget -Force

$configLines = @()
if (Test-Path -LiteralPath $patchConfigPath) {
    $configLines = @([IO.File]::ReadAllLines($patchConfigPath))
    if (-not (Test-Path -LiteralPath $patchConfigBackup)) {
        [IO.File]::Copy($patchConfigPath, $patchConfigBackup, $false)
    }
}

$configList = New-Object 'System.Collections.Generic.List[string]'
foreach ($line in $configLines) { [void]$configList.Add($line) }

$descIndex = -1
for ($i=0; $i -lt $configList.Count; $i++) {
    if ($configList[$i] -eq $patchDescriptionLine) { $descIndex=$i; break }
}
if ($descIndex -ge 0) {
    $endIndex = $configList.Count
    for ($i=$descIndex+1; $i -lt $configList.Count; $i++) {
        if ($configList[$i] -match '^\S.*:\s*$' -or $configList[$i] -match '^  \S.*:\s*$') { $endIndex=$i; break }
    }
    for ($i=$endIndex-1; $i -ge $descIndex; $i--) { $configList.RemoveAt($i) }
}

$hashIndex = -1
for ($i=0; $i -lt $configList.Count; $i++) {
    if ($configList[$i] -eq $patchHashKey) { $hashIndex=$i; break }
}

$enableBlock = @(
    $patchDescriptionLine,
    '    "TEKKEN REVOLUTION":',
    '      NPUB31250:',
    '        01.05:',
    '          Enabled: true'
)
if ($hashIndex -lt 0) {
    if ($configList.Count -gt 0 -and $configList[$configList.Count-1] -ne '') { [void]$configList.Add('') }
    [void]$configList.Add($patchHashKey)
    foreach ($line in $enableBlock) { [void]$configList.Add($line) }
}
else {
    $insertAt=$hashIndex+1
    for ($i=$enableBlock.Count-1; $i -ge 0; $i--) { $configList.Insert($insertAt,$enableBlock[$i]) }
}
New-Item -ItemType Directory -Path (Split-Path -Parent $patchConfigPath) -Force | Out-Null
[IO.File]::WriteAllLines($patchConfigPath,$configList,[Text.UTF8Encoding]::new($false))
Write-Host "RPCS3 patch: $nativePatchTarget"

# RPCN hosta: bezposrednio localhost. Zachowaj konto/token.
$rpcnPath = Join-Path $rpcs3Dir 'config\rpcn.yml'
$rpcnLines = @()
if (Test-Path -LiteralPath $rpcnPath) {
    $rpcnLines = @([IO.File]::ReadAllLines($rpcnPath))
}
else {
    $rpcnLines = @(
        'Version: 2',
        'Host: 127.0.0.1',
        'NPID: ""',
        'Password: ""',
        'Token: ""',
        'Hosts: "Patras1993|127.0.0.1"',
        'Experimental IPv6 support: false'
    )
}

$hostFound=$false; $hostsFound=$false
for($i=0;$i -lt $rpcnLines.Count;$i++){
    if($rpcnLines[$i] -match '^Host:\s*'){ $rpcnLines[$i]='Host: 127.0.0.1'; $hostFound=$true }
    elseif($rpcnLines[$i] -match '^Hosts:\s*'){ $rpcnLines[$i]='Hosts: "Patras1993|127.0.0.1"'; $hostsFound=$true }
}
if(-not $hostFound){$rpcnLines+='Host: 127.0.0.1'}
if(-not $hostsFound){$rpcnLines+='Hosts: "Patras1993|127.0.0.1"'}
[IO.File]::WriteAllLines($rpcnPath,$rpcnLines,[Text.UTF8Encoding]::new($false))
Write-Host 'RPCN RPCS3: 127.0.0.1'

# Usun historyczne aliasy BTB z HOSTS, niczego nie dodawaj.
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$currentHostLines = [IO.File]::ReadAllLines($hostsPath)
$cleanHostLines = @($currentHostLines | Where-Object {
    $_ -notmatch '(?i)\s+(patch|rpcn)\.tekkenbtb\.online\s*$' -and
    $_ -notmatch '(?i)\s+(patch|rpcn)\.patras93\.invalid\s*$'
})
if (($currentHostLines -join [Environment]::NewLine) -ne ($cleanHostLines -join [Environment]::NewLine)) {
    [IO.File]::WriteAllLines($hostsPath,$cleanHostLines,[Text.Encoding]::ASCII)
    ipconfig /flushdns | Out-Null
    Write-Host 'HOSTS: usunieto historyczne aliasy BTB.'
}

New-NetFirewallRule -DisplayName 'Patras1993 RPCN TCP' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 31313 -Profile Any -ErrorAction SilentlyContinue | Out-Null
New-NetFirewallRule -DisplayName 'Patras1993 RPCN UDP' -Direction Inbound -Action Allow -Protocol UDP -LocalPort 3657 -Profile Any -ErrorAction SilentlyContinue | Out-Null

Write-Host 'TCP 31313: OK'
Write-Host 'UDP 3657: OK'
Write-Host "RPCS3: $rpcs3Exe"
Write-Host "Tekken Revolution: $gameEboot"
Write-Host 'Architektura: RPCN DIRECT + Tailscale + natywny patch RPCS3.'
Write-Host 'Backend/launcher BTB: NIE UZYWANY.'
Write-Host 'PATRAS1993 HOST SETUP v2.2.0 GOTOWY.'
