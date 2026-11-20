#!/usr/bin/env node
// 文档一致性门禁：版本、测试数、包数、工具链、门禁引用、链接、API 覆盖面。
import { existsSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const read = (file) => readFileSync(resolve(root, file), "utf8");
const failures = [];
const passes = [];

function check(name, condition, detail) {
  if (condition) {
    passes.push(name);
  } else {
    failures.push(`${name}: ${detail}`);
  }
}

const version = read("moon.mod").match(/version\s*=\s*"([^"]+)"/)?.[1] ?? "";
const changelog = read("CHANGELOG.md");
const versions = [...changelog.matchAll(/^#### V([\d.]+)/gm)].map((m) => m[1]);
check(
  "A1 moon.mod 版本 = CHANGELOG 最新版本",
  versions[0] === version,
  `moon.mod=${version}, changelog=${versions[0]}`,
);

const ordered = versions.every((item, index) => {
  if (index === 0) return true;
  const prev = versions[index - 1].split(".").map(Number);
  const curr = item.split(".").map(Number);
  for (let i = 0; i < Math.max(prev.length, curr.length); i += 1) {
    const a = prev[i] ?? 0;
    const b = curr[i] ?? 0;
    if (a !== b) return a > b;
  }
  return false;
});
check("A2 CHANGELOG 版本降序", ordered, versions.join(" > "));

const readme = read("README.md");
const readmeMbt = read("README.mbt.md");
const agents = read("AGENTS.md");
const testing = read("docs/testing.md");
const roadmap = read("docs/roadmap.md");
const proposal = read("hackathon2026_pinyin_proposal.md");
const api = read("docs/api.md");

const badgeTests = Number(readme.match(/badge\/tests-(\d+)/)?.[1] ?? 0);
const badgePackages = Number(readme.match(/badge\/packages-(\d+)/)?.[1] ?? 0);
const perBackend = Number(testing.match(/\*\*(\d+) \/ 后端\*\*/)?.[1] ?? 0);
check(
  "A3 README 测试数 = 4 × 每后端测试数",
  badgeTests === perBackend * 4 && badgeTests > 0,
  `README=${badgeTests}, docs/testing=${perBackend}/后端`,
);

const packages = [
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
const dataPackage = existsSync(resolve(root, "data"));
check(
  "A4 README 包数 = 功能包数",
  badgePackages === packages.length + (dataPackage ? 1 : 0),
  `README=${badgePackages}, 实际=${packages.length + (dataPackage ? 1 : 0)}`,
);

check(
  "A5 AGENTS 版本 = moon.mod 版本",
  agents.includes(`版本 ${version}`),
  `AGENTS 未写版本 ${version}`,
);

const moonVersion = readme.match(/badge\/moon-([\d.]+)/)?.[1] ?? "";
check(
  "A6 README / README.mbt / AGENTS 工具链版本一致",
  moonVersion.length > 0 &&
    readmeMbt.includes(moonVersion) &&
    agents.includes(moonVersion),
  `README=${moonVersion}, README.mbt=${readmeMbt.includes(moonVersion)}, AGENTS=${agents.includes(moonVersion)}`,
);

check(
  "A7 README 与 README.mbt 测试数一致",
  readmeMbt.includes(`${perBackend} 测试`) || readmeMbt.includes(`${badgeTests}`),
  `README=${badgeTests}, README.mbt 未写 ${perBackend}/${badgeTests}`,
);

check(
  "A8 roadmap 含当前版本",
  roadmap.includes(`版本 ${version}`),
  `roadmap 未写版本 ${version}`,
);

check(
  "A9 申报书测试数与 README 一致",
  proposal.includes(`${badgeTests} 测试`) || proposal.includes(`**${badgeTests}**`),
  `申报书未写 ${badgeTests}`,
);

const ci = read(".github/workflows/ci.yml");
const mutation = read(".github/workflows/mutation.yml");
check(
  "A10 CI 引用覆盖率与文档门禁",
  ci.includes("check_coverage.mjs") && ci.includes("check_docs.mjs"),
  "ci.yml 缺少 check_coverage.mjs / check_docs.mjs",
);
check(
  "A11 变异 workflow 引用变异门禁",
  mutation.includes("mutation_test.mjs"),
  "mutation.yml 缺少 mutation_test.mjs",
);

check(
  "A12 API 文档覆盖新增接口",
  ["InputScoringConfig", "add_fuzzy_rules", "common_char_rank"].every((item) =>
    api.includes(item),
  ),
  "docs/api.md 缺少新增接口",
);

function checkLinks(file, text) {
  const linkPattern = /\[[^\]]+\]\(([^)]+)\)/g;
  for (const match of text.matchAll(linkPattern)) {
    const target = match[1];
    if (
      target.startsWith("http://") ||
      target.startsWith("https://") ||
      target.startsWith("#") ||
      target.startsWith("mailto:")
    ) {
      continue;
    }
    const path = target.split("#")[0];
    if (path.length === 0) continue;
    const base = target.startsWith("/") ? root : resolve(root, dirname(file));
    const full = resolve(base, path);
    check(`A13 链接存在 ${file} -> ${target}`, existsSync(full), "文件不存在");
  }
}
checkLinks("README.md", readme);
checkLinks("README.mbt.md", readmeMbt);

console.log(`passed ${passes.length}, failed ${failures.length}`);
if (failures.length > 0) {
  console.error("docs consistency failed:");
  for (const item of failures) console.error(`  - ${item}`);
  process.exit(1);
}
console.log("docs consistency passed");