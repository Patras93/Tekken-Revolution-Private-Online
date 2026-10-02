$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host 'PATRAS1993 - RPCS3 GUEST UPDATER'
Write-Host 'Preferred verified build: RPCS3 0.0.43-20161-96ccd89c'
Write-Host 'Fallback supported: RPCS3 0.0.43-20147-dfc0542a'
Write-Host ''

$expectedBuild = '0.0.43-20161-96ccd89c'
$archiveUrl = 'https://github.com/RPCS3/rpcs3-binaries-win/releases/download/build-96ccd89cd6931c32e66ef5c5e4f823e210c24c15/rpcs3-v0.0.43-20161-96ccd89c_win64_msvc.7z'
$archiveSha256 = '847f25f4b689797e26a63277782b4f9b13b64028eeae1d0f2448b91af8f0ccbb'

$preferred = 'E:\instalacje gier\rpcs3-v0.0.43-20146-4d88114c_win64\rpcs3.exe'
$candidates = @(
    $preferred,
    (Get-Command rpcs3.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
    (Join-Path $env:ProgramFiles 'RPCS3\rpcs3.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\RPCS3\rpcs3.exe'),
    (Join-Path $env:USERPROFILE 'Downloads\rpcs3\rpcs3.exe'),
    (Join-Path $env:USERPROFILE 'Desktop\RPCS3\rpcs3.exe')
) | Where-Object { $_ }

$rpcs3Exe = $null

# Wybierz tylko instalacje RPCS3, ktore rzeczywiscie zawieraja Tekken Revolution NPUB31250.
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

$rpcs3Dir = Split-Path -Parent $rpcs3Exe
$game = Join-Path $rpcs3Dir 'dev_hdd0\game\NPUB31250\USRDIR\EBOOT.BIN'

Write-Host "RPCS3: $rpcs3Dir"
Write-Host 'Gra NPUB31250: OK'

$versionEvidence = ''
try {
    $versionInfo = (Get-Item -LiteralPath $rpcs3Exe).VersionInfo
    $versionEvidence += "$($versionInfo.FileVersion) $($versionInfo.ProductVersion)"
} catch {}

$logPath = Join-Path $rpcs3Dir 'RPCS3.log'
if (Test-Path -LiteralPath $logPath) {
    try { $versionEvidence += [Environment]::NewLine + (Get-Content -LiteralPath $logPath -Raw -ErrorAction Stop) } catch {}
}

$markerPath = Join-Path $rpcs3Dir 'patras1993_rpc3_build.txt'
if (Test-Path -LiteralPath $markerPath) {
    try { $versionEvidence += [Environment]::NewLine + (Get-Content -LiteralPath $markerPath -Raw -ErrorAction Stop) } catch {}
}

if ($versionEvidence -match '0\.0\.43-20161-96ccd89c|20161-96ccd89c') {
    [IO.File]::WriteAllText($markerPath, $expectedBuild, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host ''
    Write-Host 'RPCS3 0.0.43-20161-96ccd89c jest juz zainstalowany.'
    Write-Host 'Status: VERIFIED STABLE FOR PATRAS1993 v2.1.1.'
    exit 0
}

$running = Get-Process rpcs3 -ErrorAction SilentlyContinue
if ($running) {
    Write-Host 'Zamykanie RPCS3 przed aktualizacja...'
    $running | Stop-Process -Force
    Start-Sleep -Milliseconds 700
}

$tmpRoot = Join-Path $env:TEMP ('Patras1993-RPCS3-' + [guid]::NewGuid().ToString('N'))
$archive = Join-Path $tmpRoot 'rpcs3.7z'
$extract = Join-Path $tmpRoot 'extract'
New-Item -ItemType Directory -Path $extract -Force | Out-Null

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Host 'Pobieranie sprawdzonego RPCS3 20161-96ccd89c...'
    Invoke-WebRequest -Uri $archiveUrl -OutFile $archive -UseBasicParsing

    $hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne $archiveSha256) {
        throw "Nieprawidlowy SHA256 archiwum RPCS3: $hash"
    }
    Write-Host 'SHA256: OK'

    $tar = Get-Command tar.exe -ErrorAction SilentlyContinue
    if (-not $tar) {
        throw 'Brak systemowego tar.exe. Na Windows 11 powinien byc dostepny.'
    }

    Write-Host 'Rozpakowywanie oficjalnego archiwum...'
    & $tar.Source -xf $archive -C $extract
    if ($LASTEXITCODE -ne 0) {
        throw "tar.exe zakonczyl sie kodem $LASTEXITCODE"
    }

    $newExe = Get-ChildItem -LiteralPath $extract -Filter 'rpcs3.exe' -File -Recurse | Select-Object -First 1
    if (-not $newExe) {
        throw 'Nie znaleziono rpcs3.exe po rozpakowaniu archiwum.'
    }

    $sourceRoot = Split-Path -Parent $newExe.FullName
    Write-Host 'Aktualizacja plikow programu. dev_hdd0 i dane uzytkownika nie sa usuwane.'

    Get-ChildItem -LiteralPath $sourceRoot -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $rpcs3Dir -Recurse -Force
    }

    $marker = Join-Path $rpcs3Dir 'patras1993_rpc3_build.txt'
    [IO.File]::WriteAllText($marker, $expectedBuild, (New-Object System.Text.UTF8Encoding($false)))

    if (-not (Test-Path -LiteralPath (Join-Path $rpcs3Dir 'rpcs3.exe'))) {
        throw 'Po aktualizacji brakuje rpcs3.exe.'
    }

    if (-not (Test-Path -LiteralPath $game)) {
        throw 'Po aktualizacji nie znaleziono gry. Aktualizacja zostala przerwana.'
    }

    Write-Host ''
    Write-Host 'RPCS3 0.0.43-20161-96ccd89c GOTOWY.'
    Write-Host 'Tekken Revolution i dane dev_hdd0 pozostaly na miejscu.'
}
finally {
    Remove-Item -LiteralPath $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue
}
