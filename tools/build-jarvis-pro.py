#!/usr/bin/env python3
"""Jarvis o'rnatgich paketini yig'adi: downloads/Jarvis-Pro-Installer.zip   (python3 tools/build-jarvis-pro.py)"""
import os, stat, zipfile
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "jarvis-pro")
OUT = os.path.join(ROOT, "downloads"); os.makedirs(OUT, exist_ok=True)
EXEC = {"install.sh", "Install-Jarvis-Mac.command"}
path = os.path.join(OUT, "Jarvis-Pro-Installer.zip")
with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
    for base, dirs, files in os.walk(SRC):
        dirs[:] = sorted(d for d in dirs if d != "__pycache__")
        for f in sorted(files):
            full = os.path.join(base, f); rel = os.path.relpath(full, SRC).replace(os.sep, "/")
            zi = zipfile.ZipInfo("Jarvis-Pro/" + rel, (2026, 11, 8, 0, 0, 0)); zi.compress_type = zipfile.ZIP_DEFLATED
            mode = 0o755 if (rel in EXEC or rel.endswith(".py")) else 0o644
            zi.external_attr = (stat.S_IFREG | mode) << 16
            z.writestr(zi, open(full, "rb").read())
print(path, round(os.path.getsize(path) / 1e3, 1), "KB")
