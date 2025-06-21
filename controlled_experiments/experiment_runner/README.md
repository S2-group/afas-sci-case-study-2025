# Experiment Runner Framework

## Architecture

### Core Components

**Classes:**
- **PowerLogger**: Energy measurement and VM process monitoring
- **ExternalMachineAPI**: SSH-based VM communication and command execution
- **ProcessManager**: Application lifecycle management and cleanup
- **RunnerConfig**: Experiment orchestration and event handling

#### Experiment Configurations
Individual experiment definitions in `ExperimentConfigs/`:

```
ExperimentConfigs/
├── P1/                   # Baseline experiments
│   ├── E0.py             # Warm-up runs (5 repetitions)
│   └── E1.py             # Reference baseline (10 repetitions)
├── P2/                   # Configuration optimization experiments
│   ├── E1.py             # Parallelism configuration
│   ├── E2.py             # Logging configuration
│   ├── E3.py             # Caching configuration
│   ├── E4.py             # Compression configuration
│   └── E5.py             # Garbage collection configuration
└── P3/                   # Integrated optimization
    └── E1.py             # Carbon-aware configuration
```

## Energy Measurement System

### PowerLogger Class

```python
class PowerLogger:
    def __init__(self, run_dir: Path, vm_qemu_id: str, sample_interval: float = 0.1):
        self.sample_interval = sample_interval  # 100ms sampling rate
        self.power_data = []                    # In-memory measurement storage
```

**Measurement Capabilities:**
- **RAPL Energy**: CPU and DRAM power consumption via `/sys/class/powercap/intel-rapl`
- **VM Process Metrics**: CPU utilization, memory usage, thread count, I/O operations
- **PowerJoular Integration**: Process-specific energy measurement
- **Temporal Synchronization**: Coordinated measurement across all monitoring tools

### Measurement Data Collection
Each measurement cycle captures:

```python
def log_power_measurements(self, log_file, last_pkg, last_dram, last_read, last_write, last_time):
    # RAPL energy deltas
    cpu_power = (pkg - last_pkg) / (delta * 1e6)      # Watts
    dram_power = (dram - last_dram) / (delta * 1e6)   # Watts
    
    # I/O operation deltas
    delta_read = read_bytes - last_read               # Bytes
    delta_write = write_bytes - last_write            # Bytes
    
    # VM process metrics via psutil
    vm_metrics = self.collect_vm_process_metrics(self.qemu_pid)
```

## VM Communication Infrastructure

### ExternalMachineAPI Class
Manages SSH-based communication with Windows VMs:

```python
class ExternalMachineAPI:
    def __init__(self, hostname=None, username=None, password=None):
        self.ssh = paramiko.SSHClient()
        self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
```

**Communication Protocols:**
- **SSH**: Command execution and parameter configuration
- **SCP**: File transfer for configuration snapshots and log collection
- **HTTP**: Application readiness verification and test execution coordination

## Experimental Lifecycle Management

### Experimental Phases

#### 1. Before Experiment (`before_experiment`)
- VM connectivity verification
- PowerJoular installation validation
- Process cleanup across all VMs
- Initial system state verification

#### 2. Before Run (`before_run`)
- Complete VM restart cycle (`sudo qm stop 111 && sudo qm start 111`)
- System cache clearing (OS and SQL Server)
- 600-second stabilization period
- Database restoration to standardized state

#### 3. Start Run (`start_run`)
- Application configuration modification
- AFAS SB application startup with parameter application
- Configuration file backup and verification
- Application readiness verification via log pattern matching

#### 4. Start Measurement (`start_measurement`)
- PowerJoular process monitoring initiation
- RAPL energy measurement baseline establishment
- psutil system monitoring activation
- Measurement synchronization and validation

#### 5. Interact (`interact`)
- Playwright test suite execution on Test VM
- Real-time test progress monitoring
- Test result collection and validation
- Functional correctness verification

#### 6. Stop Measurement (`stop_measurement`)
- PowerJoular process termination
- Final energy measurement collection
- System resource monitoring conclusion
- Measurement data integrity verification

#### 7. Stop Run (`stop_run`)
- Application process cleanup
- VM state reset preparation
- Resource utilization normalization
- Environment preparation for next iteration

#### 8. Populate Run Data (`populate_run_data`)
- Energy measurement processing and SCI calculation
- Functional test result analysis
- Performance metric aggregation
- Statistical data preparation

## Configuration Management

### Parameter Application Methods

#### Environment Variables (Parallelism, GC)
```python
powershell_command = f"""powershell -Command "
    Remove-Item env:DefaultMaxParallelism -ErrorAction SilentlyContinue;
    $env:DefaultMaxParallelism = {parallelism_value};
    .\\run.ps1"
"""
```

#### Application Configuration (Logging, Caching, Compression)
```python
update_command = f'powershell -File "C:\\anta\\set_logging_config.ps1" -enableTracing "{enable_tracing}"'
```

### Configuration Backup and Restoration
```python
backup_command = """powershell -Command "
    if (-not (Test-Path 'C:\\anta\\config_backups')) {
        New-Item -Path 'C:\\anta\\config_backups' -ItemType Directory -Force
    }
    Copy-Item 'C:\\anta\\sb\\appsettings.json' 'C:\\anta\\config_backups\\appsettings.json.original'
"""
```