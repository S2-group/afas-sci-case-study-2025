import os
import subprocess
import time

def run_command(command, description, exit_on_error=True):
    print(f"\n=== {description} ===")
    start_time = time.time()
    result = subprocess.run(command, shell=True, text=True)
    duration = time.time() - start_time
    
    if result.returncode == 0:
        print(f"✓ Completed successfully in {duration:.2f} seconds")
        return True
    else:
        print(f"✗ Failed with return code {result.returncode}")
        if exit_on_error:
            exit(1)
        return False

def main():
    print("Starting SCI calculation pipeline...")
    
    os.makedirs("azure_data/processed_data", exist_ok=True)
    os.makedirs("azure_data/standardized", exist_ok=True)
    
    if not os.path.exists("azure_data/raw_data"):
        print("Error: Raw data directory not found. Please make sure raw data is in azure_data/raw_data/")
        exit(1)
    
    run_command("python cpu.py", "Processing CPU data")
    
    run_command("python memory.py", "Processing memory data")
    
    run_command("python resample_data.py", "Resampling data to consistent intervals")
    
    output_file = "sci_results.yaml"
    run_command(
        f"if-run -m manifest.yml -o {output_file}",
        "Calculating SCI with Impact Framework"
    )
    
    run_command(
        "python extract_sci_outputs.py",
        "Extracting SCI outputs to CSV"
    )
    
    print("\n=== Pipeline Complete ===")
    print(f"SCI calculation results available in {output_file}")
    print("Extracted outputs available in sci_outputs.csv")
    print("Summary metrics available in sci_outputs_summary.csv")

if __name__ == "__main__":
    main()
