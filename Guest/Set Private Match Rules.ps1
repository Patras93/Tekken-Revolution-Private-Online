param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('On','Off')]
    [string]$Mode
)

$ErrorActionPreference = 'Stop'

if (Get-Process rpcs3 -ErrorAction SilentlyContinue) {
    throw 'RPCS3 jest uruchomiony. Zamknij emulator i uruchom ten przelacznik ponownie.'
}

$configPath = Join-Path $PSScriptRoot 'guest_config.json'
if (-not (Test-Path -LiteralPath $configPath)) {
    throw 'Brak pliku konfiguracji. Najpierw uruchom Setup.'
}

$cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$rpcs3 = [string]$cfg.rpcs3_directory
if (-not $rpcs3) {
    throw 'Brak sciezki RPCS3 w konfiguracji.'
}

$patchConfigPath = Join-Path $rpcs3 'config\patch_config.yml'
if (-not (Test-Path -LiteralPath $patchConfigPath)) {
    throw "Brak patch_config.yml: $patchConfigPath"
}

$hashKey = 'PPU-1504b75ba97abccdf2d0a93dd93aaff10591a01e:'
$descLine = '  "Patras1993 Private Match - Infinite Time + 5 Wins / 9 Rounds":'
$enabledValue = if ($Mode -eq 'On') { 'true' } else { 'false' }

$lines = New-Object 'System.Collections.Generic.List[string]'
foreach ($line in [IO.File]::ReadAllLines($patchConfigPath)) {
    [void]$lines.Add($line)
}

$descIndex = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -eq $descLine) {
        $descIndex = $i
        break
    }
}

if ($descIndex -ge 0) {
    $enabledIndex = -1
    for ($i = $descIndex + 1; $i -lt [Math]::Min($lines.Count, $descIndex + 8); $i++) {
        if ($lines[$i] -match '^\s+Enabled:\s*(true|false)\s*$') {
            $enabledIndex = $i
            break
        }
    }
    if ($enabledIndex -lt 0) {
        throw 'Znaleziono wpis Private Match, ale nie znaleziono pola Enabled.'
    }
    $lines[$enabledIndex] = '          Enabled: ' + $enabledValue
}
else {
    $hashIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq $hashKey) {
            $hashIndex = $i
            break
        }
    }
    if ($hashIndex -lt 0) {
        if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -ne '') {
            [void]$lines.Add('')
        }
        [void]$lines.Add($hashKey)
        $hashIndex = $lines.Count - 1
    }

    $block = @(
        $descLine,
        '    "TEKKEN REVOLUTION":',
        '      NPUB31250:',
        '        01.05:',
        ('          Enabled: ' + $enabledValue)
    )

    $insertAt = $hashIndex + 1
    for ($i = $block.Count - 1; $i -ge 0; $i--) {
        $lines.Insert($insertAt, $block[$i])
    }
}

[IO.File]::WriteAllLines($patchConfigPath, $lines, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ''
if ($Mode -eq 'On') {
    Write-Host 'PRIVATE MATCH RULES: ON'
    Write-Host 'HP obu graczy: nie spada'
    Write-Host 'Czas rundy: nieskonczony'
    Write-Host 'Wygrana meczu: 5 rund'
    Write-Host 'Maksymalnie: 9 rund'
    Write-Host 'Final Round: przy 4:4'
    Write-Host 'Uruchom teraz RPCS3 / Tekken Revolution.'
}
else {
    Write-Host 'PRIVATE MATCH RULES: OFF'
    Write-Host 'Normalne zasady gry przywrocone na nastepny start RPCS3.'
}
