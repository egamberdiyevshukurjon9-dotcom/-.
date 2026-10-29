// Иловага иконка (PWA): қора фонда Жарвис ядроси.  node tools/make-icons.js
const { chromium } = require("playwright"), path = require("path");
(async () => {
  const b = await chromium.launch({ args: ["--use-gl=angle","--use-angle=swiftshader","--enable-unsafe-swiftshader","--ignore-gpu-blocklist"] });
  const p = await b.newPage({ viewport: { width: 512, height: 512 }, deviceScaleFactor: 1 });
  await p.addInitScript(() => { try { localStorage.clear(); localStorage.setItem("jv_skip","1"); } catch {} });
  await p.goto("file://" + path.resolve(__dirname, "../jarvis/index.html"));
  await p.addStyleTag({ content: "#fanExit{display:none!important}" });
  await p.evaluate(() => { __jarvis.setFanMode(true); __jarvis.Holo.setFan(true,12); __jarvis.Holo.manualStep(0); for (let i=0;i<70;i++) __jarvis.Holo.manualStep(1/30); });
  await p.evaluate(() => new Promise(r => requestAnimationFrame(() => r())));
  await p.screenshot({ path: path.resolve(__dirname, "../jarvis/icon-512.png") });
  await b.close();
})();
