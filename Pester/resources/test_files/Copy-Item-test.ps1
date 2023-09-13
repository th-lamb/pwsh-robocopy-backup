$template   = "${PSScriptRoot}/template_file.txt"
$file_spec  = "${PSScriptRoot}/existing_dir"

Copy-Item -Path "${template}" -Destination "${file_spec}"
Write-Host $LASTEXITCODE



Write-Host -NoNewLine "Press any key to quit..."
[void][System.Console]::ReadKey($true)
