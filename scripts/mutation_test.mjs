#!/usr/bin/env node
// 变异测试门禁：对核心源码做单点变异，要求相关包测试必须失败（KILLED）。
// 用法：node scripts/mutation_test.mjs [--filter M01,M02]
import { spawnSync } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const args = process.argv.slice(2);
const filterAt = args.indexOf("--filter");
const filter = filterAt >= 0 ? new Set(args[filterAt + 1].split(",")) : null;

const MUTATIONS = [
  {
    id: "M01",
    name: "core.strip_tone 不再处理 ü",
    file: "core/tone_conversion.mbt",
    find: `pub fn strip_tone(pinyin : String) -> String {
  let mut s = pinyin
  for i in 0..<all_marked_vowel_array.length() {
    let original_char = all_marked_vowel_array[i]
    let replace_char = all_unmarked_vowel_array[(i - i % 4) / 4]`,
    replace: `pub fn strip_tone(pinyin : String) -> String {
  let mut s = pinyin
  for i in 0..<all_marked_vowel_array.length() {
    let original_char = all_marked_vowel_array[i]
    let replace_char = all_unmarked_vowel_array[0]`,
    pkg: "core",
  },
  {
    id: "M02",
    name: "core.set_tone 允许非法 tone 0",
    file: "core/tone_conversion.mbt",
    find: "if tone < 1 || tone > 4 {",
    replace: "if tone < 0 || tone > 4 {",
    pkg: "core",
  },
  {
    id: "M03",
    name: "convert 移除非汉字后的分隔符",
    file: "convert/pinyin_helper.mbt",
    find: "if i + 1 < str_len && ChineseHelper::is_chinese(char_array[i + 1]) {",
    replace: "if false {",
    pkg: "convert",
  },
  {
    id: "M04",
    name: "reverse 空拼音不再抛错",
    file: "reverse/pinyin_reverse.mbt",
    find: `pub fn ReversePinyinHelper::reverse_lookup(
  pinyin : String,
) -> Array[String] raise @core.PinyinError {
  if pinyin.length() == 0 {`,
    replace: `pub fn ReversePinyinHelper::reverse_lookup(
  pinyin : String,
) -> Array[String] raise @core.PinyinError {
  if false {`,
    pkg: "reverse",
  },
  {
    id: "M05",
    name: "segment 最优切分反向比较",
    file: "segment/pinyin_segmenter.mbt",
    find: "if dp_count[i] < 0 || candidate < dp_count[i] {",
    replace: "if dp_count[i] < 0 || candidate > dp_count[i] {",
    pkg: "segment",
  },
  {
    id: "M06",
    name: "fuzzy 扩展不加入变体",
    file: "fuzzy/pinyin_fuzzy.mbt",
    find:
      "if !seen.contains(v) && @core.pinyin_trie.contains(v) {",
    replace: "if false {",
    pkg: "fuzzy",
  },
  {
    id: "M07",
    name: "tone 三声变调条件失效",
    file: "tone/pinyin_tone_sandhi.mbt",
    find: "if tone_i == 3 && tone_next == 3 {",
    replace: "if tone_i == 3 && tone_next == 2 {",
    pkg: "tone",
  },
  {
    id: "M08",
    name: "normalize 带调元音声调识别错误",
    file: "normalize/pinyin_normalizer.mbt",
    find: "tone = idx % 4 + 1",
    replace: "tone = 1",
    pkg: "normalize",
  },
  {
    id: "M09",
    name: "lm 空句子对数概率返回值错误",
    file: "lm/pinyin_lm.mbt",
    find: `pub fn PinyinLM::sentence_log_prob(pinyin_array : Array[String]) -> Double {
  if pinyin_array.length() == 0 {
    return 0.0
  }`,
    replace: `pub fn PinyinLM::sentence_log_prob(pinyin_array : Array[String]) -> Double {
  if pinyin_array.length() == 0 {
    return -1.0
  }`,
    pkg: "lm",
  },
  {
    id: "M10",
    name: "input 常用字排序失效",
    file: "data/common_chars.mbt",
    find: "Some(offset) => offset",
    replace: "Some(_) => 100000",
    pkg: "input",
  },
  {
    id: "M11",
    name: "search 空文档不再抛错",
    file: "search/pinyin_search.mbt",
    find: `pub fn PinyinSearchIndex::add_document(
  self : PinyinSearchIndex,
  text : String,
) -> Int32 raise @core.PinyinError {
  if text.length() == 0 {`,
    replace: `pub fn PinyinSearchIndex::add_document(
  self : PinyinSearchIndex,
  text : String,
) -> Int32 raise @core.PinyinError {
  if false {`,
    pkg: "search",
  },
  {
    id: "M12",
    name: "disambiguate 空串不再抛错",
    file: "disambiguate/pinyin_disambiguator.mbt",
    find: `pub fn PinyinDisambiguator::disambiguate(
  str : String,
) -> Array[String] raise @core.PinyinError {
  let chars = str.to_array()
  if chars.length() == 0 {`,
    replace: `pub fn PinyinDisambiguator::disambiguate(
  str : String,
) -> Array[String] raise @core.PinyinError {
  let chars = str.to_array()
  if false {`,
    pkg: "disambiguate",
  },
  {
    id: "M13",
    name: "stream 增量输出退化为全量输出",
    file: "convert/pinyin_stream_processor.mbt",
    find: `  if full_output.length() <= self.last_output.length() {
    return ""
  }`,
    replace: `  if full_output.length() <= self.last_output.length() {
    return full_output
  }`,
    pkg: "convert",
  },
];

function runTest(pkg) {
  const result = spawnSync(
    "moon",
    ["test", "-p", pkg, "--target", "native", "--warn-list", "+73", "--deny-warn"],
    {
      cwd: root,
      encoding: "utf8",
      shell: process.platform === "win32",
      timeout: 180000,
    },
  );
  return {
    killed: result.status !== 0,
    output: `${result.stdout ?? ""}\n${result.stderr ?? ""}`,
  };
}

const selected = MUTATIONS.filter((item) => !filter || filter.has(item.id));
if (selected.length === 0) {
  console.error("no mutations selected");
  process.exit(1);
}

console.log(`baseline: moon test -p each package`);
const baseline = runTest("core");
if (!baseline.killed) {
  console.log("baseline core tests passed");
} else {
  console.error("baseline failed; refusing to mutate");
  console.error(baseline.output.split("\n").slice(-20).join("\n"));
  process.exit(1);
}

const results = [];
let mutatedFile = null;
let original = null;

function restore() {
  if (mutatedFile !== null && original !== null) {
    writeFileSync(resolve(root, mutatedFile), original, "utf8");
    mutatedFile = null;
    original = null;
  }
}

for (const mutation of selected) {
  const full = resolve(root, mutation.file);
  const source = readFileSync(full, "utf8");
  const occurrences = source.split(mutation.find).length - 1;
  if (occurrences !== 1) {
    results.push({
      ...mutation,
      status: "SKIPPED",
      detail: `expected 1 occurrence, found ${occurrences}`,
    });
    continue;
  }
  original = source;
  mutatedFile = mutation.file;
  writeFileSync(full, source.replace(mutation.find, mutation.replace), "utf8");
  const outcome = runTest(mutation.pkg);
  restore();
  results.push({
    ...mutation,
    status: outcome.killed ? "KILLED" : "SURVIVED",
    detail: outcome.killed ? "" : "package tests still pass",
  });
}

restore();

console.log("");
console.log("id    status    package       mutation");
for (const item of results) {
  console.log(
    `${item.id.padEnd(5)} ${item.status.padEnd(9)} ${item.pkg.padEnd(13)} ${item.name}`,
  );
  if (item.detail) console.log(`      ${item.detail}`);
}

const survived = results.filter((item) => item.status !== "KILLED");
console.log("");
console.log(
  `killed ${results.length - survived.length}/${results.length}, survived/skipped ${survived.length}`,
);
if (survived.length > 0) process.exit(1);