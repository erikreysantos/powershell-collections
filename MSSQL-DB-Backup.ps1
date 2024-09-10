# Disney DB Backup process
# Version 1.1
# Created by: Erik Rey Santos

# Redirect the output of the entire script to a text file (Transcript logging)
$logFilePath = "D:\DBAdmin\BackupResult_$(Get-Date -Format yyyyMMdd_HHmmss).txt"
Start-Transcript -Path $logFilePath

# Logging message
Write-Host "Disney DB Backup Process Started"
Write-Host "Log file: $logFilePath"

# Step 1: Prompt for folder path in S Drive
$folderPath = Read-Host "Go to this path S:\didduredq100_backups_01\"

# Step 2: Check if the provided folder path exists
if (Test-Path -Path $folderPath -PathType Container) {
    # Step 3: Ask for CHG number (new folder name)
    $newFolderName = Read-Host "Enter CHG number"

    # Step 4: Construct the new folder path
    $newFolderPath = Join-Path -Path $folderPath -ChildPath $newFolderName

    # Step 5: Check if folder exists, if not, create the folder
    if (!(Test-Path -Path $newFolderPath -PathType Container)) {
        New-Item -Path $newFolderPath -ItemType Directory -ErrorAction SilentlyContinue
        if (Test-Path -Path $newFolderPath -PathType Container) {
            Write-Host "Folder '$newFolderName' created successfully in '$folderPath'"
        } else {
            Write-Host "Failed to create folder '$newFolderName' in '$folderPath'"
        }
    } else {
        Write-Host "Folder '$newFolderName' already exists in '$folderPath'"
    }
} else {
    Write-Host "The provided path '$folderPath' does not exist or is not a folder"
    Stop-Transcript
    exit
}

# Step 6: Prompt for SQL Server instance name, database name, and backup destination
$SqlServerInstance = Read-Host -Prompt "Enter SQL Server instance name"
$DatabaseName = Read-Host -Prompt "Enter database name"
$BackupDestination = Join-Path -Path $newFolderPath -ChildPath "$DatabaseName.bak"

# Step 7: Construct the SQL backup script
$BackupScript = @"
BACKUP DATABASE [$DatabaseName] 
TO DISK = N'$BackupDestination' 
WITH COPY_ONLY, NOFORMAT, NOINIT, NAME = N'$DatabaseName-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 1;
"@  # STATS = 1 shows progress every 1% completion

# Step 8: Execute the SQL backup script using SQLCMD and capture the progress
$sqlcmdPath = "sqlcmd"

# Execute the backup command and capture progress in real-time
Write-Host "Starting backup for database '$DatabaseName'..."
$backupProcess = Start-Process -FilePath $sqlcmdPath -ArgumentList "-S $SqlServerInstance -Q `"$BackupScript`"" -NoNewWindow -PassThru -RedirectStandardOutput "backupProgress.txt"

# Step 9: Monitor progress from the output log
while (-not $backupProcess.HasExited) {
    # Continuously check and display backup progress from the output file
    if (Test-Path "backupProgress.txt") {
        $progress = Get-Content "backupProgress.txt" | Select-String -Pattern "(\d+)%"
        if ($progress) {
            $progress.Matches | ForEach-Object {
                Write-Host "Backup Progress: $($_.Value)"
            }
        }
    }
    Start-Sleep -Seconds 1  # Sleep for a second before checking again
}

# Step 10: Check if backup was successful
if ($backupProcess.ExitCode -eq 0) {
    Write-Host "Backup of database '$DatabaseName' completed successfully."
} else {
    Write-Host "Error during backup. Please check the log or SQL Server."
}

# Step 11: Finish logging
Write-Host "Backup completed for database '$DatabaseName' with destination '$BackupDestination'"
Write-Host "Disney DB Backup Process Finished"

# Stop logging to the log file
Stop-Transcript
