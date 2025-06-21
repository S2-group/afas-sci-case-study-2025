import yaml
import pandas as pd
import os

def extract_sci_outputs(yaml_file="sci_results.yaml", output_csv="sci_outputs.csv"):
    print(f"Extracting SCI outputs from {yaml_file}...")
    
    try:
        with open(yaml_file, 'r') as f:
            data = yaml.safe_load(f)
        
        all_outputs = []
        
        if 'tree' in data and 'children' in data['tree']:
            if 'child-1' in data['tree']['children']:
                child = data['tree']['children']['child-1']
                if 'children' in child:
                    for instance_name, instance_data in child['children'].items():
                        if 'outputs' in instance_data:
                            for output in instance_data['outputs']:
                                output['_instance'] = instance_name
                                all_outputs.append(output)
        
        if not all_outputs:
            print("No outputs found in the YAML file.")
            return False
        
        df = pd.DataFrame(all_outputs)
        
        print(f"Found outputs for {df['_instance'].nunique()} instances, total of {len(df)} data points.")
        
        if 'energy' in df.columns and 'carbon' in df.columns and 'sci' in df.columns:
            total_energy = df['energy'].sum()
            total_carbon = df['carbon'].sum()
            avg_sci = df['sci'].mean()
            
            print(f"\nKey metrics:")
            print(f"  Total energy consumption: {total_energy:.4f} kWh")
            print(f"  Total carbon emissions: {total_carbon:.4f} gCO2eq")
            print(f"  SCI: {avg_sci:.4f} gCO2eq per hour")
        
        instance_summary = df.groupby('_instance').agg({
            'energy': 'sum',
            'carbon': 'sum',
            'sci': 'mean'
        }).reset_index()
        
        print("\nInstance summary:")
        print(instance_summary.sort_values(by='energy', ascending=False).head(10).to_string(index=False))
        
        df.to_csv(output_csv, index=False)
        
        summary_csv = output_csv.replace('.csv', '_summary.csv')
        instance_summary.to_csv(summary_csv, index=False)
        
        print(f"\nOutputs exported to {output_csv}")
        print(f"Summary exported to {summary_csv}")
        
        return True
        
    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == "__main__":
    extract_sci_outputs()
