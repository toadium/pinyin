# -*- coding: utf-8 -*-
"""gen_large_phrases.py — pypinyin 大词库 → MoonBit 字符串分片 + 运行时解析.

数据源：mozillazg/python-pinyin 的 `pypinyin/phrases_dict.json`
（pypinyin 运行时词库，47k+ 词组，源自 pinyin-data phrase-pinyin-data）。

用法：
    curl -L -o /tmp/phrases_dict.json \
      https://raw.githubusercontent.com/mozillazg/python-pinyin/master/pypinyin/phrases_dict.json
    python scripts/gen_large_phrases.py --src /tmp/phrases_dict.json

输出：
    data/large_phrase_raw_01.mbt ... 字符串分片（每片 <= 8000 条）
    data/large_phrases.mbt           解析 + 聚合查找 API

为什么用字符串而不是 Map 字面量：
- 47k 条 Map 字面量会把包初始化函数撑到 wasm 的 `local count too large`；
- 字符串常量分片 + 顶层 parse 是项目已验证的规避方式（同 common_chars）。

口径：
- 每个字取第一个候选读音；
- **「一」「不」还原为原调**（yí/yì → yī，bú → bù），变调交由 tone 包处理；
- 仅保留全汉字词组，长度 2..9，读音数必须等于字数；
- 按 key 排序后顺序分片，保证多次运行字节级一致。
"""

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data"
AGGREGATE = DATA_DIR / "large_phrases.mbt"
CHUNK = 8000
SEGMENT = 1500
DEFAULT_SRC = DATA_DIR / "external" / "phrases_dict.json"
SOURCE_URL = (
    "https://raw.githubusercontent.com/mozillazg/python-pinyin/master/pypinyin/phrases_dict.json"
)

TONE_RESTORE = {
    "一": {"yí": "yī", "yì": "yī"},
    "不": {"bú": "bù"},
}

HANZI = re.compile(r"^[\u4e00-\u9fff〇]+$")
SYLLABLE = re.compile(r"^[a-züāáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜńňǹḿ]+$")


def escape(text: str) -> str:
    return text.replace("\\", "\\\\").replace('"', '\\"').replace("\t", "\\t").replace("\n", "\\n")


def write_raw_shard(index: int, items: list) -> Path:
    name = f"large_phrase_raw_{index:02d}"
    path = DATA_DIR / f"{name}.mbt"
    segments = []
    current = ""
    for word, pinyin in items:
        current += f"{word}\t{pinyin}\n"
        if len(current) >= SEGMENT:
            segments.append(current)
            current = ""
    if current:
        segments.append(current)
    lines = [
        "///|",
        f"/// pypinyin 大词库字符串分片 {index}（{len(items)} 条，{len(segments)} 段）。",
        "/// 由 scripts/gen_large_phrases.py 生成，勿手改。",
        f"pub let {name} : String =",
    ]
    for i, segment in enumerate(segments):
        suffix = " +" if i < len(segments) - 1 else ""
        lines.append(f'  "{escape(segment)}"{suffix}')
    lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    return path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--src", default=str(DEFAULT_SRC), help="phrases_dict.json 路径")
    args = parser.parse_args()

    src = Path(args.src)
    if not src.exists():
        print(f"缺少数据源: {src}", file=sys.stderr)
        print(f"下载: curl -L -o {src} {SOURCE_URL}", file=sys.stderr)
        return 1

    raw = src.read_bytes()
    digest = hashlib.sha256(raw).hexdigest()
    data = json.loads(raw.decode("utf-8"))

    entries = {}
    skipped_non_hanzi = skipped_len = skipped_syllable = restored = 0
    max_chars = 0
    for word, readings in data.items():
        if not HANZI.match(word):
            skipped_non_hanzi += 1
            continue
        if not (2 <= len(word) <= 9) or len(readings) != len(word):
            skipped_len += 1
            continue
        syllables = []
        ok = True
        for ch, candidates in zip(word, readings):
            if not candidates:
                ok = False
                break
            syllable = candidates[0]
            fixed = TONE_RESTORE.get(ch, {}).get(syllable)
            if fixed:
                restored += 1
                syllable = fixed
            if not SYLLABLE.match(syllable):
                ok = False
                break
            syllables.append(syllable)
        if not ok:
            skipped_syllable += 1
            continue
        entries[word] = ",".join(syllables)
        max_chars = max(max_chars, len(word))

    if len(entries) < 40000:
        print(f"条目数异常偏低: {len(entries)}", file=sys.stderr)
        return 1

    # 清理旧版 Map 分片
    for stale in DATA_DIR.glob("large_phrase_dict_*.mbt"):
        stale.unlink()

    ordered = sorted(entries.items())
    chunks = [ordered[i : i + CHUNK] for i in range(0, len(ordered), CHUNK)]
    for index, chunk in enumerate(chunks, 1):
        path = write_raw_shard(index, chunk)
        print(f"shard {index:02d}: {len(chunk)} 条 -> {path.name}")

    shard_names = [f"large_phrase_raw_{i:02d}" for i in range(1, len(chunks) + 1)]
    aggregate = [
        "///|",
        "/// 大词库聚合入口：pypinyin phrases_dict 转换的 47k+ 词组拼音表。",
        f"/// 数据源：{SOURCE_URL}",
        f"/// SHA256：{digest}",
        "/// 由 scripts/gen_large_phrases.py 生成；字符串分片规避 wasm 初始化局部变量上限。",
        f"pub let large_phrase_count : Int = {len(entries)}",
        "",
        "///|",
        f"pub let large_phrase_max_chars : Int = {max_chars}",
        "",
        "///|",
        '/// 解析 "词\\t拼音\\n" 文本为查找表。',
        "fn parse_large_phrase_raw(raw : String) -> Map[String, String] {",
        "  let table : Map[String, String] = Map([])",
        "  for raw_line in raw.split(\"\\n\") {",
        "    let line = raw_line.to_owned()",
        "    if line.length() > 0 {",
        "      let parts = line",
        "        .split(\"\\t\")",
        "        .map(fn(x) { x.to_owned() })",
        "        .to_array()",
        "      if parts.length() == 2 {",
        "        table[parts[0]] = parts[1]",
        "      }",
        "    }",
        "  }",
        "  table",
        "}",
        "",
        "///|",
        "let large_phrase_shards : Array[Map[String, String]] = [",
    ]
    for name in shard_names:
        aggregate.append(f"  parse_large_phrase_raw({name}),")
    aggregate += [
        "]",
        "",
        "///|",
        "/// 查询大词库；未命中返回 None。",
        "pub fn large_phrase_lookup(word : String) -> String? {",
        "  let mut found : String? = None",
        "  for shard in large_phrase_shards {",
        "    if found is None {",
        "      match shard.get(word) {",
        "        Some(value) => found = Some(value)",
        "        None => ()",
        "      }",
        "    }",
        "  }",
        "  found",
        "}",
        "",
    ]
    AGGREGATE.write_text("\n".join(aggregate), encoding="utf-8", newline="\n")

    print(f"source entries : {len(data)}")
    print(f"written        : {len(entries)} in {len(chunks)} shards")
    print(f"restored 一/不 : {restored}")
    print(f"max chars      : {max_chars}")
    print(f"skipped        : non_hanzi={skipped_non_hanzi} len={skipped_len} syllable={skipped_syllable}")
    print(f"sha256         : {digest}")
    print(f"aggregate      : {AGGREGATE.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())