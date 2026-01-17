# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LatestFileSync is a utility that synchronizes the most recently created file from a source directory to a target directory. The script clears the target directory of files (preserving subfolders by default, unless configured otherwise) and copies only the latest file from the source.

## Project Status

This project will be implemented as a PowerShell script for Windows environments. The core functionality has not yet been implemented.

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
- Source and target directory paths defined as variables at the top of the script
- These variables should be clearly marked for user configuration

**Error Handling:**
The script must gracefully handle the following scenarios:
- Source directory does not exist (exit with error code 1)
- Target directory does not exist (exit with error code 1)
- Source directory contains no files (exit with error code 1)
- File copy failures
- File deletion failures

**Logging:**
- Use `Write-Host` or `Write-Output` for major operational steps
- Log when deleting files from target directory
- Log which file is identified as the latest
- Log when copying the file
- Consider using colored output for better readability (e.g., green for success, yellow for warnings, red for errors)

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

2. **Configuration Variables Section**
   - `$SourceDirectory` - Path to source directory
   - `$TargetDirectory` - Path to target directory

3. **Validation Section**
   - Check if source directory exists
   - Check if target directory exists
   - Exit with error code 1 if either validation fails

4. **Find Latest File Logic**
   - Get all files from source directory
   - Check if any files exist
   - Sort by CreationTime and select the most recent
   - Exit with error code 1 if no files found

5. **Delete Files from Target**
   - Get all files (not directories) from target directory
   - Remove each file
   - Log the deletion operation

6. **Copy Latest File to Target**
   - Copy the latest file to target directory
   - Log the copy operation
   - Handle any copy errors

### Implementation Notes

- Use exit code 0 for successful completion
- Use exit code 1 for any error conditions
- The script focuses on files only; subdirectories in both source and target are ignored
- "Latest" is determined solely by the `CreationTime` property
- The script does not follow symlinks or process hidden files unless explicitly configured
