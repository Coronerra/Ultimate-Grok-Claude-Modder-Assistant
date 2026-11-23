# SHA256SUMS: how to make and check them

Format (GNU coreutils, one line per file, paths relative to the folder you run it in):
```
<64 hex chars>  ./Scripts/Example.pex
```

## Make (box, Linux)
```bash
cd <package>/stage
find . -type f -print0 | sort -z | xargs -0 sha256sum > ../SHA256SUMS
```

## Check (box, Linux)
```bash
cd <package>/stage && sha256sum -c ../SHA256SUMS      # every line must say OK
```

## Check (PC, PowerShell)
```powershell
$root = '<STAGING_DIR>\<package>\stage'
Get-Content "$root\..\SHA256SUMS" | ForEach-Object {
  if ($_ -match '^([0-9a-fA-F]{64})\s+\*?(.+)$') {
    $p = Join-Path $root ($Matches[2] -replace '^\./','' -replace '/','\')
    $h = (Get-FileHash -Algorithm SHA256 $p).Hash
    if ($h -ne $Matches[1].ToUpper()) { Write-Error "MISMATCH $p" } else { "OK  $p" }
  }
}
```

## Rules
- Hash the **live** file read-only right before staging and record it as the "pre" hash in CHANGES.md. Deploy refuses if it changed.
- Re-hash after copying to the PC, before deploying, and after deploying.
- Hash `plugins.txt` and `loadorder.txt` before and after any CK / xEdit / tool session; they must not change.
- Keep a separate SHA256SUMS for big pinned downloads (tools, archives) and check it before extracting.
