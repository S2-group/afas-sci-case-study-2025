# Baseline Calculation

## Architecture

The pipeline consists of four main stages:

1. **Data Preprocessing**: Raw Azure metrics extraction and standardization
2. **Resource Utilization Processing**: CPU and memory usage calculation
3. **Data Standardization**: Consistent temporal resampling and interpolation
4. **SCI Calculation**: SCI score calculation

## Data Sources

### Azure Monitor Metrics (CPU and memory utilization)

- **VM Scale Sets**: 30 instances
- **Virtual Machines**: 4 instances
- **SQL Elastic Pools**: 12 instances

Data location: `azure_data/raw_data/`
- `vm_scale_sets_cpu.csv`
- `vm_scale_sets_memory.csv`
- `vms_cpu.csv`
- `vms_memory.csv`
- `sql_elastic_pools_cpu.csv`
- `sql_elastic_pools_memory.csv`

### Static Configuration Data

- `azure_data/static_data/instance_assignments.csv`: Instance name to type mappings
- `azure_data/static_data/instance_types_specs.csv`: Hardware specifications and embodied carbon data

## Pipeline Components

### 1. CPU Processing (`cpu.py`)

Processes raw CPU utilization metrics from Azure Monitor:

**Input**: Raw Azure CPU metrics with metadata header
**Output**: CSV files with consistent timestamp format

### 2. Memory Processing (`memory.py`)

Calculates memory utilization from Azure Monitor memory metrics:

**Key Functions**:
- `load_memory_specs()`: Loads hardware specifications
- `calculate_memory_usage()`: Processes VM memory data
- `process_sql_utilization()`: Processes SQL Elastic Pool data

### 3. Data Standardization (`resample_data.py`)

Resamples all metrics to consistent 5-minute intervals:

**Output**: `azure_data/standardized/resampled_utilization.csv`

### 4. SCI Calculation (`manifest.yml`, Impact Framework)

Implements the complete SCI specification using the Impact Framework:

#### Energy Calculation
```yaml
interpolate:
  method: linear
  x: [0, 10, 50, 100]           # CPU utilization percentiles
  y: [0.12, 0.32, 0.75, 1.02]   # Power curve coefficients
```

#### Key Calculations
- **CPU Energy**: `E_cpu = CPU_factor × TDP × duration / 3600000` (kWh)
- **Memory Energy**: `E_memory = memory_GB × 0.000392 × duration / 3600` (kWh)
- **Total Energy**: `E_total = E_cpu + E_memory`

#### Embodied Emissions
```yaml
embodied-carbon: TE × (TiR/EL) × (RR/ToR)
```
Where:
- `TE`: Total embodied emissions from Cloud Carbon Footprint coefficients
- `TiR`: Time reserved (measurement duration)
- `EL`: Expected lifespan (4 years)
- `RR`: Resources reserved (vCPUs allocated)
- `ToR`: Total resources (total server cores)

#### SCI Score Calculation
```yaml
sci: (operational_emissions + embodied_emissions) / functional_unit
```
Functional unit: duration in hours (instance-hours)

## Execution

### Complete Pipeline
```bash
python run_sci_pipeline.py
```

## Configuration Parameters

### Grid Carbon Intensity
- **Value**: 355 gCO2eq/kWh
- **Source**: ElectricityMaps for The Netherlands, February 2025
- **Location**: `manifest.yml` defaults section

### Hardware Lifecycle
- **Expected Lifespan**: 4 years (126,144,000 seconds)
- **Embodied Emissions**: Cloud Carbon Footprint coefficients

### Memory Power Model
- **Coefficient**: 0.000392 watts per GB
- **Source**: Cloud Carbon Footprint methodology
- **Model**: Linear power consumption assumption

## Output Files

### Primary Results
- `sci_outputs.csv`: Complete SCI calculation results per timestamp
- `sci_outputs_summary.csv`: Aggregated results per instance
- `sci_results.yaml`: Raw Impact Framework output

### Analysis Artifacts
- `baseline.ipynb`: Complete analysis notebook that generates:
  - `baseline_results/`: Statistical analysis outputs
  - `figures/`: Plots