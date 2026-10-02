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

$patchSource = Join-Path $PSScriptRoot 'Patras1993_NPUB31250_patch.yml'
$patchTarget = Join-Path $rpcs3 'patches\NPUB31250_patch.yml'
if (-not (Test-Path -LiteralPath $patchSource)) {
    throw "Brak aktualnego patcha Guest: $patchSource"
}
New-Item -ItemType Directory -Path (Split-Path -Parent $patchTarget) -Force | Out-Null
Copy-Item -LiteralPath $patchSource -Destination $patchTarget -Force
Write-Host ('Patch zsynchronizowany: ' + $patchTarget)

$hashKey = 'PPU-1504b75ba97abccdf2d0a93dd93aaff10591a01e:'
$descLine = '  "Patras1993 P1 Health Shield - Experimental":'
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
        throw 'Znaleziono wpis P1 Health Shield, ale nie znaleziono pola Enabled.'
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
    Write-Host 'P1 HEALTH SHIELD: ON'
    Write-Host 'P1: obrazenia HP sa pomijane.'
    Write-Host 'P2: obrazenia pozostaja normalne.'
    Write-Host 'Tryb eksperymentalny: najpierw sprawdz offline.'
    Write-Host 'Uruchom teraz RPCS3 / Tekken Revolution.'
}
else {
    Write-Host 'P1 HEALTH SHIELD: OFF'
    Write-Host 'Normalne obrazenia P1 zostana przywrocone przy nastepnym starcie RPCS3.'
}
