# MSc Thesis: Decarbonizing Cloud Deployments

This repository contains all the code and data for the CS MSc thesis: **Decarbonizing Cloud Deployments: Evaluating Carbon Emissions in Multi-Tenant Architectures Using the SCI Specification**. The research follows the [**Software Carbon Intensity (SCI) Specification**](https://sci.greensoftware.foundation/) to determine the environmental impact of AFAS SB, a cloud-based software system developed by **AFAS Software**.

## Research Phases
The thesis is structured into the following phases:

### **1️. Baseline Calculation**
- Establishing a baseline SCI score by analyzing **Azure Service Fabric** production metrics.
- Data Collected: CPU utilization, memory usage (Azure VMs, VM Scale Sets, and SQL Elastic Pools).
- Converting performance metrics into energy consumption estimates.
- Files stored in `baseline_calculation/`

### **2️. Minimal Functional Deployment**
- Deploy AFAS SB on a controlled infrastructure at the **Vrije Universiteit Amsterdam’s Green Lab** using a minimal configuration on a single VM.
- Measure the VM's energy consumption under different workloads.
- Compare results with the baseline to identify trends and hotspots.

### **3️. Incremental Component Integration**
- Emulate a real-world scenario using a setup identical to AFAS SB's production Service Fabric architecture with different VMs running multiple hosts.
- Measure the energy consumption of all VMs under different workloads.
- Again compare results with the baseline to identify trends and hotspots.

### 4. Carbon-Aware Alternatives
- Evaluate energy-efficient configurations and deployment optimizations.
- Experiment with green software practices.
- Measure the energy consumption of these carbon-aware alternatives integrated into the previous setup.
- Assess how these changes affect energy usage and the carbon footprint.

### Other Details
- **Thesis Supervisor:** Ivano Malavolta (VU Amsterdam)  
- **Internship Supervisor:** Michiel Overeem (AFAS Software)  
