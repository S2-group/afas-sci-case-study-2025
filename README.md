# Empirical Assessment of Carbon Reduction Strategies in Enterprise Software Systems

This repository contains the implementation and data analysis for the thesis "Empirical Assessment of Carbon Reduction Strategies in Enterprise Software Systems".

## Research Overview

This study investigates carbon emission optimization strategies for AFAS SB, a cloud-based software platform developed by AFAS Software, through the application of the Software Carbon Intensity (SCI) specification developed by the Green Software Foundation.

### Research Questions

1. **RQ1**: What is the baseline rate of carbon emissions of AFAS SB in production?
2. **RQ2**: How do application-level configuration settings affect the rate of carbon emissions of AFAS SB?
3. **RQ3**: To what extent can the rate of carbon emissions of AFAS SB be reduced by combining optimal application-level configurations while maintaining system performance and functionality?

## Repository Structure

```
├── baseline_calculation/         # Production environment SCI calculation pipeline
├── controlled_experiments/       # Experimental setup and execution infrastructure
│   ├── app_vm/                   # Application VM configuration scripts
│   ├── experiment_runner/        # Experiment automation framework
│   └── test_vm/                  # Test execution VM scripts
└── requirements.txt              # Python dependencies
```

## Methodology

The study employs a two-phase approach:

1. **Baseline Assessment**: Analysis of production Azure metrics to establish baseline SCI scores.

2. **Controlled Experiments**: Evaluation of application-level configuration parameters in a laboratory environment using the Green Lab at VU Amsterdam.

## Key Technologies

- **SCI Calculation**: Impact Framework
- **Energy Measurement**: PowerJoular
- **System Monitoring**: psutil
- **Test Execution**: Playwright
- **Statistical Analysis**: Python 3.8 with SciPy, pandas, NumPy, matplotlib, seaborn

## Experiment Runner Framework

This project uses a customized version of the [Experiment Runner framework](https://github.com/S2-group/experiment-runner) developed by the Software and Sustainability (S2) group at VU Amsterdam. The files used in this fork are also available in this project under `controlled_experiments/experiment_runner/afas-sb`

[Customized Fork (GitHub)](https://github.com/rutgerkool/experiment-runner)

## Prerequisites

### Software Requirements

```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
npm install -g @grnsft/if
```

### Hardware Requirements

- Physical server for controlled experiments
- Proxmox virtualization platform
- Two Windows Server 2022 virtual machines

### External Dependencies

- npm
- Impact Framework CLI

### Baseline Calculation

```bash
cd baseline_calculation
python run_sci_pipeline.py
```

This processes Azure monitoring data and calculates production SCI scores.

**Performance Note**: This pipeline processes substantial production data and takes 8-10 minutes to complete for enterprise datasets. The sci_results.yaml output file will be approximately 4 million lines.

## Data Sources

### Production Data
- Azure Service Fabric monitoring metrics (February 3-9, 2025)
- 46 infrastructure instances across 12 resource groups
- CPU and memory utilization data collected via Azure Monitor

### Experimental Data
- 140 experimental runs
- Process-level energy measurements
- System resource utilization metrics
- Functional test execution results
- Raw measurement data can be found in `controlled_experiments/experiment_runner/afas-sb/experiments`

## Experimental Design

The controlled experiments consist of three phases:

- **Phase 1**: Baseline configuration (P1_E1)
- **Phase 2**: Individual configuration optimization (P2_E1 through P2_E5)
  - Parallelism configuration
  - Logging configuration  
  - Caching configuration
  - Compression configuration
  - Garbage collection configuration
- **Phase 3**: Integrated optimization (P3_E1)

Each experimental condition includes 10 repetitions to account for measurement variability.

## Cloud Carbon Footprint Modifications

9 instance specifications were added to the [ccf-coefficients repository](https://github.com/cloud-carbon-footprint/ccf-coefficients) `data/azure-instances.csv` file to calculate total embodied emissions for:

- Azure instances (Dads v5, Eads v5, GP_Gen5 series)
- Green Lab server (MOX1 series)

**Modified file**: `ccf-coefficients/azure-instances.csv`

## Statistical Analysis

All statistical analyses are implemented in Jupyter notebooks within the respective directories:

- Descriptive statistics and distribution analysis
- Mann-Whitney U tests for configuration comparisons
- Bootstrap confidence intervals for effect size estimation
- Holm correction for multiple comparison control
- Correlation analysis between resource utilization and carbon intensity

## Results Summary

Key findings from the empirical assessment:

- Baseline production SCI: 14.162 gCO2e/instance-hour (±11.011, n=46)
- Most effective optimization: Garbage collection parameter tuning (29.5-30.6% SCI reduction)
- Integrated optimization: 25.7% SCI reduction while maintaining 100% functional correctness
- Primary carbon driver: I/O operations (r = 0.997, p < 0.001)