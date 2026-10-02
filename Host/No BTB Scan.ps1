$ErrorActionPreference = 'Stop'

$hostDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $hostDir 'host_config.json'
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


$patterns = @(
    @{ Name='PATCH ASCII'; Old=[Text.Encoding]::ASCII.GetBytes($oldPatch) },
    @{ Name='PATCH UTF16'; Old=[Text.Encoding]::Unicode.GetBytes($oldPatch) },
    @{ Name='RPCN ASCII'; Old=[Text.Encoding]::ASCII.GetBytes($oldRpcn) },
    @{ Name='RPCN UTF16'; Old=[Text.Encoding]::Unicode.GetBytes($oldRpcn) }
)

Write-Host '=== PATRAS1993 NO-BTB SCAN ==='
Write-Host "Gra: $gameRoot"
Write-Host "Nowy PATCH: $newPatch"
Write-Host "Nowy RPCN : $newRpcn"
Write-Host ''

$total = 0
foreach ($file in Get-NoBtbCandidates -GameRoot $gameRoot) {
    $data = [IO.File]::ReadAllBytes($file.FullName)
    foreach ($p in $patterns) {
        $positions = Find-SequencePositions -Data $data -Needle $p.Old
        foreach ($pos in $positions) {
            Write-Host "$($p.Name): $($file.FullName) offset=0x$('{0:X}' -f $pos)"
            $total++
        }
    }
}

Write-Host ''
Write-Host "Liczba znalezionych odniesien BTB w plikach gry: $total"
if ($total -eq 0) {
    Write-Host 'SCAN: nie znaleziono domen BTB w typowych plikach wykonywalnych NPUB31250.'
    Write-Host 'Nic nie zostalo zmienione.'
}
else {
    Write-Host 'SCAN: znaleziono miejsca mozliwe do bezpiecznej podmiany 1:1.'
    Write-Host 'Nic nie zostalo zmienione.'
}
