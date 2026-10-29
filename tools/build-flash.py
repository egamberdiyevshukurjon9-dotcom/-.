#!/usr/bin/env python3
"""Флешка пакетини йиғади: downloads/Jarvis-Flash.zip  (python3 tools/build-flash.py)"""
import os, re, zipfile, stat
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "downloads"); os.makedirs(OUT, exist_ok=True)

html = open(os.path.join(ROOT, "jarvis", "index.html"), encoding="utf-8").read()
html = re.sub(r'<link rel="(?:manifest|icon|apple-touch-icon)"[^>]*>\n?', "", html)   # файлдан очилганда керак эмас

BAT = ('@echo off\r\nset "F=%~dp0Jarvis.html"\r\n'
       'for %%P in ("%ProgramFiles%\\Google\\Chrome\\Application\\chrome.exe" "%ProgramFiles(x86)%\\Google\\Chrome\\Application\\chrome.exe" "%LocalAppData%\\Google\\Chrome\\Application\\chrome.exe") do (\r\n'
       '  if exist %%P (start "" %%P "%F%" & exit /b)\r\n)\r\n'
       'start "" msedge "%F%"\r\n')
MAC = '#!/bin/bash\ncd "$(dirname "$0")"\nopen -a "Google Chrome" Jarvis.html 2>/dev/null || open Jarvis.html\n'
LIN = ('#!/bin/bash\ncd "$(dirname "$0")"\n'
       'for b in google-chrome google-chrome-stable chromium chromium-browser; do command -v $b >/dev/null && exec $b "file://$PWD/Jarvis.html"; done\n'
       'exec xdg-open Jarvis.html\n')

path = os.path.join(OUT, "Jarvis-Flash.zip")
with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
    def add(name, data, mode=0o644):
        zi = zipfile.ZipInfo("Jarvis-Flash/" + name, (2026, 1, 1, 0, 0, 0))
        zi.external_attr = (stat.S_IFREG | mode) << 16; zi.compress_type = zipfile.ZIP_DEFLATED
        z.writestr(zi, data)
    add("Jarvis.html", html.encode("utf-8"))
    add("Jarvis-Windows.bat", BAT.encode("ascii"))
    add("Jarvis-Mac.command", MAC.encode(), 0o755)
    add("Jarvis-Linux.sh", LIN.encode(), 0o755)
    fan = os.path.join(ROOT, "fan")
    readme = open(os.path.join(fan, "README-uz.txt"), "rb").read()
    add("README-uz.txt", b"\xef\xbb\xbf" + readme)
    for f in sorted(os.listdir(fan)):
        if f.endswith(".mp4"): add("fan/" + f, open(os.path.join(fan, f), "rb").read())
        elif f.endswith(".txt"): add("fan/" + f, b"\xef\xbb\xbf" + open(os.path.join(fan, f), "rb").read())
print(path, round(os.path.getsize(path)/1e6, 1), "MB")
