#!/usr/bin/env python3
"""Янги версия чиқариш: python3 tools/release.py 2.2.0   — index.html ва version.json даги рақамни янгилайди.
Сўнг коммит қилиб push қилинг: ўрнатилган илова ўзи янгилангани ҳақида хабар беради."""
import re, sys, json, os
ver = sys.argv[1]
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "jarvis")
p = os.path.join(root, "index.html"); s = open(p, encoding="utf-8").read()
s, n = re.subn(r'const APP_VERSION = "[^"]+";', f'const APP_VERSION = "{ver}";', s); assert n == 1
open(p, "w", encoding="utf-8").write(s)
q = os.path.join(root, "version.json"); j = json.load(open(q, encoding="utf-8")); j["version"] = ver
json.dump(j, open(q, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print("версия:", ver)
