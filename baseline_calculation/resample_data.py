import pandas as pd
import glob
import os

def resample_data(input_directory="azure_data/processed_data", 
                  output_file="azure_data/standardized/resampled_utilization.csv",
                  resample_interval="5min"):
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    instance_specs = pd.read_csv("azure_data/static_data/instance_types_specs.csv")
    instance_assignments = pd.read_csv("azure_data/static_data/instance_assignments.csv")
    instance_data = instance_assignments.merge(instance_specs, on='InstanceType', how='left')
    
    instance_map = {
        row['InstanceName']: (
            row['ResourcesReserved'], 
            row['ResourcesTotal'], 
            row['TotalMemoryGigaBytes'], 
            row['ThermalDesignPower'], 
            row['EmbodiedEmissions']
        ) 
        for _, row in instance_data.iterrows()
    }
    
    cpu_files = [
        "azure_data/processed_data/sql_elastic_pools_cpu_utilization.csv",
        "azure_data/processed_data/vms_cpu_utilization.csv",
        "azure_data/processed_data/vm_scale_sets_cpu_utilization.csv"
    ]
    
    memory_files = [
        "azure_data/processed_data/sql_elastic_pools_memory_utilization.csv",
        "azure_data/processed_data/vms_memory_utilization.csv",
        "azure_data/processed_data/vm_scale_sets_memory_utilization.csv"
    ]
    
    cpu_dfs = []
    for file in cpu_files:
        if os.path.exists(file):
            print(f"Processing {file}")
            df = pd.read_csv(file)
            df.rename(columns={"Timestamp": "timestamp"}, inplace=True)
            
            df["timestamp"] = pd.to_datetime(df["timestamp"], format="%d/%m/%Y %H:%M", errors='coerce')
            
            id_vars = ["timestamp"]
            value_vars = [col for col in df.columns if col != "timestamp"]
            
            for col in value_vars:
                df[col] = pd.to_numeric(df[col], errors='coerce')
            
            df_melted = df.melt(id_vars=id_vars, var_name="cloud/instance-type", value_name="cpu/utilization")
            df_melted.dropna(subset=["cpu/utilization"], inplace=True)
            
            cpu_dfs.append(df_melted)
    
    memory_dfs = []
    for file in memory_files:
        if os.path.exists(file):
            print(f"Processing {file}")
            df = pd.read_csv(file)
            df.rename(columns={"Timestamp": "timestamp"}, inplace=True)
            
            df["timestamp"] = pd.to_datetime(df["timestamp"], format="%d/%m/%Y %H:%M", errors='coerce')
            
            value_vars = [col for col in df.columns if col != "timestamp"]
            for col in value_vars:
                df[col] = pd.to_numeric(df[col], errors='coerce')
            
            id_vars = ["timestamp"]
            df_melted = df.melt(id_vars=id_vars, var_name="cloud/instance-type", value_name="memory/utilization")
            df_melted.dropna(subset=["memory/utilization"], inplace=True)
            
            memory_dfs.append(df_melted)
    
    print("Combining CPU data...")
    cpu_data = pd.concat(cpu_dfs, ignore_index=True)
    print("Combining memory data...")
    memory_data = pd.concat(memory_dfs, ignore_index=True)
    
    print("Merging CPU and memory data...")
    merged_data = pd.merge(cpu_data, memory_data, on=["timestamp", "cloud/instance-type"], how="outer")
    
    print(f"Resampling data to {resample_interval} intervals...")
    resampled_data = []
    
    for instance, group in merged_data.groupby("cloud/instance-type"):
        print(f"Resampling for instance: {instance}")
        
        group = group.set_index("timestamp")
        
        numeric_columns = group.select_dtypes(include=['number']).columns
        
        resampled = group[numeric_columns].resample(resample_interval).mean()
        
        resampled = resampled.interpolate(method='linear')
        
        resampled = resampled.reset_index()
        
        resampled["cloud/instance-type"] = instance
        
        resampled_data.append(resampled)
    
    print("Combining resampled data...")
    final_data = pd.concat(resampled_data, ignore_index=True)
    
    final_data["duration"] = int(pd.Timedelta(resample_interval).total_seconds())
    
    print("Adding static information...")
    final_data['resources-reserved'] = final_data['cloud/instance-type'].apply(
        lambda x: next((v[0] for k, v in instance_map.items() if k in x), None))
    final_data['resources-total'] = final_data['cloud/instance-type'].apply(
        lambda x: next((v[1] for k, v in instance_map.items() if k in x), None))
    final_data['memory'] = final_data['cloud/instance-type'].apply(
        lambda x: next((v[2] for k, v in instance_map.items() if k in x), None))
    final_data['cpu/thermal-design-power'] = final_data['cloud/instance-type'].apply(
        lambda x: next((v[3] for k, v in instance_map.items() if k in x), None))
    final_data['baseline-emissions'] = final_data['cloud/instance-type'].apply(
        lambda x: next((v[4] for k, v in instance_map.items() if k in x), None))
    
    final_data["timestamp"] = final_data["timestamp"].dt.strftime("%Y-%m-%dT%H:%M:%S.000Z")
    
    print(f"Saving resampled data to {output_file}...")
    final_data.to_csv(output_file, index=False)
    print(f"Resampled data saved successfully.")
    
    return final_data

if __name__ == "__main__":
    resample_data()
