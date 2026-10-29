// Жарвис ҳолограмма видеоларини ясайди (3D вентилятор учун: қора фон, марказда ядро).
// Ишлатиш:  node tools/render-fan.js <чиқиш-папкаси>   (playwright ва ffmpeg керак)
const { chromium } = require("playwright");
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const OUT = path.resolve(process.argv[2] || "fan");
const FFMPEG = process.env.FFMPEG || "ffmpeg";
const FPS = 30, SIZE = 600;
const PAGE = "file://" + path.resolve(__dirname, "../jarvis/index.html");

// Узлуксиз қайтариладиган ядро (12 сония) — ҳар ранг учун
const LOOP = c => ({ name: `jarvis-core-${c}`, loop: true, segments: [{ shape: "core", color: c, seconds: 12 }] });
const SHOW = { name: "jarvis-showcase", loop: false, segments: [
  ["core","cyan"],["globe","cyan"],["heart","red"],["dna","green"],["atom","purple"],["galaxy","white"],["saturn","gold"],["cube","cyan"],["pyramid","gold"],["torus","green"],["core","cyan"]
].map(([shape,color]) => ({ shape, color, seconds: 5 })) };
const JOBS = (process.env.JOBS ? process.env.JOBS.split(",") : ["cyan","gold","red","show"]).map(j => j === "show" ? SHOW : LOOP(j));

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const browser = await chromium.launch({ args: ["--use-gl=angle","--use-angle=swiftshader","--enable-unsafe-swiftshader","--ignore-gpu-blocklist"] });
  const page = await browser.newPage({ viewport: { width: SIZE, height: SIZE }, deviceScaleFactor: 1 });
  await page.addInitScript(() => { try { localStorage.clear(); localStorage.setItem("jv_skip","1"); } catch {} });
  await page.goto(PAGE); await page.addStyleTag({ content: "#fanExit{display:none!important}" }); await page.waitForTimeout(500);
  await page.evaluate(() => { __jarvis.setFanMode(true); __jarvis.Holo.setFan(true,12); __jarvis.Holo.manualStep(0); });
  for (const job of JOBS) {
    const dir = fs.mkdtempSync(path.join(OUT, `.frames-${job.name}-`));
    let n = 0;
    await page.evaluate(() => __jarvis.Holo.resetTime());
    for (const [si, seg] of job.segments.entries()) {
      await page.evaluate(({shape,color}) => { __jarvis.Holo.setColor(color); __jarvis.Holo.setShape(shape); }, seg);
      if (job.loop) for (let i = 0; i < FPS*12; i++) await page.evaluate(dt => __jarvis.Holo.manualStep(dt), 1/FPS); // тиниқлашиш (даврни тўлдиради)
      for (let i = 0; i < FPS*seg.seconds; i++) {
        await page.evaluate(dt => __jarvis.Holo.manualStep(dt), 1/FPS);
        await page.evaluate(() => new Promise(r => requestAnimationFrame(() => r())));
        await page.screenshot({ path: path.join(dir, String(n++).padStart(5,"0") + ".jpg"), type: "jpeg", quality: 92 });
      }
      console.log(job.name, "segment", si+1, "/", job.segments.length, "frames", n);
    }
    execFileSync(FFMPEG, ["-y","-loglevel","error","-framerate",String(FPS),"-i",path.join(dir,"%05d.jpg"),"-c:v","libx264","-preset","slow","-crf","30","-pix_fmt","yuv420p","-movflags","+faststart",path.join(OUT, job.name + ".mp4")]);
    fs.rmSync(dir, { recursive: true, force: true });
    console.log("OK", job.name + ".mp4");
  }
  await browser.close();
})();
