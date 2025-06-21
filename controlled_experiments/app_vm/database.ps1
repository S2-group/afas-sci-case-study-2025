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

sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "SELECT name, recovery_model_desc FROM sys.databases WHERE name IN ('f_afasnext_main', 'f_afasnext_s1');"
sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "SELECT name, size/128.0 AS SizeMB, size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeMB FROM tempdb.sys.database_files;"
sqlcmd -S localhost -U sa -P "YourStrongPassword123!" -Q "SELECT * FROM sys.configurations WHERE name IN ('max server memory (MB)', 'optimize for ad hoc workloads', 'cost threshold for parallelism', 'max degree of parallelism');"
