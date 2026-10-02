$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host 'PATRAS1993 - TEKKEN REVOLUTION REAL HEALTH FINDER v2'
Write-Host 'NPUB31250 / APP_VER 01.05 / RPCS3'
Write-Host 'Tylko odczyt pamieci - skrypt niczego nie zmienia.'
Write-Host ''

$src = @'
using System;
using System.Runtime.InteropServices;

public static class PatrasHealthMemory {
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

if (-not ('PatrasHealthMemory' -as [type])) {
    Add-Type -TypeDefinition $src -Language CSharp
}

function Read-Block {
    param([IntPtr]$Handle, [uint64]$Address, [int]$Size)

    $buf = New-Object byte[] $Size
    [UIntPtr]$read = [UIntPtr]::Zero
    $ok = [PatrasHealthMemory]::ReadProcessMemory(
        $Handle,
        [IntPtr]::new([long]$Address),
        $buf,
        [UIntPtr]::new([uint64]$Size),
        [ref]$read
    )

    if (-not $ok -or $read.ToUInt64() -ne [uint64]$Size) {
        $err = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
        throw ('ReadProcessMemory failed at 0x{0:X}, size 0x{1:X}, Win32={2}' -f $Address,$Size,$err)
    }
    return $buf
}

function Get-BE32 {
    param([byte[]]$Buffer,[int]$Offset)
    return [uint32](
        ([uint32]$Buffer[$Offset] -shl 24) -bor
        ([uint32]$Buffer[$Offset+1] -shl 16) -bor
        ([uint32]$Buffer[$Offset+2] -shl 8) -bor
        ([uint32]$Buffer[$Offset+3])
    )
}

function Get-BE16 {
    param([byte[]]$Buffer,[int]$Offset)
    return [uint16](
        ([uint16]$Buffer[$Offset] -shl 8) -bor
        ([uint16]$Buffer[$Offset+1])
    )
}

function Get-BEFloat32 {
    param([byte[]]$Buffer,[int]$Offset)
    [byte[]]$tmp = @(
        $Buffer[$Offset+3],
        $Buffer[$Offset+2],
        $Buffer[$Offset+1],
        $Buffer[$Offset]
    )
    return [BitConverter]::ToSingle($tmp,0)
}

function Float-Same {
    param([single]$A,[single]$B)
    if ([Single]::IsNaN($A) -or [Single]::IsNaN($B) -or
        [Single]::IsInfinity($A) -or [Single]::IsInfinity($B)) {
        return $false
    }
    $scale = [Math]::Max(1.0,[Math]::Max([Math]::Abs([double]$A),[Math]::Abs([double]$B)))
    return ([Math]::Abs([double]$A-[double]$B) -le (0.00001 * $scale))
}

$proc = Get-Process -Name 'rpcs3','rpcs3-avx2' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) {
    throw 'RPCS3 nie jest uruchomiony. Uruchom Tekken Revolution i wejdz do zwyklej walki offline.'
}

$PROCESS_QUERY_INFORMATION = 0x0400
$PROCESS_VM_READ = 0x0010
$handle = [PatrasHealthMemory]::OpenProcess(
    ($PROCESS_QUERY_INFORMATION -bor $PROCESS_VM_READ),
    $false,
    $proc.Id
)

if ($handle -eq [IntPtr]::Zero) {
    $err = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
    throw "Nie mozna otworzyc procesu RPCS3. Win32=$err. Jesli RPCS3 jest uruchomiony jako administrator, uruchom skrypt jako administrator."
}

# Public TR tooling confirms:
# P1 position/player block begins at guest 0x012D9F00.
# P2 counterpart is exactly +0x24A0.
# We scan one complete player stride and require mirrored P1/P2 damage behavior.
[uint64]$p1Base = 0x3012D9F00
[uint64]$stride = 0x24A0
[uint64]$p2Base = $p1Base + $stride
[int]$scanSize = 0x24A0

try {
    Write-Host ('RPCS3 PID: ' + $proc.Id)
    Write-Host ('P1 block: 0x{0:X} - 0x{1:X}' -f $p1Base,($p1Base+[uint64]$scanSize-1))
    Write-Host ('P2 block: 0x{0:X} - 0x{1:X}' -f $p2Base,($p2Base+[uint64]$scanSize-1))
    Write-Host ''
    Write-Host 'WAZNE: w czasie pomiaru nie zmieniaj postaci.'
    Write-Host ''

    Write-Host 'KROK 1 z 4 - PELNE ZYCIE.'
    Write-Host 'Rozpocznij nowa runde. P1 i P2 maja miec pelne paski.'
    Read-Host 'Nacisnij ENTER'
    $p1Full1 = Read-Block $handle $p1Base $scanSize
    $p2Full1 = Read-Block $handle $p2Base $scanSize

    Write-Host ''
    Write-Host 'KROK 2 z 4 - OBIJ TYLKO P1.'
    Write-Host 'Pozwol CPU uderzyc P1 kilka razy. Sam nie bij P2. Nie koncz rundy.'
    Read-Host 'Gdy P1 straci wyrazna czesc zycia, nacisnij ENTER'
    $p1Damaged = Read-Block $handle $p1Base $scanSize
    $p2WhileP1Damaged = Read-Block $handle $p2Base $scanSize

    Write-Host ''
    Write-Host 'KROK 3 z 4 - NOWA RUNDA.'
    Write-Host 'Doprowadz do nastepnej rundy i poczekaj, az oba paski znow sa pelne.'
    Read-Host 'Na poczatku nowej rundy nacisnij ENTER'
    $p1Full2 = Read-Block $handle $p1Base $scanSize
    $p2Full2 = Read-Block $handle $p2Base $scanSize

    Write-Host ''
    Write-Host 'KROK 4 z 4 - OBIJ TYLKO P2.'
    Write-Host 'Teraz Ty uderz P2 kilka razy. Staraj sie, aby P1 nie dostal ciosu. Nie koncz rundy.'
    Read-Host 'Gdy P2 straci wyrazna czesc zycia, nacisnij ENTER'
    $p1WhileP2Damaged = Read-Block $handle $p1Base $scanSize
    $p2Damaged = Read-Block $handle $p2Base $scanSize

    # Save all raw measurements BEFORE candidate processing.
    # If later analysis fails, the four-step test does not need to be repeated.
    $outDir = Join-Path $PSScriptRoot 'diagnostics'
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $rawDir = Join-Path $outDir ("REAL-health-raw-$stamp")
    New-Item -ItemType Directory -Path $rawDir -Force | Out-Null

    [IO.File]::WriteAllBytes((Join-Path $rawDir '01-P1-full.bin'), $p1Full1)
    [IO.File]::WriteAllBytes((Join-Path $rawDir '01-P2-full.bin'), $p2Full1)
    [IO.File]::WriteAllBytes((Join-Path $rawDir '02-P1-damaged.bin'), $p1Damaged)
    [IO.File]::WriteAllBytes((Join-Path $rawDir '02-P2-while-P1-damaged.bin'), $p2WhileP1Damaged)
    [IO.File]::WriteAllBytes((Join-Path $rawDir '03-P1-full.bin'), $p1Full2)
    [IO.File]::WriteAllBytes((Join-Path $rawDir '03-P2-full.bin'), $p2Full2)
    [IO.File]::WriteAllBytes((Join-Path $rawDir '04-P1-while-P2-damaged.bin'), $p1WhileP2Damaged)
    [IO.File]::WriteAllBytes((Join-Path $rawDir '04-P2-damaged.bin'), $p2Damaged)

    Write-Host ''
    Write-Host ('Surowe pomiary zapisane: ' + $rawDir)

    $c32 = New-Object System.Collections.Generic.List[object]
    for ($o=0; $o -le $scanSize-4; $o+=4) {
        [uint32]$p1a = Get-BE32 $p1Full1 $o
        [uint32]$p1b = Get-BE32 $p1Damaged $o
        [uint32]$p1c = Get-BE32 $p1Full2 $o
        [uint32]$p1d = Get-BE32 $p1WhileP2Damaged $o
        [uint32]$p2a = Get-BE32 $p2Full1 $o
        [uint32]$p2b = Get-BE32 $p2WhileP1Damaged $o
        [uint32]$p2c = Get-BE32 $p2Full2 $o
        [uint32]$p2d = Get-BE32 $p2Damaged $o

        if ($p1a -gt $p1b -and $p2c -gt $p2d -and
            $p2a -eq $p2b -and $p1c -eq $p1d -and
            $p1a -eq $p1c -and $p2a -eq $p2c -and
            $p1a -le 1000000 -and $p2a -le 1000000) {

            $score = 400
            if ($p1a -eq $p2a) { $score += 150 }
            if ($p1a -le 10000 -and $p2a -le 10000) { $score += 100 }
            if ($p1b -gt 0 -and $p2d -gt 0) { $score += 50 }
            $d1 = [uint64]$p1a - [uint64]$p1b
            $d2 = [uint64]$p2c - [uint64]$p2d
            if ($d1 -le 10000 -and $d2 -le 10000) { $score += 50 }

            $c32.Add([pscustomobject]@{
                Score=$score; Type='BE32'; Offset=('0x{0:X}' -f $o)
                P1Address=('0x{0:X}' -f ($p1Base+[uint64]$o))
                P2Address=('0x{0:X}' -f ($p2Base+[uint64]$o))
                P1Full=$p1a; P1Damaged=$p1b; P1Delta=$d1
                P2Full=$p2c; P2Damaged=$p2d; P2Delta=$d2
            })
        }
    }

    $c16 = New-Object System.Collections.Generic.List[object]
    for ($o=0; $o -le $scanSize-2; $o+=2) {
        [uint16]$p1a = Get-BE16 $p1Full1 $o
        [uint16]$p1b = Get-BE16 $p1Damaged $o
        [uint16]$p1c = Get-BE16 $p1Full2 $o
        [uint16]$p1d = Get-BE16 $p1WhileP2Damaged $o
        [uint16]$p2a = Get-BE16 $p2Full1 $o
        [uint16]$p2b = Get-BE16 $p2WhileP1Damaged $o
        [uint16]$p2c = Get-BE16 $p2Full2 $o
        [uint16]$p2d = Get-BE16 $p2Damaged $o

        if ($p1a -gt $p1b -and $p2c -gt $p2d -and
            $p2a -eq $p2b -and $p1c -eq $p1d -and
            $p1a -eq $p1c -and $p2a -eq $p2c) {

            $score = 350
            if ($p1a -eq $p2a) { $score += 120 }
            if ($p1a -le 10000 -and $p2a -le 10000) { $score += 80 }
            if ($p1b -gt 0 -and $p2d -gt 0) { $score += 40 }

            $c16.Add([pscustomobject]@{
                Score=$score; Type='BE16'; Offset=('0x{0:X}' -f $o)
                P1Address=('0x{0:X}' -f ($p1Base+[uint64]$o))
                P2Address=('0x{0:X}' -f ($p2Base+[uint64]$o))
                P1Full=$p1a; P1Damaged=$p1b; P1Delta=([uint32]$p1a-[uint32]$p1b)
                P2Full=$p2c; P2Damaged=$p2d; P2Delta=([uint32]$p2c-[uint32]$p2d)
            })
        }
    }

    $cf = New-Object System.Collections.Generic.List[object]
    for ($o=0; $o -le $scanSize-4; $o+=4) {
        [single]$p1a = Get-BEFloat32 $p1Full1 $o
        [single]$p1b = Get-BEFloat32 $p1Damaged $o
        [single]$p1c = Get-BEFloat32 $p1Full2 $o
        [single]$p1d = Get-BEFloat32 $p1WhileP2Damaged $o
        [single]$p2a = Get-BEFloat32 $p2Full1 $o
        [single]$p2b = Get-BEFloat32 $p2WhileP1Damaged $o
        [single]$p2c = Get-BEFloat32 $p2Full2 $o
        [single]$p2d = Get-BEFloat32 $p2Damaged $o

        $finite = -not (
            [Single]::IsNaN($p1a) -or [Single]::IsNaN($p1b) -or [Single]::IsNaN($p1c) -or [Single]::IsNaN($p1d) -or
            [Single]::IsNaN($p2a) -or [Single]::IsNaN($p2b) -or [Single]::IsNaN($p2c) -or [Single]::IsNaN($p2d) -or
            [Single]::IsInfinity($p1a) -or [Single]::IsInfinity($p1b) -or [Single]::IsInfinity($p1c) -or [Single]::IsInfinity($p1d) -or
            [Single]::IsInfinity($p2a) -or [Single]::IsInfinity($p2b) -or [Single]::IsInfinity($p2c) -or [Single]::IsInfinity($p2d)
        )

        if ($finite -and
            $p1a -gt $p1b -and $p2c -gt $p2d -and
            (Float-Same $p2a $p2b) -and (Float-Same $p1c $p1d) -and
            (Float-Same $p1a $p1c) -and (Float-Same $p2a $p2c) -and
            [Math]::Abs([double]$p1a) -le 1000000 -and [Math]::Abs([double]$p2a) -le 1000000) {

            $score = 300
            if (Float-Same $p1a $p2a) { $score += 120 }
            if ($p1a -gt 0 -and $p1a -le 10000 -and $p2a -gt 0 -and $p2a -le 10000) { $score += 80 }
            if ($p1b -gt 0 -and $p2d -gt 0) { $score += 40 }

            $cf.Add([pscustomobject]@{
                Score=$score; Type='BEFLOAT32'; Offset=('0x{0:X}' -f $o)
                P1Address=('0x{0:X}' -f ($p1Base+[uint64]$o))
                P2Address=('0x{0:X}' -f ($p2Base+[uint64]$o))
                P1Full=('{0:R}' -f $p1a); P1Damaged=('{0:R}' -f $p1b); P1Delta=('{0:R}' -f ($p1a-$p1b))
                P2Full=('{0:R}' -f $p2c); P2Damaged=('{0:R}' -f $p2d); P2Delta=('{0:R}' -f ($p2c-$p2d))
            })
        }
    }

    # Do not use + on generic List[object] collections in Windows PowerShell.
    # Enumerate them into one ordinary object array instead.
    $all = @(
        foreach ($item in $c32) { $item }
        foreach ($item in $c16) { $item }
        foreach ($item in $cf)  { $item }
    )
    $top = @($all | Sort-Object -Property @{Expression={$_.Score};Descending=$true},Type,Offset | Select-Object -First 100)

    $outFile = Join-Path $outDir ("REAL-health-candidates-$stamp.txt")

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('PATRAS1993 TEKKEN REVOLUTION REAL HEALTH FINDER v2')
    $lines.Add(('RPCS3 PID: {0}' -f $proc.Id))
    $lines.Add(('P1 base: 0x{0:X}' -f $p1Base))
    $lines.Add(('P2 base: 0x{0:X}' -f $p2Base))
    $lines.Add(('Stride: 0x{0:X}' -f $stride))
    $lines.Add(('Scan size: 0x{0:X}' -f $scanSize))
    $lines.Add('')
    $lines.Add(('BE32 candidates: ' + $c32.Count))
    $lines.Add(('BE16 candidates: ' + $c16.Count))
    $lines.Add(('BEFLOAT32 candidates: ' + $cf.Count))
    $lines.Add('')
    $lines.Add('Score Type Offset P1Address P2Address P1Full P1Damaged P1Delta P2Full P2Damaged P2Delta')

    foreach ($c in $top) {
        $lines.Add(('{0} {1} {2} {3} {4} {5} {6} {7} {8} {9} {10}' -f
            $c.Score,$c.Type,$c.Offset,$c.P1Address,$c.P2Address,
            $c.P1Full,$c.P1Damaged,$c.P1Delta,$c.P2Full,$c.P2Damaged,$c.P2Delta))
    }

    [IO.File]::WriteAllLines($outFile,$lines,(New-Object System.Text.UTF8Encoding($false)))

    Write-Host ''
    Write-Host ('BE32: ' + $c32.Count + '; BE16: ' + $c16.Count + '; FLOAT: ' + $cf.Count)
    if ($top.Count -gt 0) {
        Write-Host 'Najlepsi kandydaci:'
        foreach ($c in ($top | Select-Object -First 12)) {
            Write-Host ('Score {0}; {1}; offset {2}; P1 {3}->{4}; P2 {5}->{6}' -f
                $c.Score,$c.Type,$c.Offset,$c.P1Full,$c.P1Damaged,$c.P2Full,$c.P2Damaged)
        }
    }
    else {
        Write-Host 'Brak kandydata spelniajacego wszystkie cztery warunki.'
        Write-Host 'Powtorz test, pilnujac aby w kroku 2 obrazenia dostal tylko P1, a w kroku 4 tylko P2.'
    }

    Write-Host ''
    Write-Host ('Raport: ' + $outFile)
    Write-Host 'Wyslij mi REAL-health-candidates-*.txt.'
}
finally {
    if ($handle -ne [IntPtr]::Zero) {
        [void][PatrasHealthMemory]::CloseHandle($handle)
    }
}
