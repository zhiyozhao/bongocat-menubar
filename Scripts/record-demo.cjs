#!/usr/bin/env node
// record-demo.cjs: records the README GIFs from the website demo (site/), so the
// README shows exactly what the website shows.
//
// Output: docs/assets/demo-{zh,en}-{light,dark}.gif (2x, 720pt wide)
// Needs: Playwright with Chrome, and ffmpeg.
//   PLAYWRIGHT=/path/to/node_modules/playwright node Scripts/record-demo.cjs   (or: make demo)
//
// It drives the page frame by frame instead of capturing real time: each key
// event from STROKES is sent, the demo is screenshotted, and the gap to the next
// event becomes that frame's duration. STROKES matches the autoplay in site/demo.js.

const http = require("http");
const fs = require("fs");
const path = require("path");
const os = require("os");
const { execFileSync } = require("child_process");
const { chromium } = require(process.env.PLAYWRIGHT || "playwright");

const root = path.resolve(__dirname, "..");
const site = path.join(root, "site");
const out = path.join(root, "docs/assets");

const STROKES = [["b", 0.8, 1.15], ["o", 1.35, 1.65], ["n", 1.85, 2.1], ["g", 2.3, 2.95], ["o", 2.5, 2.95],
  ["Space", 3.15, 3.35], ["c", 3.5, 3.75], ["a", 3.9, 4.15], ["t", 4.3, 4.6]];
const LOOP = 6.2;

const types = { ".html": "text/html", ".css": "text/css", ".js": "text/javascript", ".svg": "image/svg+xml", ".png": "image/png" };
const server = http.createServer((req, res) => {
  let file = path.join(site, decodeURIComponent(req.url.split("?")[0]));
  if (file.endsWith("/")) file += "index.html";
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { "Content-Type": types[path.extname(file)] || "application/octet-stream" });
    res.end(data);
  });
});

(async () => {
  await new Promise((r) => server.listen(0, "127.0.0.1", r));
  const base = `http://127.0.0.1:${server.address().port}`;
  const events = STROKES.flatMap(([key, down, up]) => [[down, "down", key], [up, "up", key]]);
  const times = [...new Set([0, ...events.map((e) => e[0]), LOOP])].sort((a, b) => a - b);

  const browser = await chromium.launch({ channel: "chrome" });
  for (const lang of ["zh", "en"]) for (const scheme of ["light", "dark"]) {
    const ctx = await browser.newContext({ viewport: { width: 900, height: 800 }, deviceScaleFactor: 2, colorScheme: scheme, reducedMotion: "reduce" });
    const page = await ctx.newPage();
    await page.addInitScript(() => { Date.prototype.toLocaleTimeString = () => "9:41"; });
    await page.goto(base + (lang === "en" ? "/en/" : "/"), { waitUntil: "networkidle" });
    // The GIF is not interactive, so drop the "try typing" hint and center the mode switch.
    await page.addStyleTag({ content: ".demo { width: 720px !important; } .hint { display: none; } .demo-foot { justify-content: center; }" });
    await page.evaluate(() => document.fonts.ready);
    const demo = page.locator(".demo");
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), "bongo-demo-"));
    const list = [];
    for (let i = 0; i < times.length - 1; i++) {
      for (const [t, kind, key] of events) if (t === times[i]) await (kind === "down" ? page.keyboard.down(key) : page.keyboard.up(key));
      const png = path.join(dir, `f${String(i).padStart(3, "0")}.png`);
      await demo.screenshot({ path: png });
      list.push(`file '${png}'`, `duration ${(times[i + 1] - times[i]).toFixed(3)}`);
    }
    list.push(list[list.length - 2]); // concat demuxer needs the last file repeated
    fs.writeFileSync(path.join(dir, "list.txt"), list.join("\n") + "\n");
    const gif = path.join(out, `demo-${lang}-${scheme}.gif`);
    execFileSync("ffmpeg", ["-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", path.join(dir, "list.txt"),
      "-filter_complex", "[0:v]split[a][b];[a]palettegen=max_colors=64:stats_mode=full[p];[b][p]paletteuse=dither=none",
      "-fps_mode", "vfr", "-loop", "0", gif]);
    fs.rmSync(dir, { recursive: true, force: true });
    console.log(`wrote ${path.relative(root, gif)} (${Math.round(fs.statSync(gif).size / 1024)} KB)`);
    await ctx.close();
  }
  await browser.close();
  server.close();
})();
