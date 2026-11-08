---
name: jarvis-setup
description: github.com/adewaskar/jarvis (J.A.R.V.I.S. ovozli yordamchi, Claude Code bilan ishlaydi) ni foydalanuvchining kompyuteriga xavfsiz o'rnatadi, sozlaydi va tekshiradi. "Jarvisni o'rnat", "install Jarvis", "jarvis.git", "ElevenLabs ovozini ulab ber", "Jarvis ishlamayapti" desa ishlating.
---

# Jarvis (adewaskar/jarvis) o'rnatish va sozlash

Jarvis ikki qismdan iborat: **bridge** (Node serveri, miya: Claude Code'ni headless ishlatadi) va **face** (brauzer sahifasi: ovoz va hologramma). Faqat shu kompyuterda (`127.0.0.1`) ishlaydi.

## Talablar (avval tekshiring)

```bash
node --version      # 20 yoki yuqori
git --version
claude --version    # Claude Code o'rnatilgan va login qilingan bo'lishi kerak
```

- Node yo'q: Windows `winget install OpenJS.NodeJS.LTS`, macOS `brew install node`, yoki nodejs.org.
- Git yo'q: Windows `winget install Git.Git`, macOS `xcode-select --install`.
- Claude Code yo'q: `npm install -g @anthropic-ai/claude-code`, so'ng foydalanuvchi o'zi `claude` ni ishga tushirib login qiladi. **Login'ni siz bajara olmaysiz.**
- Brauzer: haqiqiy Chrome yoki Edge oynasi. Ichki ko'rish paneli (preview) mikrofonni bloklaydi.

## O'rnatish

1. Papka tanlang (odatda `~/Jarvis`). U allaqachon mavjud va bo'sh bo'lmasa, **to'xtang va so'rang**, ustidan yozmang.
2. Tekshirilgan versiyani oling:
   ```bash
   git clone https://github.com/adewaskar/jarvis.git ~/Jarvis
   cd ~/Jarvis
   git checkout 9ae5ec846b6b20a17b2d264e699d6234c4284b23   # 2026-11-07 da sinalgan; eng yangisi uchun o'tkazib yuboring
   npm ci
   ```
3. Xavfsizlik yangilanishlari (dompurify kabi): `npm audit fix`, so'ng `npm test`. Test yiqilsa: `git checkout -- package-lock.json && npm ci`.
4. `npm run setup` bilan tekshiring (u hech narsani o'zgartirmaydi).

## Sozlamalar (kalitlarni chatga yozdirmang)

Hamma sozlama muhit o'zgaruvchisi bilan beriladi. Eng qulayi: `~/.jarvis/jarvis.env` fayli (ruxsat `600`), `KEY=VALUE` qatorlari:

| O'zgaruvchi | Ma'nosi |
|---|---|
| `ELEVENLABS_API_KEY` | Ixtiyoriy. Yaxshi ovoz va Scribe transkripsiya. Kalit: https://elevenlabs.io/app/settings/api-keys |
| `JARVIS_VOICE_ID` | ElevenLabs ovoz ID'si. Default `JBFqnCBsd6RMkjVDRZzb` (George) |
| `JARVIS_ACCOUNT_CONNECTORS=1` | claude.ai hisobidagi Gmail/Kalendar kabi ulagichlarni Jarvisga qo'shadi. Faqat foydalanuvchi aniq xohlasa |
| `JARVIS_MCP_SERVERS` | `~/.claude.json` dagi qaysi MCP serverlar berilishi (vergul bilan) |
| `JARVIS_ALLOW_WRITES=1` | Harakatlar (yuborish, bosish, o'chirish) ruxsati. **Default o'chiq. Foydalanuvchi so'ramaguncha yoqmang** |

Kalitni foydalanuvchi o'zi terminalda kiritsin; agar u kalitni chatga tashlab yuborsa, uni faylga yozing va chatda qayta takrorlamang.

## Ishga tushirish va tekshirish

```bash
cd ~/Jarvis && npm start        # bridge + face birga
curl -s http://127.0.0.1:8787/health      # {"ok":true,"tts":...,"stt":...}
```

Foydalanuvchi Chrome'da `http://localhost:5173` ni ochadi, **INITIALISE** ni bosadi, mikrofonga ruxsat beradi va "Hey Jarvis" deydi. Tugmalar: Space (gapirish), D (diagnostika), T (ovoz sinovi), V (ovozni almashtirish), Esc (to'xtatish).

## Nosozliklar

- **Eshitmaydi:** Chrome/Edge emasmi, haqiqiy oynami, mikrofonga ruxsat berilganmi; D bosing.
- **Miya javob bermaydi:** `npm start` ishlab turibdimi, 8787 port bandmi, `claude` login qilinganmi.
- **Sahifa 5173 da emas:** bridge faqat 5173-5199 va 4173-4199 portlariga ishonadi.
- **Ovoz yomon:** ElevenLabs kaliti yo'q bo'lsa brauzer ovozi ishlatiladi (bu normal).

## Xavfsizlik qoidalari

- Default holat faqat o'qish. Yozish rejimi (`npm run bridge:writes`) ni yoqishdan oldin `bridge/policy.mjs` dagi `decideTool()` ni foydalanuvchiga tushuntiring.
- `JARVIS_BRIDGE_HOST` ni `127.0.0.1` dan boshqasiga o'zgartirmang.
- Kalit/tokenlarni git'ga qo'shmang; `.env.local` va `jarvis.env` repoga kirmaydi.
