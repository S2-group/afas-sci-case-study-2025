# Test Execution VM Configuration

## Test Scenario Structure

```json
{
    "description": "Scenario description text",
    "startTime": 1706000000000,
    "endTime": 1706000120000,
    "duration": 120000,
    "status": "Succeeded"
}
```

## Output Data Structure

### Generated Files
```
out/log/
├── scenario/                   
│   ├── scenario_001.json       # Scenario results
│   └── [...]                   # Additional scenario results
└── scenario_summary.csv        # Run summary
```