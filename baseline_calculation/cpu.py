import pandas as pd

def process_cpu_utilization(csv_file):
    input_file = f"azure_data/raw_data/{csv_file}.csv"
    output_file = f"azure_data/processed_data/{csv_file}_utilization.csv"

    df_cpu = pd.read_csv(input_file, skiprows=10) 

    df_cpu.rename(columns={df_cpu.columns[0]: "Timestamp"}, inplace=True)

    instances = df_cpu.columns[1:]
    cleaned_instances = {instance: instance.split("/")[-1] for instance in instances}
    df_cpu.rename(columns=cleaned_instances, inplace=True)

    df_cpu["Timestamp"] = pd.to_datetime(df_cpu["Timestamp"], errors='coerce')
    df_cpu["Timestamp"] = df_cpu["Timestamp"].dt.strftime("%d/%m/%Y %H:%M")

    df_cpu.iloc[:, 1:] = df_cpu.iloc[:, 1:].apply(pd.to_numeric, errors='coerce')

    df_cpu.to_csv(output_file, index=False)
    print(f"Processed CPU utilization data saved to: {output_file}")

process_cpu_utilization("vm_scale_sets_cpu")
process_cpu_utilization("vms_cpu")
process_cpu_utilization("sql_elastic_pools_cpu")
