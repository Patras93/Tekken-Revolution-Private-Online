$ErrorActionPreference='Stop'
$root=Split-Path -Parent $MyInvocation.MyCommand.Path

$subject='CN=patch.tekkenbtb.online'
$cert=Get-ChildItem Cert:\CurrentUser\My | Where-Object {
  $_.Subject -eq $subject -and $_.HasPrivateKey -and $_.NotAfter -gt (Get-Date)
} | Sort-Object NotAfter -Descending | Select-Object -First 1

if(-not $cert){
  $cert=New-SelfSignedCertificate -DnsName 'patch.tekkenbtb.online' -CertStoreLocation 'Cert:\CurrentUser\My' -FriendlyName 'Patras1993 Tekken Revolution Backend' -NotAfter (Get-Date).AddYears(5)
}

$thumb=$cert.Thumbprint.ToUpperInvariant()
$repoRoot = Split-Path -Parent $root
$envFile = Join-Path $repoRoot 'local_backend\server_cert_thumbprint.txt'
[IO.File]::WriteAllText($envFile,$thumb,[Text.UTF8Encoding]::new($false))

New-NetFirewallRule -DisplayName 'Patras1993 Tekken Revolution HTTPS' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 443 -Profile Any -ErrorAction SilentlyContinue | Out-Null
New-NetFirewallRule -DisplayName 'Patras1993 RPCN' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 31313 -Profile Any -ErrorAction SilentlyContinue | Out-Null

Write-Host "Certyfikat: $thumb"
Write-Host 'Port 443: OK'
Write-Host 'Port 31313: OK'
Write-Host 'Nie jest instalowany ani uruchamiany BTB Launcher.'
