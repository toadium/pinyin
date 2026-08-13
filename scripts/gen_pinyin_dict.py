# -*- coding: utf-8 -*-
"""gen_pinyin_dict.py — pinyin4cj → MoonBit 字典字面量生成脚本.

从源库 pinyin4cj 转写四张字典为 MoonBit 数据子包
(walkzzz/pinyin/data) 的 `pub let` 字面量文件：

  - src/data/chinese_dict.mbt       : Map[Int, Int]      繁→简码点映射
  - src/data/mutil_pinyin_dict.mbt  : Map[String, String] 词组拼音
  - src/data/tongyong_pinyin_dict.mbt : Map[String, String] 通用拼音
  - src/data/pinyin_dict.mbt        : Map[String, String] 单字拼音

所有文件读写显式指定 UTF-8 编码。解析后按 key 去重（保留末次 value，与 MoonBit Map
字面量及源库 Cangjie HashMap([...]) 构造语义一致），对被丢弃的重复 key 打印审计日志。
去重后条目数严格断言，不符则 sys.exit(1)。四张字典按 key 排序输出，多次运行产生
字节级一致产物。

环境变量：
  PINYIN4CJ_ROOT  源库 pinyin4cj 根目录（默认 D:\\CodeWorkspace\\forCangjie\\pinyin4cj）

输出目录固定为脚本所在项目根目录下的 src/data/ 子目录。
"""

import os
import re
import sys
from pathlib import Path
from typing import TypeVar

# 泛型类型变量（用于 dedup_by_key / format_repr 签名）
K = TypeVar('K')
V = TypeVar('V')

# 脚本所在目录（scripts/），项目根目录为其父目录
_SCRIPT_DIR: Path = Path(__file__).resolve().parent
_PROJECT_ROOT: Path = _SCRIPT_DIR.parent

# 源库根目录：优先从环境变量 PINYIN4CJ_ROOT 读取，未设置时回退到历史默认路径
SOURCE_ROOT: str = os.environ.get(
    "PINYIN4CJ_ROOT",
    r"D:\CodeWorkspace\forCangjie\pinyin4cj",
)
# 输出目录（数据子包）：项目根目录下的 src/data/
OUTPUT_DIR: str = str(_PROJECT_ROOT / "src" / "data")

# 源库字典文件路径
CHINESE_DICT_SRC: str = SOURCE_ROOT + r"\src\chinese.dict.cj"
MUTIL_PINYIN_DICT_SRC: str = SOURCE_ROOT + r"\src\mutil_pinyin.dict.cj"
TONGYONG_PINYIN_DICT_SRC: str = SOURCE_ROOT + r"\src\tongyong_pinyin_dict.cj"
PINYIN_DICT_SRC: str = SOURCE_ROOT + r"\resource\pinyin.dict.txt"

# 输出文件路径
CHINESE_DICT_OUT: str = OUTPUT_DIR + r"\chinese_dict.mbt"
MUTIL_PINYIN_DICT_OUT: str = OUTPUT_DIR + r"\mutil_pinyin_dict.mbt"
TONGYONG_PINYIN_DICT_OUT: str = OUTPUT_DIR + r"\tongyong_pinyin_dict.mbt"
PINYIN_DICT_OUT: str = OUTPUT_DIR + r"\pinyin_dict.mbt"

# 预期条目数（v4 去重后值，见设计 §概述/实际条目数核对）
EXPECTED_COUNTS: dict[str, int] = {
    "chinese_dict": 2533,         # v3: 2543 → v4: 2533（去重 10 条）
    "mutil_pinyin_dict": 843,     # v3: 845 → v4: 843（去重 2 条）
    "tongyong_pinyin_dict": 82,   # 不变
    "pinyin_dict": 20903,         # 不变
}

# chinese.dict.cj 单字符 Rune 条目正则：(r'X', r'Y')
_RE_CHINESE = re.compile(r"\(r'(.)'\s*,\s*r'(.)'\)")
# 字符串字面量条目正则：("key", "value")，非贪婪匹配
_RE_STRING = re.compile(r'\("(.+?)"\s*,\s*"(.+?)"\)')


def parse_chinese_dict(src_path: str) -> list[tuple[int, int]]:
    """解析 chinese.dict.cj，提取 (r'X', r'Y') 条目，
    返回 [(ord(X), ord(Y)), ...] 的码点对列表（含重复 key）。"""
    items: list[tuple[int, int]] = []
    with open(src_path, "r", encoding="utf-8") as fh:
        for line in fh:
            m = _RE_CHINESE.search(line)
            if m:
                trad = m.group(1)
                simp = m.group(2)
                items.append((ord(trad), ord(simp)))
    return items


def parse_string_dict(src_path: str) -> list[tuple[str, str]]:
    """解析 mutil_pinyin.dict.cj 或 tongyong_pinyin_dict.cj，
    提取 ("key", "value") 条目，返回 [(key, value), ...] 列表（含重复 key）。"""
    items: list[tuple[str, str]] = []
    with open(src_path, "r", encoding="utf-8") as fh:
        for line in fh:
            m = _RE_STRING.search(line)
            if m:
                items.append((m.group(1), m.group(2)))
    return items


def parse_pinyin_dict(src_path: str) -> list[tuple[str, str]]:
    """解析 pinyin.dict.txt（两行一组：汉字 / 拼音读音），
    返回 [(汉字, 拼音), ...] 列表（含重复 key，若有）。"""
    items: list[tuple[str, str]] = []
    with open(src_path, "r", encoding="utf-8") as fh:
        lines = [ln.rstrip("\n").rstrip("\r") for ln in fh]
    # 两行一组：奇数行汉字（key），偶数行拼音（value）
    i = 0
    while i + 1 < len(lines):
        key = lines[i]
        value = lines[i + 1]
        # 跳过空行（若有）
        if key == "" and value == "":
            i += 2
            continue
        items.append((key, value))
        i += 2
    return items


def format_repr(v: K) -> str:
    """自定义格式化函数（非 repr()），用于审计日志中 key/value 的可读表示：
    - Int：f"{v} (0x{v:X})"（十进制+十六进制，如 33266 → "33266 (0x81FA)"）
    - str：repr(v)（原始字符，如 '臺' → "'臺'"）
    - 其他类型：repr(v) 兜底"""
    if isinstance(v, int):
        return f"{v} (0x{v:X})"
    return repr(v)


def dedup_by_key(items: list[tuple[K, V]], name: str) -> list[tuple[K, V]]:
    """按 key 去重，保留末次 value（与 MoonBit Map 字面量及源库 Cangjie HashMap 语义一致）。
    对每个被丢弃的重复 key，打印审计日志：
      [DEDUP] {name}: key={key_repr}, kept_value={kept_repr}, dropped_value={dropped_repr}
    返回去重后的条目列表（保持原列表中首次出现的 key 顺序，后续 write_* 会按 key 排序，
    故顺序不影响输出确定性）。

    实现说明：正向遍历用 dict 累积，后出现的 key 覆盖先出现的，故保留末次 value。
    注意：dict(reversed(items)) 是错误等价实现——它保留首次 value 而非末次，禁止使用。
    """
    seen: dict[K, V] = {}
    for k, v in items:
        if k in seen:
            # 重复 key：当前 v 为 kept（末次），seen[k] 为被覆盖的 dropped
            print(f"[DEDUP] {name}: key={format_repr(k)}, "
                  f"kept_value={format_repr(v)}, dropped_value={format_repr(seen[k])}")
        seen[k] = v
    return list(seen.items())


def write_chinese_dict(items: list[tuple[int, int]], out_path: str) -> None:
    """将码点对列表按 Int key 升序排序后，
    写入 chinese_dict.mbt 为 `pub let chinese_dict : Map[Int, Int] = { 0xXXXX: 0xYYYY, ... }`。"""
    sorted_items = sorted(items, key=lambda kv: kv[0])
    lines: list[str] = []
    lines.append("///|")
    lines.append("/// 繁体→简体汉字码点映射，由 scripts/gen_pinyin_dict.py 从源库 chinese.dict.cj 生成。")
    lines.append(f"/// 共 {len(sorted_items)} 条，key 为繁体码点（Int），value 为简体码点（Int），16 进制字面量。")
    lines.append("/// 源库含 10 组重复繁体 key，已按末次 value 去重（与 MoonBit Map 字面量语义一致）。")
    lines.append("pub let chinese_dict : Map[Int, Int] = {")
    for k, v in sorted_items:
        # 大写 16 进制码点，如 0x81FA
        lines.append(f"  0x{k:X}: 0x{v:X},")
    lines.append("}")
    with open(out_path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")


def write_string_dict(var_name: str, items: list[tuple[str, str]], out_path: str,
                      doc_lines: list[str]) -> None:
    """将字符串对列表按 String key 字典序排序后，
    写入 .mbt 为 `pub let {var_name} : Map[String, String] = { "k": "v", ... }`。"""
    sorted_items = sorted(items, key=lambda kv: kv[0])
    lines: list[str] = []
    lines.append("///|")
    for dl in doc_lines:
        lines.append(dl)
    lines.append(f"pub let {var_name} : Map[String, String] = {{")
    for k, v in sorted_items:
        lines.append(f'  "{k}": "{v}",')
    lines.append("}")
    with open(out_path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")


def assert_count(name: str, actual: int, expected: int) -> None:
    """断言 actual == expected。不等则打印实际与预期值并 sys.exit(1)。"""
    if actual != expected:
        print(f"[ASSERT FAIL] {name}: actual={actual}, expected={expected}", file=sys.stderr)
        sys.exit(1)


def main() -> None:
    """主函数：解析四张字典 → 按 key 去重 → 断言去重后条目数 → 排序 → 写入 4 个 .mbt 文件 → 打印生成摘要。"""
    # 1. 解析四张字典（含重复 key）
    chinese_items = parse_chinese_dict(CHINESE_DICT_SRC)
    mutil_items = parse_string_dict(MUTIL_PINYIN_DICT_SRC)
    tongyong_items = parse_string_dict(TONGYONG_PINYIN_DICT_SRC)
    pinyin_items = parse_pinyin_dict(PINYIN_DICT_SRC)

    # 2. 按 key 去重，保留末次 value（与 MoonBit Map 字面量及源库 Cangjie HashMap 语义一致）
    chinese_items = dedup_by_key(chinese_items, "chinese_dict")
    mutil_items = dedup_by_key(mutil_items, "mutil_pinyin_dict")
    tongyong_items = dedup_by_key(tongyong_items, "tongyong_pinyin_dict")
    pinyin_items = dedup_by_key(pinyin_items, "pinyin_dict")

    # 3. 断言去重后条目数（= 写入条目数 = 运行时 Map.length()）
    assert_count("chinese_dict", len(chinese_items), EXPECTED_COUNTS["chinese_dict"])
    assert_count("mutil_pinyin_dict", len(mutil_items), EXPECTED_COUNTS["mutil_pinyin_dict"])
    assert_count("tongyong_pinyin_dict", len(tongyong_items), EXPECTED_COUNTS["tongyong_pinyin_dict"])
    assert_count("pinyin_dict", len(pinyin_items), EXPECTED_COUNTS["pinyin_dict"])

    # 4. 写入 4 个 .mbt 文件（排序在 write_* 内部完成）
    write_chinese_dict(chinese_items, CHINESE_DICT_OUT)
    write_string_dict(
        "mutil_pinyin_dict", mutil_items, MUTIL_PINYIN_DICT_OUT,
        [
            "/// 词组拼音映射，由 scripts/gen_pinyin_dict.py 从源库 mutil_pinyin.dict.cj 生成。",
            f"/// 共 {len(mutil_items)} 条，key 为词组（String），value 为逗号分隔拼音（含带调元音）。",
            "/// 源库含 2 组重复词组 key，已按末次 value 去重（与 MoonBit Map 字面量语义一致）。",
        ],
    )
    write_string_dict(
        "tongyong_pinyin_dict", tongyong_items, TONGYONG_PINYIN_DICT_OUT,
        [
            "/// 通用拼音映射，由 scripts/gen_pinyin_dict.py 从源库 tongyong_pinyin_dict.cj 生成。",
            f"/// 共 {len(tongyong_items)} 条，key/value 均为纯 ASCII 字符串。",
        ],
    )
    write_string_dict(
        "pinyin_dict", pinyin_items, PINYIN_DICT_OUT,
        [
            "/// 单字拼音映射，由 scripts/gen_pinyin_dict.py 从源库 resource/pinyin.dict.txt 生成。",
            f"/// 共 {len(pinyin_items)} 条，key 为汉字（String），value 为逗号分隔多音（含带调元音）。",
        ],
    )

    # 5. 打印生成摘要
    print(f"[OK] chinese_dict       : {len(chinese_items)} entries -> {CHINESE_DICT_OUT}")
    print(f"[OK] mutil_pinyin_dict  : {len(mutil_items)} entries -> {MUTIL_PINYIN_DICT_OUT}")
    print(f"[OK] tongyong_pinyin_dict: {len(tongyong_items)} entries -> {TONGYONG_PINYIN_DICT_OUT}")
    print(f"[OK] pinyin_dict        : {len(pinyin_items)} entries -> {PINYIN_DICT_OUT}")


if __name__ == "__main__":
    main()
