<#
.SYNOPSIS
    LatestFileSync - Synchronizes the most recently created file from source to target directory.

.DESCRIPTION
    This script deletes all files (but not subfolders) from the target directory,
    finds the most recently created file in the source directory based on CreationTime,
    and copies that file to the target directory.

.NOTES
    Author: LatestFileSync Project
    Version: 1.0

    Exit Codes:
    0 - Success
    1 - Error (missing directories, no files found, or operation failure)

.EXAMPLE
    .\LatestFileSync.ps1
    Runs the script with the configured source and target directories.
#>

# ================================================================================
# CONFIGURATION VARIABLES
# ================================================================================
# Configure these paths according to your needs

$SourceDirectory = "C:\Path\To\Source"  # Path to source directory
$TargetDirectory = "C:\Path\To\Target"  # Path to target directory

# ================================================================================
# VALIDATION SECTION
# ================================================================================

Write-Host "LatestFileSync - Starting synchronization..." -ForegroundColor Cyan
Write-Host ""

# Check if source directory exists
if (-not (Test-Path -Path $SourceDirectory -PathType Container)) {
    Write-Host "ERROR: Source directory does not exist: $SourceDirectory" -ForegroundColor Red
    exit 1
}

# Check if target directory exists
if (-not (Test-Path -Path $TargetDirectory -PathType Container)) {
    Write-Host "ERROR: Target directory does not exist: $TargetDirectory" -ForegroundColor Red
    exit 1
}

Write-Host "Validation successful" -ForegroundColor Green
Write-Host "  Source: $SourceDirectory" -ForegroundColor Gray
Write-Host "  Target: $TargetDirectory" -ForegroundColor Gray
Write-Host ""

# ================================================================================
# FIND LATEST FILE LOGIC
# ================================================================================

Write-Host "Finding latest file in source directory..." -ForegroundColor Cyan

try {
    # Get all files (not directories) from source directory
    $SourceFiles = Get-ChildItem -Path $SourceDirectory -File -ErrorAction Stop

    # Check if any files exist
    if ($SourceFiles.Count -eq 0) {
        Write-Host "ERROR: No files found in source directory" -ForegroundColor Red
        exit 1
    }

    # Sort by CreationTime in descending order and select the most recent
    $LatestFile = $SourceFiles | Sort-Object CreationTime -Descending | Select-Object -First 1

    Write-Host "Latest file identified: $($LatestFile.Name)" -ForegroundColor Green
    Write-Host "  Created: $($LatestFile.CreationTime)" -ForegroundColor Gray
    Write-Host "  Size: $([math]::Round($LatestFile.Length / 1KB, 2)) KB" -ForegroundColor Gray
    Write-Host ""
}
catch {
    Write-Host "ERROR: Failed to access source directory: $_" -ForegroundColor Red
    exit 1
}

# ================================================================================
# DELETE FILES FROM TARGET
# ================================================================================

Write-Host "Deleting files from target directory..." -ForegroundColor Cyan

try {
    # Get all files (not directories) from target directory
    $TargetFiles = Get-ChildItem -Path $TargetDirectory -File -ErrorAction Stop

    if ($TargetFiles.Count -eq 0) {
        Write-Host "No files to delete in target directory" -ForegroundColor Yellow
    }
    else {
        # Remove each file
        foreach ($File in $TargetFiles) {
            try {
                Remove-Item -Path $File.FullName -Force -ErrorAction Stop
                Write-Host "  Deleted: $($File.Name)" -ForegroundColor Gray
            }
            catch {
                Write-Host "WARNING: Failed to delete file: $($File.Name) - $_" -ForegroundColor Yellow
            }
        }
        Write-Host "Deleted $($TargetFiles.Count) file(s) from target directory" -ForegroundColor Green
    }
    Write-Host ""
}
catch {
    Write-Host "ERROR: Failed to access target directory: $_" -ForegroundColor Red
    exit 1
}

# ================================================================================
# COPY LATEST FILE TO TARGET
# ================================================================================

Write-Host "Copying latest file to target directory..." -ForegroundColor Cyan

try {
    # Copy the latest file to target directory
    Copy-Item -Path $LatestFile.FullName -Destination $TargetDirectory -Force -ErrorAction Stop

    Write-Host "Successfully copied: $($LatestFile.Name)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Synchronization completed successfully!" -ForegroundColor Green
    exit 0
}
catch {
    Write-Host "ERROR: Failed to copy file: $_" -ForegroundColor Red
    exit 1
}
