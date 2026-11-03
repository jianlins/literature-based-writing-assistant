[CmdletBinding()]
param(
    [ValidateRange(1, 65535)]
    [int]$Port = 9222,

    [string]$ChromePath
)

$ErrorActionPreference = 'Stop'

function Get-ChromePath {
    param([string]$RequestedPath)

    if ($RequestedPath) {
        if (Test-Path -LiteralPath $RequestedPath -PathType Leaf) {
            return (Resolve-Path -LiteralPath $RequestedPath).Path
        }

        throw "The Chrome executable supplied with -ChromePath does not exist: $RequestedPath"
    }

    $candidates = @(
        (Get-Command chrome.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1),
        (Get-Command chrome -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1),
        (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe'),
        (Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe')
    ) | Where-Object { $_ }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    return $null
}

function Test-CdpBrowser {
    param([int]$RequestedPort)

    try {
        $version = Invoke-RestMethod -Uri "http://127.0.0.1:$RequestedPort/json/version" -TimeoutSec 2
        return -not [string]::IsNullOrWhiteSpace([string]$version.webSocketDebuggerUrl)
    } catch {
        return $false
    }
}

try {
    $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $profileConfig = Join-Path $projectRoot 'config\browser-profile.local.json'
    $profileSource = 'temporary'
    $profileDir = $null
    if (Test-Path -LiteralPath $profileConfig -PathType Leaf) {
        try {
            $profileSettings = Get-Content -LiteralPath $profileConfig -Raw | ConvertFrom-Json
        } catch {
            throw "Invalid browser profile configuration: $profileConfig"
        }
        if (-not $PSBoundParameters.ContainsKey('Port') -and $null -ne $profileSettings.cdp_port) {
            $configuredPortText = [string]$profileSettings.cdp_port
            if ($configuredPortText -notmatch '^\d+$') {
                throw "Invalid CDP port in browser profile configuration: $profileConfig"
            }
            $configuredPort = [int]$configuredPortText
            if ($configuredPort -lt 1 -or $configuredPort -gt 65535) {
                throw "Invalid CDP port in browser profile configuration: $profileConfig"
            }
            $Port = $configuredPort
        }
    }

    if (Test-CdpBrowser -RequestedPort $Port) {
        Write-Host "A CDP browser is already available on port $Port; reuse it instead of starting Chrome."
        exit 0
    }

    $chrome = Get-ChromePath -RequestedPath $ChromePath
    if (-not $chrome) {
        throw @"
Google Chrome could not be found automatically.

Install Google Chrome, or tell your coding assistant where Chrome is installed by providing the full path to chrome.exe. For example:
  powershell -ExecutionPolicy Bypass -File .\.agents\scripts\start-research-chrome.ps1 -ChromePath 'C:\Program Files\Google\Chrome\Application\chrome.exe'

If you are using a chatbot app and it called this script, paste this error and the full path to chrome.exe into the chat. Do not provide a browser profile, password, or other private data.
"@
    }

    # Use the dedicated profile after confirming a new browser is necessary.
    # Without one, create a temporary task-only profile. Keep the port
    # synchronized with .codex/config.toml.
    if ($null -ne $profileSettings) {
        $profileDir = [string]$profileSettings.user_data_dir
        if ([string]::IsNullOrWhiteSpace($profileDir) -or -not (Test-Path -LiteralPath $profileDir -PathType Container)) {
            throw "Configured browser profile directory is unavailable: $profileDir"
        }
        $profileSource = 'configured'
    } else {
        $profileDir = Join-Path ([System.IO.Path]::GetTempPath()) "research-browser-chrome-$Port"
        New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
    }

    Start-Process -FilePath $chrome -ArgumentList @(
        "--remote-debugging-port=$Port",
        "--user-data-dir=$profileDir",
        '--no-first-run',
        '--no-default-browser-check'
    )

    Write-Host "Started $profileSource research Chrome on CDP port $Port."
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
