$configPath = 'C:\anta\sb\appsettings.json'
$tempPath = 'C:\anta\sb\appsettings-temp.json'
$jqPath = 'C:\Tools\jq.exe'

Write-Output "Applying P3 optimized configuration (logging + cache)..."

$config = Get-Content $configPath -Raw | ConvertFrom-Json

Write-Output "1. Applying minimal logging configuration..."

if (-not ($config.PSObject.Properties.Name -contains 'hostSettings')) {
    $config | Add-Member -NotePropertyName 'hostSettings' -NotePropertyValue @{}
}

if (-not ($config.hostSettings.PSObject.Properties.Name -contains 'diagnostics')) {
    $config.hostSettings | Add-Member -NotePropertyName 'diagnostics' -NotePropertyValue @{}
}

$config.hostSettings.diagnostics.enableTracing = $false
$config.hostSettings.diagnostics.consoleLogging = $false

if (-not ($config.PSObject.Properties.Name -contains 'Logging')) {
    $config | Add-Member -NotePropertyName 'Logging' -NotePropertyValue @{}
}

if (-not ($config.Logging.PSObject.Properties.Name -contains 'LogLevel')) {
    $config.Logging | Add-Member -NotePropertyName 'LogLevel' -NotePropertyValue @{}
}

$config.Logging.LogLevel.Default = "Error"

Write-Output "   Minimal logging applied"

Write-Output "2. Applying extended cache configuration..."

if ($config.'cqrsConfig#json'.eventManager.eventStreamReader) {
    $existingType = $config.'cqrsConfig#json'.eventManager.eventStreamReader.type
    
    $config.'cqrsConfig#json'.eventManager.eventStreamReader = @{
        type = $existingType
        parameters = @(
            @{ maxCachedItems = 10000 }
            @{ expirationInSeconds = 300 }
        )
    }
    
    Write-Output "   Extended cache configuration applied"
}

$config | ConvertTo-Json -Depth 32 | Set-Content -Encoding utf8 -Path $tempPath
& $jqPath --indent 2 . $tempPath | Set-Content -Encoding utf8 -Path $configPath
Remove-Item $tempPath -Force

Write-Output "P3 optimized configuration applied successfully"