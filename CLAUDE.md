# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LatestFileSync is a utility that synchronizes the most recently created file from a source directory to a target directory. The script clears the target directory of files (preserving subfolders by default, unless configured otherwise) and copies only the latest file from the source.

## Project Status

This project is implemented as a PowerShell script for Windows environments. The core functionality is complete and tested. Version 3.0 uses parameters for directory configuration instead of hardcoded variables.

## PowerShell Script Specifications

### Script Filename
The script should be saved as `LatestFileSync.ps1` in the root directory of this repository.

### Script Behavior

The script performs the following operations in sequence:

1. **Delete Files in Target Directory**
   - Remove all files from the target directory
   - Preserve all subfolders (do not delete folders)
   - Only delete files at the root level of the target directory

2. **Find Latest File in Source Directory**
   - Scan the source directory for files (not folders)
   - Identify the most recently created file based on `CreationTime` property
   - Only consider files, not directories

3. **Copy Latest File to Target**
   - Copy the identified latest file to the target directory
   - Preserve the original filename

### Requirements

**PowerShell Best Practices:**
- Use clear, descriptive variable names
- Follow PowerShell naming conventions (PascalCase for variables)
- Use cmdlets appropriately (Get-ChildItem, Copy-Item, Remove-Item, etc.)
- Include proper error handling with try-catch blocks

**Configuration:**
- Source and target directory paths are provided as mandatory script parameters
- LogFileName is an optional parameter with default value "LatestFileSync.log"
- Parameters must include proper validation:
  - SourceDirectory: Mandatory, ValidateNotNullOrEmpty
  - TargetDirectory: Mandatory, ValidateNotNullOrEmpty
  - LogFileName: Optional with default value "LatestFileSync.log"

**Error Handling:**
The script must gracefully handle the following scenarios:
- Source directory does not exist (exit with error code 1)
- Target directory does not exist (exit with error code 1)
- Source directory contains no files (exit with error code 1)
- File copy failures
- File deletion failures

**Logging:**
- All messages must be written to a log file in the target directory
- Do NOT write output to console (except for critical validation errors before log file can be created)
- Log file should be named `LatestFileSync.log` by default
- Log entries must include timestamps in format: `yyyy-MM-dd HH:mm:ss`
- Log entries must include severity level: INFO, SUCCESS, WARNING, ERROR
- Log format: `[Timestamp] [Level] Message`
- Log when deleting files from target directory
- Log which file is identified as the latest
- Log when copying the file
- The log file itself must be excluded from deletion operations

**User Interaction:**
- No user input prompts during execution
- Script should run unattended from start to finish
- All behavior determined by configuration variables

**Code Documentation:**
- Include inline comments explaining each major section
- Add comments for complex logic
- Include a header comment block with script purpose and usage

**Script Structure:**
The script should follow this structure:

1. **Header Comment Block**
   - Script name, purpose, and usage instructions
   - Parameter documentation (.PARAMETER for each parameter)
   - Usage examples (.EXAMPLE)

2. **Parameters Section**
   - `param()` block with:
     - `$SourceDirectory` - Mandatory parameter for source directory path
     - `$TargetDirectory` - Mandatory parameter for target directory path
     - `$LogFileName` - Optional parameter with default value "LatestFileSync.log"

3. **Logging Function**
   - Define a `Write-Log` function that accepts message and level parameters
   - Function appends timestamped entries to the log file
   - Function handles cases where log file cannot be written

4. **Validation Section**
   - Check if source directory exists
   - Check if target directory exists
   - Exit with error code 1 if either validation fails
   - Initialize log file path after validation
   - Begin logging operations

5. **Find Latest File Logic**
   - Get all files from source directory
   - Check if any files exist
   - Sort by CreationTime and select the most recent
   - Exit with error code 1 if no files found
   - Log the identified file details

6. **Delete Files from Target**
   - Get all files (not directories) from target directory
   - Exclude the log file from deletion list
   - Remove each file (except log file)
   - Log each deletion operation

7. **Copy Latest File to Target**
   - Copy the latest file to target directory
   - Log the copy operation
   - Handle any copy errors

### Implementation Notes

- Use exit code 0 for successful completion
- Use exit code 1 for any error conditions
- The script focuses on files only; subdirectories in both source and target are ignored
- "Latest" is determined solely by the `CreationTime` property
- The script does not follow symlinks or process hidden files unless explicitly configured
- The log file (`LatestFileSync.log`) is created in the target directory and appends entries on each run
- The log file persists across runs and is never deleted by the script
- Console output is minimized to only critical errors during validation (before log file can be initialized)
