#!/usr/bin/env node
// 多音字覆盖审计：字典层完整性 + 常用字词组覆盖 + 词条读音一致性。
//
// 三层口径：
// 1) 字典层：pinyin_dict 中所有多音字（>=2 读音）必须保留全部读音；
// 2) 常用字层：data/common_chars 中的多音字必须有至少一个词组上下文（100%）；
// 3) 全量层：统计全部多音字的词组上下文覆盖率（记录，不强制 100%，生僻字回退字级）。
//
// 退出码：常用字层或一致率不达标 => 1。

import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const MAP_RE = /"([^"]+)":\s*"([^"]+)"/g;
const STR_RE = /"((?:[^"\\]|\\.)*)"/g;

function parseMap(file) {
  const text = readFileSync(join(ROOT, file), "utf8");
  const result = new Map();
  for (const match of text.matchAll(MAP_RE)) result.set(match[1], match[2]);
  return result;
}

function unescape(text) {
  return text.replace(/\\n/g, "\n").replace(/\\t/g, "\t").replace(/\\"/g, '"');
}

function parseRawShard(file) {
  const text = readFileSync(join(ROOT, file), "utf8");
  return [...text.matchAll(STR_RE)].map((m) => unescape(m[1])).join("");
}

const pinyin = parseMap("data/pinyin_dict.mbt");
const poly = new Map(
  [...pinyin]
    .filter(([, value]) => value.includes(","))
    .map(([char, value]) => [char, value.split(",").filter(Boolean)]),
);

const phrases = new Map([
  ...parseMap("data/mutil_pinyin_dict.mbt"),
  ...parseMap("data/common_phrases.mbt"),
]);
for (let i = 1; i <= 6; i++) {
  const raw = parseRawShard(`data/large_phrase_raw_0${i}.mbt`);
  for (const line of raw.split("\n")) {
    const tab = line.indexOf("\t");
    if (tab <= 0) continue;
    const word = line.slice(0, tab);
    const readings = line.slice(tab + 1);
    if (word && readings) phrases.set(word, readings);
  }
}

const covered = new Set();
let positions = 0;
let consistent = 0;
for (const [word, readingsText] of phrases) {
  const readings = readingsText.split(",").filter(Boolean);
  const chars = [...word];
  if (readings.length !== chars.length) continue;
  chars.forEach((char, index) => {
    covered.add(char);
    if (!poly.has(char)) return;
    positions += 1;
    if (poly.get(char).includes(readings[index])) consistent += 1;
  });
}

const polyReadings = [...poly.values()].reduce((sum, list) => sum + list.length, 0);
const commonChars = new Set([...parseRawShard("data/common_chars.mbt")]);
const commonPoly = [...poly.keys()].filter((char) => commonChars.has(char));
const commonMissing = commonPoly.filter((char) => !covered.has(char));
const totalCovered = [...poly.keys()].filter((char) => covered.has(char));

const ratio = (value, total) => (total === 0 ? 0 : value / total);
const consistency = ratio(consistent, positions);
const format = (value) => `${(value * 100).toFixed(2)}%`;

console.log(`多音字: ${poly.size}（读音 ${polyReadings}）`);
console.log(
  `常用字多音字: ${commonPoly.length}，词组覆盖 ${commonPoly.length - commonMissing.length}（${format(
    1 - ratio(commonMissing.length, commonPoly.length),
  )}）`,
);
console.log(
  `全量词组覆盖: ${totalCovered.length}/${poly.size}（${format(
    ratio(totalCovered.length, poly.size),
  )}）`,
);
console.log(`词条读音一致: ${consistent}/${positions}（${format(consistency)}）`);
if (commonMissing.length > 0) {
  console.log(`常用字缺口: ${commonMissing.slice(0, 40).join("")}`);
}

const failures = [];
if (poly.size < 3000) failures.push(`多音字数量异常偏低: ${poly.size}`);
if (commonMissing.length > 0) failures.push(`常用字缺口 ${commonMissing.length}`);
if (consistency < 0.998) failures.push(`词条读音一致率 ${format(consistency)} < 99.8%`);

if (failures.length > 0) {
  console.log(`\n=== polyphone check: FAIL (${failures.length}) ===`);
  for (const failure of failures) console.log(`FAIL  ${failure}`);
  process.exit(1);
}
console.log("\n=== polyphone check: PASS ===");