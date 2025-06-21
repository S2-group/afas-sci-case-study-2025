# Controlled Experiments

## Experimental Design

### Phase Structure
1. **Phase 1 (P1)**: Baseline Configuration
   - P1_E1: Reference baseline (10 repetitions)

2. **Phase 2 (P2)**: Individual Configuration Optimization
   - P2_E1: Parallelism configuration (40 runs across 4 settings)
   - P2_E2: Logging configuration (20 runs across 2 settings)
   - P2_E3: Caching configuration (20 runs across 2 settings)
   - P2_E4: Compression configuration (10 runs, 1 setting)
   - P2_E5: Garbage collection configuration (40 runs across 4 settings)

3. **Phase 3 (P3)**: Integrated Optimization
   - P3_E1: Carbon-aware combined configuration (10 runs, 1 setting)

### Configuration Categories

#### Parallelism Configuration (P2_E1)
- **DefaultMaxParallelism**: Thread pool sizing (4, 8, 16)
- **DefaultMaxLookAhead**: Work queue depth (12, 24, 48)

#### Logging Configuration (P2_E2)
- **enableTracing**: Tracing toggle
- **consoleLogging**: Console output control
- **logLevel**: Minimum severity threshold (Warning, Error)

#### Caching Configuration (P2_E3)
- **maxCachedItems**: Cache capacity (10,000, 20,000 items)
- **expirationInSeconds**: TTL settings (60, 300 seconds)

#### Compression Configuration (P2_E4)
- **enableResponseCompression**: HTTP response compression toggle

#### Garbage Collection Configuration (P2_E5)
- **DOTNET_gcServer**: Server GC mode enablement
- **DOTNET_gcConcurrent**: Concurrent collection control
- **DOTNET_GCConserveMemory**: Memory conservation level (0-9 scale)
- **DOTNET_GCDynamicAdaptationMode**: Adaptive heap sizing
- **Additional GC parameters**: LOH threshold, heap count, affinity settings

## Measurement Infrastructure

### Energy Monitoring
- **PowerJoular**: Process-specific energy measurement
  - Direct process energy attribution
  - CPU and total power consumption tracking
  - Sub-second temporal resolution

- **psutil**: System resource monitoring
  - CPU utilization percentages
  - Memory consumption (RSS, VMS)
  - I/O operation counts and byte transfers
  - Thread count monitoring

### Functional Testing
- **Test Suite**: 79 functional scenarios from AFAS test suite
- **Framework**: Playwright for browser automation
- **Coverage**: Core business processes requiring substantial computation
- **Validation**: Success rate and execution duration tracking

## Execution Protocol

### Pre-Experiment Setup
1. **VM State Reset**
   ```bash
   sudo qm stop 111 && sudo qm start 111
   ```

2. **System Cache Clearing**
   ```bash
   sudo sync
   sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
   ```

3. **SQL Server Cache Clearing**
   ```sql
   DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE; DBCC FREESYSTEMCACHE('ALL');
   ```

4. **Stabilization**
   - 300-second VM boot delay
   - 600-second stabilization period

### Experimental Run Sequence
1. **Environment Reset**: VM restart and cache clearing
2. **Configuration Application**: Parameter modification via PowerShell scripts
3. **Application Startup**: AFAS SB initialization with monitoring
4. **Measurement Initiation**: PowerJoular and psutil monitoring start
5. **Test Execution**: Playwright test suite execution
6. **Measurement Collection**: Energy and performance data capture
7. **Environment Cleanup**: Process termination and data collection

### Data Collection
Each experimental run generates:
- **Power Log**: `power_log.csv` (RAPL energy, VM metrics)
- **PowerJoular Output**: `powerjoular_*.csv` (process-level energy)
- **Test Results**: `scenario_summary.csv` (functional test outcomes)
- **Application Logs**: `app_vm_startup.log` (application initialization)
- **Configuration Snapshot**: `appsettings.json` (applied parameters)

## Output Structure

### Experimental Results
```
experiments/
├── P1_E1/                         # Baseline experiment
│   ├── metadata.json              # Experiment configuration
│   ├── run_0_repetition_0/        # Individual run data
│   │   ├── power_log.csv          # Energy measurements
│   │   ├── powerjoular_*.csv      # Process energy data
│   │   ├── scenario_summary.csv   # Test execution results
│   │   └── app_vm_startup.log     # Application logs
│   └── run_table.csv              # Aggregated results
└── [P2_E1 through P3_E1]/         # Additional experiments
```