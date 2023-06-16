# BACKUP_BASE_DIR

## Possible situations

| Case  | Object type         | Example                     | Can be created? | Notes                                                 |
|-------|---------------------|-----------------------------|-----------------|-------------------------------------------------------|
| 1     | Relative path       | `Backup\`                   | yes             | Use script location as base? Or the current drive?    |
| 2     | Drive letter        | `C:`                        | no              | PowerShell's `Split-Path` uses the term "Qualifier".  |
| 3     | Local path          | `C:\Backup\`                | yes             | -> "directory"                                        |
| 4     | Network computer    | `\\fileserver`              | no              |                                                       |
| 5     | Network share       | `\\fileserver\Backup`       | no              |                                                       |
| 6     | "Network folder"    | `\\fileserver\Backup\foo\`  | yes             | Handle like local folders? -> "directory"             |

<!--
All **combinations are unique** regarding `Source-Dir`, `/IF`, `/XD`, and `/XF` — we have to handle 7 cases.
-->

## Case 1

A relative path like `Backup\` could be interpreted in different ways.

- `C:\<script folder>\Backup\`
- `C:\Backup\`
- `<Userprofile>\Backup\`
