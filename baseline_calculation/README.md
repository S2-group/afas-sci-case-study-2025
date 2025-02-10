# Baseline Calculation - Carbon Emissions of AFAS SB

For the **Baseline Calculation phase** the goal is to calculate the baseline carbon emissions of AFAS SB by analyzing collected Azure cloud metrics over a week-long period (Monday, February 3 – Sunday, February 9, 2025). Since Azure does not provide energy consumption metrics, the CPU and memory data will be used to estimate energy consumption using [**Performance Engineering**](https://sci-guide.greensoftware.foundation/E/PerformanceEngineeringBased/). This data will then be used in the SCI formula to calculate a baseline SCI score. 

## Data Sources

The dataset consists of CPU and memory usage metrics collected from Azure Virtual Machine Scale Sets, individual Virtual Machines, and SQL Elastic Pools. These resources are part of the AFAS SB cloud infrastructure, deployed across multiple resource groups:

- Virtual Machine Scale Sets (VMSS) from Service Fabric clusters:
    - Cluster003-RG, Cluster004-RG, Cluster008-RG, Cluster009-RG, and DebugCluster002-RG (Production & Development)
    - Used for processing application workloads.

- Standalone Virtual Machines:
    - LoggingService-RG (Logging Services), Proxy001-RG & ServicesProxy-RG (Proxy Services)
    - Used for proxy, logging, and management operations.

- SQL Elastic Pools:
    - SqlServer001-RG, SqlServer002-RG, SqlServer003-RG, SqlServerDebug001-RG
    - Used for database management and query execution.

### Raw Data (`azure_data/raw_data/`)
- Contains unprocessed CSV files with CPU and memory usage metrics collected from Azure.
- These datasets span one full week (Feb 3 - Feb 9, 2025).

### Processed Data (`azure_data/processed_data/`)
- Processed CSV files with cleaned, formatted, and useful CPU and memory data.
- Includes:
  - **Memory Used (Bytes)**
  - **Memory Utilization (%)**
  - **CPU Utilization (%)**

### Static Data (`azure_data/static_data/`)
- Stores instance type specifications and assignments.
- Used to map virtual machines to their instance types and retrieve memory capacities.
- This data is taken from:
    - [CloudPrice](https://cloudprice.net/).
    - [Microsoft's documentation](https://learn.microsoft.com/en-us/azure/azure-sql/database/resource-limits-vcore-elastic-pools?view=azuresql).

## Scripts

### `memory.py`
- Processes memory utilization and usage for VMs and SQL Elastic Pools using the instance specifications from the static data CSV files.
- Formats the data.

### `cpu.py`
- Processes CPU utilization for VMs and SQL Elastic Pools.
- Formats the data.

## Methodology

- To estimate energy consumption [**Performance Engineering**](https://sci-guide.greensoftware.foundation/E/PerformanceEngineeringBased/) will be used.
- The CPU and memory usage data will be combined with hardware specifications such as the **TDP** (Thermal Design Power) to calculate power consumption using the following formula:

$$
P_{\text{kWh}} = \frac{c \cdot P_c + P_r + g \cdot P_g}{1000}
$$

where:
- $c$ = the number of CPU cores
- $P_c$ = the power consumption of the CPU (W)
- $P_g$ = the power consumption of the GPU (W)
- $g$ = the number of memory sticks
- $P_r$ = the power consumption of the memory (W)

This formula provides the estimated power consumption in kilowatt-hours (kWh) by taking into account CPU, GPU, and memory power usage. Because the instance types included in the metrics do not have a GPU, $P_g$ is assumed to be 0. 
