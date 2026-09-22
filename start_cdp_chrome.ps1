param(
    [int]$Port = 9222,
    [switch]$Login
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$profilePath = Join-Path $projectRoot 'chrome_profile'
$cdpReadyPath = Join-Path $projectRoot '.cdp_cookie_ready'
$appPath = Join-Path $projectRoot 'tmall_taobao_monitor\app.py'
$pythonPath = 'D:\python\python.exe'
$dashboardUrl = 'http://127.0.0.1:5000/'
$loginUrl = 'https://login.taobao.com/'
$needsLogin = $Login -or -not (Test-Path $cdpReadyPath)
$programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
$chromeCandidates = @(
    (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),
    (Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe')
)
if ($programFilesX86) {
    $chromeCandidates += Join-Path $programFilesX86 'Google\Chrome\Application\chrome.exe'
}
$chromePath = $chromeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $chromePath) {
    throw 'Google Chrome was not found. Install Chrome and try again.'
}

New-Item -ItemType Directory -Force -Path $profilePath | Out-Null

$arguments = @(
    '--remote-debugging-address=127.0.0.1',
    "--remote-debugging-port=$Port",
    "--remote-allow-origins=http://127.0.0.1:$Port",
    "--user-data-dir=$profilePath"
)

function Open-CdpTab {
    param([string]$Url)

    $encodedUrl = [Uri]::EscapeDataString($Url)
    Invoke-RestMethod -Method Put -Uri "http://127.0.0.1:$Port/json/new?$encodedUrl" -TimeoutSec 10 | Out-Null
}

if (-not (Test-NetConnection -ComputerName '127.0.0.1' -Port $Port -InformationLevel Quiet)) {
    $initialUrl = if ($needsLogin) { $loginUrl } else { 'https://www.taobao.com/' }
    Start-Process -FilePath $chromePath -ArgumentList ($arguments + $initialUrl)
    Write-Host "CDP Chrome started: http://127.0.0.1:$Port"
} else {
    Write-Host "CDP Chrome is already running: http://127.0.0.1:$Port"
}
Write-Host "Browser profile: $profilePath"

if ($needsLogin) {
    try {
        Open-CdpTab -Url $loginUrl
        Write-Host 'Taobao login page opened in CDP Chrome.'
    } catch {
        throw "Could not open the Taobao login page through CDP: $($_.Exception.Message)"
    }
    Write-Host 'Complete Taobao login in the opened Chrome window, then press Enter.'
    Read-Host | Out-Null
}

if (-not (Test-Path $pythonPath)) {
    throw "Python was not found: $pythonPath"
}

try {
    Invoke-WebRequest -UseBasicParsing -Uri $dashboardUrl -TimeoutSec 2 | Out-Null
    Write-Host 'Monitor service is already running.'
} catch {
    Start-Process -FilePath $pythonPath -ArgumentList $appPath -WorkingDirectory $projectRoot
    Write-Host 'Monitor service is starting.'
}

$serviceReady = $false
for ($attempt = 1; $attempt -le 15; $attempt++) {
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $dashboardUrl -TimeoutSec 2 | Out-Null
        $serviceReady = $true
        break
    } catch {
        Start-Sleep -Seconds 1
    }
}

if (-not $serviceReady) {
    throw 'Monitor service did not become ready within 15 seconds.'
}

try {
    $syncUrl = 'http://127.0.0.1:5000/api/cdp/sync'
    $syncResponse = Invoke-RestMethod -Uri $syncUrl -Method Post -TimeoutSec 10
    if ($syncResponse.success) {
        New-Item -ItemType File -Force -Path $cdpReadyPath | Out-Null
        Write-Host 'Cookie sync completed.'
    } else {
        throw $syncResponse.message
    }
} catch {
    throw "Cookie sync was not completed: $($_.Exception.Message)"
}

Open-CdpTab -Url $dashboardUrl
Write-Host "Dashboard opened in CDP Chrome: $dashboardUrl"