$ErrorActionPreference = 'SilentlyContinue'

Write-Host ''
Write-Host 'PATRAS1993 - STOP HOST v2.2.0'
Write-Host ''

$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$rpcn = Join-Path $repo 'local_rpcn\rpcn.exe'
$stopped=0

Get-CimInstance Win32_Process | Where-Object {
    $_.Name -ieq 'rpcn.exe' -and $_.ExecutablePath -eq $rpcn
} | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    Write-Host ('RPCN zatrzymany. PID '+$_.ProcessId)
    $stopped++
}

if($stopped -eq 0){Write-Host 'RPCN Patras1993 nie byl uruchomiony.'}
else{Write-Host 'Patras1993 Host zatrzymany.'}
