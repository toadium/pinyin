#!/usr/bin/env node
// 覆盖率门禁：运行 moon coverage analyze，解析 full_summary，排除数据/示例包。
// 用法：node scripts/check_coverage.mjs [--min 92] [--from .tmp/coverage.txt]
import { spawnSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const args = process.argv.slice(2);
const minAt = args.indexOf("--min");
const min = minAt >= 0 ? Number(args[minAt + 1]) : 92;
const fromAt = args.indexOf("--from");
const PACKAGES = [
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
];
const EXCLUDED = new Set(["data", "examples", "docs", "scripts"]);

function loadOutput() {
  if (fromAt >= 0) {
    return readFileSync(resolve(root, args[fromAt + 1]), "utf8");
  }
  const run = spawnSync(
    "moon",
    ["coverage", "analyze", "--", "-f", "summary"],
    { cwd: root, encoding: "utf8", shell: process.platform === "win32" },
  );
  const output = `${run.stdout ?? ""}\n${run.stderr ?? ""}`;
  if (run.status !== 0) {
    console.error("coverage command failed");
    console.error(output.split("\n").slice(-20).join("\n"));
    process.exit(1);
  }
  return output;
}

function packageOf(file) {
  const parts = file.replace(/\\/g, "/").split("/");
  for (const part of parts) {
    if (PACKAGES.includes(part)) return part;
  }
  return null;
}

const output = loadOutput();
const rows = [];
const pattern = /^\s*(.+?\.mbt):\s*(\d+)\/(\d+)\s*$/gm;
for (const match of output.matchAll(pattern)) {
  const file = match[1].replace(/\\/g, "/");
  const parts = file.split("/");
  if (parts.some((part) => EXCLUDED.has(part))) continue;
  const pkg = packageOf(file);
  if (!pkg) continue;
  rows.push({
    file,
    pkg,
    covered: Number(match[2]),
    total: Number(match[3]),
  });
}

if (rows.length === 0) {
  console.error("no coverage rows parsed");
  process.exit(1);
}

const byPackage = new Map();
for (const row of rows) {
  const item = byPackage.get(row.pkg) ?? { covered: 0, total: 0, files: 0 };
  item.covered += row.covered;
  item.total += row.total;
  item.files += 1;
  byPackage.set(row.pkg, item);
}

let totalCovered = 0;
let totalLines = 0;
const failures = [];
console.log("package        covered/total    ratio   gate");
for (const pkg of PACKAGES) {
  const item = byPackage.get(pkg);
  if (!item) continue;
  const ratio = (item.covered / item.total) * 100;
  totalCovered += item.covered;
  totalLines += item.total;
  const pass = ratio >= 85;
  if (!pass) failures.push(`${pkg}: ${ratio.toFixed(1)}% < 85%`);
  console.log(
    `${pkg.padEnd(14)} ${String(item.covered).padStart(4)}/${String(item.total).padEnd(4)}   ${ratio.toFixed(1).padStart(5)}%   ${pass ? "PASS" : "FAIL"}`,
  );
}

const totalRatio = (totalCovered / totalLines) * 100;
console.log("-".repeat(48));
console.log(
  `total          ${String(totalCovered).padStart(4)}/${String(totalLines).padEnd(4)}   ${totalRatio.toFixed(1).padStart(5)}%   ${totalRatio >= min ? "PASS" : "FAIL"} (min ${min}%)`,
);

if (totalRatio < min) failures.push(`total: ${totalRatio.toFixed(1)}% < ${min}%`);
if (failures.length > 0) {
  console.error("\ncoverage gate failed:");
  for (const item of failures) console.error(`  - ${item}`);
  process.exit(1);
}
console.log("\ncoverage gate passed");