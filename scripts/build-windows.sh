#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
dotnet publish windows/N2O.Windows.csproj -c Release -r win-x64 \
  --self-contained true -p:PublishSingleFile=true \
  -p:EnableCompressionInSingleFile=true \
  -p:IncludeNativeLibrariesForSelfExtract=true -o build/windows-x64
python3 - <<'PY'
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
root = Path.cwd()
with ZipFile(root / 'build/N2O-Windows-x64.zip', 'w', ZIP_DEFLATED) as archive:
    archive.write(root / 'build/windows-x64/N2O.exe', 'N2O/N2O.exe')
    archive.write(root / 'windows/README.md', 'N2O/README.txt')
print(root / 'build/N2O-Windows-x64.zip')
PY
