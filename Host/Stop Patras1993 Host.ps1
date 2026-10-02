$ErrorActionPreference = 'SilentlyContinue'

Write-Host ''
Write-Host 'PATRAS1993 - STOP HOST'
Write-Host ''

$repo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$rpcn = Join-Path $repo 'local_rpcn\rpcn.exe'
$backend = Join-Path $repo 'local_backend\server.ps1'

$stopped = 0

Get-CimInstance Win32_Process | Where-Object {
    $_.Name -ieq 'rpcn.exe' -and $_.ExecutablePath -eq $rpcn
} | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    Write-Host ('RPCN zatrzymany. PID ' + $_.ProcessId)
    $stopped++
}

Get-CimInstance Win32_Process | Where-Object {
    ($_.Name -ieq 'powershell.exe' -or $_.Name -ieq 'pwsh.exe') -and
    $_.CommandLine -like ('*' + $backend + '*')
} | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    Write-Host ('Backend zatrzymany. PID ' + $_.ProcessId)
    $stopped++
}

if ($stopped -eq 0) {
    Write-Host 'Nie znaleziono procesow Patras1993 Host do zatrzymania.'
}
else {
    Write-Host ''
    Write-Host 'Patras1993 Host zatrzymany.'
}
