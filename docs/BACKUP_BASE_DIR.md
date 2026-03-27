# BACKUP_BASE_DIR

## Possible situations

| Case  | Object type           | Example                     | Can be created? | Notes                                                 |
|-------|-----------------------|-----------------------------|-----------------|-------------------------------------------------------|
| 1     | Local path            | `C:\Backup\`                | yes             | -> "directory"                                        |
| 2     | Drive letter          | `C:`                        | no              | PowerShell's `Split-Path` uses the term "Qualifier".  |
| 3     | Relative path         | `Backup\`                   | yes             | Use script location as base? Or the current drive?    |
| ~~4~~ | ~~Network computer~~  | ~~`\\fileserver`~~          | ~~no~~          | We can create subfolders only on a network **share**! |
| 5     | Network share         | `\\fileserver\Backup`       | no              |                                                       |
| 6     | "Network folder"      | `\\fileserver\Backup\foo\`  | yes             | Handle like local folders -> "directory"              |

<!--
### Invalid cases

- 4 (Network computer): We can create subfolders only on a network share.
-->

### Case 3

A relative path like `Backup\` could be interpreted in different ways.

- Case 3a: Path below the script directory: e.g. `C:\<script folder>\Backup\`
- Case 3b: Path below the current drive: e.g. `D:\Backup\`
- Case 3c: Path below the home drive: `C:\Backup\`
- Case 3d: Path below the user home: `<Userprofile>\Backup\`
- ...?
