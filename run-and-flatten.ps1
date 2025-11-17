param(
  [string]$Policy = ".\policies\cspef-s3-check-publicblock.yml",
  [string]$Region = "ap-south-1"
)

Write-Host "Running custodian policy (using venv custodian exe): $Policy"

# call custodian directly from venv so we don't need Activate.ps1
$custodianExe = Join-Path -Path (Resolve-Path .\venv\Scripts).Path -ChildPath "custodian.exe"
if (-Not (Test-Path $custodianExe)) {
    Write-Host "custodian.exe not found at $custodianExe; attempting 'custodian' fallback"
    & custodian run -s .\custodian-output $Policy --region $Region
} else {
    & $custodianExe run -s .\custodian-output $Policy --region $Region
}

Write-Host "Converting resources.json arrays to ndjson..."
$files = Get-ChildItem .\custodian-output -Recurse -Filter resources.json -ErrorAction SilentlyContinue
if ($files.Count -eq 0) { Write-Host "No resources.json found under .\custodian-output"; exit }

foreach ($f in $files) {
  try {
    $json = Get-Content $f.FullName -Raw | ConvertFrom-Json
    $out = Join-Path $f.Directory.FullName "ndjson_resources.json"
    if ($json -is [System.Array]) {
      $json | ForEach-Object { $_ | ConvertTo-Json -Compress } | Out-File -FilePath $out -Encoding utf8
    } else {
      $json | ConvertTo-Json -Compress | Out-File -FilePath $out -Encoding utf8
    }
    Write-Host "Wrote $out"
  } catch {
    Write-Host "ERROR processing $($f.FullName): $_"
    Copy-Item $f.FullName ($f.Directory.FullName + "\corrupt_resources.json") -Force
  }
}

# update last write time so Filebeat notices them
Get-ChildItem .\custodian-output -Recurse -Filter ndjson_resources.json | ForEach-Object { (Get-Item $_.FullName).LastWriteTime = Get-Date }

Write-Host "Done. NDJSON files created and timestamped."
