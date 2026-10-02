$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host 'PATRAS1993 - TEKKEN REVOLUTION ONLINE GUEST'
Write-Host ''

$expectedBuild = '0.0.43-20147-dfc0542a'
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

$rpcs3Exe = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

if (-not $rpcs3Exe) {
    Write-Host 'Nie znaleziono RPCS3 w typowych lokalizacjach. Przeszukuje dyski lokalne...'
    foreach ($drive in (Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root)) {
        $found = Get-ChildItem -LiteralPath $drive -Filter 'rpcs3.exe' -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\\(Windows|ProgramData)\\' } |
            Select-Object -First 1
        if ($found) {
            $rpcs3Exe = $found.FullName
            break
        }
    }
}

if (-not $rpcs3Exe) {
    throw 'Nie znaleziono rpcs3.exe.'
}

$rpcs3 = Split-Path -Parent $rpcs3Exe
$game = Join-Path $rpcs3 'dev_hdd0\game\NPUB31250\USRDIR\EBOOT.BIN'
if (-not (Test-Path -LiteralPath $game)) {
    throw "Znaleziono RPCS3, ale nie znaleziono Tekken Revolution NPUB31250: $game"
}

Write-Host "RPCS3: $rpcs3"
Write-Host 'Tekken Revolution NPUB31250: OK'

$buildOk = $false
$buildMarker = Join-Path $rpcs3 'patras1993_rpc3_build.txt'

if (Test-Path -LiteralPath $buildMarker) {
    $markerValue = (Get-Content -LiteralPath $buildMarker -Raw).Trim()
    if ($markerValue -eq $expectedBuild) {
        $buildOk = $true
    }
}

if (-not $buildOk) {
    $logPath = Join-Path $rpcs3 'RPCS3.log'
    if (Test-Path -LiteralPath $logPath) {
        $firstLine = Get-Content -LiteralPath $logPath -TotalCount 1
        if ($firstLine -like "*$expectedBuild*") {
            $buildOk = $true
            [IO.File]::WriteAllText($buildMarker, $expectedBuild, (New-Object System.Text.UTF8Encoding($false)))
        }
    }
}

if (-not $buildOk) {
    $versionInfo = (Get-Item -LiteralPath $rpcs3Exe).VersionInfo
    $combinedVersion = "$($versionInfo.FileVersion) $($versionInfo.ProductVersion)"
    if ($combinedVersion -like '*20147*' -and $combinedVersion -like '*dfc0542a*') {
        $buildOk = $true
        [IO.File]::WriteAllText($buildMarker, $expectedBuild, (New-Object System.Text.UTF8Encoding($false)))
    }
}

if (-not $buildOk) {
    throw 'RPCS3 nie jest potwierdzony jako 0.0.43-20147-dfc0542a. Uruchom najpierw Guest\Update RPCS3 for Patras1993.cmd.'
}

Write-Host "RPCS3 build: $expectedBuild OK"

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
    required_rpcs3_build = $expectedBuild
    game = 'NPUB31250'
} | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding UTF8

Write-Host ''
Write-Host 'GUEST GOTOWY.'
Write-Host "RPCS3: $expectedBuild"
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
