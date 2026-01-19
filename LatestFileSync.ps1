<#
.SYNOPSIS
    LatestFileSync - Synchronizes the most recently created file from source to target directory.

.DESCRIPTION
    This script deletes all files (but not subfolders) from the target directory,
    finds the most recently created file in the source directory based on CreationTime,
    and copies that file to the target directory. All operations are logged to a file
    in the target directory.

.PARAMETER SourceDirectory
    The path to the source directory containing files to sync from. This parameter is mandatory.

.PARAMETER TargetDirectory
    The path to the target directory where the latest file will be copied. This parameter is mandatory.

.PARAMETER LogFileName
    Optional. The name of the log file to create in the target directory.
    If not specified, defaults to "LatestFileSync.log".

.NOTES
    Author: LatestFileSync Project
    Version: 3.0

    Exit Codes:
    0 - Success
    1 - Error (missing directories, no files found, or operation failure)

.EXAMPLE
    .\LatestFileSync.ps1 -SourceDirectory "C:\Documents\Reports" -TargetDirectory "C:\Archive\Latest"
    Synchronizes the most recent file from Reports to Latest directory using default log file name.

.EXAMPLE
    .\LatestFileSync.ps1 -SourceDirectory "C:\Backups" -TargetDirectory "D:\Current" -LogFileName "sync.log"
    Synchronizes files and uses a custom log file name.
#>

# ================================================================================
# PARAMETERS
# ================================================================================

param(
    [Parameter(Mandatory = $true, HelpMessage = "Path to the source directory")]
    [ValidateNotNullOrEmpty()]
    [string]$SourceDirectory,

    [Parameter(Mandatory = $true, HelpMessage = "Path to the target directory")]
    [ValidateNotNullOrEmpty()]
    [string]$TargetDirectory,

    [Parameter(Mandatory = $false, HelpMessage = "Name of the log file (created in target directory)")]
    [string]$LogFileName = "LatestFileSync.log"
)

# ================================================================================
# LOGGING FUNCTION
# ================================================================================

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"

    # Write to log file
    try {
        Add-Content -Path $LogFilePath -Value $LogMessage -ErrorAction Stop
    }
    catch {
        # If we can't write to log file, there's not much we can do
        # This might happen if target directory doesn't exist yet
    }
}

# ================================================================================
# VALIDATION SECTION
# ================================================================================

# Check if source directory exists
if (-not (Test-Path -Path $SourceDirectory -PathType Container)) {
    # Can't log to file if target directory might not exist, so write to console for this error
    Write-Error "ERROR: Source directory does not exist: $SourceDirectory"
    exit 1
}

# Check if target directory exists
if (-not (Test-Path -Path $TargetDirectory -PathType Container)) {
    Write-Error "ERROR: Target directory does not exist: $TargetDirectory"
    exit 1
}

# Initialize log file path now that we know target directory exists
$LogFilePath = Join-Path $TargetDirectory $LogFileName

# Start logging
Write-Log -Message "LatestFileSync - Starting synchronization" -Level "INFO"
Write-Log -Message "Source: $SourceDirectory" -Level "INFO"
Write-Log -Message "Target: $TargetDirectory" -Level "INFO"
Write-Log -Message "Validation successful" -Level "SUCCESS"

# ================================================================================
# FIND LATEST FILE LOGIC
# ================================================================================

Write-Log -Message "Finding latest file in source directory" -Level "INFO"

try {
    # Get all files (not directories) from source directory
    $SourceFiles = Get-ChildItem -Path $SourceDirectory -ErrorAction Stop | Where-Object { -not $_.PSIsContainer }

    # Check if any files exist
    if ($SourceFiles.Count -eq 0) {
        Write-Log -Message "No files found in source directory" -Level "ERROR"
        exit 1
    }

    # Sort by CreationTime in descending order and select the most recent
    $LatestFile = $SourceFiles | Sort-Object CreationTime -Descending | Select-Object -First 1

    Write-Log -Message "Latest file identified: $($LatestFile.Name)" -Level "SUCCESS"
    Write-Log -Message "Created: $($LatestFile.CreationTime)" -Level "INFO"
    Write-Log -Message "Size: $([math]::Round($LatestFile.Length / 1KB, 2)) KB" -Level "INFO"
}
catch {
    Write-Log -Message "Failed to access source directory: $_" -Level "ERROR"
    exit 1
}

# ================================================================================
# DELETE FILES FROM TARGET
# ================================================================================

Write-Log -Message "Deleting files from target directory" -Level "INFO"

try {
    # Get all files (not directories) from target directory (excluding log file)
    $TargetFiles = Get-ChildItem -Path $TargetDirectory -ErrorAction Stop | Where-Object { -not $_.PSIsContainer -and $_.Name -ne $LogFileName }

    if ($TargetFiles.Count -eq 0) {
        Write-Log -Message "No files to delete in target directory" -Level "INFO"
    }
    else {
        # Remove each file
        foreach ($File in $TargetFiles) {
            try {
                Remove-Item -Path $File.FullName -Force -ErrorAction Stop
                Write-Log -Message "Deleted: $($File.Name)" -Level "INFO"
            }
            catch {
                Write-Log -Message "Failed to delete file: $($File.Name) - $_" -Level "WARNING"
            }
        }
        Write-Log -Message "Deleted $($TargetFiles.Count) file(s) from target directory" -Level "SUCCESS"
    }
}
catch {
    Write-Log -Message "Failed to access target directory: $_" -Level "ERROR"
    exit 1
}

# ================================================================================
# COPY LATEST FILE TO TARGET
# ================================================================================

Write-Log -Message "Copying latest file to target directory" -Level "INFO"

try {
    # Copy the latest file to target directory
    Copy-Item -Path $LatestFile.FullName -Destination $TargetDirectory -Force -ErrorAction Stop

    Write-Log -Message "Successfully copied: $($LatestFile.Name)" -Level "SUCCESS"
    Write-Log -Message "Synchronization completed successfully" -Level "SUCCESS"
    exit 0
}
catch {
    Write-Log -Message "Failed to copy file: $_" -Level "ERROR"
    exit 1
}
