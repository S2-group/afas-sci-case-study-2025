param (
    [Parameter(Mandatory=$false)]
    [int]$CPUCap = 0,
    
    [Parameter(Mandatory=$false)]
    [int]$MemoryCap = 0
)

$sqlClearRG = @"
IF EXISTS (SELECT * FROM sys.resource_governor_configuration WHERE classifier_function_id IS NOT NULL)
BEGIN
    ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = NULL);
    ALTER RESOURCE GOVERNOR RECONFIGURE;
END

IF OBJECT_ID('dbo.ResourceGovernorClassifier') IS NOT NULL
    DROP FUNCTION dbo.ResourceGovernorClassifier;

IF EXISTS (SELECT * FROM sys.resource_governor_workload_groups WHERE name = 'AFASWorkloadGroup')
    DROP WORKLOAD GROUP AFASWorkloadGroup;

IF EXISTS (SELECT * FROM sys.resource_governor_resource_pools WHERE name = 'AFASPool')
    DROP RESOURCE POOL AFASPool;

ALTER RESOURCE GOVERNOR RECONFIGURE;
"@

sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q $sqlClearRG

if ($CPUCap -gt 0 -or $MemoryCap -gt 0) {
    Write-Host "Configuring SQL Server with the following caps:"
    if ($CPUCap -gt 0) { Write-Host "- CPU Cap: $CPUCap%" }
    if ($MemoryCap -gt 0) { Write-Host "- Memory Cap: $MemoryCap%" }
} else {
    Write-Host "Configuring SQL Server with no resource caps"
}

sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q @"
IF DB_ID('f_afasnext_main') IS NOT NULL
BEGIN
    ALTER DATABASE f_afasnext_main SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE f_afasnext_main;
END
"@

sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q @"
IF DB_ID('f_afasnext_s1') IS NOT NULL
BEGIN
    ALTER DATABASE f_afasnext_s1 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE f_afasnext_s1;
END
"@

sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "RESTORE DATABASE f_afasnext_main
FROM DISK = 'C:\Temp\f_rutgertemplate-1.bak'
WITH REPLACE, RECOVERY,
MOVE 'f_stabletestinrichting-1' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\f_afasnext_main.mdf',
MOVE 'f_stabletestinrichting-1_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\f_afasnext_main_log.ldf'"

sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "RESTORE DATABASE f_afasnext_s1
FROM DISK = 'C:\Temp\f_rutgertemplate-1-S1.bak'
WITH REPLACE, RECOVERY,
MOVE 'f_stabletestinrichting-1-S1' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\f_afasnext_s1.mdf',
MOVE 'f_stabletestinrichting-1-S1_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\f_afasnext_s1_log.ldf'"

sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "EXEC sp_configure 'show advanced options', 1; RECONFIGURE;"
sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "EXEC sp_configure 'max server memory (MB)', 24576; RECONFIGURE;"

sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "EXEC sp_configure 'optimize for ad hoc workloads', 1; RECONFIGURE;"

sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "EXEC sp_configure 'cost threshold for parallelism', 50; RECONFIGURE;"

sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "EXEC sp_configure 'max degree of parallelism', 4; RECONFIGURE;"

sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "ALTER DATABASE tempdb MODIFY FILE (NAME = 'tempdev', SIZE = 512MB, FILEGROWTH = 64MB);"
sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "ALTER DATABASE tempdb MODIFY FILE (NAME = 'temp2', SIZE = 512MB, FILEGROWTH = 64MB);"
sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "ALTER DATABASE tempdb MODIFY FILE (NAME = 'temp3', SIZE = 512MB, FILEGROWTH = 64MB);"
sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "ALTER DATABASE tempdb MODIFY FILE (NAME = 'temp4', SIZE = 512MB, FILEGROWTH = 64MB);"
sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "ALTER DATABASE tempdb MODIFY FILE (NAME = 'temp5', SIZE = 512MB, FILEGROWTH = 64MB);"
sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "ALTER DATABASE tempdb MODIFY FILE (NAME = 'temp6', SIZE = 512MB, FILEGROWTH = 64MB);"
sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "ALTER DATABASE tempdb MODIFY FILE (NAME = 'temp7', SIZE = 512MB, FILEGROWTH = 64MB);"
sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "ALTER DATABASE tempdb MODIFY FILE (NAME = 'temp8', SIZE = 512MB, FILEGROWTH = 64MB);"
sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "ALTER DATABASE tempdb MODIFY FILE (NAME = 'templog', SIZE = 512MB, FILEGROWTH = 64MB);"

sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "ALTER DATABASE f_afasnext_main SET RECOVERY SIMPLE;"
sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "ALTER DATABASE f_afasnext_s1 SET RECOVERY SIMPLE;"

if ($CPUCap -gt 0 -or $MemoryCap -gt 0) {
    $actualCPUCap = if ($CPUCap -gt 0) { $CPUCap } else { 100 }
    $actualMemoryCap = if ($MemoryCap -gt 0) { $MemoryCap } else { 100 }
    
    @"
    -- Create a Resource Pool with the specified caps
    IF EXISTS (SELECT name FROM sys.resource_governor_resource_pools WHERE name = 'AFASPool')
        ALTER RESOURCE POOL AFASPool WITH (
            MAX_CPU_PERCENT = $actualCPUCap,
            MIN_CPU_PERCENT = 0,
            MAX_MEMORY_PERCENT = $actualMemoryCap,
            MIN_MEMORY_PERCENT = 0
        );
    ELSE
        CREATE RESOURCE POOL AFASPool WITH (
            MAX_CPU_PERCENT = $actualCPUCap,
            MIN_CPU_PERCENT = 0,
            MAX_MEMORY_PERCENT = $actualMemoryCap,
            MIN_MEMORY_PERCENT = 0
        );

    -- Create a Workload Group that uses this Pool
    IF EXISTS (SELECT name FROM sys.resource_governor_workload_groups WHERE name = 'AFASWorkloadGroup')
        ALTER WORKLOAD GROUP AFASWorkloadGroup USING AFASPool;
    ELSE
        CREATE WORKLOAD GROUP AFASWorkloadGroup USING AFASPool WITH (
            MAX_DOP = 4,
            REQUEST_MAX_MEMORY_GRANT_PERCENT = 5,
            REQUEST_MAX_CPU_TIME_SEC = 0,
            REQUEST_MEMORY_GRANT_TIMEOUT_SEC = 0,
            MAX_REQUESTS_PER_CPU = 0,
            GROUP_MAX_REQUESTS = 0
        );

    -- Create a function to classify connections to this workload group
    IF OBJECT_ID('dbo.ResourceGovernorClassifier') IS NOT NULL
        DROP FUNCTION dbo.ResourceGovernorClassifier;
    GO

    CREATE FUNCTION dbo.ResourceGovernorClassifier() 
    RETURNS sysname
    WITH SCHEMABINDING
    AS
    BEGIN
        -- This will assign all connections to our capped workload group
        RETURN 'AFASWorkloadGroup';
    END;
    GO

    -- Register the classifier function
    ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = dbo.ResourceGovernorClassifier);

    -- Apply the configuration
    ALTER RESOURCE GOVERNOR RECONFIGURE;
"@ | Set-Content -Path "$pwd\sql_resource_caps.sql"

    sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -i "$pwd\sql_resource_caps.sql"
    
    sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q @"
    SELECT 
        rp.name AS [Resource Pool Name],
        rp.max_cpu_percent,
        rp.max_memory_percent,
        wg.name AS [Workload Group Name],
        wg.max_dop,
        wg.request_max_memory_grant_percent
    FROM sys.resource_governor_resource_pools rp
    JOIN sys.resource_governor_workload_groups wg ON rp.pool_id = wg.pool_id
    WHERE rp.name = 'AFASPool';

    SELECT 
        is_enabled,
        classifier_function_id
    FROM sys.resource_governor_configuration;
"@
}
else {
    sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q @"
    -- Disable the Resource Governor if it's enabled
    IF EXISTS (SELECT 1 FROM sys.resource_governor_configuration WHERE is_enabled = 1)
    BEGIN
        ALTER RESOURCE GOVERNOR DISABLE;
    END
"@
    Write-Host "Resource Governor is disabled (no caps applied)"
}

sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "SELECT name, recovery_model_desc FROM sys.databases WHERE name IN ('f_afasnext_main', 'f_afasnext_s1');"
sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "SELECT name, size/128.0 AS SizeMB, size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeMB FROM tempdb.sys.database_files;"
sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "SELECT * FROM sys.configurations WHERE name IN ('max server memory (MB)', 'optimize for ad hoc workloads', 'cost threshold for parallelism', 'max degree of parallelism');"

if ($CPUCap -gt 0 -or $MemoryCap -gt 0) {
    Write-Host "SQL Server configured with the following resource caps:"
    if ($CPUCap -gt 0) { Write-Host "- CPU Cap: $CPUCap%" }
    if ($MemoryCap -gt 0) { Write-Host "- Memory Cap: $MemoryCap%" }
} else {
    Write-Host "SQL Server configured with no resource caps"
}
