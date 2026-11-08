# Jarvis: kompyuteringizga o'rnatish

Bu paket videodagi **Jarvis** (`github.com/adewaskar/jarvis`) ni kompyuteringizga o'rnatadi: ovozli yordamchi, Iron Man uslubidagi hologramma interfeysi, miyasi esa sizning **Claude Code** hisobingiz.

```
 Brauzer (yuz va ovoz)  <--ws://localhost:8787-->  Bridge (miya: Claude Code, headless)
 "Hey Jarvis", hologramma                          sizning MCP serverlaringiz bilan ishlaydi
```

## Nima kerak (bir marta)

| Narsa | Qayerdan |
|---|---|
| **Claude Code obunasi** va login | `npm install -g @anthropic-ai/claude-code`, keyin terminalda `claude` va login |
| **Node.js 20+** | https://nodejs.org |
| **Git** | https://git-scm.com |
| **Chrome yoki Edge** | haqiqiy brauzer oynasi (ichki "preview" mikrofonni bloklaydi) |
| ElevenLabs kaliti (ixtiyoriy) | https://elevenlabs.io/app/settings/api-keys, yaxshi ovoz uchun |

## O'rnatish

1. ZIP'ni oching.
2. **Windows:** `Install-Jarvis-Windows.bat` ni ikki marta bosing.
   **macOS:** `Install-Jarvis-Mac.command` ni ikki marta bosing (bloklasa: Terminal'da `bash install.sh`).
   **Linux:** Terminal'da `bash install.sh`.
3. O'rnatgich savol beradi: ElevenLabs kaliti (kiritganingiz ekranda ko'rinmaydi, Enter bosib o'tkazib yuborsangiz ham bo'ladi) va Gmail/Kalendar ulagichlari (standart: yo'q).
4. Tugagach **bir marta** terminalda `claude` yozib login qiling (agar qilmagan bo'lsangiz).

O'rnatgich nima qiladi:
- Jarvis'ni GitHub'dan `~/Jarvis` (Windows: `C:\Users\<siz>\Jarvis`) papkasiga klonlaydi va **men sinagan versiyaga** (`9ae5ec8`) o'tkazadi. Eng yangisi uchun `--latest` (Windows: `-Latest`).
- `npm ci` bilan o'rnatadi, xavfsizlik yangilanishlarini (`npm audit fix`) qo'llaydi va testlarni ishga tushiradi. Test yiqilsa, yangilanishni qaytaradi.
- Sozlamalarni `~/.jarvis/jarvis.env` ga yozadi (faqat siz o'qiy olasiz). Ovoz: ElevenLabs George (`JBFqnCBsd6RMkjVDRZzb`), videodagi bilan bir xil.
- Skilllarni `~/.claude/skills/` ga qo'yadi (mavjudini bosmaydi).
- `start-jarvis.sh` / `Start-Jarvis.bat` (+ Windows'da ish stoli yorlig'i) yaratadi.

## Ishlatish

1. Ishga tushiring: ish stolidagi **Jarvis** yorlig'i (Windows), `Start-Jarvis.command` (macOS) yoki `bash ~/Jarvis/start-jarvis.sh`.
2. Chrome'da `http://localhost:5173` (o'zi ochiladi), **INITIALISE** ni bosing, mikrofonga ruxsat bering.
3. **"Hey Jarvis"** deng. Space: wake so'zsiz gapirish. **D**: diagnostika. **T**: ovoz sinovi. **Esc**: to'xtatish.

Misollar: *"Bugun AI sohasida nima yangilik?"*, *"Mark VII kostyumining rasmini yarat"*, *"Interfeysni qizil qil"*.

## Xavfsizlik (muhim)

- Jarvis **faqat o'qish rejimida** boshlanadi: qidiradi, o'qiydi, rasm yaratadi, lekin yubormaydi, o'chirmaydi, bosmaydi. Harakatlarga ruxsat: `npm run bridge:writes`. Avval `bridge/policy.mjs` dagi `decideTool()` ni o'qing.
- U faqat sizning kompyuteringizda (`127.0.0.1`) ishlaydi. Boshqa manzilga ochmang.
- Gmail/Kalendar ulagichlari Jarvis'ga **pochtangizni o'qish** imkonini beradi. Faqat xohlasangiz yoqing: `~/.jarvis/jarvis.env` ga `JARVIS_ACCOUNT_CONNECTORS=1`.
- Kalitlarni hech qachon chatga, skrinshotga yoki GitHub'ga qo'ymang. Videodagi kalitlar namunaviy.

## Skilllar (Claude Code uchun)

| Skill | Manba | Nima qiladi |
|---|---|---|
| `ai-video-editor` | 3-video (ozbekcha, "7 qadam") | `AI Video Editor/{footage,references,export}` papkasi, ffmpeg o'rnatish, referenslardan `style.skill.md`, jimlikni kesish (`scripts/autocut.py`), subtitr, rang, musiqa, eksport |
| `jarvis-setup` | 4-video ("Jarvis bilan rolik") | Claude Code ichida "Jarvisni o'rnat" desangiz, shu ishlarni qadamma-qadam bajaradi/tuzatadi |

Ishlatish: Claude Code'ni istalgan papkada oching va *"AI Video Editor papkasini tayyorla"* yoki *"Jarvisni o'rnat"* deng.

## Yangilash

`bash install.sh --latest` (Windows: `-Latest`). Eslatma: eng yangi versiyani men sinamaganman.

## Nosozliklar

- **Eshitmaydi:** Chrome/Edge emasmi? haqiqiy oynami? mikrofonga ruxsat berilganmi? **D** ni bosing.
- **Javob bermaydi:** terminalda `npm start` ishlab turibdimi, `claude` login qilinganmi.
- **`npm ci` yiqilsa:** internetni tekshirib, o'rnatgichni qayta ishga tushiring (u o'zi 3 usulda urinadi).
- **Ovoz yomon:** ElevenLabs kaliti yo'q bo'lsa brauzer ovozi ishlatiladi. Bu normal.
