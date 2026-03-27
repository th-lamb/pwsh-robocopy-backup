# Bootstrap Logging System

`backup.ps1` implements a "Bootstrap Logging" mechanism. This ensures that the script remains informative even during the first vulnerable initialization phase.

## The Problem

A standard logging system (like the one in `lib/logging-functions.ps1`) depends on:
1.  **Library Sourcing:** The functions must be loaded into memory.
2.  **Configuration:** The log file path must be known (usually from `backup.ini`).

If an error occurs *before* these steps are complete (e.g., the `lib/` folder is missing or `backup.ini` is corrupt), the script would typically crash with raw PowerShell errors, leaving the user without a clean log entry.

## The Solution: Two-Stage Logging

The "Bootstrap" approach splits logging into two distinct phases.

### Phase 1: The Early Buffer (Pre-Flight)

At the very start of `backup.ps1`, a lightweight, dependency-free logging system is initialized:

*   **Message Buffer:** A script-scoped list (`$Script:earlyMsgBuffer`) temporarily stores messages.
*   **Early Logger:** A local function `Write-EarlyMsg` is defined. It:
    *   Writes a message directly to the console so the user has immediate feedback.
    *   Saves a structured object (Timestamp, Severity, Message) into the buffer.

This allows us to safely wrap critical setup steps — like changing the working directory and sourcing library files — in `try/catch` blocks.

### Phase 2: The Handover (Persistent Logging)

Once the library functions are available and settings (including `$BACKUP_LOGFILE`) are successfully read, the script performs a "Handover":

1.  **Validation:** The script confirms that a valid log file path exists.
2.  **Flushing:** It loops through all messages stored in the `$Script:earlyMsgBuffer`.
3.  **Persistence:** It uses the real `Add-LogMessage` function to write these early events into the permanent log file.
4.  **Cleanup:** The buffer is cleared to free memory.

## Benefits

*   **Graceful Failures:** If the `lib/` folder is renamed or deleted, the user receives a clear, human-readable error message instead of a "Red Screen of Death."
*   **Complete Audit Trail:** The final log file contains a complete history of the run, including the very first initialization steps, ensuring no information is lost.
*   **Resilience:** The script can now handle its own "bootstrapping" process without external dependencies, making it much more robust in unstable environments.

## Implementation Details

*   **Location:** The bootstrap logic is located at the top of `backup.ps1` in the `Bootstrap Logging` region.
*   **Handover Point:** The "Flush" occurs immediately after the `Read-SettingsFile` call in the `Read settings file` region.
