"use strict";
const $ = id => document.getElementById(id);
const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
const talkBtn = $("talkBtn"), heard = $("heard"), subtitle = $("subtitle");

const R = {  // жавоб матнлари
  "en-US": { hello:"Hello! How may I help you?", time:d=>`It is ${d.getHours()}:${String(d.getMinutes()).padStart(2,"0")}`,
    date:d=>`Today is ${d.toDateString()}`, opening:n=>`Opening ${n}`, search:q=>`Here is what I found for ${q}`,
    who:"I am Jarvis, your virtual assistant.", joke:["Why do programmers prefer dark mode? Because light attracts bugs."],
    calc:r=>`The answer is ${r}`, nosr:"Speech recognition is not supported in this browser. Use Chrome or Edge.", err:"Microphone error: " },
  "uz-UZ": { hello:"Салом! Сизга қандай ёрдам бера оламан?", time:d=>`Соат ${d.getHours()} ${String(d.getMinutes()).padStart(2,"0")}`,
    date:d=>`Бугун ${d.toLocaleDateString("uz-UZ")}`, opening:n=>`${n} очилмоқда`, search:q=>`${q} бўйича натижалар`,
    who:"Мен Жарвис, сизнинг виртуал ёрдамчингизман.", joke:["Дастурчи нега қоронғида ўтиради? Чунки у баг қидиради."],
    calc:r=>`Жавоб: ${r}`, nosr:"Бу браузер овозни таниб олмайди. Chrome ёки Edge ишлатинг.", err:"Микрофон хатоси: " },
  "ru-RU": { hello:"Привет! Чем могу помочь?", time:d=>`Сейчас ${d.getHours()}:${String(d.getMinutes()).padStart(2,"0")}`,
    date:d=>`Сегодня ${d.toLocaleDateString("ru-RU")}`, opening:n=>`Открываю ${n}`, search:q=>`Результаты по запросу ${q}`,
    who:"Я Джарвис, ваш виртуальный помощник.", joke:["Почему программист сидит в темноте? Он ищет баги, а не свет."],
    calc:r=>`Ответ: ${r}`, nosr:"Браузер не поддерживает распознавание речи. Используйте Chrome или Edge.", err:"Ошибка микрофона: " }
};
const fold = s => s.toLowerCase().replace(/[ўқғҳё]/g,c=>({"ў":"у","қ":"к","ғ":"г","ҳ":"х","ё":"е"})[c]).replace(/['’ʻʼ`‘]/g,"");
const has = (s,l) => l.some(w => s.includes(fold(w)));
const SITES = { youtube:["https://www.youtube.com",["youtube","ютуб"]], google:["https://www.google.com",["google","гугл"]],
  telegram:["https://web.telegram.org",["telegram","телеграм"]], instagram:["https://www.instagram.com",["instagram","инстаграм"]],
  gmail:["https://mail.google.com",["gmail","гмейл","джимейл"]], maps:["https://maps.google.com",["maps","карта","харита"]] };

function speak(text){
  $("talkBtn").dataset.last = text; subtitle.textContent = text;
  if(!("speechSynthesis" in window)) return;
  speechSynthesis.cancel();
  const u = new SpeechSynthesisUtterance(text), lang = $("lang").value;
  u.lang = lang; const v = speechSynthesis.getVoices().find(v=>v.lang.startsWith(lang.slice(0,2))) || speechSynthesis.getVoices().find(v=>v.lang.startsWith("ru"));
  if(v) u.voice = v; u.pitch = .9; speechSynthesis.speak(u);
}

function calc(s){
  const e = s.replace(/,/g,".").replace(/плюс|plus|кушув|куш|qosh/g,"+").replace(/минус|minus|айир/g,"-")
    .replace(/умножить на|times|multiplied by|купайтир|[x×х*]/g,"*").replace(/разделить на|divided by|бул|÷|\//g,"/").replace(/[^0-9+\-*/.() ]/g," ").trim();
  if(!/^\d/.test(e) || !/[+\-*/]/.test(e) || !/\d$/.test(e)) return null;
  try{ const r = Function('"use strict";return ('+e+')')(); return isFinite(r) ? Math.round(r*1e6)/1e6 : null; }catch{ return null; }
}

function handle(raw){
  const lang = $("lang").value, r = R[lang], d = new Date();
  const s = fold(raw).replace(/[.,!?]/g," ").replace(/\s+/g," ").trim().replace(/^(jarvis|жарвис|джарвис)\s*/,"");
  if(!s) return speak(r.hello);
  if(/^(hello|hi|hey|салом|привет|здравствуй|assalomu alaykum)/.test(s)) return speak(r.hello);
  if(has(s,["what time","soat necha","соат неча","который час","сколько времени","вакт неча"])) return speak(r.time(d));
  if(has(s,["what date","what day","today","сана","бугун кайси","какое число","какой сегодня"])) return speak(r.date(d));
  if(has(s,["who are you","кимсан","ты кто","кто ты","kimsan"])) return speak(r.who);
  if(has(s,["joke","хазил","шутк","анекдот","hazil"])) return speak(r.joke[0]);
  const m = s.match(/(?:search for|search|find|кидир|qidir|найди|поищи)\s+(.+)/);
  if(m){ window.open("https://www.google.com/search?q="+encodeURIComponent(m[1]),"_blank","noopener"); return speak(r.search(m[1])); }
  if(has(s,["open","оч ","оч","открой","ochib","och"])){
    for(const [name,[url,words]] of Object.entries(SITES)) if(has(s,words)){ window.open(url,"_blank","noopener"); return speak(r.opening(name)); }
  }
  const c = calc(s); if(c!==null) return speak(r.calc(c));
  window.open("https://www.google.com/search?q="+encodeURIComponent(raw),"_blank","noopener");
  speak(r.search(raw));
}

let rec = null;
function startRecognition(){
  const r = R[$("lang").value];
  if(!SR){ speak(r.nosr); return; }
  if(rec){ rec.stop(); return; }
  rec = new SR(); rec.lang = $("lang").value; rec.interimResults = true; rec.continuous = false;
  rec.onstart = () => { document.body.classList.add("listening"); talkBtn.lastChild.textContent = " Listening… (click to stop)"; };
  rec.onresult = e => { const res = e.results[e.results.length-1]; heard.textContent = res[0].transcript; if(res.isFinal) handle(res[0].transcript); };
  rec.onerror = e => { if(e.error!=="no-speech" && e.error!=="aborted") speak(r.err+e.error); };
  rec.onend = () => { rec = null; document.body.classList.remove("listening"); talkBtn.lastChild.textContent = " Click here to speak"; };
  rec.start();
}
window.startRecognition = startRecognition;
if("speechSynthesis" in window) speechSynthesis.onvoiceschanged = () => {};
