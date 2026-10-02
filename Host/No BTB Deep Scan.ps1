$ErrorActionPreference = 'Stop'

$hostDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $hostDir 'host_config.json'
if (-not (Test-Path -LiteralPath $configPath)) {
    throw 'Brak host_config.json. Uruchom najpierw Setup Patras1993 Host.cmd.'
}

$cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$rpcs3 = [string]$cfg.rpcs3_directory
if (-not (Test-Path -LiteralPath $rpcs3)) { throw "Brak katalogu RPCS3: $rpcs3" }

$terms = @(
    'patch.tekkenbtb.online',
    'rpcn.tekkenbtb.online',
    'tekkenbtb.online',
    'TekkenBTB'
)

function Find-Bytes {
    param([byte[]]$Data,[byte[]]$Needle)
    $hits = New-Object 'System.Collections.Generic.List[int]'
    if (-not $Data -or -not $Needle -or $Needle.Length -eq 0 -or $Data.Length -lt $Needle.Length) { return $hits }
    for ($i=0; $i -le $Data.Length-$Needle.Length; $i++) {
        $ok=$true
        for($j=0;$j -lt $Needle.Length;$j++){
            if($Data[$i+$j] -ne $Needle[$j]){ $ok=$false; break }
        }
        if($ok){ [void]$hits.Add($i); $i += $Needle.Length-1 }
    }
    return $hits
}

Write-Host '=== PATRAS1993 NO-BTB DEEP SCAN ==='
Write-Host "RPCS3: $rpcs3"
Write-Host 'Skan obejmuje konfiguracje, cache i pliki binarne RPCS3.'
Write-Host 'Nic nie zostanie zmienione.'
Write-Host ''

$skipDirs = @(
    (Join-Path $rpcs3 'dev_hdd0\game\NPUB31250'),
    (Join-Path $rpcs3 'dev_hdd0\disc'),
    (Join-Path $rpcs3 'captures'),
    (Join-Path $rpcs3 'screenshots')
)

$files = Get-ChildItem -LiteralPath $rpcs3 -File -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object {
        $full = $_.FullName
        $skip = $false
        foreach($d in $skipDirs){
            if($full.StartsWith($d,[StringComparison]::OrdinalIgnoreCase)){ $skip=$true; break }
        }
        (-not $skip) -and $_.Length -le 268435456
    }

$total=0
foreach($file in $files){
    try { $data=[IO.File]::ReadAllBytes($file.FullName) } catch { continue }
    foreach($term in $terms){
        $ascii=[Text.Encoding]::ASCII.GetBytes($term)
        $utf16=[Text.Encoding]::Unicode.GetBytes($term)
        foreach($pos in (Find-Bytes -Data $data -Needle $ascii)){
            Write-Host "ASCII: $term"
            Write-Host "  $($file.FullName)"
            Write-Host "  offset=0x$('{0:X}' -f $pos)"
            $total++
        }
        foreach($pos in (Find-Bytes -Data $data -Needle $utf16)){
            Write-Host "UTF16: $term"
            Write-Host "  $($file.FullName)"
            Write-Host "  offset=0x$('{0:X}' -f $pos)"
            $total++
        }
    }
}

Write-Host ''
Write-Host "Liczba znalezionych odniesien BTB poza NPUB31250: $total"
if($total -eq 0){
    Write-Host 'DEEP SCAN: brak domen/nazw BTB w instalacji RPCS3 poza gra.'
} else {
    Write-Host 'DEEP SCAN: znaleziono pozostalosci. Wklej caly wynik.'
}
Write-Host 'Nic nie zostalo zmienione.'
