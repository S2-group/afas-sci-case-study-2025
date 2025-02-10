import pandas as pd

def load_memory_specs():
    instance_types_df = pd.read_csv("azure_data/static_data/instance_types_specs.csv")
    instance_assignments_df = pd.read_csv("azure_data/static_data/instance_assignments.csv")
    
    merged_df = instance_assignments_df.merge(instance_types_df, on="InstanceType")
    
    vm_memory_specs = {row["InstanceName"]: row["TotalMemoryGigaBytes"] * 1024 ** 3 for _, row in merged_df.iterrows() if not row["InstanceType"].startswith("GP_Gen5")}
    sql_memory_specs = {row["InstanceName"]: row["TotalMemoryGigaBytes"] * 1024 ** 3 for _, row in merged_df.iterrows() if row["InstanceType"].startswith("GP_Gen5")}
    
    return vm_memory_specs, sql_memory_specs

def calculate_memory_usage(csv_file):
    used_output_file = f"azure_data/processed_data/{csv_file}_used.csv"
    utilization_output_file = f"azure_data/processed_data/{csv_file}_utilization.csv"

    vm_memory_specs, sql_memory_specs = load_memory_specs()

    df = pd.read_csv(f"azure_data/raw_data/{csv_file}.csv", skiprows=10)
    df.rename(columns={df.columns[0]: "Timestamp"}, inplace=True)

    instances = df.columns[1:]
    cleaned_instances = {instance: instance.split("/")[-1] for instance in instances}
    df.rename(columns=cleaned_instances, inplace=True)

    df.iloc[:, 1:] = df.iloc[:, 1:].apply(pd.to_numeric, errors='coerce')
    df["Timestamp"] = pd.to_datetime(df["Timestamp"], errors='coerce')
    df["Timestamp"] = df["Timestamp"].dt.strftime("%d/%m/%Y %H:%M")

    df_used = df.copy()
    df_utilization = df.copy()

    for instance in df_used.columns[1:]:
        matching_vm_spec = next((spec for spec in vm_memory_specs if instance.startswith(spec)), None)
        if matching_vm_spec:
            df_used[instance] = vm_memory_specs[matching_vm_spec] - df[instance]

    for instance in df_utilization.columns[1:]:
        matching_vm_spec = next((spec for spec in vm_memory_specs if instance.startswith(spec)), None)
        if matching_vm_spec:
            df_utilization[instance] = ((vm_memory_specs[matching_vm_spec] - df[instance]) / vm_memory_specs[matching_vm_spec]) * 100

    for instance in df_used.columns[1:]:
        matching_sql_spec = next((spec for spec in sql_memory_specs if instance.startswith(spec)), None)
        if matching_sql_spec:
            df_used[instance] = (df[instance] / 100) * sql_memory_specs[matching_sql_spec]

    df_used.to_csv(used_output_file, index=False)
    print(f"Processed memory usage data saved to: {used_output_file}")

    df_utilization = df_utilization.drop(columns=[col for col in df_utilization.columns[1:] if any(col.startswith(spec) for spec in sql_memory_specs)], errors='ignore')

    if not df_utilization.empty:
        df_utilization.to_csv(utilization_output_file, index=False)
        print(f"Processed memory utilization data saved to: {utilization_output_file}")

def process_sql_utilization(csv_file):
    input_file = f"azure_data/raw_data/{csv_file}.csv"
    output_file = f"azure_data/processed_data/{csv_file}_utilization.csv"

    df_sql = pd.read_csv(input_file, skiprows=10)
    df_sql.rename(columns={df_sql.columns[0]: "Timestamp"}, inplace=True)

    instances = df_sql.columns[1:]
    cleaned_instances = {instance: instance.split("/")[-1] for instance in instances}
    df_sql.rename(columns=cleaned_instances, inplace=True)

    df_sql["Timestamp"] = pd.to_datetime(df_sql["Timestamp"], errors='coerce')
    df_sql["Timestamp"] = df_sql["Timestamp"].dt.strftime("%d/%m/%Y %H:%M")

    df_sql.iloc[:, 1:] = df_sql.iloc[:, 1:].apply(pd.to_numeric, errors='coerce')

    df_sql.to_csv(output_file, index=False)
    print(f"Processed SQL utilization data saved to: {output_file}")

calculate_memory_usage("vm_scale_sets_memory")
calculate_memory_usage("vms_memory")
calculate_memory_usage("sql_elastic_pools_memory")
process_sql_utilization("sql_elastic_pools_memory")
