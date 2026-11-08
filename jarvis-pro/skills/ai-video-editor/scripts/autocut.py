#!/usr/bin/env python3
"""Videodagi sukunat (jim) qismlarni kesib tashlaydi.  Faqat ffmpeg kerak (ffprobe shart emas).

Ishlatish:
  python3 autocut.py kirish.mp4 chiqish.mp4 [--noise -35] [--min-silence 0.6] [--pad 0.12] [--crf 18]
"""
import argparse, os, re, subprocess, sys, tempfile


def run(cmd):
    return subprocess.run(cmd, stderr=subprocess.PIPE, stdout=subprocess.PIPE, text=True)


def duration_and_audio(ffmpeg, path):
    info = run([ffmpeg, "-hide_banner", "-i", path]).stderr
    m = re.search(r"Duration:\s*(\d+):(\d+):(\d+\.\d+)", info)
    if not m:
        sys.exit("Davomiylikni aniqlab bo'lmadi: " + path)
    dur = int(m.group(1)) * 3600 + int(m.group(2)) * 60 + float(m.group(3))
    return dur, "Audio:" in info


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("input"); ap.add_argument("output")
    ap.add_argument("--noise", type=float, default=-35.0, help="jimlik chegarasi, dB (default -35)")
    ap.add_argument("--min-silence", type=float, default=0.6, help="shundan uzun jimlik kesiladi, soniya")
    ap.add_argument("--pad", type=float, default=0.12, help="har bo'lakning ikki chetiga qoldiriladigan zaxira, soniya")
    ap.add_argument("--crf", type=int, default=18)
    ap.add_argument("--ffmpeg", default="ffmpeg")
    a = ap.parse_args()

    if not os.path.isfile(a.input):
        sys.exit("Fayl topilmadi: " + a.input)
    dur, has_audio = duration_and_audio(a.ffmpeg, a.input)
    if not has_audio:
        sys.exit("Videoda audio yo'q: jimlikni aniqlab bo'lmaydi.")

    log = run([a.ffmpeg, "-hide_banner", "-nostats", "-i", a.input, "-af",
               f"silencedetect=noise={a.noise}dB:d={a.min_silence}", "-f", "null", "-"]).stderr
    starts = [float(x) for x in re.findall(r"silence_start:\s*(-?\d+\.?\d*)", log)]
    ends = [float(x) for x in re.findall(r"silence_end:\s*(-?\d+\.?\d*)", log)]
    if len(starts) > len(ends):          # jimlik video oxirigacha davom etgan
        ends.append(dur)
    silences = [(max(0.0, s), min(dur, e)) for s, e in zip(starts, ends)]

    keep, cur = [], 0.0
    for s, e in silences:
        if s - cur > 0.05:
            keep.append((cur, s))
        cur = e
    if dur - cur > 0.05:
        keep.append((cur, dur))
    # zaxira qo'shib, kesishgan bo'laklarni birlashtiramiz
    padded = []
    for s, e in keep:
        s, e = max(0.0, s - a.pad), min(dur, e + a.pad)
        if padded and s <= padded[-1][1]:
            padded[-1] = (padded[-1][0], max(padded[-1][1], e))
        else:
            padded.append((s, e))
    if not padded:
        sys.exit("Hammasi jim deb topildi. --noise ni pasaytiring (masalan -45).")

    kept = sum(e - s for s, e in padded)
    print(f"Asl: {dur:.2f}s -> qoladi: {kept:.2f}s ({len(padded)} bo'lak, {dur - kept:.2f}s kesildi)")

    parts, labels = [], ""
    for i, (s, e) in enumerate(padded):
        parts.append(f"[0:v]trim=start={s:.3f}:end={e:.3f},setpts=PTS-STARTPTS[v{i}]")
        parts.append(f"[0:a]atrim=start={s:.3f}:end={e:.3f},asetpts=PTS-STARTPTS[a{i}]")
        labels += f"[v{i}][a{i}]"
    parts.append(f"{labels}concat=n={len(padded)}:v=1:a=1[v][a]")
    graph = ";\n".join(parts)
    tail = ["-map", "[v]", "-map", "[a]", "-c:v", "libx264", "-preset", "medium", "-crf", str(a.crf),
            "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", a.output]
    base = [a.ffmpeg, "-y", "-hide_banner", "-loglevel", "error", "-i", a.input]
    if len(graph) < 20000:               # qisqa graf: to'g'ridan-to'g'ri (barcha ffmpeg versiyalarida ishlaydi)
        attempts = [base + ["-filter_complex", graph] + tail]
        script = None
    else:                                # uzun graf: faylga yozamiz (yangi va eski ffmpeg sintaksisi)
        with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False) as f:
            f.write(graph); script = f.name
        attempts = [base + ["-/filter_complex", script] + tail, base + ["-filter_complex_script", script] + tail]
    try:
        for cmd in attempts:
            r = run(cmd)
            if r.returncode == 0:
                break
    finally:
        if script:
            os.unlink(script)
    if r.returncode != 0:
        sys.exit("ffmpeg xatosi:\n" + r.stderr)
    print("Tayyor:", a.output)


if __name__ == "__main__":
    main()
