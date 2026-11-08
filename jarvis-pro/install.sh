#!/usr/bin/env bash
# JARVIS o'rnatgichi (macOS / Linux) -- github.com/adewaskar/jarvis
# Ishlatish:  bash install.sh [--dir ~/Jarvis] [--latest] [--yes] [--skip-claude] [--skip-skills] [--skip-audit-fix] [--reconfigure]
set -euo pipefail

REPO_URL="https://github.com/adewaskar/jarvis.git"
PINNED_SHA="9ae5ec846b6b20a17b2d264e699d6234c4284b23"   # 2026-11-07 da sinalgan versiya
DEST="${HOME}/Jarvis"
CONF_DIR="${HOME}/.jarvis"; ENV_FILE="${CONF_DIR}/jarvis.env"
LATEST=0; YES=0; SKIP_CLAUDE=0; SKIP_SKILLS=0; SKIP_AUDIT=0; RECONF=0
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() { sed -n '2,3p' "$0"; }
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) DEST="$2"; shift 2 ;;
    --latest) LATEST=1; shift ;;
    --yes|-y) YES=1; shift ;;
    --skip-claude) SKIP_CLAUDE=1; shift ;;
    --skip-skills) SKIP_SKILLS=1; shift ;;
    --skip-audit-fix) SKIP_AUDIT=1; shift ;;
    --reconfigure) RECONF=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Noma'lum parametr: $1"; exit 2 ;;
  esac
done

if [ -t 1 ]; then B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; N=$'\033[0m'; else B=""; G=""; Y=""; R=""; N=""; fi
say()  { printf '%s\n' "${B}==>${N} $*"; }
ok()   { printf '%s\n' "  ${G}ok${N}  $*"; }
warn() { printf '%s\n' "  ${Y}!${N}   $*"; }
die()  { printf '%s\n' "${R}Xato:${N} $*" >&2; exit 1; }

ask_yn() {  # ask_yn "savol" y|n   (interaktiv bo'lmasa yoki --yes bo'lsa standart javob)
  local q="$1" def="${2:-n}" ans
  if [ "$YES" = 1 ] || [ ! -t 0 ]; then [ "$def" = y ]; return; fi
  read -r -p "$q [$([ "$def" = y ] && echo 'Ha/yoq' || echo 'ha/Yoq')]: " ans || ans=""
  case "$ans" in "") [ "$def" = y ] ;; y|Y|yes|YES|h|H|ha|Ha|HA|да|Да|ҳа|Ҳа) return 0 ;; *) return 1 ;; esac
}

OS="$(uname -s)"
echo
say "JARVIS o'rnatgichi (${OS})"
echo "    Papka: ${DEST}"
echo

# 1) Talablar ----------------------------------------------------------------
say "1/7  Talablarni tekshirish"
command -v git  >/dev/null 2>&1 || die "git topilmadi. macOS: 'xcode-select --install', Linux: 'sudo apt install git'."
command -v node >/dev/null 2>&1 || die "Node.js topilmadi. https://nodejs.org dan 20+ versiyani o'rnating (macOS: 'brew install node')."
command -v npm  >/dev/null 2>&1 || die "npm topilmadi (Node.js bilan birga o'rnatiladi)."
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
[ "$NODE_MAJOR" -ge 20 ] || die "Node.js $(node --version) juda eski. 20 yoki yuqori kerak."
ok "git $(git --version | awk '{print $3}'), node $(node --version), npm $(npm --version)"

# 2) Claude Code -------------------------------------------------------------
say "2/7  Claude Code"
if command -v claude >/dev/null 2>&1; then
  ok "claude topildi: $(claude --version 2>/dev/null | head -1)"
elif [ "$SKIP_CLAUDE" = 1 ]; then
  warn "Claude Code o'tkazib yuborildi (--skip-claude). Jarvis miyasi uchun u kerak."
elif ask_yn "Claude Code o'rnatilmagan. Hozir o'rnataymi (npm install -g @anthropic-ai/claude-code)?" y; then
  if npm install -g @anthropic-ai/claude-code; then ok "Claude Code o'rnatildi."
  else warn "O'rnatilmadi (ruxsat xatosi bo'lishi mumkin). https://docs.claude.com/en/docs/claude-code dagi usuldan foydalaning."; fi
else
  warn "Claude Code o'rnatilmadi. Keyinroq: npm install -g @anthropic-ai/claude-code"
fi

# 3) Jarvis'ni olish ---------------------------------------------------------
say "3/7  Jarvis'ni GitHub'dan olish"
if [ -d "$DEST/.git" ]; then
  [ "$(git -C "$DEST" remote get-url origin 2>/dev/null || true)" = "$REPO_URL" ] || [ "$(git -C "$DEST" remote get-url origin 2>/dev/null || true)" = "${REPO_URL%.git}" ] \
    || die "$DEST boshqa repozitoriy. Boshqa papka tanlang: --dir"
  git -C "$DEST" checkout --quiet -- package-lock.json 2>/dev/null || true
  git -C "$DEST" fetch --quiet origin
  ok "mavjud nusxa yangilandi"
elif [ -e "$DEST" ] && [ -n "$(ls -A "$DEST" 2>/dev/null)" ]; then
  die "$DEST band (bo'sh emas). Boshqa papka tanlang: --dir <yo'l>"
else
  git clone --quiet "$REPO_URL" "$DEST"
  ok "klonlandi: $REPO_URL"
fi
if [ "$LATEST" = 1 ]; then
  DEF="$(git -C "$DEST" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)"; DEF="${DEF:-main}"
  git -C "$DEST" checkout --quiet "$DEF" && git -C "$DEST" pull --quiet --ff-only origin "$DEF"
  warn "eng yangi versiya ($DEF) olindi: bu versiya sinalmagan"
else
  git -C "$DEST" checkout --quiet "$PINNED_SHA" 2>/dev/null || die "Sinalgan versiya ($PINNED_SHA) topilmadi. --latest bilan urinib ko'ring."
  ok "sinalgan versiya: ${PINNED_SHA:0:7}"
fi

# 4) Bog'liqliklar -----------------------------------------------------------
# onnxruntime-node (ixtiyoriy brauzer ovozi uchun) Linux'da katta CUDA faylini yuklashga urinadi va tez-tez yiqiladi: uni o'tkazib yuboramiz.
export npm_config_onnxruntime_node_install_cuda=skip
npm_install() {   # 1) oddiy  2) qayta urinish  3) o'rnatish skriptlarisiz (asosiy dastur baribir ishlaydi)
  ( cd "$DEST" && npm ci --no-fund --no-audit --loglevel=error ) && return 0
  warn "npm ci yiqildi, qayta uriniladi..."
  ( cd "$DEST" && npm ci --no-fund --no-audit --loglevel=error ) && return 0
  warn "o'rnatish skriptlarisiz uriniladi (ixtiyoriy brauzer ovozi 'kokoro' ishlamasligi mumkin)"
  ( cd "$DEST" && npm ci --ignore-scripts --no-fund --no-audit --loglevel=error )
}
say "4/7  Bog'liqliklarni o'rnatish (npm ci), 1-2 daqiqa"
npm_install || die "npm ci muvaffaqiyatsiz. Internetni tekshiring va qayta ishga tushiring."
ok "o'rnatildi"
if [ "$SKIP_AUDIT" = 0 ]; then
  say "     Xavfsizlik yangilanishlari (npm audit fix) va sinov"
  if ( cd "$DEST" && npm test --silent >/dev/null 2>&1 ); then
    ( cd "$DEST" && npm audit fix --no-fund --loglevel=error >/dev/null 2>&1 || true )
    if ( cd "$DEST" && npm test --silent >/dev/null 2>&1 ); then ok "yangilanishlar qo'llandi, testlar o'tdi"
    else
      warn "yangilanishdan keyin testlar o'tmadi: asl holatga qaytarilmoqda"
      ( cd "$DEST" && git checkout --quiet -- package-lock.json ) && npm_install || die "asl holatni tiklab bo'lmadi"
    fi
  else
    warn "testlar yangilanishdan oldin ham o'tmadi (bu kompyuterdagi muhit sababli bo'lishi mumkin): audit fix o'tkazib yuborildi"
  fi
fi

# 5) Sozlamalar --------------------------------------------------------------
say "5/7  Sozlamalar"
mkdir -p "$CONF_DIR"; chmod 700 "$CONF_DIR" 2>/dev/null || true
if [ -f "$ENV_FILE" ] && [ "$RECONF" = 0 ]; then
  ok "mavjud sozlama saqlandi: $ENV_FILE  (o'zgartirish: --reconfigure)"
else
  EL_KEY="${ELEVENLABS_API_KEY:-}"; CONNECT=0
  if [ -z "$EL_KEY" ] && [ "$YES" = 0 ] && [ -t 0 ]; then
    echo "    ElevenLabs kaliti (ixtiyoriy): yaxshi ovoz uchun. Olish: https://elevenlabs.io/app/settings/api-keys"
    echo "    Kalit ekranda ko'rinmaydi. O'tkazib yuborish uchun Enter bosing."
    read -r -s -p "    ELEVENLABS_API_KEY: " EL_KEY || EL_KEY=""; echo
  fi
  EL_KEY="$(printf '%s' "$EL_KEY" | tr -d '[:space:]')"
  if ask_yn "Gmail/Kalendar kabi claude.ai ulagichlarini Jarvisga ulaymi? (u ularni o'qiy oladi)" n; then CONNECT=1; fi
  ( umask 077
    {
      echo "# Jarvis sozlamalari -- bu faylni hech kimga yubormang"
      echo "JARVIS_VOICE_ID=JBFqnCBsd6RMkjVDRZzb"
      [ -n "$EL_KEY" ] && echo "ELEVENLABS_API_KEY=$EL_KEY"
      [ "$CONNECT" = 1 ] && echo "JARVIS_ACCOUNT_CONNECTORS=1"
      true
    } > "$ENV_FILE" )
  chmod 600 "$ENV_FILE"
  ok "yozildi: $ENV_FILE (faqat siz o'qiy olasiz)"
  [ -n "$EL_KEY" ] && ok "ElevenLabs kaliti saqlandi" || warn "ElevenLabs kaliti yo'q: brauzer ovozi ishlatiladi (bu normal)"
fi

# 6) Skilllar ----------------------------------------------------------------
say "6/7  Claude Code skilllari"
if [ "$SKIP_SKILLS" = 1 ] || [ ! -d "$HERE/skills" ]; then warn "o'tkazib yuborildi"
else
  mkdir -p "${HOME}/.claude/skills"
  for d in "$HERE"/skills/*/; do
    n="$(basename "$d")"
    if [ -e "${HOME}/.claude/skills/$n" ]; then warn "$n: allaqachon bor, tegilmadi"
    else cp -R "$d" "${HOME}/.claude/skills/$n" && ok "$n"; fi
  done
fi

# 7) Ishga tushirgich --------------------------------------------------------
say "7/7  Ishga tushirgich"
LAUNCH="$DEST/start-jarvis.sh"
cat > "$LAUNCH" <<'LAUNCHER'
#!/usr/bin/env bash
cd "$(dirname "$0")"
ENV_FILE="$HOME/.jarvis/jarvis.env"
if [ -f "$ENV_FILE" ]; then   # faqat KEY=VALUE qatorlari o'qiladi (kod bajarilmaydi)
  while IFS='=' read -r k v; do
    case "$k" in ''|\#*) continue ;; esac
    case "$k" in *[!A-Za-z0-9_]*) continue ;; esac
    export "$k=$v"
  done < "$ENV_FILE"
fi
URL="http://localhost:5173"
( sleep 7
  if [ "$(uname -s)" = Darwin ]; then open -a "Google Chrome" "$URL" 2>/dev/null || open "$URL"
  else for b in google-chrome google-chrome-stable chromium chromium-browser; do command -v "$b" >/dev/null 2>&1 && exec "$b" "$URL"; done; xdg-open "$URL" 2>/dev/null; fi ) >/dev/null 2>&1 &
exec npm start
LAUNCHER
chmod +x "$LAUNCH"
if [ "$OS" = Darwin ]; then cp "$LAUNCH" "$DEST/Start-Jarvis.command" && chmod +x "$DEST/Start-Jarvis.command"; fi
ok "$LAUNCH"

echo
say "Preflight (npm run setup):"
( cd "$DEST" && npm run --silent setup ) || true

echo
printf '%s\n' "${G}${B}Tayyor!${N}"
cat <<EOF

  1) Claude Code login qilinganini tekshiring (bir marta):   claude
  2) Ishga tushirish:                                         bash "$LAUNCH"
     (macOS: Finder'da $DEST/Start-Jarvis.command ni ikki marta bosing)
  3) Chrome'da http://localhost:5173 oching, INITIALISE ni bosing, mikrofonga ruxsat bering va "Hey Jarvis" deng.

  Eslatma: Jarvis hozir faqat O'QISH rejimida (hech narsani yubormaydi/o'chirmaydi).
  Yangilash:  bash "$HERE/install.sh" --latest
EOF
