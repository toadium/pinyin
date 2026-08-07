# 详细设计（v4）

## 概述

本任务为 pinyin4cj → MoonBit 移植 R3（字典字面量生成）的**首次 RETRY**，修正 v3 失败的重复 key 去重缺陷。

### v3 失败根因

v3 生成脚本 `parse_*` 按行正则匹配收集所有条目（含重复 key），`write_*` 按 key 排序后原样写入 `.mbt` 文件（保留重复 key 行）。MoonBit Map 字面量构造时对重复 key 静默去重（取末次 value），导致运行时 `Map.length()` < 写入条目数：

| 字典 | v3 写入条目数 | 运行时 Map.length() | 差异 | 源库重复 key 组数 |
|------|--------------|---------------------|------|------------------|
| `chinese_dict` | 2543 | 2533 | -10 | 10 |
| `mutil_pinyin_dict` | 845 | 843 | -2 | 2 |
| `tongyong_pinyin_dict` | 82 | 82 | 0 | 0 |
| `pinyin_dict` | 20903 | 20903 | 0 | 0 |

测试断言 2543/845 与运行时实际 2533/843 不符，2 用例失败（`chinese_dict_has_2543_entries` / `mutil_pinyin_dict_has_845_entries`）。

### v4 修正方向

1. **生成脚本增加去重逻辑**：在 `parse_*` 返回后，按 key 去重，**保留末次 value**（与 MoonBit Map 字面量语义及源库 Cangjie `HashMap([...])` 构造语义一致），打印被丢弃的重复 key 审计日志
2. **更新 `EXPECTED_COUNTS`** 为去重后条目数：`chinese_dict: 2533`、`mutil_pinyin_dict: 843`（`tongyong_pinyin_dict: 82`、`pinyin_dict: 20903` 不变）
3. **断言时序调整**：先去重，再断言去重后条目数（断言的是最终写入 `.mbt` 的条目数，须与运行时 `Map.length()` 一致）
4. **重新运行脚本生成 4 个 `.mbt` 文件**
5. **同步更新测试文件断言**：`chinese_dict_test.mbt` 2543→2533，`mutil_pinyin_dict_test.mbt` 845→843

### 去重语义保真论证

去重保留末次 value 是源库语义保真的正确处置，**非放宽断言**：
- **MoonBit Map 字面量**：对重复 key 取末次 value（v3 运行时已验证）
- **源库 Cangjie `HashMap([...])`**：构造同样对重复 key 去重取末次（Cangjie 标准库语义）
- **结论**：去重后条目数 2533/843 是源库语义保真的正确值，断言更新为 2533/843 是修正预期值（设计文档 §D 授权"由编码 agent 核对源库后修正预期值"），非容差放宽

### 源库文件名勘误（沿用 v3）

task_v3.md 将词组拼音字典文件名误写为 `src/mutil_pinyin_dict.cj`，**实际源库文件名为 `src/mutil_pinyin.dict.cj`**。v3 脚本已使用实际文件名，v4 沿用不变。

### 实际条目数核对（v4 更新）

| 字典 | v3 预期（含重复） | v4 预期（去重后） | 差异 | 来源 |
|------|------------------|------------------|------|------|
| `chinese_dict` | 2543 | **2533** | -10 | v3 运行时 `Map.length()` 验证 |
| `mutil_pinyin_dict` | 845 | **843** | -2 | v3 运行时 `Map.length()` 验证 |
| `tongyong_pinyin_dict` | 82 | 82 | 0 | 无重复 key，不变 |
| `pinyin_dict` | 20903 | 20903 | 0 | 无重复 key，不变 |

## 文件规划

| 文件路径 | 操作 | 职责 |
|---------|------|------|
| `scripts/gen_pinyin_dict.py` | **修改** | 增加 `dedup_by_key` 函数与 `format_repr` 格式化函数；更新 `EXPECTED_COUNTS`；调整 `main` 流程为"解析→去重→断言→写入" |
| `data/chinese_dict.mbt` | **重新生成** | `pub let chinese_dict : Map[Int, Int]`，2533 条繁→简码点映射（去重后，无重复 key） |
| `data/mutil_pinyin_dict.mbt` | **重新生成** | `pub let mutil_pinyin_dict : Map[String, String]`，843 条词组拼音（去重后，无重复 key） |
| `data/tongyong_pinyin_dict.mbt` | **重新生成** | `pub let tongyong_pinyin_dict : Map[String, String]`，82 条通用拼音（无重复 key，内容不变） |
| `data/pinyin_dict.mbt` | **重新生成** | `pub let pinyin_dict : Map[String, String]`，20903 条单字拼音（无重复 key，内容不变） |
| `chinese_dict_test.mbt` | **修改** | 用例名 `chinese_dict_has_2543_entries` → `chinese_dict_has_2533_entries`，`content="2543"` → `content="2533"`，文档注释同步 |
| `mutil_pinyin_dict_test.mbt` | **修改** | 用例名 `mutil_pinyin_dict_has_845_entries` → `mutil_pinyin_dict_has_843_entries`，`content="845"` → `content="843"`，文档注释同步 |

**说明**：
- 路径均相对项目根目录 `D:\CodeWorkspace\forMoonbit\pinyin`。
- `data/tongyong_pinyin_dict.mbt` 与 `data/pinyin_dict.mbt` 虽标记"重新生成"，但因源库无重复 key，去重后内容与 v3 字节级一致（脚本确定性输出保证）。
- 本任务**不修改** `moon.mod` / `moon.pkg` / `data/moon.pkg` / `README.mbt.md` / `README.md` / `pinyin_format.mbt` / `pinyin_error.mbt` / `pinyin_format_test.mbt` / `pinyin_error_test.mbt` / `tongyong_pinyin_dict_test.mbt` / `pinyin_dict_test.mbt`（R1/R2/R3 产出保持不变）。

## 类型定义

本任务涉及两类"类型"：Python 脚本的函数签名（脚本本身）与 MoonBit 数据常量签名（生成产物）。

### Python 脚本模块结构（`scripts/gen_pinyin_dict.py`）

**形态**：Python 3 模块脚本（`if __name__ == "__main__": main()` 入口）
**职责**：解析源库四张字典，按 key 去重（保留末次 value），断言去重后条目数，按 key 排序，写入 4 个 `.mbt` 字面量文件

#### 模块导入

```python
from typing import TypeVar  # 用于 dedup_by_key / format_repr 泛型签名
```

#### 模块级常量

```python
# 源库根目录
SOURCE_ROOT: str = r"D:\CodeWorkspace\forCangjie\pinyin4cj"
# 输出目录（数据子包）
OUTPUT_DIR: str = r"D:\CodeWorkspace\forMoonbit\pinyin\data"

# 源库字典文件路径
CHINESE_DICT_SRC: str       # SOURCE_ROOT + r"\src\chinese.dict.cj"
MUTIL_PINYIN_DICT_SRC: str   # SOURCE_ROOT + r"\src\mutil_pinyin.dict.cj"  ← 实际文件名（勘误见 §概述）
TONGYONG_PINYIN_DICT_SRC: str # SOURCE_ROOT + r"\src\tongyong_pinyin_dict.cj"
PINYIN_DICT_SRC: str         # SOURCE_ROOT + r"\resource\pinyin.dict.txt"

# 输出文件路径
CHINESE_DICT_OUT: str        # OUTPUT_DIR + r"\chinese_dict.mbt"
MUTIL_PINYIN_DICT_OUT: str   # OUTPUT_DIR + r"\mutil_pinyin_dict.mbt"
TONGYONG_PINYIN_DICT_OUT: str # OUTPUT_DIR + r"\tongyong_pinyin_dict.mbt"
PINYIN_DICT_OUT: str         # OUTPUT_DIR + r"\pinyin_dict.mbt"

# 预期条目数（v4 去重后值，见 §概述/实际条目数核对）
EXPECTED_COUNTS: dict[str, int] = {
    "chinese_dict": 2533,         # v3: 2543 → v4: 2533（去重 10 条）
    "mutil_pinyin_dict": 843,     # v3: 845 → v4: 843（去重 2 条）
    "tongyong_pinyin_dict": 82,   # 不变
    "pinyin_dict": 20903,         # 不变
}
```

#### 函数签名

```python
# 泛型类型变量（用于 dedup_by_key / format_repr 签名）
K = TypeVar('K')
V = TypeVar('V')

def parse_chinese_dict(src_path: str) -> list[tuple[int, int]]:
    """解析 chinese.dict.cj，提取 (r'X', r'Y') 条目，
    返回 [(ord(X), ord(Y)), ...] 的码点对列表（含重复 key）。"""

def parse_string_dict(src_path: str) -> list[tuple[str, str]]:
    """解析 mutil_pinyin.dict.cj 或 tongyong_pinyin_dict.cj，
    提取 ("key", "value") 条目，返回 [(key, value), ...] 列表（含重复 key）。"""

def parse_pinyin_dict(src_path: str) -> list[tuple[str, str]]:
    """解析 pinyin.dict.txt（两行一组：汉字 / 拼音读音），
    返回 [(汉字, 拼音), ...] 列表（含重复 key，若有）。"""

def dedup_by_key(items: list[tuple[K, V]], name: str) -> list[tuple[K, V]]:
    """按 key 去重，保留末次 value（与 MoonBit Map 字面量及源库 Cangjie HashMap 语义一致）。
    对每个被丢弃的重复 key，打印审计日志：[DEDUP] {name}: key={key}, kept_value={kept}, dropped_value={dropped}。
    返回去重后的条目列表（保持原列表中末次出现的相对顺序）。"""

def format_repr(v: K) -> str:
    """自定义格式化函数（非 repr()），用于审计日志中 key/value 的可读表示：
    - Int：f"{v} (0x{v:X})"（十进制+十六进制，如 33266 → "33266 (0x81FA)"）
    - str：repr(v)（原始字符，如 '臺' → "'臺'"）
    - 其他类型：repr(v) 兜底"""

def write_chinese_dict(items: list[tuple[int, int]], out_path: str) -> None:
    """将码点对列表按 Int key 升序排序后，
    写入 chinese_dict.mbt 为 `pub let chinese_dict : Map[Int, Int] = { 0xXXXX: 0xYYYY, ... }`。"""

def write_string_dict(var_name: str, items: list[tuple[str, str]], out_path: str,
                      doc_lines: list[str]) -> None:
    """将字符串对列表按 String key 字典序排序后，
    写入 .mbt 为 `pub let {var_name} : Map[String, String] = { "k": "v", ... }`。"""

def assert_count(name: str, actual: int, expected: int) -> None:
    """断言 actual == expected。不等则打印实际与预期值并 sys.exit(1)。"""

def main() -> None:
    """主函数：解析四张字典 → 按 key 去重 → 断言去重后条目数 → 排序 → 写入 4 个 .mbt 文件 → 打印生成摘要。"""
```

#### 解析逻辑规格（沿用 v3，不变）

**`parse_chinese_dict`**：
- 输入文件编码：UTF-8（显式 `encoding="utf-8"`）
- 逐行扫描，正则匹配 `r'\(r\'(.)\'\s*,\s*r\'(.)\'\)'`（单字符 Rune 字面量）
- 对每条匹配，提取繁体字符 X 与简体字符 Y，转换为 `(ord(X), ord(Y))` 码点对
- 跳过非匹配行（注释、声明、空行、`])` 收尾行）
- 返回码点对列表（**含重复 key**，去重在 `dedup_by_key` 中处理）

**`parse_string_dict`**：
- 输入文件编码：UTF-8（显式 `encoding="utf-8"`）
- 逐行扫描，正则匹配 `r'\("(.+?)"\s*,\s*"(.+?)"\)'`（字符串字面量，非贪婪匹配）
- 对每条匹配，提取 key 与 value 原样保留（含带调元音 UTF-8 字符）
- 跳过非匹配行
- 返回字符串对列表（**含重复 key**，去重在 `dedup_by_key` 中处理）

**`parse_pinyin_dict`**：
- 输入文件编码：UTF-8（显式 `encoding="utf-8"`）
- 逐行读取，两行一组：奇数行为汉字（key），偶数行为拼音读音（value，逗号分隔多音）
- 跳过空行（若有）
- 返回 `[(汉字, 拼音), ...]` 列表（**含重复 key**，去重在 `dedup_by_key` 中处理）

#### 去重逻辑规格（v4 新增）

**`dedup_by_key`**：
- **输入**：`items`（解析阶段原始条目列表，含重复 key），`name`（字典名，用于审计日志）
- **去重策略**：按 key 去重，**保留末次 value**（与 MoonBit Map 字面量及源库 Cangjie `HashMap([...])` 构造语义一致）
- **实现方式**：从右到左遍历（或反向遍历），首次遇到的 key 即原列表末次出现的 key，保留；后续遇到的相同 key 丢弃。或等价地：用 `dict` 正向构造（`dict(items)`），再转回列表（`dict` 构造时按迭代顺序插入，后出现的 key 覆盖先出现的，故保留末次 value）。**注意**：`dict(reversed(items))` 是**错误**等价实现——它保留首次 value 而非末次，与核心目标矛盾，禁止使用。
- **审计日志**：对每个被丢弃的重复 key，向 `stdout` 打印一行：
  ```
  [DEDUP] {name}: key={key_repr}, kept_value={kept_repr}, dropped_value={dropped_repr}
  ```
  - `{key_repr}` / `{kept_repr}` / `{dropped_repr}`：key 与 value 的自定义格式化形式（由 `format_repr()` 函数生成，**非 `repr()` 形式**）：对 Int 显示 `十进制 (0x十六进制)`（如 `33266 (0x81FA)`），对 String 显示 `repr()` 形式（如 `'臺'`），便于追溯码点与字符
  - 审计日志便于追溯源库重复 key 的具体内容与去重决策
- **返回值**：去重后的条目列表，保持原列表中末次出现的相对顺序（后续 `write_*` 会按 key 排序，故顺序不影响输出确定性）
- **无重复 key 时**：直接返回原列表（不打印审计日志），零开销

#### 输出格式规格（沿用 v3，不变）

**`write_chinese_dict`**：
- 输出文件编码：UTF-8（显式 `encoding="utf-8"`）
- 按 Int key 升序排序（`sorted(items, key=lambda kv: kv[0])`）
- 文件头部：`///` 文档注释（说明来源、条目数、生成脚本）
- 常量声明：`pub let chinese_dict : Map[Int, Int] = {`
- 每条目一行：`  0xXXXX: 0xYYYY,`（16 进制大写码点，`f"0x{cp:X}"` 输出）
- 文件尾部：`}`

**`write_string_dict`**：
- 输出文件编码：UTF-8（显式 `encoding="utf-8"`）
- 按 String key 字典序排序（`sorted(items, key=lambda kv: kv[0])`）
- 文件头部：`///` 文档注释
- 常量声明：`pub let {var_name} : Map[String, String] = {`
- 每条目一行：`  "key": "value",`（字符串字面量，拼音数据不含 `"`，无需转义）
- 文件尾部：`}`

### MoonBit 数据常量签名（生成产物）

四个 `.mbt` 文件各定义一个 `pub let` 顶层常量，位于数据子包 `pinyin/pinyin/data`：

#### chinese_dict

**形态**：`pub let` 顶层绑定，`Map[Int, Int]` 字面量
**包路径**：`pinyin/pinyin/data`
**职责**：繁体→简体汉字码点映射

```moonbit
/// 繁体→简体汉字码点映射，由 scripts/gen_pinyin_dict.py 从源库 chinese.dict.cj 生成。
/// 共 2533 条，key 为繁体码点（Int），value 为简体码点（Int），16 进制字面量。
/// 源库含 10 组重复繁体 key，已按末次 value 去重（与 MoonBit Map 字面量语义一致）。
pub let chinese_dict : Map[Int, Int] = {
  0x81FA: 0x53F0,
  0x842C: 0x4E07,
  ...
}
```

#### mutil_pinyin_dict

**形态**：`pub let` 顶层绑定，`Map[String, String]` 字面量
**包路径**：`pinyin/pinyin/data`
**职责**：词组→拼音映射

```moonbit
/// 词组拼音映射，由 scripts/gen_pinyin_dict.py 从源库 mutil_pinyin.dict.cj 生成。
/// 共 843 条，key 为词组（String），value 为逗号分隔拼音（含带调元音）。
/// 源库含 2 组重复词组 key，已按末次 value 去重（与 MoonBit Map 字面量语义一致）。
pub let mutil_pinyin_dict : Map[String, String] = {
  "阿訇": "ā,hōng",
  ...
}
```

#### tongyong_pinyin_dict

**形态**：`pub let` 顶层绑定，`Map[String, String]` 字面量
**包路径**：`pinyin/pinyin/data`
**职责**：通用拼音映射

```moonbit
/// 通用拼音映射，由 scripts/gen_pinyin_dict.py 从源库 tongyong_pinyin_dict.cj 生成。
/// 共 82 条，key/value 均为纯 ASCII 字符串。
pub let tongyong_pinyin_dict : Map[String, String] = {
  "chi": "chih",
  ...
}
```

#### pinyin_dict

**形态**：`pub let` 顶层绑定，`Map[String, String]` 字面量
**包路径**：`pinyin/pinyin/data`
**职责**：单字→拼音映射

```moonbit
/// 单字拼音映射，由 scripts/gen_pinyin_dict.py 从源库 resource/pinyin.dict.txt 生成。
/// 共 20903 条，key 为汉字（String），value 为逗号分隔多音（含带调元音）。
pub let pinyin_dict : Map[String, String] = {
  "〇": "líng",
  "一": "yī",
  ...
}
```

**可见性决策**（沿用 v3）：四个常量均使用 `pub let`（非 `pub(self) let`），确保 R4 字典视图任务可通过 `@data` 跨包引用。

## 错误处理

本任务为**数据生成脚本**，错误处理采用 Python 惯例（异常 + 断言），不涉及 MoonBit `raise`/`catch`。

### 脚本错误处理策略

| 错误模式 | 检测方式 | 处置 |
|---------|---------|------|
| 源库文件不存在 | `open()` 抛 `FileNotFoundError` | 脚本自然终止，exit code ≠ 0 |
| 源库文件编码错误 | `open(..., encoding="utf-8")` 抛 `UnicodeDecodeError` | 脚本自然终止 |
| 去重后条目数与预期不符 | `assert_count()` 显式断言 | 打印实际与预期值，`sys.exit(1)` |
| 正则匹配零条目 | 解析后列表为空 → `assert_count` 断言失败 | 同上 |
| 输出目录不存在 | `open(out_path, "w")` 抛 `FileNotFoundError` | 脚本自然终止 |

### 生成产物（.mbt）错误处理

四个 `.mbt` 文件为纯数据字面量，**无运行时错误路径**：
- `Map` 字面量构造不抛错（MoonBit 内置 Map 字面量语法，编译期完成）
- 去重后无重复 key，Map 字面量构造无静默去重，写入条目数 = 运行时 `Map.length()`
- 唯一可能的编译期错误：Map 字面量语法错误（由 `moon check` 检测）

### 验证阶段潜在失败模式与处置

| 失败模式 | 根因 | 处置 |
|---------|------|------|
| Python 脚本运行失败 | 源库路径错误或源库文件名变动 | 核对 `SOURCE_ROOT` 与源库文件名 |
| Python 脚本断言失败 | 去重后条目数与 `EXPECTED_COUNTS` 不符 | 脚本打印实际计数，核对源库重复 key 数后修正 `EXPECTED_COUNTS` |
| `moon check` 报告语法错误 | Map 字面量语法拼写 | 对照 wiki 示例与本文 §类型定义 签名修正 |
| `moon test` 条目数断言失败 | 去重后条目数与测试断言不符 | 核对脚本 `EXPECTED_COUNTS` 与测试断言一致 |

## 行为契约

### A. `scripts/gen_pinyin_dict.py` 内容契约

**前置条件**：项目根目录 `D:\CodeWorkspace\forMoonbit\pinyin` 存在且可写；源库 `D:\CodeWorkspace\forCangjie\pinyin4cj` 存在且可读；`data/` 目录已存在（R1 产出）；v3 产出的 `scripts/gen_pinyin_dict.py` 存在（本任务修改）。

**文件内容要求**：
- Python 3 脚本，UTF-8 编码
- 所有文件读写显式指定 `encoding="utf-8"`（强制）
- 模块级常量定义源库路径、输出路径、预期条目数（见 §类型定义/模块级常量）
- 四个解析函数 + **一个去重函数** + **一个格式化函数** + 两个输出函数 + 一个断言函数 + `main` 入口（见 §类型定义/函数签名）
- `if __name__ == "__main__": main()` 入口
- 脚本含注释（模块文档字符串、函数文档字符串、关键步骤注释），落实用户偏好"代码包含必要的注释和文档"

**后置条件**：
- 文件存在于 `D:\CodeWorkspace\forMoonbit\pinyin\scripts\gen_pinyin_dict.py`
- 脚本可独立运行：`python scripts/gen_pinyin_dict.py`（工作目录为项目根目录）
- 运行后在 `data/` 目录重新生成 4 个 `.mbt` 文件
- 运行退出码 0（成功）或 1（断言失败）
- 运行时对 `chinese_dict` 打印 10 行 `[DEDUP]` 审计日志，对 `mutil_pinyin_dict` 打印 2 行，对其余两张字典不打印

### B. 解析契约（沿用 v3，不变）

**`parse_chinese_dict` 契约**：
- 输入：`D:\CodeWorkspace\forCangjie\pinyin4cj\src\chinese.dict.cj`（2556 行，UTF-8）
- 输出：`list[tuple[int, int]]`，长度 = 2543（**含重复 key**，去重前）
- 每条目：源 `(r'臺', r'台'),` → 目标 `(0x81FA, 0x53F0)` 即 `(ord('臺'), ord('台'))`

**`parse_string_dict` 契约（mutil_pinyin_dict）**：
- 输入：`D:\CodeWorkspace\forCangjie\pinyin4cj\src\mutil_pinyin.dict.cj`（858 行，UTF-8，**注意实际文件名**）
- 输出：`list[tuple[str, str]]`，长度 = 845（**含重复 key**，去重前）
- 每条目：源 `("阿訇", "ā,hōng"),` → 目标 `("阿訇", "ā,hōng")`（原样保留）

**`parse_string_dict` 契约（tongyong_pinyin_dict）**：
- 输入：`D:\CodeWorkspace\forCangjie\pinyin4cj\src\tongyong_pinyin_dict.cj`（92 行，UTF-8）
- 输出：`list[tuple[str, str]]`，长度 = 82（无重复 key）

**`parse_pinyin_dict` 契约**：
- 输入：`D:\CodeWorkspace\forCangjie\pinyin4cj\resource\pinyin.dict.txt`（41806 行，UTF-8）
- 输出：`list[tuple[str, str]]`，长度 = 20903（无重复 key）
- 解析：两行一组，奇数行汉字（key），偶数行拼音（value）

### C. 去重契约（v4 新增）

**`dedup_by_key` 契约**：

| 字典 | 输入长度（含重复） | 输出长度（去重后） | 丢弃条目数 | 审计日志行数 |
|------|------------------|------------------|-----------|-------------|
| `chinese_dict` | 2543 | 2533 | 10 | 10 |
| `mutil_pinyin_dict` | 845 | 843 | 2 | 2 |
| `tongyong_pinyin_dict` | 82 | 82 | 0 | 0 |
| `pinyin_dict` | 20903 | 20903 | 0 | 0 |

- **去重语义**：保留末次 value（与 MoonBit Map 字面量及源库 Cangjie `HashMap([...])` 构造语义一致）
- **审计日志格式**：`[DEDUP] {name}: key={key_repr}, kept_value={kept_repr}, dropped_value={dropped_repr}`（`{key_repr}` / `{kept_repr}` / `{dropped_repr}` 由 `format_repr()` 生成，非 `repr()`）
- **无重复 key 时**：直接返回原列表，不打印审计日志

### D. 输出契约（沿用 v3，条目数更新）

**`write_chinese_dict` 契约**：
- 输出文件：`D:\CodeWorkspace\forMoonbit\pinyin\data\chinese_dict.mbt`（UTF-8）
- 排序：按 Int key 升序
- 文件结构：
  ```moonbit
  /// 繁体→简体汉字码点映射，由 scripts/gen_pinyin_dict.py 从源库 chinese.dict.cj 生成。
  /// 共 2533 条，key 为繁体码点（Int），value 为简体码点（Int），16 进制字面量。
  /// 源库含 10 组重复繁体 key，已按末次 value 去重（与 MoonBit Map 字面量语义一致）。
  pub let chinese_dict : Map[Int, Int] = {
    0xXXXX: 0xYYYY,
    ...
  }
  ```
- 文件总行数：3（文档注释，含去重说明行）+ 1（声明）+ 2533（条目）+ 1（收尾）= 2538 行
- 每条目一行，缩进 2 空格，以逗号结尾

**`write_string_dict` 契约（mutil_pinyin_dict）**：
- 输出文件：`data/mutil_pinyin_dict.mbt`（UTF-8）
- 排序：按 String key 字典序
- 文件结构：
  ```moonbit
  /// 词组拼音映射，由 scripts/gen_pinyin_dict.py 从源库 mutil_pinyin.dict.cj 生成。
  /// 共 843 条，key 为词组（String），value 为逗号分隔拼音（含带调元音）。
  /// 源库含 2 组重复词组 key，已按末次 value 去重（与 MoonBit Map 字面量语义一致）。
  pub let mutil_pinyin_dict : Map[String, String] = {
    "key": "value",
    ...
  }
  ```
- 文件总行数：3（文档注释，含去重说明行）+ 1（声明）+ 843（条目）+ 1（收尾）= 848 行

**`write_string_dict` 契约（tongyong_pinyin_dict / pinyin_dict）**：
- 文档注释不变（无去重说明行），条目数 82 / 20903 不变
- 内容与 v3 字节级一致（无重复 key，去重无影响）

**确定性输出保证**（沿用 v3）：
- 四张字典均按 key 排序输出，多次运行产生字节级一致产物
- 去重逻辑确定性：相同输入产生相同输出（末次 value 唯一确定）

### E. 完整性断言契约（v4 更新）

**前置条件**：四张字典均已解析并去重完成。

**断言规则**（沿用 v3，严格相等，不使用约等于容差）：
- 四张字典均含精确条目数断言（去重后条目数）
- 断言值采用 v4 去重后值（见 §概述/实际条目数核对）：

| 字典 | 断言值 | 来源 |
|------|--------|------|
| `chinese_dict` | 2533 | v3 运行时 `Map.length()` 验证（去重 10 条） |
| `mutil_pinyin_dict` | 843 | v3 运行时 `Map.length()` 验证（去重 2 条） |
| `tongyong_pinyin_dict` | 82 | 无重复 key，与 v3 一致 |
| `pinyin_dict` | 20903 | 无重复 key，与 v3 一致 |

**断言时序**（v4 调整）：
1. 解析四张字典（含重复 key）
2. **按 key 去重，保留末次 value**（v4 新增）
3. **断言去重后条目数**（v4 调整：断言的是最终写入 `.mbt` 的条目数，须与运行时 `Map.length()` 一致）
4. 排序并写入 4 个 `.mbt` 文件

**断言失败处置**：`assert_count()` 打印实际与预期值并 `sys.exit(1)`。

### F. 测试文件断言更新契约（v4 新增）

**`chinese_dict_test.mbt` 修改契约**：
- 用例名：`chinese_dict_has_2543_entries` → `chinese_dict_has_2533_entries`
- 断言内容：`inspect(@data.chinese_dict.length(), content="2543")` → `inspect(@data.chinese_dict.length(), content="2533")`
- 文档注释同步：`2543 条` → `2533 条`，`条目第 13-2555 行共 2543 条` → `源库条目第 13-2555 行共 2543 条（含 10 组重复 key），去重后 2533 条`
- 其余 4 个用例（`maps_*` / `returns_none` / `valid_codepoints`）不变

**`mutil_pinyin_dict_test.mbt` 修改契约**：
- 用例名：`mutil_pinyin_dict_has_845_entries` → `mutil_pinyin_dict_has_843_entries`
- 断言内容：`inspect(@data.mutil_pinyin_dict.length(), content="845")` → `inspect(@data.mutil_pinyin_dict.length(), content="843")`
- 文档注释同步：`845 条` → `843 条`，`条目第 13-857 行共 845 条` → `源库条目第 13-857 行共 845 条（含 2 组重复 key），去重后 843 条`
- 其余 3 个用例（`maps_*` / `returns_none`）不变

**`tongyong_pinyin_dict_test.mbt` / `pinyin_dict_test.mbt`**：不变（无重复 key，断言值 82 / 20903 不变）

### G. 命名规范契约（沿用 v3，不变）

| 元素 | 命名 | 规范 | 源库对应 |
|------|------|------|---------|
| 脚本文件 | `gen_pinyin_dict.py` | lower_snake | — |
| 数据文件 | `chinese_dict.mbt` | lower_snake | `chinese.dict.cj` |
| 数据文件 | `mutil_pinyin_dict.mbt` | lower_snake | `mutil_pinyin.dict.cj` |
| 数据文件 | `tongyong_pinyin_dict.mbt` | lower_snake | `tongyong_pinyin_dict.cj` |
| 数据文件 | `pinyin_dict.mbt` | lower_snake | `pinyin.dict.txt` |
| MoonBit 常量 | `chinese_dict` | lower_snake | `chinese_dict` |
| MoonBit 常量 | `mutil_pinyin_dict` | lower_snake | `mutil_pinyin_dict` |
| MoonBit 常量 | `tongyong_pinyin_dict` | lower_snake | `tongyong_pinyin_dict` |
| MoonBit 常量 | `pinyin_dict` | lower_snake | `pinyin_dict` |
| Python 函数 | `parse_chinese_dict` / `dedup_by_key` / `format_repr` 等 | lower_snake | — |
| Python 常量 | `SOURCE_ROOT` / `EXPECTED_COUNTS` 等 | UPPER_SNAKE | — |
| 测试用例名 | `chinese_dict_has_2533_entries` | lower_snake | — |
| 测试用例名 | `mutil_pinyin_dict_has_843_entries` | lower_snake | — |

### H. 与已有代码的交互契约

**前置条件**：R1 产出的项目骨架 + R2 产出的基础类型 + R3 v3 产出的脚本与数据文件存在且 `moon check` 通过（exit code 0，2 warnings）。

**交互影响**：
- **`moon.mod`**：不受影响（本任务不修改）。
- **`moon.pkg`**：不受影响（本任务不修改）。
- **`data/moon.pkg`**：不受影响（本任务不修改）。
- **`pinyin_format.mbt` / `pinyin_error.mbt` / `pinyin_format_test.mbt` / `pinyin_error_test.mbt`**：不受影响（本任务不修改、不引用）。
- **`tongyong_pinyin_dict_test.mbt` / `pinyin_dict_test.mbt`**：不受影响（本任务不修改，断言值不变）。
- **`scripts/gen_pinyin_dict.py`**：本任务修改（增加 `dedup_by_key` 函数与 `format_repr` 格式化函数，更新 `EXPECTED_COUNTS`，调整 `main` 流程）。
- **`data/chinese_dict.mbt` / `data/mutil_pinyin_dict.mbt`**：本任务重新生成（去重后，条目数 2533 / 843，无重复 key）。
- **`data/tongyong_pinyin_dict.mbt` / `data/pinyin_dict.mbt`**：本任务重新生成（内容与 v3 字节级一致，无重复 key）。
- **`chinese_dict_test.mbt` / `mutil_pinyin_dict_test.mbt`**：本任务修改（断言值 2543→2533 / 845→843）。
- **`unused_package` 警告**：持续存在（主包非 test 源文件仍不引用 `@data.xxx`），与 R1/R2/R3 状态一致。
- **`text_segment_excceed` 警告**：持续存在（`pinyin_dict.mbt` 仍超 16384 行），与 v3 状态一致，本任务不处理。

**后置条件**：
- `scripts/gen_pinyin_dict.py` 含 `dedup_by_key` 函数与 `format_repr` 格式化函数，`EXPECTED_COUNTS` 为 `{chinese: 2533, mutil: 843, tongyong: 82, pinyin: 20903}`。
- `data/chinese_dict.mbt` 含 2533 条条目（无重复 key），`data/mutil_pinyin_dict.mbt` 含 843 条条目（无重复 key）。
- `data/tongyong_pinyin_dict.mbt` / `data/pinyin_dict.mbt` 内容与 v3 字节级一致。
- `chinese_dict_test.mbt` 断言 `content="2533"`，`mutil_pinyin_dict_test.mbt` 断言 `content="843"`。
- 其余文件与 R1/R2/R3 v3 产出完全一致（字节级不变）。

### I. 验证契约

**前置条件**：上述 7 个文件均已修改/重新生成（脚本已修改并运行生成 4 个 `.mbt` 文件，2 个测试文件已更新断言）。

**验证命令**（工作目录：`D:\CodeWorkspace\forMoonbit\pinyin`，即项目根目录）：

```sh
moon check
moon test
```

**预期输出**：

1. `moon check`：成功（exit code 0），2 warnings，0 errors：
   - `Warning (0029) (unused_package): Unused package 'pinyin/pinyin/data'`（预期，主包非 test 源文件未引用 `@data.xxx`）
   - `Warning (0033) (text_segment_excceed)`（预期，`pinyin_dict.mbt` 超 16384 行软限制，exit code 0 不阻断）

2. `moon test`：26 tests, passed 26, failed 0（全部通过）

**后置条件**：
- `moon check` exit code 0，2 warnings（均预期，不阻断）。
- `moon test` 26 tests 全部通过，0 失败。
- 四张字典运行时 `Map.length()` 分别为 2533 / 843 / 82 / 20903，与测试断言一致。
- 项目根目录结构在 v3 基础上：`scripts/gen_pinyin_dict.py` 已修改，`data/chinese_dict.mbt` / `data/mutil_pinyin_dict.mbt` 已重新生成（去重后），`chinese_dict_test.mbt` / `mutil_pinyin_dict_test.mbt` 已更新断言。

**警告治理**（沿用 v3，落实用户偏好"不忽略任何警告"）：

- **`Warning (0029) (unused_package)`**：
  - (a) 消息：`Unused package 'pinyin/pinyin/data'`
  - (b) 根因：主包非 test 源文件（`pinyin_format.mbt` / `pinyin_error.mbt`）均未引用 `@data.xxx`；test 块对 `@data.xxx` 的引用不计入包使用统计
  - (c) 处置：接受为预期警告，与 R1/R2/R3 状态一致，不阻断本任务验收
  - (d) 消除条件：R4 字典视图任务在主包非 test 源文件（`pinyin_dicts.mbt`）中引用 `@data.xxx` 后自动消除

- **`Warning (0033) (text_segment_excceed)`**：
  - (a) 消息：`Text segment is about to exceed the line limit. Consider mark ///| above the the top-level structures to splitting it into multiple segments.`
  - (b) 根因：`data/pinyin_dict.mbt` 共 20907 行（2 行文档 + 1 行声明 + 20903 条目 + 1 行收尾），Map 字面量体超过 16384 行软限制
  - (c) 处置：接受为预期警告（编译成功，exit code 0，不影响功能），本任务不处理
  - (d) 消除条件：需拆分 `pinyin_dict` 为多常量（设计变更，改变 `@data.pinyin_dict` 单一常量接口），留待 R4 字典视图任务或设计修订评估

## 依赖关系

### 本任务依赖的已有资源

| 资源 | 用途 |
|------|------|
| R1 产出：`moon.mod` / `moon.pkg` / `data/moon.pkg` | 模块与包配置（本任务不修改） |
| R2 产出：`pinyin_format.mbt` / `pinyin_error.mbt` 及测试 | 基础类型（本任务不修改） |
| R3 v3 产出：`scripts/gen_pinyin_dict.py` | 待修改的生成脚本（增加去重逻辑） |
| R3 v3 产出：`data/*.mbt` 4 个文件 | 待重新生成的数据文件（去重后） |
| R3 v3 产出：`chinese_dict_test.mbt` / `mutil_pinyin_dict_test.mbt` | 待修改的测试文件（更新断言） |
| R3 v3 产出：`tongyong_pinyin_dict_test.mbt` / `pinyin_dict_test.mbt` | 不变的测试文件（本任务不修改） |
| 源库：`src/chinese.dict.cj` | 繁→简字典转写输入（2556 行，2543 条目含 10 组重复 key） |
| 源库：`src/mutil_pinyin.dict.cj` | 词组拼音字典转写输入（858 行，845 条目含 2 组重复 key） |
| 源库：`src/tongyong_pinyin_dict.cj` | 通用拼音字典转写输入（92 行，82 条目无重复 key） |
| 源库：`resource/pinyin.dict.txt` | 单字拼音字典转写输入（41806 行，20903 组无重复 key） |
| Python 3 运行时 | 生成脚本执行环境 |
| MoonBit 语言：`pub let` + Map 字面量 | 数据子包常量定义语法 |

### 暴露给后续任务的公开接口

| 接口 | 消费任务 |
|------|---------|
| `@data.chinese_dict`（`Map[Int, Int]`，**2533 条**，去重后） | R4 字典视图构造（`pinyin_dicts.mbt`） |
| `@data.mutil_pinyin_dict`（`Map[String, String]`，**843 条**，去重后） | R4 字典视图构造 |
| `@data.tongyong_pinyin_dict`（`Map[String, String]`，82 条） | R4 字典视图构造 |
| `@data.pinyin_dict`（`Map[String, String]`，20903 条） | R4 字典视图构造 |
| `scripts/gen_pinyin_dict.py`（含去重逻辑与审计日志格式化） | 字典数据再生（源库更新后重跑脚本） |

**后续任务边界**（本任务不创建）：
- `pinyin_dicts.mbt`（R4 字典视图构造，引用 `@data.*`）
- `tone_conversion.mbt` / `pinyin_helper.mbt` / `chinese_helper.mbt` / `pinyin_spec.mbt`（R5-R8）
- 测试文件新增（R9+）
- `README.mbt.md` 填充（R10）
- `text_segment_excceed` 警告消除（设计变更，留待后续评估）

## 修订说明（v4 r1）

本任务为 R3 v3 失败后的首次 RETRY，基于 `verify_v3.md`（FAILED，24 passed / 2 failed）与 `test_v3.md`（失败用例原因分析 + 建议处置）修订设计。

| 审查意见（v3 失败根因） | 修改措施（v4） |
|------------------------|---------------|
| `chinese_dict` 运行时 2533 ≠ 预期 2543（差 10，源库含 10 组重复繁体 key） | 脚本增加 `dedup_by_key` 去重逻辑，保留末次 value；`EXPECTED_COUNTS["chinese_dict"]` 更新为 2533；测试断言 `content="2543"` → `content="2533"`，用例名同步更新 |
| `mutil_pinyin_dict` 运行时 843 ≠ 预期 845（差 2，源库含 2 组重复词组 key） | 同上，`EXPECTED_COUNTS["mutil_pinyin_dict"]` 更新为 843；测试断言 `content="845"` → `content="843"`，用例名同步更新 |
| v3 脚本 `parse_*` 收集所有条目（含重复 key），`write_*` 原样写入，MoonBit Map 字面量静默去重导致运行时数据丢失 | 脚本 `main` 流程调整为"解析→**去重**→断言→写入"，断言的是去重后条目数（= 写入条目数 = 运行时 `Map.length()`） |
| v3 `assert_count` 在去重前执行，漏检 Map 字面量去重 | 断言时序调整：先去重，再断言去重后条目数 |
| 去重语义须与源库 Cangjie `HashMap([...])` 一致 | 去重保留末次 value（MoonBit Map 字面量与 Cangjie HashMap 均取末次），语义保真 |
| 去重过程须可追溯 | `dedup_by_key` 对每个被丢弃的重复 key 打印审计日志：`[DEDUP] {name}: key=..., kept_value=..., dropped_value=...` |
| `tongyong_pinyin_dict` / `pinyin_dict` 无重复 key，不变 | 脚本重新生成（内容字节级不变），测试文件不修改 |
| `text_segment_excceed` 警告（`pinyin_dict.mbt` 超 16384 行） | 本任务不处理（exit code 0 不阻断），留待 R4 字典视图任务或设计修订评估 |
| `unused_package` 警告（主包非 test 源文件未引用 `@data.xxx`） | 接受为预期警告，与 R1/R2/R3 状态一致，R4 字典视图任务后消除 |

## 修订说明（v4 r2）

基于 `design_review_v4_r1.md`（REJECTED，5 项发现）修订设计。

| 审查意见 | 修改措施 | 采纳决策 |
|---------|---------|---------|
| **[严重]** `dedup_by_key` 等价实现建议 `dict(reversed(items))` 保留首次 value，与核心目标"保留末次 value"矛盾 | 删除错误的 `dict(reversed(items))` 建议；改为 `dict(items)`（正向构造，后者覆盖前者 = 保留末次 value），并显式标注"`dict(reversed(items))` 是错误等价实现，禁止使用"；保留"从右到左遍历首次保留"的正确描述不变 | **接受**。审查意见经 Python 实际执行验证，`dict(reversed(items))` 确实保留首次 value，与设计核心目标矛盾，必须修正 |
| **[一般]** 审计日志规格自相矛盾：声称用 `repr()` 形式，又要求"对 Int 显示十进制+十六进制" | 采用方案 B：新增 `format_repr(v)` 自定义格式化函数（非 `repr()`），Int 用 `f"{v} (0x{v:X})"`、String 用 `repr(v)`；明确标注"非 `repr()` 形式，而是自定义格式化"；同步更新 §去重逻辑规格、§去重契约、§函数签名、§命名规范、§交互契约、§后置条件、§公开接口 | **接受（方案 B）**。Int 码点十六进制有助于追溯繁简映射，`repr()` 无法满足；自定义格式化消除歧义 |
| **[轻微]** 测试文件文档注释更新保留旧行号"第 13-2555 行"，去重后实际行号已变 | 文档注释更新为 `源库条目第 13-2555 行共 2543 条（含 10 组重复 key），去重后 2533 条`，明确标注"源库"前缀以消除歧义 | **部分接受**。经核对测试文件原文，"第 13-2555 行"实为源库 `chinese.dict.cj` 的行号（源库未变，行号引用仍准确），非生成文件行号。但审查意见指出表述存在歧义风险，故添加"源库"前缀与"含 N 组重复 key"说明以消除歧义，保留源库行号引用不变 |
| **[轻微]** `dedup_by_key` 签名使用未定义的泛型类型变量 `K`、`V` | 新增 §模块导入 `from typing import TypeVar`；函数签名代码块首部添加 `K = TypeVar('K')` / `V = TypeVar('V')` 声明 | **接受**。补充类型变量声明使签名语法完整 |
| **[轻微]** 文件行数分类"2（文档注释）+ 1（去重说明注释）"与示例展示的 3 行 `///` 文档注释不一致 | 统一为"3（文档注释，含去重说明行）+ 1（声明）+ N（条目）+ 1（收尾）"，与示例展示形式一致 | **接受**。分类拆分应与示例展示形式一致，避免行数计算误解 |