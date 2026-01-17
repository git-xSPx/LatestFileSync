<#
.SYNOPSIS
    Test suite for LatestFileSync.ps1

.DESCRIPTION
    Comprehensive test script that validates all behaviors of LatestFileSync.ps1:
    - Identifies latest file by CreationTime
    - Deletes files but preserves subfolders in target
    - Handles missing directories
    - Handles empty source directory
    - Only considers files, not directories

.NOTES
    This script creates temporary test directories and cleans them up after testing.
#>

# Test configuration
$TestRootPath = Join-Path $env:TEMP "LatestFileSyncTests"
$ScriptPath = Join-Path $PSScriptRoot "LatestFileSync.ps1"

# Test results tracking
$TestsPassed = 0
$TestsFailed = 0
$TestResults = @()

# ================================================================================
# HELPER FUNCTIONS
# ================================================================================

function Write-TestHeader {
    param([string]$TestName)
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Cyan
    Write-Host "TEST: $TestName" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Cyan
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message
    )

    if ($Passed) {
        Write-Host "PASSED: $TestName" -ForegroundColor Green
        $script:TestsPassed++
    }
    else {
        Write-Host "FAILED: $TestName" -ForegroundColor Red
        Write-Host "  Reason: $Message" -ForegroundColor Yellow
        $script:TestsFailed++
    }

    $script:TestResults += [PSCustomObject]@{
        TestName = $TestName
        Passed = $Passed
        Message = $Message
    }
}

function New-TestEnvironment {
    param(
        [string]$SourcePath,
        [string]$TargetPath
    )

    # Clean up if exists
    if (Test-Path $SourcePath) { Remove-Item $SourcePath -Recurse -Force }
    if (Test-Path $TargetPath) { Remove-Item $TargetPath -Recurse -Force }

    # Create fresh directories
    New-Item -Path $SourcePath -ItemType Directory -Force | Out-Null
    New-Item -Path $TargetPath -ItemType Directory -Force | Out-Null
}

function Update-ScriptConfiguration {
    param(
        [string]$SourcePath,
        [string]$TargetPath
    )

    # Read the script content
    $ScriptContent = Get-Content $ScriptPath -Raw

    # Replace the configuration variables
    $ScriptContent = $ScriptContent -replace '\$SourceDirectory = ".*?"', "`$SourceDirectory = `"$SourcePath`""
    $ScriptContent = $ScriptContent -replace '\$TargetDirectory = ".*?"', "`$TargetDirectory = `"$TargetPath`""

    # Create a temporary script file
    $TempScriptPath = Join-Path $env:TEMP "LatestFileSync_Test.ps1"
    Set-Content -Path $TempScriptPath -Value $ScriptContent

    return $TempScriptPath
}

function Invoke-ScriptTest {
    param([string]$TempScriptPath)

    try {
        $Output = & $TempScriptPath 2>&1
        $ExitCode = $LASTEXITCODE
        return @{
            Output = $Output
            ExitCode = $ExitCode
        }
    }
    catch {
        return @{
            Output = $_.Exception.Message
            ExitCode = 1
        }
    }
}

# ================================================================================
# TEST 1: Latest File Identification by CreationTime
# ================================================================================

Write-TestHeader "Latest File Identification by CreationTime"

$SourcePath = Join-Path $TestRootPath "Test1_Source"
$TargetPath = Join-Path $TestRootPath "Test1_Target"

New-TestEnvironment -SourcePath $SourcePath -TargetPath $TargetPath

# Create files with different creation times
$File1 = Join-Path $SourcePath "old_file.txt"
$File2 = Join-Path $SourcePath "middle_file.txt"
$File3 = Join-Path $SourcePath "newest_file.txt"

# Create files with specific delays to ensure different CreationTime
New-Item -Path $File1 -ItemType File | Out-Null
Set-Content -Path $File1 -Value "Old file"
Start-Sleep -Milliseconds 100

New-Item -Path $File2 -ItemType File | Out-Null
Set-Content -Path $File2 -Value "Middle file"
Start-Sleep -Milliseconds 100

New-Item -Path $File3 -ItemType File | Out-Null
Set-Content -Path $File3 -Value "Newest file"

# Manually set creation times to be absolutely sure
$OldTime = (Get-Date).AddHours(-3)
$MiddleTime = (Get-Date).AddHours(-2)
$NewTime = (Get-Date).AddHours(-1)

(Get-Item $File1).CreationTime = $OldTime
(Get-Item $File2).CreationTime = $MiddleTime
(Get-Item $File3).CreationTime = $NewTime

Write-Host "Created test files with different CreationTime values:" -ForegroundColor Gray
Write-Host "  old_file.txt: $OldTime" -ForegroundColor Gray
Write-Host "  middle_file.txt: $MiddleTime" -ForegroundColor Gray
Write-Host "  newest_file.txt: $NewTime" -ForegroundColor Gray

# Run the script
$TempScript = Update-ScriptConfiguration -SourcePath $SourcePath -TargetPath $TargetPath
$Result = Invoke-ScriptTest -TempScriptPath $TempScript
Remove-Item $TempScript -Force

# Verify newest file was copied
$CopiedFiles = Get-ChildItem -Path $TargetPath -File
$Passed = ($CopiedFiles.Count -eq 1) -and ($CopiedFiles[0].Name -eq "newest_file.txt")
Write-TestResult -TestName "Latest File Identification" -Passed $Passed -Message $(if ($Passed) { "Correct file copied" } else { "Expected newest_file.txt, got: $($CopiedFiles.Name -join ', ')" })

# ================================================================================
# TEST 2: Files Deleted but Subfolders Preserved
# ================================================================================

Write-TestHeader "Files Deleted but Subfolders Preserved in Target"

$SourcePath = Join-Path $TestRootPath "Test2_Source"
$TargetPath = Join-Path $TestRootPath "Test2_Target"

New-TestEnvironment -SourcePath $SourcePath -TargetPath $TargetPath

# Create source file
New-Item -Path (Join-Path $SourcePath "source_file.txt") -ItemType File | Out-Null

# Create files and subfolders in target
New-Item -Path (Join-Path $TargetPath "old_file1.txt") -ItemType File | Out-Null
New-Item -Path (Join-Path $TargetPath "old_file2.txt") -ItemType File | Out-Null
New-Item -Path (Join-Path $TargetPath "subfolder1") -ItemType Directory | Out-Null
New-Item -Path (Join-Path $TargetPath "subfolder2") -ItemType Directory | Out-Null
New-Item -Path (Join-Path $TargetPath "subfolder1\subfolder_file.txt") -ItemType File | Out-Null

Write-Host "Created in target: 2 files, 2 subfolders (1 with file inside)" -ForegroundColor Gray

# Run the script
$TempScript = Update-ScriptConfiguration -SourcePath $SourcePath -TargetPath $TargetPath
$Result = Invoke-ScriptTest -TempScriptPath $TempScript
Remove-Item $TempScript -Force

# Verify files deleted but subfolders preserved
$TargetFiles = Get-ChildItem -Path $TargetPath -File
$TargetFolders = Get-ChildItem -Path $TargetPath -Directory

$FilesCorrect = ($TargetFiles.Count -eq 1) -and ($TargetFiles[0].Name -eq "source_file.txt")
$FoldersPreserved = ($TargetFolders.Count -eq 2)
$SubfolderFilePreserved = Test-Path (Join-Path $TargetPath "subfolder1\subfolder_file.txt")

$Passed = $FilesCorrect -and $FoldersPreserved -and $SubfolderFilePreserved

Write-Host "Results:" -ForegroundColor Gray
Write-Host "  Files in target root: $($TargetFiles.Count) (Expected: 1 - source_file.txt)" -ForegroundColor Gray
Write-Host "  Subfolders preserved: $($TargetFolders.Count) (Expected: 2)" -ForegroundColor Gray
Write-Host "  Subfolder contents preserved: $SubfolderFilePreserved" -ForegroundColor Gray

Write-TestResult -TestName "Files Deleted, Subfolders Preserved" -Passed $Passed -Message $(if ($Passed) { "Correct behavior" } else { "Files: $FilesCorrect, Folders: $FoldersPreserved, Subfolder files: $SubfolderFilePreserved" })

# ================================================================================
# TEST 3: Error Handling - Source Directory Does Not Exist
# ================================================================================

Write-TestHeader "Error Handling - Source Directory Does Not Exist"

$SourcePath = Join-Path $TestRootPath "NonExistent_Source"
$TargetPath = Join-Path $TestRootPath "Test3_Target"

# Ensure source doesn't exist, target does
if (Test-Path $SourcePath) { Remove-Item $SourcePath -Recurse -Force }
New-Item -Path $TargetPath -ItemType Directory -Force | Out-Null

Write-Host "Source directory does not exist: $SourcePath" -ForegroundColor Gray

# Run the script
$TempScript = Update-ScriptConfiguration -SourcePath $SourcePath -TargetPath $TargetPath
$Result = Invoke-ScriptTest -TempScriptPath $TempScript
Remove-Item $TempScript -Force

# Verify exit code is 1
$Passed = ($Result.ExitCode -eq 1)
Write-TestResult -TestName "Source Directory Missing" -Passed $Passed -Message $(if ($Passed) { "Exit code 1 as expected" } else { "Expected exit code 1, got: $($Result.ExitCode)" })

# ================================================================================
# TEST 4: Error Handling - Target Directory Does Not Exist
# ================================================================================

Write-TestHeader "Error Handling - Target Directory Does Not Exist"

$SourcePath = Join-Path $TestRootPath "Test4_Source"
$TargetPath = Join-Path $TestRootPath "NonExistent_Target"

# Ensure source exists, target doesn't
New-Item -Path $SourcePath -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path $SourcePath "test.txt") -ItemType File | Out-Null
if (Test-Path $TargetPath) { Remove-Item $TargetPath -Recurse -Force }

Write-Host "Target directory does not exist: $TargetPath" -ForegroundColor Gray

# Run the script
$TempScript = Update-ScriptConfiguration -SourcePath $SourcePath -TargetPath $TargetPath
$Result = Invoke-ScriptTest -TempScriptPath $TempScript
Remove-Item $TempScript -Force

# Verify exit code is 1
$Passed = ($Result.ExitCode -eq 1)
Write-TestResult -TestName "Target Directory Missing" -Passed $Passed -Message $(if ($Passed) { "Exit code 1 as expected" } else { "Expected exit code 1, got: $($Result.ExitCode)" })

# ================================================================================
# TEST 5: Error Handling - No Files in Source Directory
# ================================================================================

Write-TestHeader "Error Handling - No Files in Source Directory"

$SourcePath = Join-Path $TestRootPath "Test5_Source"
$TargetPath = Join-Path $TestRootPath "Test5_Target"

New-TestEnvironment -SourcePath $SourcePath -TargetPath $TargetPath

# Create only a subdirectory in source, no files
New-Item -Path (Join-Path $SourcePath "empty_subfolder") -ItemType Directory | Out-Null

Write-Host "Source directory contains only a subfolder, no files" -ForegroundColor Gray

# Run the script
$TempScript = Update-ScriptConfiguration -SourcePath $SourcePath -TargetPath $TargetPath
$Result = Invoke-ScriptTest -TempScriptPath $TempScript
Remove-Item $TempScript -Force

# Verify exit code is 1
$Passed = ($Result.ExitCode -eq 1)
Write-TestResult -TestName "No Files in Source" -Passed $Passed -Message $(if ($Passed) { "Exit code 1 as expected" } else { "Expected exit code 1, got: $($Result.ExitCode)" })

# ================================================================================
# TEST 6: Only Files Considered (Not Directories)
# ================================================================================

Write-TestHeader "Only Files Considered (Not Directories)"

$SourcePath = Join-Path $TestRootPath "Test6_Source"
$TargetPath = Join-Path $TestRootPath "Test6_Target"

New-TestEnvironment -SourcePath $SourcePath -TargetPath $TargetPath

# Create file and directory in source
$TestFile = Join-Path $SourcePath "test_file.txt"
$TestFolder = Join-Path $SourcePath "test_folder"

New-Item -Path $TestFile -ItemType File | Out-Null
Start-Sleep -Milliseconds 100
New-Item -Path $TestFolder -ItemType Directory | Out-Null

# Make directory "newer" by creation time
(Get-Item $TestFile).CreationTime = (Get-Date).AddHours(-2)
(Get-Item $TestFolder).CreationTime = (Get-Date).AddHours(-1)

Write-Host "Created file (older) and directory (newer) in source" -ForegroundColor Gray

# Run the script
$TempScript = Update-ScriptConfiguration -SourcePath $SourcePath -TargetPath $TargetPath
$Result = Invoke-ScriptTest -TempScriptPath $TempScript
Remove-Item $TempScript -Force

# Verify file was copied (not directory)
$CopiedFiles = Get-ChildItem -Path $TargetPath -File
$CopiedFolders = Get-ChildItem -Path $TargetPath -Directory

$Passed = ($CopiedFiles.Count -eq 1) -and ($CopiedFiles[0].Name -eq "test_file.txt") -and ($CopiedFolders.Count -eq 0)
Write-TestResult -TestName "Only Files Considered" -Passed $Passed -Message $(if ($Passed) { "File copied, directory ignored" } else { "Expected only test_file.txt, got: Files=$($CopiedFiles.Count), Folders=$($CopiedFolders.Count)" })

# ================================================================================
# TEST 7: Successful Execution Returns Exit Code 0
# ================================================================================

Write-TestHeader "Successful Execution Returns Exit Code 0"

$SourcePath = Join-Path $TestRootPath "Test7_Source"
$TargetPath = Join-Path $TestRootPath "Test7_Target"

New-TestEnvironment -SourcePath $SourcePath -TargetPath $TargetPath

# Create a simple test file
New-Item -Path (Join-Path $SourcePath "success_test.txt") -ItemType File | Out-Null

Write-Host "Created test file in source" -ForegroundColor Gray

# Run the script
$TempScript = Update-ScriptConfiguration -SourcePath $SourcePath -TargetPath $TargetPath
$Result = Invoke-ScriptTest -TempScriptPath $TempScript
Remove-Item $TempScript -Force

# Verify exit code is 0
$Passed = ($Result.ExitCode -eq 0)
Write-TestResult -TestName "Successful Exit Code" -Passed $Passed -Message $(if ($Passed) { "Exit code 0 as expected" } else { "Expected exit code 0, got: $($Result.ExitCode)" })

# ================================================================================
# CLEANUP
# ================================================================================

Write-Host ""
Write-Host "Cleaning up test directories..." -ForegroundColor Cyan
if (Test-Path $TestRootPath) {
    Remove-Item $TestRootPath -Recurse -Force
    Write-Host "Test directories removed" -ForegroundColor Green
}

# ================================================================================
# SUMMARY
# ================================================================================

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

foreach ($Result in $TestResults) {
    $Status = if ($Result.Passed) { "PASS" } else { "FAIL" }
    $Color = if ($Result.Passed) { "Green" } else { "Red" }
    Write-Host "[$Status] $($Result.TestName)" -ForegroundColor $Color
}

Write-Host ""
Write-Host "Total Tests: $($TestsPassed + $TestsFailed)" -ForegroundColor White
Write-Host "Passed: $TestsPassed" -ForegroundColor Green
Write-Host "Failed: $TestsFailed" -ForegroundColor Red
Write-Host ""

if ($TestsFailed -eq 0) {
    Write-Host "All tests passed successfully!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "Some tests failed. Please review the results above." -ForegroundColor Yellow
    exit 1
}
