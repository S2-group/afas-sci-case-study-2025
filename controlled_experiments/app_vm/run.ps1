param (
    [Parameter(Mandatory=$false)]
    [int]$CPUCap = 0,
    
    [Parameter(Mandatory=$false)]
    [int]$MemoryCap = 0
)

if ($CPUCap -gt 0 -or $MemoryCap -gt 0) {
    Write-Host "Running with resource constraints - CPU Cap: $CPUCap%, Memory Cap: $MemoryCap%"
    C:\anta\database_constrained.ps1 -CPUCap $CPUCap -MemoryCap $MemoryCap
} else {
    Write-Host "Running with normal configuration (no constraints)"
    C:\anta\database.ps1
}

C:\anta\sb\backend\Afas.Cqrs.Webserver.exe
