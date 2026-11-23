#!/usr/bin/env node
// 展示页自检：静态资源 + JS 导出 + 拼音语义。
// Pages self-check for pinyin.
import { copyFileSync, existsSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const jsBuild = join(root, "_build/js/release/build/playground/playground.js");
const jsDocs = join(root, "docs/playground.js");

let failures = 0;
let checks = 0;
function check(name, ok, detail) {
  checks += 1;
  console.log(`${ok ? "PASS" : "FAIL"}  ${name}${detail ? `  (${detail})` : ""}`);
  if (!ok) failures += 1;
}

for (const file of ["docs/index.html", "docs/app.js", "docs/style.css"]) {
  check(`asset exists: ${file}`, existsSync(join(root, file)));
}

const html = readFileSync(join(root, "docs/index.html"), "utf8");
const appJs = readFileSync(join(root, "docs/app.js"), "utf8");
check("index.html mentions pinyin + 输入法", html.includes("pinyin") && html.includes("输入法"));
check("index.html loads app.js / style.css", html.includes("app.js") && html.includes("style.css"));
check("index.html loads playground.js via app.js", appJs.includes("./playground.js"));

// --- 展示页结构（Chart.js / Leaflet 式库首页） ---
const sections = ["features", "demo", "start", "api", "quality", "docs"];
check(
  "index.html 分区锚点齐全",
  sections.every((id) => html.includes(`id="${id}"`) && html.includes(`href="#${id}"`)),
  sections.join(", "),
);
for (const id of ["hero-text", "hero-mark", "hero-number", "hero-initial", "hero-time"]) {
  check(`hero 实时演示钩子: ${id}`, html.includes(`id="${id}"`));
}
check(
  "app.js Hero 用消歧结果实时渲染",
  appJs.includes("pinyin_disambiguate") &&
    appJs.includes("#hero-mark") &&
    appJs.includes("toToneNumber") &&
    appJs.includes("#hero-time"),
);
for (const action of ["convert", "input", "shuangpin", "disambiguate", "segment", "normalize"]) {
  check(`演示动作钩子: data-run=${action}`, html.includes(`data-run="${action}"`));
}
check(
  "演示预置按钮保留",
  ["zhongguo", "zg", "shurufa"].every((p) => html.includes(`data-preset="${p}"`)) &&
    ["xiaohe", "ziranma"].every((p) => html.includes(`data-preset-sp="${p}"`)),
);

const htmlIds = new Set([...html.matchAll(/id="([^"]+)"/g)].map((m) => m[1]));
const copyTargets = [...html.matchAll(/data-copy-target="([^"]+)"/g)].map((m) => m[1]);
check(
  "复制按钮指向存在的元素",
  copyTargets.length >= 5 && copyTargets.every((target) => htmlIds.has(target)),
  copyTargets.join(", "),
);
check(
  "主题切换 + 本地持久化",
  html.includes('id="theme-toggle"') && appJs.includes("pinyin-theme") && appJs.includes("localStorage"),
);
check(
  "无外链 CDN 静态资源",
  !/https?:\/\/[^"']+\.(css|js)(\?|")/.test(html),
  "页面应只引用本地 style.css / app.js",
);
check(
  "文档入口链接齐全",
  ["docs/api.md", "docs/architecture.md", "docs/roadmap.md", "docs/testing.md"].every((file) =>
    html.includes(file),
  ),
);

const modulePackages = [
  "core",
  "convert",
  "reverse",
  "segment",
  "fuzzy",
  "disambiguate",
  "search",
  "tone",
  "normalize",
  "lm",
  "input",
  "shuangpin",
  "data",
  "playground",
];
const moduleLinks = [...html.matchAll(/blob\/main\/([a-z]+)\/README\.md/g)].map(
  (match) => match[1],
);
check(
  "模块卡 / API 表 / 演示卡链接到包级 README",
  moduleLinks.length >= 25 && moduleLinks.every((pkg) => modulePackages.includes(pkg)),
  `${moduleLinks.length} 个链接`,
);
check(
  "11 个功能包均有 README 入口",
  [
    "convert",
    "reverse",
    "disambiguate",
    "segment",
    "fuzzy",
    "search",
    "tone",
    "normalize",
    "lm",
    "input",
    "shuangpin",
  ].every((pkg) => html.includes(`/${pkg}/README.md`)),
);
check(
  "14 个包 README 存在",
  modulePackages.every((pkg) => existsSync(join(root, pkg, "README.md"))),
);
check(
  "特性卡为整卡链接（12 个）",
  (html.match(/<a class="feature" /g) || []).length === 12,
  `${(html.match(/<a class="feature" /g) || []).length} 个`,
);
check(
  "导航高亮脚本存在",
  appJs.includes("IntersectionObserver") && appJs.includes('classList.toggle("active"'),
);

const modVersion = readFileSync(join(root, "moon.mod"), "utf8").match(/version\s*=\s*"([^"]+)"/)?.[1] ?? "";
check("页面版本徽章 = moon.mod", html.includes(`id="version">${modVersion}`), `moon.mod=${modVersion}`);

const testing = readFileSync(join(root, "docs/testing.md"), "utf8");
const perBackend = testing.match(/\*\*(\d+) \/ 后端\*\*/)?.[1] ?? "";
const totalTests = testing.match(/\*\*(\d+)（四后端）\*\*/)?.[1] ?? "";
const coverage = testing.match(/\*\*\d+\/\d+ = ([\d.]+%)\*\*/)?.[1] ?? "";
check("页面每后端测试数 = docs/testing", perBackend.length > 0 && html.includes(`${perBackend} × 4`));
check("页面四后端合计 = docs/testing", totalTests.length > 0 && html.includes(totalTests));
check("页面覆盖率 = docs/testing", coverage.length > 0 && html.includes(coverage));

const build = spawnSync("moon", ["build", "--target", "js", "--release", "playground"], {
  cwd: root,
  encoding: "utf8",
  shell: process.platform === "win32",
  timeout: 600000,
});
check("build playground js", build.status === 0, (build.stderr ?? "").slice(0, 300));
if (build.status !== 0) process.exit(1);
check("playground.js build exists", existsSync(jsBuild));
if (!existsSync(jsBuild)) process.exit(1);

copyFileSync(jsBuild, jsDocs);
check("docs/playground.js exists", existsSync(jsDocs));

const mod = await import("file://" + jsDocs.replace(/\\/g, "/"));
for (const name of [
  "pinyin_version",
  "pinyin_convert",
  "pinyin_disambiguate",
  "pinyin_input",
  "pinyin_shuangpin",
  "pinyin_segment",
  "pinyin_normalize",
]) {
  check(`export: ${name}`, typeof mod[name] === "function");
}

check("version non-empty", typeof mod.pinyin_version() === "string" && mod.pinyin_version().length > 0);
check(
  "convert 中国 contains zhōng",
  mod.pinyin_convert("中国", " ", "mark").includes("zhōng"),
);
check(
  "convert number format",
  mod.pinyin_convert("中国", " ", "number").includes("zhong1"),
);
check("convert empty folds to empty", mod.pinyin_convert("", " ", "mark") === "");
check("disambiguate 银行 = yín háng", mod.pinyin_disambiguate("银行") === "yín háng");
check("disambiguate 重庆 = chóng qìng", mod.pinyin_disambiguate("重庆") === "chóng qìng");
check("input nihao starts with 你好", mod.pinyin_input("nihao").split("|")[0] === "你好");
check("input zg contains 中国", mod.pinyin_input("zg").split("|").includes("中国"));
check("input shurufa starts with 输入法", mod.pinyin_input("shurufa").split("|")[0] === "输入法");
check("input empty folds to empty", mod.pinyin_input("") === "");
check("shuangpin nihc = ni hao", mod.pinyin_shuangpin("xiaohe", "nihc") === "ni hao");
check("shuangpin nihk = ni hao", mod.pinyin_shuangpin("ziranma", "nihk") === "ni hao");
check("shuangpin odd input unchanged", mod.pinyin_shuangpin("xiaohe", "abc") === "abc");
check("segment xian non-empty", mod.pinyin_segment("xian").length > 0);
check("segment invalid folds to empty", mod.pinyin_segment("") === "");
check("normalize ZHONG1 = zhōng", mod.pinyin_normalize("ZHONG1") === "zhōng");
check("normalize nv = nü", mod.pinyin_normalize("nv") === "nü");

console.log(`\n=== pages check: ${failures === 0 ? "PASS" : `FAIL (${failures})`} · ${checks} checks ===`);
if (failures > 0) process.exit(1);