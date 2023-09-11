# pwsh-robocopy-backup

Backup with PowerShell and robocopy using a list of directories/files to backup.

## ...

### Exceptions

#### Single files

Single files (e.g. `%UserProfile%\.gitconfig`) will be copied directly without robocopy.
Reason: robocopy always works folder based and would search for the file pattern in all subfolders.
This would:

- Waste time,
- Very likely create a lot of empty subfolders in the backup, and
- Possibly even copy unwanted other files with the same filename from subfolders.
