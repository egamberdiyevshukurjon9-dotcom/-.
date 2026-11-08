# JARVIS ornatgichi (Windows) -- github.com/adewaskar/jarvis
# Ishlatish:  powershell -ExecutionPolicy Bypass -File install.ps1 [-Dir C:\Jarvis] [-Latest] [-Yes] [-SkipClaude] [-SkipSkills] [-SkipAuditFix] [-Reconfigure]
param(
  [string]$Dir = (Join-Path $env:USERPROFILE "Jarvis"),
  [switch]$Latest, [switch]$Yes, [switch]$SkipClaude, [switch]$SkipSkills, [switch]$SkipAuditFix, [switch]$Reconfigure
)
# Native buyruqlar xatosini ($LASTEXITCODE) o'zimiz tekshiramiz
$ErrorActionPreference = "Continue"

$RepoUrl   = "https://github.com/adewaskar/jarvis.git"
$PinnedSha = "9ae5ec846b6b20a17b2d264e699d6234c4284b23"   # 2026-11-07 da sinalgan versiya
$ConfDir   = Join-Path $env:USERPROFILE ".jarvis"
$EnvFile   = Join-Path $ConfDir "jarvis.env"
$Here      = Split-Path -Parent $MyInvocation.MyCommand.Path
$Interactive = [Environment]::UserInteractive -and (-not $Yes)

function Say($m)  { Write-Host "==> $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "  ok  $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  !   $m" -ForegroundColor Yellow }
function Die($m)  { Write-Host "Xato: $m" -ForegroundColor Red; exit 1 }
function Has($n)  { return [bool](Get-Command $n -ErrorAction SilentlyContinue) }

function AskYN($q, $def) {
  if (-not $Interactive) { return ($def -eq "y") }
  $hint = "ha/Yoq"
  if ($def -eq "y") { $hint = "Ha/yoq" }
  $a = Read-Host "$q [$hint]"
  if ([string]::IsNullOrWhiteSpace($a)) { return ($def -eq "y") }
  $a = $a.Trim().ToLower()
  return ($a -eq "y" -or $a -eq "yes" -or $a -eq "h" -or $a -eq "ha")
}

# npm/git ni papkada ishga tushirib, chiqish kodini qaytaradi
function InDir($path, [scriptblock]$block) {
  Push-Location $path
  try { & $block | Out-Host; return $LASTEXITCODE } finally { Pop-Location }   # chiqish ekranga, funksiya faqat chiqish kodini qaytaradi
}

Write-Host ""
Say "JARVIS ornatgichi (Windows)"
Write-Host "    Papka: $Dir"
Write-Host ""

# 1) Talablar -------------------------------------------------------------
Say "1/7  Talablarni tekshirish"
if (-not (Has "git")) {
  if ((Has "winget") -and (AskYN "git topilmadi. winget bilan ornataymi?" "y")) {
    winget install -e --id Git.Git --accept-package-agreements --accept-source-agreements
    Die "git ornatildi. Terminalni yoping, qaytadan oching va ornatgichni yana ishga tushiring."
  }
  Die "git topilmadi. https://git-scm.com dan ornating, keyin qayta urinib koring."
}
if (-not (Has "node")) {
  if ((Has "winget") -and (AskYN "Node.js topilmadi. winget bilan ornataymi?" "y")) {
    winget install -e --id OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
    Die "Node.js ornatildi. Terminalni yoping, qaytadan oching va ornatgichni yana ishga tushiring."
  }
  Die "Node.js topilmadi. https://nodejs.org dan 20+ versiyani ornating."
}
if (-not (Has "npm")) { Die "npm topilmadi (Node.js bilan birga ornatiladi)." }
$nodeMajor = [int](& node -p "process.versions.node.split('.')[0]")
if ($nodeMajor -lt 20) { Die "Node.js $(& node --version) juda eski. 20 yoki yuqori kerak." }
Ok "git, node $(& node --version), npm $(& npm --version)"

# 2) Claude Code ----------------------------------------------------------
Say "2/7  Claude Code"
if (Has "claude") {
  Ok "claude topildi"
} elseif ($SkipClaude) {
  Warn "Claude Code otkazib yuborildi. Jarvis miyasi uchun u kerak."
} elseif (AskYN "Claude Code ornatilmagan. Hozir ornataymi (npm install -g @anthropic-ai/claude-code)?" "y") {
  & npm install -g "@anthropic-ai/claude-code"
  if ($LASTEXITCODE -eq 0) { Ok "Claude Code ornatildi." } else { Warn "Ornatilmadi. https://docs.claude.com/en/docs/claude-code dagi usuldan foydalaning." }
} else {
  Warn "Claude Code ornatilmadi. Keyinroq: npm install -g @anthropic-ai/claude-code"
}

# 3) Jarvis'ni olish ------------------------------------------------------
Say "3/7  Jarvis'ni GitHub'dan olish"
if (Test-Path (Join-Path $Dir ".git")) {
  $origin = (& git -C $Dir remote get-url origin) 2>$null
  if (($origin -ne $RepoUrl) -and ($origin -ne ($RepoUrl -replace "\.git$", ""))) { Die "$Dir boshqa repozitoriy. Boshqa papka tanlang: -Dir" }
  & git -C $Dir checkout --quiet -- package-lock.json 2>$null
  & git -C $Dir fetch --quiet origin
  Ok "mavjud nusxa yangilandi"
} elseif ((Test-Path $Dir) -and ((Get-ChildItem -Force $Dir | Measure-Object).Count -gt 0)) {
  Die "$Dir band (bosh emas). Boshqa papka tanlang: -Dir <yol>"
} else {
  & git clone --quiet $RepoUrl $Dir
  if ($LASTEXITCODE -ne 0) { Die "git clone muvaffaqiyatsiz. Internetni tekshiring." }
  Ok "klonlandi: $RepoUrl"
}
if ($Latest) {
  $def = ((& git -C $Dir symbolic-ref --short refs/remotes/origin/HEAD) 2>$null) -replace "^origin/", ""
  if ([string]::IsNullOrWhiteSpace($def)) { $def = "main" }
  & git -C $Dir checkout --quiet $def
  & git -C $Dir pull --quiet --ff-only origin $def
  Warn "eng yangi versiya ($def) olindi: bu versiya sinalmagan"
} else {
  & git -C $Dir checkout --quiet $PinnedSha 2>$null
  if ($LASTEXITCODE -ne 0) { Die "Sinalgan versiya ($PinnedSha) topilmadi. -Latest bilan urinib koring." }
  Ok "sinalgan versiya: $($PinnedSha.Substring(0,7))"
}

# 4) Bog'liqliklar --------------------------------------------------------
# onnxruntime-node (ixtiyoriy brauzer ovozi uchun) katta fayl yuklashga urinadi va yiqilishi mumkin: o'tkazib yuboramiz.
$env:npm_config_onnxruntime_node_install_cuda = "skip"
function NpmInstall {
  $c = InDir $Dir { & npm ci --no-fund --no-audit --loglevel=error }
  if ($c -eq 0) { return $true }
  Warn "npm ci yiqildi, qayta uriniladi..."
  $c = InDir $Dir { & npm ci --no-fund --no-audit --loglevel=error }
  if ($c -eq 0) { return $true }
  Warn "ornatish skriptlarisiz uriniladi (ixtiyoriy brauzer ovozi 'kokoro' ishlamasligi mumkin)"
  $c = InDir $Dir { & npm ci --ignore-scripts --no-fund --no-audit --loglevel=error }
  return ($c -eq 0)
}
Say "4/7  Bog'liqliklarni ornatish (npm ci), 1-2 daqiqa"
if (-not (NpmInstall)) { Die "npm ci muvaffaqiyatsiz. Internetni tekshiring va qayta ishga tushiring." }
Ok "ornatildi"
if (-not $SkipAuditFix) {
  Say "     Xavfsizlik yangilanishlari (npm audit fix) va sinov"
  $c = InDir $Dir { & npm test --silent *> $null }
  if ($c -eq 0) {
    InDir $Dir { & npm audit fix --no-fund --loglevel=error *> $null } | Out-Null
    $c = InDir $Dir { & npm test --silent *> $null }
    if ($c -eq 0) { Ok "yangilanishlar qollandi, testlar otdi" }
    else {
      Warn "yangilanishdan keyin testlar otmadi: asl holatga qaytarilmoqda"
      & git -C $Dir checkout --quiet -- package-lock.json
      if (-not (NpmInstall)) { Die "asl holatni tiklab bolmadi" }
    }
  } else {
    Warn "testlar yangilanishdan oldin ham otmadi: audit fix otkazib yuborildi"
  }
}

# 5) Sozlamalar -----------------------------------------------------------
Say "5/7  Sozlamalar"
if (-not (Test-Path $ConfDir)) { New-Item -ItemType Directory -Path $ConfDir | Out-Null }
if ((Test-Path $EnvFile) -and (-not $Reconfigure)) {
  Ok "mavjud sozlama saqlandi: $EnvFile  (ozgartirish: -Reconfigure)"
} else {
  $key = $env:ELEVENLABS_API_KEY
  if ([string]::IsNullOrWhiteSpace($key) -and $Interactive) {
    Write-Host "    ElevenLabs kaliti (ixtiyoriy): yaxshi ovoz uchun. Olish: https://elevenlabs.io/app/settings/api-keys"
    Write-Host "    Kalit ekranda korinmaydi. Otkazib yuborish uchun Enter bosing."
    $sec = Read-Host "    ELEVENLABS_API_KEY" -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    try { $key = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
  }
  if ($null -eq $key) { $key = "" }
  $key = ($key -replace "\s", "")
  $connect = AskYN "Gmail/Kalendar kabi claude.ai ulagichlarini Jarvisga ulaymi? (u ularni oqiy oladi)" "n"
  $lines = @("# Jarvis sozlamalari -- bu faylni hech kimga yubormang", "JARVIS_VOICE_ID=JBFqnCBsd6RMkjVDRZzb")
  if ($key.Length -gt 0) { $lines += "ELEVENLABS_API_KEY=$key" }
  if ($connect) { $lines += "JARVIS_ACCOUNT_CONNECTORS=1" }
  [IO.File]::WriteAllLines($EnvFile, $lines, (New-Object System.Text.UTF8Encoding($false)))
  & icacls $EnvFile /inheritance:r /grant:r "$($env:USERNAME):(R,W)" | Out-Null   # faqat siz o'qiy olasiz
  Ok "yozildi: $EnvFile (faqat siz oqiy olasiz)"
  if ($key.Length -gt 0) { Ok "ElevenLabs kaliti saqlandi" } else { Warn "ElevenLabs kaliti yoq: brauzer ovozi ishlatiladi (bu normal)" }
}

# 6) Skilllar -------------------------------------------------------------
Say "6/7  Claude Code skilllari"
$skillsSrc = Join-Path $Here "skills"
if ($SkipSkills -or (-not (Test-Path $skillsSrc))) {
  Warn "otkazib yuborildi"
} else {
  $skillsDst = Join-Path $env:USERPROFILE ".claude\skills"
  if (-not (Test-Path $skillsDst)) { New-Item -ItemType Directory -Path $skillsDst -Force | Out-Null }
  foreach ($d in Get-ChildItem -Directory $skillsSrc) {
    $target = Join-Path $skillsDst $d.Name
    if (Test-Path $target) { Warn "$($d.Name): allaqachon bor, tegilmadi" }
    else { Copy-Item -Recurse $d.FullName $target; Ok $d.Name }
  }
}

# 7) Ishga tushirgich -----------------------------------------------------
Say "7/7  Ishga tushirgich"
$bat = Join-Path $Dir "Start-Jarvis.bat"
$batText = @'
@echo off
cd /d "%~dp0"
set "ENVF=%USERPROFILE%\.jarvis\jarvis.env"
if exist "%ENVF%" for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%ENVF%") do set "%%a=%%b"
start "" /b powershell -NoProfile -WindowStyle Hidden -Command "Start-Sleep 8; Start-Process 'http://localhost:5173'"
npm start
pause
'@
[IO.File]::WriteAllText($bat, $batText, (New-Object System.Text.ASCIIEncoding))
Ok $bat
try {
  $ws = New-Object -ComObject WScript.Shell
  $lnk = $ws.CreateShortcut((Join-Path ([Environment]::GetFolderPath("Desktop")) "Jarvis.lnk"))
  $lnk.TargetPath = $bat
  $lnk.WorkingDirectory = $Dir
  $lnk.Save()
  Ok "Ish stolida 'Jarvis' yorlig'i yaratildi"
} catch { Warn "Ish stoli yorlig'ini yaratib bolmadi (muhim emas)" }

Write-Host ""
Say "Preflight (npm run setup):"
InDir $Dir { & npm run --silent setup } | Out-Null

Write-Host ""
Write-Host "Tayyor!" -ForegroundColor Green
Write-Host @"

  1) Claude Code login qilinganini tekshiring (bir marta):   claude
  2) Ishga tushirish:  ish stolidagi 'Jarvis' yorlig'i yoki  $bat
  3) Chrome'da http://localhost:5173 oching, INITIALISE ni bosing, mikrofonga ruxsat bering va "Hey Jarvis" deng.
     (Standart brauzeringiz Chrome yoki Edge bolishi kerak.)

  Eslatma: Jarvis hozir faqat OQISH rejimida (hech narsani yubormaydi/ochirmaydi).
  Yangilash:  powershell -ExecutionPolicy Bypass -File "$Here\install.ps1" -Latest
"@
