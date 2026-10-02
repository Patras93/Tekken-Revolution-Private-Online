$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host 'PATRAS1993 - TEKKEN REVOLUTION ONLINE GUEST'
Write-Host ''

$preferredBuild = '0.0.43-20161-96ccd89c'
$fallbackBuild = '0.0.43-20147-dfc0542a'
$acceptedBuilds = @($preferredBuild, $fallbackBuild)
$nativePatchSource = Join-Path $PSScriptRoot 'Patras1993_NPUB31250_patch.yml'

$hostIp = Read-Host 'Podaj adres Tailscale hosta Patras1993 (100.x.x.x)'
if ($hostIp -notmatch '^100\.(?:[0-9]{1,3}\.){2}[0-9]{1,3}$') {
    throw 'Nieprawidlowy adres Tailscale.'
}

$preferredRpcs3 = 'E:\instalacje gier\rpcs3-v0.0.43-20146-4d88114c_win64\rpcs3.exe'
$candidates = @(
    $preferredRpcs3,
    (Get-Command rpcs3.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
    (Join-Path $env:ProgramFiles 'RPCS3\rpcs3.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\RPCS3\rpcs3.exe'),
    (Join-Path $env:USERPROFILE 'Downloads\rpcs3\rpcs3.exe'),
    (Join-Path $env:USERPROFILE 'Desktop\RPCS3\rpcs3.exe')
) | Where-Object { $_ }

$rpcs3Exe = $null

# Najpierw wybierz tylko instalacje RPCS3, ktore faktycznie zawieraja Tekken Revolution NPUB31250.
foreach ($candidate in $candidates) {
    if (-not (Test-Path -LiteralPath $candidate)) {
        continue
    }

    $candidateDir = Split-Path -Parent $candidate
    $candidateGame = Join-Path $candidateDir 'dev_hdd0\game\NPUB31250\USRDIR\EBOOT.BIN'
    if (Test-Path -LiteralPath $candidateGame) {
        $rpcs3Exe = $candidate
        break
    }
}

if (-not $rpcs3Exe) {
    Write-Host 'Nie znaleziono RPCS3 z Tekken Revolution w typowych lokalizacjach. Przeszukuje dyski lokalne...'
    foreach ($drive in (Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root)) {
        $foundList = Get-ChildItem -LiteralPath $drive -Filter 'rpcs3.exe' -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object {
                $_.FullName -notmatch '(?i)\\(Windows|ProgramData|\$Recycle\.Bin|System Volume Information)\\'
            }

        foreach ($found in $foundList) {
            $candidateDir = Split-Path -Parent $found.FullName
            $candidateGame = Join-Path $candidateDir 'dev_hdd0\game\NPUB31250\USRDIR\EBOOT.BIN'
            if (Test-Path -LiteralPath $candidateGame) {
                $rpcs3Exe = $found.FullName
                break
            }
        }

        if ($rpcs3Exe) {
            break
        }
    }
}

if (-not $rpcs3Exe) {
    throw 'Nie znaleziono instalacji RPCS3 zawierajacej Tekken Revolution NPUB31250. RPCS3 i gra musza byc w tej samej instalacji emulatora.'
}

$rpcs3 = Split-Path -Parent $rpcs3Exe
$game = Join-Path $rpcs3 'dev_hdd0\game\NPUB31250\USRDIR\EBOOT.BIN'

Write-Host "RPCS3: $rpcs3"
Write-Host 'Tekken Revolution NPUB31250: OK'

$buildOk = $false
$detectedBuild = $null
$buildMarker = Join-Path $rpcs3 'patras1993_rpc3_build.txt'

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

function Get-VersionEvidence {
    $parts = New-Object 'System.Collections.Generic.List[string]'

    try {
        $vi = (Get-Item -LiteralPath $rpcs3Exe).VersionInfo
        [void]$parts.Add([string]$vi.FileVersion)
        [void]$parts.Add([string]$vi.ProductVersion)
    } catch {}

    $p = Get-Process rpcs3 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($p -and $p.MainWindowTitle) {
        [void]$parts.Add([string]$p.MainWindowTitle)
    }

    $rawLog = Join-Path $rpcs3 'RPCS3.log'
    if (Test-Path -LiteralPath $rawLog) {
        try { [void]$parts.Add((Get-Content -LiteralPath $rawLog -Raw -ErrorAction Stop)) } catch {}
    }

    $gzLog = Join-Path $rpcs3 'RPCS3.log.gz'
    if (Test-Path -LiteralPath $gzLog) {
        $gzText = Get-GzipText $gzLog
        if ($gzText) { [void]$parts.Add($gzText) }
    }

    if (Test-Path -LiteralPath $buildMarker) {
        try { [void]$parts.Add((Get-Content -LiteralPath $buildMarker -Raw -ErrorAction Stop)) } catch {}
    }

    return ($parts -join [Environment]::NewLine)
}

$evidence = Get-VersionEvidence
if ($evidence -match '0\.0\.43-20161-96ccd89c|20161-96ccd89c') {
    $detectedBuild = $preferredBuild
    $buildOk = $true
}
elseif ($evidence -match '0\.0\.43-20147-dfc0542a|20147-dfc0542a') {
    $detectedBuild = $fallbackBuild
    $buildOk = $true
}

if (-not $buildOk) {
    $startedForCheck = $false
    if (-not (Get-Process rpcs3 -ErrorAction SilentlyContinue)) {
        Write-Host 'Sprawdzanie wersji RPCS3...'
        Start-Process -FilePath $rpcs3Exe -WorkingDirectory $rpcs3 | Out-Null
        $startedForCheck = $true
        Start-Sleep -Seconds 3
    }

    $evidence = Get-VersionEvidence
    if ($evidence -match '0\.0\.43-20161-96ccd89c|20161-96ccd89c') {
        $detectedBuild = $preferredBuild
        $buildOk = $true
    }
    elseif ($evidence -match '0\.0\.43-20147-dfc0542a|20147-dfc0542a') {
        $detectedBuild = $fallbackBuild
        $buildOk = $true
    }

    if ($startedForCheck) {
        Get-Process rpcs3 -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
}

if (-not $buildOk) {
    throw 'Nieobslugiwany build RPCS3. Uruchom Guest\Update RPCS3 for Patras1993.cmd. Preferowany: 20161-96ccd89c; fallback: 20147-dfc0542a.'
}

[IO.File]::WriteAllText($buildMarker, $detectedBuild, (New-Object System.Text.UTF8Encoding($false)))

if ($detectedBuild -eq $preferredBuild) {
    Write-Host "RPCS3 build: $detectedBuild VERIFIED"
}
else {
    Write-Host "RPCS3 build: $detectedBuild FALLBACK"
}

if (-not (Test-Path -LiteralPath $nativePatchSource)) {
    throw "Brak patcha Revolution w projekcie: $nativePatchSource"
}

$patchDir = Join-Path $rpcs3 'patches'
$patchTarget = Join-Path $patchDir 'NPUB31250_patch.yml'
$patchConfigPath = Join-Path $rpcs3 'config\patch_config.yml'
$patchConfigBackup = Join-Path $rpcs3 'config\patch_config.yml.patras1993.guest.bak'
$patchHashKey = 'PPU-1504b75ba97abccdf2d0a93dd93aaff10591a01e:'
$patchDescriptionLine = '  "Patras1993 Revolution Runtime Patches":'

New-Item -ItemType Directory -Path $patchDir -Force | Out-Null
Copy-Item -LiteralPath $nativePatchSource -Destination $patchTarget -Force
Write-Host "Patch Revolution: $patchTarget"

$configLines = @()
if (Test-Path -LiteralPath $patchConfigPath) {
    $configLines = @([IO.File]::ReadAllLines($patchConfigPath))
    if (-not (Test-Path -LiteralPath $patchConfigBackup)) {
        [IO.File]::Copy($patchConfigPath, $patchConfigBackup, $false)
    }
}

$configList = New-Object 'System.Collections.Generic.List[string]'
foreach ($line in $configLines) {
    [void]$configList.Add($line)
}

$descIndex = -1
for ($i = 0; $i -lt $configList.Count; $i++) {
    if ($configList[$i] -eq $patchDescriptionLine) {
        $descIndex = $i
        break
    }
}

if ($descIndex -ge 0) {
    $endIndex = $configList.Count
    for ($i = $descIndex + 1; $i -lt $configList.Count; $i++) {
        if ($configList[$i] -match '^\S.*:\s*$' -or $configList[$i] -match '^  \S.*:\s*$') {
            $endIndex = $i
            break
        }
    }
    for ($i = $endIndex - 1; $i -ge $descIndex; $i--) {
        $configList.RemoveAt($i)
    }
}

$hashIndex = -1
for ($i = 0; $i -lt $configList.Count; $i++) {
    if ($configList[$i] -eq $patchHashKey) {
        $hashIndex = $i
        break
    }
}

$enableBlock = @(
    $patchDescriptionLine,
    '    "TEKKEN REVOLUTION":',
    '      NPUB31250:',
    '        01.05:',
    '          Enabled: true'
)

if ($hashIndex -lt 0) {
    if ($configList.Count -gt 0 -and $configList[$configList.Count - 1] -ne '') {
        [void]$configList.Add('')
    }
    [void]$configList.Add($patchHashKey)
    foreach ($line in $enableBlock) {
        [void]$configList.Add($line)
    }
}
else {
    $insertAt = $hashIndex + 1
    for ($i = $enableBlock.Count - 1; $i -ge 0; $i--) {
        $configList.Insert($insertAt, $enableBlock[$i])
    }
}

New-Item -ItemType Directory -Path (Split-Path -Parent $patchConfigPath) -Force | Out-Null
[IO.File]::WriteAllLines($patchConfigPath, $configList, (New-Object System.Text.UTF8Encoding($false)))
Write-Host 'Patch Revolution: ENABLED (453 wpisy).'

$rpcnPath = Join-Path $rpcs3 'config\rpcn.yml'
$rpcnBackup = Join-Path $rpcs3 'config\rpcn.yml.patras1993.guest.bak'
$rpcnLines = @()

if (Test-Path -LiteralPath $rpcnPath) {
    $rpcnLines = @([IO.File]::ReadAllLines($rpcnPath))
    if (-not (Test-Path -LiteralPath $rpcnBackup)) {
        [IO.File]::Copy($rpcnPath, $rpcnBackup, $false)
    }
}
else {
    $rpcnLines = @(
        'Version: 2',
        'Host: np.rpcs3.net',
        'NPID: ""',
        'Password: ""',
        'Token: ""',
        'Hosts: "Official RPCN Server|np.rpcs3.net"',
        'Experimental IPv6 support: false'
    )
}

$hostFound = $false
$hostsFound = $false

for ($i = 0; $i -lt $rpcnLines.Count; $i++) {
    if ($rpcnLines[$i] -match '^Host:\s*') {
        $rpcnLines[$i] = 'Host: ' + $hostIp
        $hostFound = $true
    }
    elseif ($rpcnLines[$i] -match '^Hosts:\s*') {
        $rpcnLines[$i] = 'Hosts: "Patras1993|' + $hostIp + '"'
        $hostsFound = $true
    }
}

if (-not $hostFound) {
    $rpcnLines += 'Host: ' + $hostIp
}
if (-not $hostsFound) {
    $rpcnLines += 'Hosts: "Patras1993|' + $hostIp + '"'
}

[IO.File]::WriteAllLines($rpcnPath, $rpcnLines, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "RPCN: host ustawiony na $hostIp"
Write-Host 'RPCN: istniejacy NPID/Password/Token pozostawione bez zmian.'

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsBackup = "$hostsPath.patras1993.guest.bak"
$currentHostLines = [IO.File]::ReadAllLines($hostsPath)
$filteredHostLines = @(
    $currentHostLines |
        Where-Object { $_ -notmatch '(?i)\s+(patch|rpcn)\.tekkenbtb\.online\s*$' }
)
$desiredHostLines = @($filteredHostLines)
$desiredHostLines += "$hostIp patch.tekkenbtb.online"
$desiredHostLines += "$hostIp rpcn.tekkenbtb.online"

$currentText = ($currentHostLines -join [Environment]::NewLine).TrimEnd()
$desiredText = ($desiredHostLines -join [Environment]::NewLine).TrimEnd()

if ($currentText -ne $desiredText) {
    if (-not (Test-Path -LiteralPath $hostsBackup)) {
        [IO.File]::Copy($hostsPath, $hostsBackup, $false)
    }

    $tmpHosts = Join-Path $env:TEMP ('hosts.patras1993.guest.' + [guid]::NewGuid().ToString('N'))
    try {
        [IO.File]::WriteAllLines($tmpHosts, $desiredHostLines, [Text.Encoding]::ASCII)
        [IO.File]::Copy($tmpHosts, $hostsPath, $true)
    }
    finally {
        Remove-Item -LiteralPath $tmpHosts -Force -ErrorAction SilentlyContinue
    }

    ipconfig /flushdns | Out-Null
}

$configPath = Join-Path $PSScriptRoot 'guest_config.json'
@{
    host_tailscale_ip = $hostIp
    rpcs3_directory = $rpcs3
    required_rpcs3_build = $detectedBuild
    game = 'NPUB31250'
} | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding UTF8

Write-Host ''
Write-Host 'GUEST GOTOWY.'
Write-Host "RPCS3: $detectedBuild"
Write-Host 'Tekken Revolution: NPUB31250 01.05'
Write-Host 'Patch: Patras1993 Revolution Runtime Patches'
Write-Host "RPCN: $hostIp"
Write-Host ''
Write-Host 'WAŻNE - KONTO RPCN PATRAS1993:'
Write-Host 'Konto na oficjalnym RPCN nie tworzy automatycznie konta na prywatnym serwerze Patras1993.'
Write-Host 'Jesli pierwszy raz laczysz sie z Patras1993, uruchom RPCS3 i utworz osobne konto RPCN na serwerze Patras1993.'
Write-Host 'Po utworzeniu konta i poprawnym zalogowaniu uruchamiaj gre przez Guest\Start Online Guest.cmd.'
Write-Host ''
Read-Host 'Nacisnij ENTER po przeczytaniu tej informacji'
