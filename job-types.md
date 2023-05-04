# Job types

## All parameter combinations

| Case  | Object type         | Inclusions  | Exclusions  | Source-Dir  | /IF                 | /XD                 | /XF               | Notes                 |
|-------|---------------------|-------------|-------------|-------------|---------------------|---------------------|-------------------|-----------------------|
| 1     | source-dir          | no          | no          | source-dir  | `*.*`               | —                   | —                 ||
| 2     |                     | yes         | no          | source-dir  | incl-files-pattern  | —                   | —                 ||
| 3     |                     | no          | yes         | source-dir  | `*.*`               | excl-files-pattern  | excl-dirs-pattern ||
| 4     |                     | yes         | yes         | source-dir  | incl-files-pattern  | excl-files-pattern  | excl-dirs-pattern ||
|       |                     |             |             |             |                     |                     |                   ||
| 5     | source-file         | invalid     | invalid     | parent-dir  | filename            | —                   | —                 | Backup 1 single file. |
|       |                     |             |             |             |                     |                     |                   ||
| —     | source-dir-pattern  | —           | —           | —           | —                   | —                   | —                 | **Not implemented (would require multiple target dirs!)** |
|       |                     |             |             |             |                     |                     |                   ||
| 6     | source-file-pattern | invalid     | no          | parent-dir  | file-pattern        | —                   | —                 | **Pattern must include the parent directory!** |
| 7     |                     | invalid     | yes         | parent-dir  | file-pattern        | excl-files-pattern  | excl-dirs-pattern | e.g. `*.pdf` but not `secret.pdf` |

All **combinations are unique** regarding `Source-Dir`, `/IF`, `/XD`, and `/XF` — we have to handle 7 cases.
