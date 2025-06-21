param(
    [Parameter(Mandatory=$true)]
    [int]$maxCachedItems,
    
    [Parameter(Mandatory=$true)]
    [int]$expirationSeconds
)

$configPath = 'C:\anta\sb\appsettings.json'
$backupDir = 'C:\anta\config_backups'
$backupPath = "$backupDir\appsettings.json.original"
$tempPath = 'C:\anta\sb\appsettings-temp.json'
$jqPath = 'C:\Tools\jq.exe'

Write-Output "Starting configuration management..."

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

Write-Output "Updating configuration with maxCachedItems=$maxCachedItems, expirationSeconds=$expirationSeconds"

$config = Get-Content $configPath -Raw | ConvertFrom-Json

if (-not ($config.PSObject.Properties.Name -contains 'cqrsConfig#json')) {
    Write-Output "Adding cqrsConfig#json property"
    $config | Add-Member -NotePropertyName 'cqrsConfig#json' -NotePropertyValue @{}
}

if (-not ($config.'cqrsConfig#json'.PSObject.Properties.Name -contains 'eventManager')) {
    Write-Output "Adding eventManager property"
    $config.'cqrsConfig#json' | Add-Member -NotePropertyName 'eventManager' -NotePropertyValue @{}
}

if (-not ($config.'cqrsConfig#json'.eventManager.PSObject.Properties.Name -contains 'eventStreamReader')) {
    Write-Output "Adding eventStreamReader property"
    $config.'cqrsConfig#json'.eventManager | Add-Member -NotePropertyName 'eventStreamReader' -NotePropertyValue @{}
}

$oldType = $null
if ($config.'cqrsConfig#json'.eventManager.eventStreamReader.PSObject.Properties.Name -contains 'type') {
    $oldType = $config.'cqrsConfig#json'.eventManager.eventStreamReader.type
}

$config.'cqrsConfig#json'.eventManager.eventStreamReader = @{ 
    type = $oldType
    parameters = @(
        @{ maxCachedItems = $maxCachedItems }
        @{ expirationInSeconds = $expirationSeconds }
    )
}

$config | ConvertTo-Json -Depth 32 | Set-Content -Encoding utf8 -Path $tempPath

& $jqPath --indent 2 . $tempPath | Set-Content -Encoding utf8 -Path $configPath

Remove-Item $tempPath -Force

$newConfig = Get-Content $configPath -Raw | ConvertFrom-Json
$maxItems = $newConfig.'cqrsConfig#json'.eventManager.eventStreamReader.parameters[0].maxCachedItems
$expiration = $newConfig.'cqrsConfig#json'.eventManager.eventStreamReader.parameters[1].expirationInSeconds
Write-Output "Configuration updated: maxCachedItems=$maxItems, expirationInSeconds=$expiration"