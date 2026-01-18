# LatestFileSync

A PowerShell utility that synchronizes the most recently created file from a source directory to a target directory. The script clears the target directory of files (while preserving subfolders) and copies only the latest file from the source. All operations are logged to a file in the target directory.

## Overview

LatestFileSync performs three main operations:
1. **Deletes all files** (but not subfolders) from the target directory
2. **Identifies the latest file** in the source directory based on CreationTime
3. **Copies that file** to the target directory

This is useful for scenarios where you need to automatically sync the most recent output file, log, backup, or document from one location to another.

## How It Works

The script executes the following steps in sequence:

1. **Validation**: Checks that both source and target directories exist
2. **Find Latest File**: Scans the source directory for files (not folders) and identifies the one with the most recent `CreationTime` property
3. **Clear Target**: Removes all files from the root of the target directory, preserving any subfolders and their contents
4. **Copy File**: Copies the identified latest file to the target directory

## Requirements

- Windows operating system
- PowerShell 5.1 or higher
- Read access to source directory
- Write/delete access to target directory

## Installation

1. Clone or download this repository
2. Ensure PowerShell execution policy allows running scripts:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

## Usage

### Basic Usage

Run the script with source and target directory parameters:

```powershell
.\LatestFileSync.ps1 -SourceDirectory "C:\Path\To\Source" -TargetDirectory "C:\Path\To\Target"
```

### Custom Log File Name

Optionally specify a custom log file name:

```powershell
.\LatestFileSync.ps1 -SourceDirectory "C:\Documents\Reports" -TargetDirectory "C:\Archive\Latest" -LogFileName "sync.log"
```

### Getting Help

View parameter help:

```powershell
Get-Help .\LatestFileSync.ps1 -Detailed
```

The script runs silently without console output. All operations are logged to a file in the target directory (default: `LatestFileSync.log`).

### Log File

The script creates and maintains a log file in the target directory with the following characteristics:

- **Location**: Target directory (e.g., `C:\Archive\Latest\LatestFileSync.log`)
- **Format**: `[Timestamp] [Level] Message`
- **Levels**: INFO, SUCCESS, WARNING, ERROR
- **Behavior**: Appends to existing log file (not overwritten on each run)
- **Protection**: The log file is never deleted by the script

### Example Log Output

```
[2026-01-17 20:45:30] [INFO] LatestFileSync - Starting synchronization
[2026-01-17 20:45:30] [INFO] Source: C:\Documents\Reports
[2026-01-17 20:45:30] [INFO] Target: C:\Archive\Latest
[2026-01-17 20:45:30] [SUCCESS] Validation successful
[2026-01-17 20:45:30] [INFO] Finding latest file in source directory
[2026-01-17 20:45:30] [SUCCESS] Latest file identified: Report_2026-01-17.pdf
[2026-01-17 20:45:30] [INFO] Created: 01/17/2026 20:45:25
[2026-01-17 20:45:30] [INFO] Size: 245.67 KB
[2026-01-17 20:45:30] [INFO] Deleting files from target directory
[2026-01-17 20:45:30] [INFO] Deleted: Report_2026-01-16.pdf
[2026-01-17 20:45:30] [SUCCESS] Deleted 1 file(s) from target directory
[2026-01-17 20:45:30] [INFO] Copying latest file to target directory
[2026-01-17 20:45:31] [SUCCESS] Successfully copied: Report_2026-01-17.pdf
[2026-01-17 20:45:31] [SUCCESS] Synchronization completed successfully
```

### Viewing the Log

To view the log file in real-time:

```powershell
Get-Content "C:\Path\To\Target\LatestFileSync.log" -Tail 20
```

Or to monitor it continuously:

```powershell
Get-Content "C:\Path\To\Target\LatestFileSync.log" -Wait -Tail 10
```

## Exit Codes

The script uses standard exit codes:

- `0` - Success: File synchronized successfully
- `1` - Error: One of the following occurred:
  - Source directory does not exist
  - Target directory does not exist
  - No files found in source directory
  - File copy operation failed

## Testing

A comprehensive test suite is included to validate all script behaviors:

```powershell
.\Test-LatestFileSync.ps1
```

The test suite validates:
- Latest file identification by CreationTime
- File deletion with subfolder preservation
- Error handling for missing directories
- Error handling for empty source directory
- Verification that only files (not directories) are considered
- Exit code validation

All tests create temporary directories and clean up automatically.

## Important Notes

- **Only files are synchronized**: Directories in the source are ignored
- **Subfolders are preserved**: Only files at the root level of the target directory are deleted
- **CreationTime is used**: The script uses the file's CreationTime property, not LastWriteTime or LastAccessTime
- **No prompts**: The script runs unattended without user interaction
- **Overwrites existing files**: If a file with the same name exists in the target, it will be overwritten
- **Silent operation**: The script does not output to console; all information is logged to file
- **Log file protection**: The log file (`LatestFileSync.log`) is never deleted and persists across runs
- **Log file format**: Each log entry includes timestamp and severity level for easy parsing and monitoring

## Use Cases

- Syncing the latest backup file to a specific location
- Copying the most recent log file for monitoring
- Keeping a "latest" folder updated with the newest document
- Automated deployment of the most recent build output
- Archiving the most recent data export

## License

This project is provided as-is for use in personal and commercial projects.
