import json
import os
import glob
import csv
from datetime import datetime

def convert_timestamp(timestamp):
    dt = datetime.fromtimestamp(timestamp / 1000)
    return dt.strftime('%Y-%m-%d %H:%M:%S')

def process_scenario_files(input_dir, output_file):
    json_files = glob.glob(os.path.join(input_dir, '*.json'))
    
    output_data = []
    
    for file_path in json_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                
            scenario_data = {
                'description': data.get('description', ''),
                'startTime': convert_timestamp(data.get('startTime', 0)),
                'endTime': convert_timestamp(data.get('endTime', 0)),
                'duration': data.get('duration', 0),
                'status': data.get('status', '')
            }
            
            output_data.append(scenario_data)
            
        except Exception as e:
            print(f"Error processing file {file_path}: {e}")
    
    output_data.sort(key=lambda x: datetime.strptime(x['startTime'], '%Y-%m-%d %H:%M:%S'))
    
    output_dir = os.path.dirname(output_file)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    if output_data:
        with open(output_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=['description', 'startTime', 'endTime', 'duration', 'status'])
            writer.writeheader()
            writer.writerows(output_data)
        print(f"Successfully wrote data to {output_file}")
    else:
        print("No data was processed.")

if __name__ == "__main__":
    input_directory = os.path.join("out", "log", "scenario")
    output_csv = os.path.join("out", "log", "scenario_summary.csv")
    
    if not os.path.exists(input_directory):
        print(f"Input directory '{input_directory}' does not exist.")
    else:
        process_scenario_files(input_directory, output_csv)
