$ErrorActionPreference = 'Stop'

$hostDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $hostDir
$configPath = Join-Path $hostDir 'host_config.json'
$backendDir = Join-Path $repoRoot 'local_backend'
$thumbFile = Join-Path $backendDir 'server_cert_thumbprint.txt'

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
$gameRoot = Join-Path $rpcs3 'dev_hdd0\game\NPUB31250'
if (-not (Test-Path -LiteralPath $gameRoot)) { throw "Brak NPUB31250: $gameRoot" }

$oldPatch = 'patch.tekkenbtb.online'
$newPatch = 'patch.patras93.invalid'
$oldRpcn = 'rpcn.tekkenbtb.online'
$newRpcn = 'rpcn.patras93.invalid'


function Find-SequencePositions {
    param([byte[]]$Data,[byte[]]$Needle)
    $positions = New-Object 'System.Collections.Generic.List[int]'
    if (-not $Data -or -not $Needle -or $Needle.Length -eq 0 -or $Data.Length -lt $Needle.Length) {
        return $positions
    }
    for ($i = 0; $i -le $Data.Length - $Needle.Length; $i++) {
        $ok = $true
        for ($j = 0; $j -lt $Needle.Length; $j++) {
            if ($Data[$i + $j] -ne $Needle[$j]) { $ok = $false; break }
        }
        if ($ok) {
            [void]$positions.Add($i)
            $i += ($Needle.Length - 1)
        }
    }
    return $positions
}

function Replace-Sequence {
    param([byte[]]$Data,[byte[]]$Old,[byte[]]$New)
    if ($Old.Length -ne $New.Length) { throw 'Stary i nowy ciag maja rozna dlugosc.' }
    $positions = Find-SequencePositions -Data $Data -Needle $Old
    foreach ($pos in $positions) {
        [Array]::Copy($New, 0, $Data, $pos, $New.Length)
    }
    return $positions.Count
}

function Get-NoBtbCandidates {
    param([string]$GameRoot)
    $extensions = @('.bin','.self','.sprx','.prx','.elf','.dll','.exe')
    Get-ChildItem -LiteralPath $GameRoot -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object {
            ($extensions -contains $_.Extension.ToLowerInvariant()) -and
            $_.Length -le 268435456 -and
            $_.Name -notlike '*.patras1993-no-btb.bak'
        }
}


$oldPatchA = [Text.Encoding]::ASCII.GetBytes($oldPatch)
$newPatchA = [Text.Encoding]::ASCII.GetBytes($newPatch)
$oldPatchU = [Text.Encoding]::Unicode.GetBytes($oldPatch)
$newPatchU = [Text.Encoding]::Unicode.GetBytes($newPatch)
$oldRpcnA = [Text.Encoding]::ASCII.GetBytes($oldRpcn)
$newRpcnA = [Text.Encoding]::ASCII.GetBytes($newRpcn)
$oldRpcnU = [Text.Encoding]::Unicode.GetBytes($oldRpcn)
$newRpcnU = [Text.Encoding]::Unicode.GetBytes($newRpcn)

if ($oldPatchA.Length -ne $newPatchA.Length -or $oldRpcnA.Length -ne $newRpcnA.Length) {
    throw 'Nazwy No-BTB nie maja identycznej dlugosci jak stare domeny.'
}

$changedFiles = 0
$changedRefs = 0
foreach ($file in Get-NoBtbCandidates -GameRoot $gameRoot) {
    $data = [IO.File]::ReadAllBytes($file.FullName)
    $count = 0
    $count += Replace-Sequence -Data $data -Old $oldPatchA -New $newPatchA
    $count += Replace-Sequence -Data $data -Old $oldPatchU -New $newPatchU
    $count += Replace-Sequence -Data $data -Old $oldRpcnA -New $newRpcnA
    $count += Replace-Sequence -Data $data -Old $oldRpcnU -New $newRpcnU

    if ($count -gt 0) {
        $backup = $file.FullName + '.patras1993-no-btb.bak'
        if (-not (Test-Path -LiteralPath $backup)) {
            [IO.File]::Copy($file.FullName, $backup, $false)
        }
        [IO.File]::WriteAllBytes($file.FullName, $data)
        Write-Host "PATCHED: $($file.FullName) ($count)"
        $changedFiles++
        $changedRefs += $count
    }
}

if ($changedRefs -eq 0) {
    throw 'Nie znaleziono domen BTB w typowych plikach wykonywalnych gry. Nie zmieniono konfiguracji sieci. Uruchom najpierw No BTB Scan.cmd i wklej wynik.'
}

# RPCN hosta zawsze bez domeny: localhost.
$rpcnPath = Join-Path $rpcs3 'config\rpcn.yml'
if (Test-Path -LiteralPath $rpcnPath) {
    $lines = @([IO.File]::ReadAllLines($rpcnPath))
    $hasHost = $false
    $hasHosts = $false
    for ($i=0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^Host:\s*') { $lines[$i] = 'Host: 127.0.0.1'; $hasHost=$true }
        elseif ($lines[$i] -match '^Hosts:\s*') { $lines[$i] = 'Hosts: "Patras1993|127.0.0.1"'; $hasHosts=$true }
    }
    if (-not $hasHost) { $lines += 'Host: 127.0.0.1' }
    if (-not $hasHosts) { $lines += 'Hosts: "Patras1993|127.0.0.1"' }
    [IO.File]::WriteAllLines($rpcnPath, $lines, [Text.UTF8Encoding]::new($false))
}

# HOSTS: usun stare i nowe aliasy, dodaj tylko nasze niepubliczne aliasy.
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsBackup = "$hostsPath.patras1993.no-btb.bak"
if (-not (Test-Path -LiteralPath $hostsBackup)) {
    [IO.File]::Copy($hostsPath, $hostsBackup, $false)
}
$hostLines = @([IO.File]::ReadAllLines($hostsPath) | Where-Object {
    $_ -notmatch '(?i)\s+(patch|rpcn)\.tekkenbtb\.online\s*$' -and
    $_ -notmatch '(?i)\s+(patch|rpcn)\.patras93\.invalid\s*$'
})
$hostLines += "127.0.0.1 $newPatch"
$hostLines += "127.0.0.1 $newRpcn"
[IO.File]::WriteAllLines($hostsPath, $hostLines, [Text.Encoding]::ASCII)
ipconfig /flushdns | Out-Null

# Nowy certyfikat backendu bez nazwy BTB.
$cert = Get-ChildItem 'Cert:\CurrentUser\My' |
    Where-Object { $_.Subject -eq "CN=$newPatch" -and $_.HasPrivateKey -and $_.NotAfter -gt (Get-Date) } |
    Sort-Object NotAfter -Descending |
    Select-Object -First 1
if (-not $cert) {
    $cert = New-SelfSignedCertificate -DnsName $newPatch -CertStoreLocation 'Cert:\CurrentUser\My' -FriendlyName 'Patras1993 No-BTB Backend' -NotAfter (Get-Date).AddYears(5)
}
$thumb = $cert.Thumbprint.ToUpperInvariant()
[IO.File]::WriteAllText($thumbFile, $thumb, [Text.UTF8Encoding]::new($false))

$trusted = Get-ChildItem 'Cert:\CurrentUser\Root' | Where-Object { $_.Thumbprint -eq $thumb } | Select-Object -First 1
if (-not $trusted) {
    $tmp = Join-Path $env:TEMP 'patras1993-no-btb.cer'
    try {
        Export-Certificate -Cert $cert -FilePath $tmp -Force | Out-Null
        Import-Certificate -FilePath $tmp -CertStoreLocation 'Cert:\CurrentUser\Root' | Out-Null
    }
    finally { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
}

@{
    mode = 'NO-BTB'
    patch_host = $newPatch
    rpcn_host = '127.0.0.1'
    changed_files = $changedFiles
    changed_references = $changedRefs
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $hostDir 'no_btb_config.json') -Encoding UTF8

Write-Host ''
Write-Host '=== NO-BTB HOST: ON ==='
Write-Host "Zmienione pliki gry: $changedFiles"
Write-Host "Zmienione odniesienia: $changedRefs"
Write-Host "Backend: $newPatch -> 127.0.0.1"
Write-Host 'RPCN: 127.0.0.1'
Write-Host 'Stare domeny BTB zostaly usuniete z HOSTS.'
Write-Host 'Uruchom teraz Start Patras1993 Host.cmd, potem Tekken Revolution.'
