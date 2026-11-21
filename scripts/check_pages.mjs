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
function check(name, ok, detail) {
  console.log(`${ok ? "PASS" : "FAIL"}  ${name}${detail ? `  (${detail})` : ""}`);
  if (!ok) failures += 1;
}

for (const file of ["docs/index.html", "docs/app.js", "docs/style.css"]) {
  check(`asset exists: ${file}`, existsSync(join(root, file)));
}

const html = readFileSync(join(root, "docs/index.html"), "utf8");
check("index.html mentions pinyin + 输入法", html.includes("pinyin") && html.includes("输入法"));
check("index.html loads app.js / style.css", html.includes("app.js") && html.includes("style.css"));
check("index.html loads playground.js via app.js", readFileSync(join(root, "docs/app.js"), "utf8").includes("./playground.js"));

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

console.log(`\n=== pages check: ${failures === 0 ? "PASS" : `FAIL (${failures})`} ===`);
if (failures > 0) process.exit(1);