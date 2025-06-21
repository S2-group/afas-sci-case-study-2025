$env:Path += ";C:\Program Files\nodejs;C:\Program Files\Python312;C:\Program Files\Python312\Scripts;C:\Program Files\Git\cmd"
[Environment]::SetEnvironmentVariable("Path", $env:Path, "Machine")

$rootOut = "C:\anta\features\out"

Get-ChildItem -Path $rootOut -Recurse -File | Where-Object {
    $_.Name -notin @(".gitignore", "readme.md")
} | Remove-Item -Force

Get-ChildItem -Path $rootOut -Recurse -Directory | Where-Object {
    @(Get-ChildItem $_.FullName -Force).Count -eq 0
} | Remove-Item -Force -Recurse

Write-Host "All output folders cleaned"

npm run sandboxsuite
python .\extract_scenario_data.py
