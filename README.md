# LatestFileSync

A PowerShell utility that synchronizes the most recently created file from a source directory to a target directory. The script clears the target directory of files (while preserving subfolders) and copies only the latest file from the source.

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

## Configuration

Before running the script, you must configure the source and target directories:

1. Open `LatestFileSync.ps1` in a text editor
2. Locate the configuration section at the top of the script
3. Update the following variables:

```powershell
$SourceDirectory = "C:\Path\To\Source"  # Path to source directory
$TargetDirectory = "C:\Path\To\Target"  # Path to target directory
```

## Usage

Once configured, run the script from PowerShell:

```powershell
.\LatestFileSync.ps1
```

The script will:
- Display validation messages in cyan
- Show the latest file identified with its creation time and size
- Log file deletion operations in gray
- Report success in green or errors in red

### Example Output

```
LatestFileSync - Starting synchronization...

Validation successful
  Source: C:\Documents\Reports
  Target: C:\Archive\Latest

Finding latest file in source directory...
Latest file identified: Report_2026-01-17.pdf
  Created: 01/17/2026 20:45:30
  Size: 245.67 KB

Deleting files from target directory...
  Deleted: Report_2026-01-16.pdf
Deleted 1 file(s) from target directory

Copying latest file to target directory...
Successfully copied: Report_2026-01-17.pdf

Synchronization completed successfully!
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

## Use Cases

- Syncing the latest backup file to a specific location
- Copying the most recent log file for monitoring
- Keeping a "latest" folder updated with the newest document
- Automated deployment of the most recent build output
- Archiving the most recent data export

## License

This project is provided as-is for use in personal and commercial projects.
