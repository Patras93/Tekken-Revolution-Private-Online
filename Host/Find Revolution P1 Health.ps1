$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host 'PATRAS1993 - TEKKEN REVOLUTION P1 HEALTH FINDER'
Write-Host 'Dla NPUB31250 / 01.05 / RPCS3'
Write-Host ''

$src = @'
using System;
using System.Runtime.InteropServices;

public static class PatrasMemory {
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr OpenProcess(uint access, bool inheritHandle, int processId);

    [DllImport("kernel32.dll", SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ReadProcessMemory(
        IntPtr process,
        IntPtr address,
        byte[] buffer,
        UIntPtr size,
        out UIntPtr bytesRead);

    [DllImport("kernel32.dll", SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool CloseHandle(IntPtr handle);
}
'@

if (-not ('PatrasMemory' -as [type])) {
    Add-Type -TypeDefinition $src -Language CSharp
}

function Get-BE32 {
    param([byte[]]$Buffer, [int]$Offset)
    return [uint32](
        ([uint32]$Buffer[$Offset] -shl 24) -bor
        ([uint32]$Buffer[$Offset + 1] -shl 16) -bor
        ([uint32]$Buffer[$Offset + 2] -shl 8) -bor
        ([uint32]$Buffer[$Offset + 3])
    )
}

function Get-BE16 {
    param([byte[]]$Buffer, [int]$Offset)
    return [uint16](
        ([uint16]$Buffer[$Offset] -shl 8) -bor
        ([uint16]$Buffer[$Offset + 1])
    )
}

function Read-Block {
    param(
        [IntPtr]$Handle,
        [uint64]$Address,
        [int]$Size
    )

    $buf = New-Object byte[] $Size
    [UIntPtr]$read = [UIntPtr]::Zero
    $ok = [PatrasMemory]::ReadProcessMemory(
        $Handle,
        [IntPtr]::new([long]$Address),
        $buf,
        [UIntPtr]::new([uint64]$Size),
        [ref]$read
    )

    if (-not $ok -or $read.ToUInt64() -ne [uint64]$Size) {
        $err = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
        throw ('ReadProcessMemory failed at 0x{0:X} size 0x{1:X}; Win32={2}' -f $Address, $Size, $err)
    }

    return $buf
}

$proc = Get-Process -Name 'rpcs3','rpcs3-avx2' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) {
    throw 'RPCS3 nie jest uruchomiony. Uruchom Tekken Revolution i wejdz do zwyklej walki offline.'
}

$PROCESS_QUERY_INFORMATION = 0x0400
$PROCESS_VM_READ = 0x0010
$handle = [PatrasMemory]::OpenProcess(
    ($PROCESS_QUERY_INFORMATION -bor $PROCESS_VM_READ),
    $false,
    $proc.Id
)

if ($handle -eq [IntPtr]::Zero) {
    $err = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
    throw "Nie mozna otworzyc procesu RPCS3. Win32=$err. Jesli RPCS3 jest uruchomiony jako administrator, uruchom ten skrypt jako administrator."
}

# Known Revolution 01.05 layout:
# RPCS3 PS3-memory base = 0x300000000
# P1 anchor = base + 0x12DA030
# player stride = 0x24A0
# Scan a wider window around the anchor so HP can be before or after it.
[uint64]$p1Anchor = 0x3012DA030
[uint64]$stride = 0x24A0
[int]$scanBefore = 0x1000
[int]$scanAfter = 0x3000
[int]$scanSize = $scanBefore + $scanAfter
[uint64]$p1Start = $p1Anchor - [uint64]$scanBefore
[uint64]$p2Start = $p1Start + $stride

try {
    Write-Host ('RPCS3 PID: ' + $proc.Id)
    Write-Host ('P1 scan: 0x{0:X} - 0x{1:X}' -f $p1Start, ($p1Start + [uint64]$scanSize - 1))
    Write-Host ''
    Write-Host 'KROK 1: wejdz do walki offline i ustaw P1 na pelnym zyciu.'
    Read-Host 'Gdy P1 ma pelne zycie, nacisnij ENTER'

    $p1Before = Read-Block -Handle $handle -Address $p1Start -Size $scanSize
    $p2Before = Read-Block -Handle $handle -Address $p2Start -Size $scanSize

    Write-Host ''
    Write-Host 'KROK 2: pozwol przeciwnikowi uderzyc P1 kilka razy, ale NIE daj sie znokautowac.'
    Read-Host 'Po utracie czesci zycia P1 nacisnij ENTER'

    $p1After = Read-Block -Handle $handle -Address $p1Start -Size $scanSize
    $p2After = Read-Block -Handle $handle -Address $p2Start -Size $scanSize

    $candidates32 = New-Object System.Collections.Generic.List[object]

    for ($o = 0; $o -le $scanSize - 4; $o += 4) {
        [uint32]$a = Get-BE32 $p1Before $o
        [uint32]$b = Get-BE32 $p1After $o
        [uint32]$p2a = Get-BE32 $p2Before $o
        [uint32]$p2b = Get-BE32 $p2After $o

        if ($a -gt $b) {
            [uint64]$delta = [uint64]$a - [uint64]$b

            # Health-like values are usually small-ish. Keep a generous ceiling.
            if ($a -le 1000000 -and $delta -le 1000000) {
                $p2Changed = ($p2a -ne $p2b)
                $score = 0
                if (-not $p2Changed) { $score += 100 }
                if ($a -le 10000) { $score += 50 }
                if ($b -gt 0) { $score += 20 }
                if ($delta -le 5000) { $score += 20 }

                $candidates32.Add([pscustomobject]@{
                    Score = $score
                    Bits = 32
                    OffsetFromP1Anchor = [int64]$o - [int64]$scanBefore
                    Address = ('0x{0:X}' -f ($p1Start + [uint64]$o))
                    Before = $a
                    After = $b
                    Delta = $delta
                    P2Before = $p2a
                    P2After = $p2b
                    P2Changed = $p2Changed
                })
            }
        }
    }

    $top32 = @($candidates32 | Sort-Object Score, Delta -Descending | Select-Object -First 40)

    $candidates16 = New-Object System.Collections.Generic.List[object]
    if ($top32.Count -lt 3) {
        for ($o = 0; $o -le $scanSize - 2; $o += 2) {
            [uint16]$a = Get-BE16 $p1Before $o
            [uint16]$b = Get-BE16 $p1After $o
            [uint16]$p2a = Get-BE16 $p2Before $o
            [uint16]$p2b = Get-BE16 $p2After $o

            if ($a -gt $b -and $a -le 10000) {
                [uint32]$delta = [uint32]$a - [uint32]$b
                $p2Changed = ($p2a -ne $p2b)
                $score = 0
                if (-not $p2Changed) { $score += 100 }
                if ($b -gt 0) { $score += 20 }
                if ($delta -le 1000) { $score += 20 }

                $candidates16.Add([pscustomobject]@{
                    Score = $score
                    Bits = 16
                    OffsetFromP1Anchor = [int64]$o - [int64]$scanBefore
                    Address = ('0x{0:X}' -f ($p1Start + [uint64]$o))
                    Before = $a
                    After = $b
                    Delta = $delta
                    P2Before = $p2a
                    P2After = $p2b
                    P2Changed = $p2Changed
                })
            }
        }
    }

    $top16 = @($candidates16 | Sort-Object Score, Delta -Descending | Select-Object -First 40)

    $outDir = Join-Path $PSScriptRoot 'diagnostics'
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $outFile = Join-Path $outDir ("P1-health-candidates-$stamp.txt")

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('PATRAS1993 TEKKEN REVOLUTION P1 HEALTH FINDER')
    $lines.Add(('RPCS3 PID: {0}' -f $proc.Id))
    $lines.Add(('P1 anchor: 0x{0:X}' -f $p1Anchor))
    $lines.Add(('P2 stride: 0x{0:X}' -f $stride))
    $lines.Add('')
    $lines.Add('TOP BE32 CANDIDATES')
    $lines.Add('Score Bits Offset Address Before After Delta P2Before P2After P2Changed')

    foreach ($c in $top32) {
        $lines.Add(('{0} {1} {2:+0;-0;0} {3} {4} {5} {6} {7} {8} {9}' -f
            $c.Score,$c.Bits,$c.OffsetFromP1Anchor,$c.Address,$c.Before,$c.After,$c.Delta,$c.P2Before,$c.P2After,$c.P2Changed))
    }

    if ($top16.Count -gt 0) {
        $lines.Add('')
        $lines.Add('TOP BE16 CANDIDATES')
        $lines.Add('Score Bits Offset Address Before After Delta P2Before P2After P2Changed')
        foreach ($c in $top16) {
            $lines.Add(('{0} {1} {2:+0;-0;0} {3} {4} {5} {6} {7} {8} {9}' -f
                $c.Score,$c.Bits,$c.OffsetFromP1Anchor,$c.Address,$c.Before,$c.After,$c.Delta,$c.P2Before,$c.P2After,$c.P2Changed))
        }
    }

    [IO.File]::WriteAllLines($outFile, $lines, (New-Object System.Text.UTF8Encoding($false)))

    Write-Host ''
    Write-Host ('Znaleziono kandydatow BE32: ' + $top32.Count)
    if ($top32.Count -gt 0) {
        Write-Host 'Najlepsi kandydaci:'
        foreach ($c in ($top32 | Select-Object -First 10)) {
            Write-Host ('Score {0}; offset {1:+0;-0;0}; {2}; {3} -> {4}; delta {5}; P2Changed={6}' -f
                $c.Score,$c.OffsetFromP1Anchor,$c.Address,$c.Before,$c.After,$c.Delta,$c.P2Changed)
        }
    }

    Write-Host ''
    Write-Host ('Pelny raport: ' + $outFile)
    Write-Host 'Wyslij mi ten plik P1-health-candidates-*.txt. Na jego podstawie zrobimy P1 Health Shield.'
}
finally {
    if ($handle -ne [IntPtr]::Zero) {
        [void][PatrasMemory]::CloseHandle($handle)
    }
}
