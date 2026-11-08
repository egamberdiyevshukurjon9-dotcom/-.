---
name: ai-video-editor
description: Video montaj va motion dizayn uchun ish muhitini tayyorlaydi va Claude Code bilan videoni tahrirlaydi (kesish, subtitr, rang, musiqa, eksport). Foydalanuvchi "video montaj", "videoni kes", "subtitr qo'y", "AI Video Editor", "video edit", "stil skill" desa yoki footage/references papkalari bor bo'lsa ishlating. Sets up an ffmpeg-based AI video editing workspace and edits footage end to end.
---

# AI Video Editor (Claude Code + ffmpeg)

Bu skill videolardagi 7 qadamli usulni bajaradi: papka -> asboblar -> referenslar -> stil skill -> kesish -> subtitr/rang/musiqa -> eksport.

## 1-qadam. Ish papkasi

Foydalanuvchi bergan joyda (yoki joriy papkada) shu tuzilmani yarating. Mavjud fayllarni **o'chirmang va ustidan yozmang**.

```
AI Video Editor/
  footage/       # xom videolar (foydalanuvchi shu yerga tashlaydi)
  references/    # namuna videolar va rasmlar (uslub manbai)
  export/        # tayyor natijalar
  style.skill.md # 4-qadamda yaratiladi
```

## 2-qadam. Kerakli asboblar

Avval nima borligini tekshiring: `ffmpeg -version`, `ffprobe -version`, `python3 --version`.
Yo'q bo'lsa, foydalanuvchining tizimiga mos buyruqni **ko'rsating va ruxsat so'rab** ishga tushiring:

| Tizim | ffmpeg |
|---|---|
| Windows | `winget install Gyan.FFmpeg` |
| macOS | `brew install ffmpeg` |
| Ubuntu/Debian | `sudo apt install ffmpeg` |

Subtitr uchun (ixtiyoriy, bir marta): `pip install faster-whisper`. O'zbek tili (`uz`) qo'llab-quvvatlanadi, lekin aniqlik inglizchadan past. Natijani foydalanuvchiga tekshirtiring.

## 3-qadam. Referenslarni o'rganish

`references/` dagi har bir videodan kadrlar va ritmni oling:

```bash
ffprobe -v error -show_entries format=duration:stream=width,height,r_frame_rate -of default=nw=1 ref.mp4
ffmpeg -i ref.mp4 -vf "fps=1/2,scale=480:-2" -q:v 3 frames/ref_%03d.jpg      # har 2 soniyada kadr
ffmpeg -i ref.mp4 -vf "select='gt(scene,0.35)',showinfo" -f null - 2>&1 | grep pts_time   # kesish joylari
```

Kadrlarni ko'rib, quyidagilarni yozib oling: o'rtacha plan uzunligi, kesish tezligi, rang (iliq/sovuq, kontrast), subtitr uslubi (shrift, joylashuv, so'zma-so'z ajratish), musiqa ritmi, o'tishlar.

## 4-qadam. Stil skill (`style.skill.md`)

3-qadam xulosasidan `style.skill.md` yozing: qisqa, tekshirsa bo'ladigan qoidalar (masalan: "plan 2-4 soniya", "subtitr pastdan 20%, qalin oq, qora soya, 1 qatorda 4 so'zgacha", "rang: +10 kontrast, -5 to'yinganlik"). Foydalanuvchiga ko'rsatib, tasdig'ini oling. Keyingi barcha montajda shu faylga amal qiling.

## 5-qadam. Montaj (kesishdan boshlang)

1. **Inventar:** `footage/` dagi har fayl uchun davomiylik, o'lcham, kadr tezligi, audio bor-yo'qligi.
2. **Sukunatni kesish:**
   ```bash
   python3 scripts/autocut.py "footage/clip.mp4" "export/clip_cut.mp4" --noise -35 --min-silence 0.6 --pad 0.12
   ```
   Natijani eshitib/ko'rib baholang; juda ko'p kesilsa `--noise` ni -40 ga tushiring, `--pad` ni oshiring.
3. **Subtitr:** `faster-whisper` bilan SRT oling, matnni foydalanuvchiga tekshirtiring, keyin:
   ```bash
   ffmpeg -i in.mp4 -vf "subtitles=in.srt:force_style='FontName=Arial,FontSize=18,Bold=1,Outline=2,MarginV=60'" -c:a copy out.mp4
   ```
4. **Rang:** `ffmpeg -i in.mp4 -vf "eq=contrast=1.1:saturation=0.95:brightness=0.02" out.mp4` (yoki `lut3d=file.cube`).
5. **Musiqa:** ovozli videoda musiqani gapirganda pasaytiring:
   ```bash
   ffmpeg -i video.mp4 -i music.mp3 -filter_complex "[1:a]volume=0.35[m];[m][0:a]sidechaincompress=threshold=0.05:ratio=8[mduck];[0:a][mduck]amix=inputs=2:duration=first[a]" -map 0:v -map "[a]" -c:v copy out.mp4
   ```
6. **Motion grafika:** sarlavha/lower-third uchun `drawtext` yoki HTML->video (Playwright skrinshotlari) dan foydalaning; murakkab holatda foydalanuvchi bilan kelishing.

## 6-qadam. Eksport

Vertikal (Reels/TikTok/Shorts): `-vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920"`.

```bash
ffmpeg -i in.mp4 -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart "export/final.mp4"
```

Har doim yakuniy faylni `ffprobe` bilan tekshiring (o'lcham, davomiylik, audio) va foydalanuvchiga yo'lini ayting.

## 7-qadam. MCP (ixtiyoriy)

Foydalanuvchi montajni tashqi xizmat bilan ulamoqchi bo'lsa (masalan, Drive'dan fayl olish, Telegramga yuborish), mos MCP serverni `claude mcp add` bilan ulashni taklif qiling. Kalitlarni **chatga yozdirmang**, muhit o'zgaruvchisi yoki fayl orqali bering.

## Qoidalar

- Asl `footage/` fayllarni hech qachon o'zgartirmang; natijalar faqat `export/` ga.
- Har bosqichdan keyin qisqa natija bering va keyingisiga o'tishdan oldin so'rang.
- Noma'lum narsani taxmin qilmang: buyruq xato bersa, xatoni ko'rsatib, sabab va yechimni ayting.
