$ErrorActionPreference = "Stop"

$addonName = "WizardBuff"
$srcDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$staging   = Join-Path $env:TEMP "${addonName}_pack"
$zipFile   = Join-Path ([Environment]::GetFolderPath("Desktop")) "${addonName}.zip"

Write-Host "Packing $addonName ..."
Write-Host "Source : $srcDir"
Write-Host "Output : $zipFile"

# Clean staging
if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $staging $addonName) -Force | Out-Null

# Copy addon files, skip junk
$exclude = @('.git', '.github')
Get-ChildItem -Path $srcDir -Exclude '*.zip','pack.*','.gitignore','.pkgmeta','README.md' |
    Where-Object { $_.Name -notin $exclude } |
    ForEach-Object {
        $dest = Join-Path (Join-Path $staging $addonName) $_.Name
        Copy-Item -Path $_.FullName -Destination $dest -Recurse -Force
    }

# Zip
if (Test-Path $zipFile) { Remove-Item $zipFile -Force }
Compress-Archive -Path (Join-Path $staging $addonName) -DestinationPath $zipFile -Force

if (Test-Path $zipFile) {
    $size = [math]::Round((Get-Item $zipFile).Length / 1KB)
    Write-Host "`nDone! ${size} KB -> $zipFile" -ForegroundColor Green
} else {
    Write-Host "`nERROR: zip not created" -ForegroundColor Red
}

# Cleanup
Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Read-Host "Press Enter to close"
