$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$log = Join-Path $root 'server.log'
"START $(Get-Date -Format o)" | Set-Content -LiteralPath $log -Encoding utf8

$thumbFile = Join-Path $root 'server_cert_thumbprint.txt'
if (-not (Test-Path -LiteralPath $thumbFile)) {
    throw 'Brak server_cert_thumbprint.txt. Uruchom Host\Setup Patras1993 Host.cmd jako administrator.'
}

$thumbprint = (Get-Content -LiteralPath $thumbFile -Raw).Trim()
$cert = Get-Item "Cert:\CurrentUser\My\$thumbprint" -ErrorAction Stop

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, 443)
$listener.Start()
"LISTEN 0.0.0.0:443 thumbprint=$($cert.Thumbprint)" | Add-Content -LiteralPath $log

function Send-Response {
    param(
        $Ssl,
        [int]$Status,
        [string]$ContentType,
        [byte[]]$Body,
        [hashtable]$ExtraHeaders
    )

    $reason = if ($Status -eq 200) { 'OK' } elseif ($Status -eq 404) { 'Not Found' } else { 'Error' }
    $crlf = [char]13 + [char]10
    $headers = "HTTP/1.1 $Status $reason$crlf"
    $headers += "Content-Type: $ContentType$crlf"
    $headers += "Content-Length: $($Body.Length)$crlf"
    $headers += "Connection: close$crlf"

    if ($ExtraHeaders) {
        foreach ($key in $ExtraHeaders.Keys) {
            $headers += "${key}: $($ExtraHeaders[$key])$crlf"
        }
    }

    $headers += $crlf
    $headerBytes = [Text.Encoding]::ASCII.GetBytes($headers)
    $Ssl.Write($headerBytes, 0, $headerBytes.Length)

    if ($Body.Length -gt 0) {
        $Ssl.Write($Body, 0, $Body.Length)
    }

    $Ssl.Flush()
}

function Read-Bytes([string]$FileName) {
    $filePath = Join-Path $root $FileName
    if (-not (Test-Path -LiteralPath $filePath)) {
        throw "Brak pliku backendu: $FileName"
    }
    return [IO.File]::ReadAllBytes($filePath)
}

try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        $ssl = $null
        $reader = $null

        try {
            $ssl = [System.Net.Security.SslStream]::new($client.GetStream(), $false)
            $ssl.AuthenticateAsServer(
                $cert,
                $false,
                [System.Security.Authentication.SslProtocols]::Tls12,
                $false
            )

            $reader = [IO.StreamReader]::new(
                $ssl,
                [Text.Encoding]::ASCII,
                $false,
                1024,
                $true
            )

            $requestLine = $reader.ReadLine()
            if ([string]::IsNullOrWhiteSpace($requestLine)) {
                continue
            }

            $parts = $requestLine.Split(' ')
            if ($parts.Count -lt 2) {
                throw "Nieprawidlowa linia HTTP: $requestLine"
            }

            $method = $parts[0]
            $path = $parts[1]
            $hostHeader = ''
            $userAgent = ''

            while (($header = $reader.ReadLine()) -ne $null -and $header -ne '') {
                if ($header -match '^(?i)Host:\s*(.+)$') {
                    $hostHeader = $Matches[1].Trim()
                }
                elseif ($header -match '^(?i)User-Agent:\s*(.+)$') {
                    $userAgent = $Matches[1].Trim()
                }
            }

            "$(Get-Date -Format o) $method host=$hostHeader path=$path ua=$userAgent" |
                Add-Content -LiteralPath $log

            switch -Regex ($path) {
                '^/resolve/NPUB31250$' {
                    Send-Response $ssl 200 'application/json' (Read-Bytes 'resolve_NPUB31250.json') @{}
                    break
                }
                '^/patches/tr$' {
                    Send-Response $ssl 200 'application/octet-stream' (Read-Bytes 'patches_tr.bin') @{
                        'x-comm-id' = 'NPWR04645'
                        'x-sub-id' = '01'
                        'x-title-id' = 'NPUB31250'
                    }
                    break
                }
                '^/modules/tr/manifest$' {
                    Send-Response $ssl 200 'application/json' (Read-Bytes 'modules_tr_manifest.json') @{}
                    break
                }
                '^/modules/tr/tr_logic\.dll$' {
                    Send-Response $ssl 200 'application/octet-stream' (Read-Bytes 'tr_logic.dll') @{}
                    break
                }
                '^/launcher/config$' {
                    Send-Response $ssl 200 'application/json' (Read-Bytes 'launcher_config.json') @{}
                    break
                }
                '^/launcher/restart_epoch$' {
                    Send-Response $ssl 200 'application/json' (Read-Bytes 'restart_epoch.json') @{}
                    break
                }
                '^/launcher/hook/windows$' {
                    Send-Response $ssl 200 'application/octet-stream' (Read-Bytes 'version.dll.original') @{}
                    break
                }
                '^/launcher/updater/windows/binary$' {
                    Send-Response $ssl 200 'application/octet-stream' (Read-Bytes 'tr_updater.exe') @{}
                    break
                }
                '^/launcher/update/windows/manifest$' {
                    $body = [Text.Encoding]::UTF8.GetBytes('{"available":false,"file_size":0,"filename":"","sha256":"","signature":""}')
                    Send-Response $ssl 200 'application/json' $body @{}
                    break
                }
                default {
                    $body = [Text.Encoding]::UTF8.GetBytes('{"detail":"Not Found"}')
                    Send-Response $ssl 404 'application/json' $body @{}
                }
            }
        }
        catch {
            "$(Get-Date -Format o) ERROR $($_.Exception.Message)" | Add-Content -LiteralPath $log
        }
        finally {
            if ($reader) { try { $reader.Dispose() } catch {} }
            if ($ssl) { try { $ssl.Dispose() } catch {} }
            try { $client.Close() } catch {}
        }
    }
}
finally {
    try { $listener.Stop() } catch {}
}
