param(
    [Parameter(Mandatory=$true)]
    [string]$enableResponseCompression
)

$enableCompressionBool = if ($enableResponseCompression -eq "true" -or $enableResponseCompression -eq "$true") { $true } else { $false }

$configPath = 'C:\anta\sb\appsettings.json'
$backupDir = 'C:\anta\config_backups'
$backupPath = "$backupDir\appsettings.json.original"
$tempPath = 'C:\anta\sb\appsettings-temp.json'
$jqPath = 'C:\Tools\jq.exe'

Write-Output "Starting compression configuration management..."

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

Write-Output "Updating configuration with enableResponseCompression=$enableCompressionBool"

$config = Get-Content $configPath -Raw | ConvertFrom-Json

if (-not ($config.PSObject.Properties.Name -contains 'hostSettings')) {
    Write-Output "Adding hostSettings property"
    $config | Add-Member -NotePropertyName 'hostSettings' -NotePropertyValue @{}
}

if (-not ($config.hostSettings.PSObject.Properties.Name -contains 'responseCompression')) {
    Write-Output "Adding responseCompression property"
    $config.hostSettings | Add-Member -NotePropertyName 'responseCompression' -NotePropertyValue @{
        enableResponseCompression = $enableCompressionBool
    }
} else {
    Write-Output "Updating existing responseCompression property"
    $config.hostSettings.responseCompression.enableResponseCompression = $enableCompressionBool
}

$config | ConvertTo-Json -Depth 32 | Set-Content -Encoding utf8 -Path $tempPath

& $jqPath --indent 2 . $tempPath | Set-Content -Encoding utf8 -Path $configPath

Remove-Item $tempPath -Force

$newConfig = Get-Content $configPath -Raw | ConvertFrom-Json
$compressionEnabled = $newConfig.hostSettings.responseCompression.enableResponseCompression
Write-Output "Configuration updated: enableResponseCompression=$compressionEnabled"