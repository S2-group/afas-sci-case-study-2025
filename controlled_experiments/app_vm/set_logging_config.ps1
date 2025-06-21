param(
    [Parameter(Mandatory=$true)]
    [string]$enableTracing,
    
    [Parameter(Mandatory=$true)]
    [string]$consoleLogging,
    
    [Parameter(Mandatory=$true)]
    [string]$logLevel
)

$enableTracingBool = if ($enableTracing -eq "true" -or $enableTracing -eq "$true") { $true } else { $false }
$consoleLoggingBool = if ($consoleLogging -eq "true" -or $consoleLogging -eq "$true") { $true } else { $false }

$configPath = 'C:\anta\sb\appsettings.json'
$backupDir = 'C:\anta\config_backups'
$backupPath = "$backupDir\appsettings.json.original"
$tempPath = 'C:\anta\sb\appsettings-temp.json'
$jqPath = 'C:\Tools\jq.exe'

Write-Output "Starting logging configuration management..."

if (-not (Test-Path $backupDir)) {
    Write-Output "Creating backup directory: $backupDir"
    New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path $backupPath)) {
    Write-Output "Creating initial backup of configuration"
    Copy-Item $configPath $backupPath -Force
} else {
    Write-Output "Restoring configuration from backup"
    Copy-Item $backupPath $configPath -Force
}

Write-Output "Updating configuration with enableTracing=$enableTracingBool, consoleLogging=$consoleLoggingBool, logLevel=$logLevel"

$config = Get-Content $configPath -Raw | ConvertFrom-Json

if (-not ($config.PSObject.Properties.Name -contains 'hostSettings')) {
    Write-Output "Adding hostSettings property"
    $config | Add-Member -NotePropertyName 'hostSettings' -NotePropertyValue @{}
}

if (-not ($config.hostSettings.PSObject.Properties.Name -contains 'diagnostics')) {
    Write-Output "Adding diagnostics property"
    $config.hostSettings | Add-Member -NotePropertyName 'diagnostics' -NotePropertyValue @{}
}

if (-not ($config.PSObject.Properties.Name -contains 'Logging')) {
    Write-Output "Adding Logging property"
    $config | Add-Member -NotePropertyName 'Logging' -NotePropertyValue @{}
}

if (-not ($config.Logging.PSObject.Properties.Name -contains 'LogLevel')) {
    Write-Output "Adding LogLevel property"
    $config.Logging | Add-Member -NotePropertyName 'LogLevel' -NotePropertyValue @{}
}

$config.hostSettings.diagnostics.enableTracing = $enableTracingBool
$config.hostSettings.diagnostics.consoleLogging = $consoleLoggingBool
$config.Logging.LogLevel.Default = $logLevel

$config | ConvertTo-Json -Depth 32 | Set-Content -Encoding utf8 -Path $tempPath

& $jqPath --indent 2 . $tempPath | Set-Content -Encoding utf8 -Path $configPath

Remove-Item $tempPath -Force

$newConfig = Get-Content $configPath -Raw | ConvertFrom-Json
Write-Output "Configuration updated: enableTracing=$($newConfig.hostSettings.diagnostics.enableTracing), consoleLogging=$($newConfig.hostSettings.diagnostics.consoleLogging), logLevel=$($newConfig.Logging.LogLevel.Default)"