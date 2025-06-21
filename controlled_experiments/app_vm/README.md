# Application VM Configuration Scripts

## Configuration Scripts

Application launcher with optional resource constraints (`run.ps1`):

```powershell
param (
    [Parameter(Mandatory=$false)]
    [int]$CPUCap = 0,
    
    [Parameter(Mandatory=$false)]
    [int]$MemoryCap = 0
)
```

**Functionality:**
- **Resource Constraints**: Optional CPU and memory limitations for the database
- **Database Initialization**: Executes database preparation scripts
- **Application Launch**: Starts `Afas.Cqrs.Webserver.exe` with current configuration

### JSON Structure (`appsettings.json`)
The application configuration follows standard .NET configuration patterns:

```json
{
    "hostSettings": {
        "diagnostics": {
            "enableTracing": true,
            "consoleLogging": false
        },
        "responseCompression": {
            "enableResponseCompression": false
        }
    },
    "Logging": {
        "LogLevel": {
            "Default": "Warning"
        }
    },
    "cqrsConfig#json": {
        "eventManager": {
            "eventStreamReader": {
                "type": "...",
                "parameters": [
                    { "maxCachedItems": 10000 },
                    { "expirationInSeconds": 300 }
                ]
            }
        }
    }
}
```