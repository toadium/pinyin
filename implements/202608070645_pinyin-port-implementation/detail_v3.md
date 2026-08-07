# 详细设计（v3）

## 概述

本任务为 pinyin4cj → MoonBit 移植的**第三个编码任务**（R3），目标是创建 Python 3 生成脚本 `scripts/gen_pinyin_dict.py`，从源库 `D:\CodeWorkspace\forCangjie\pinyin4cj` 转写四张字典为 MoonBit 字面量，并运行脚本生成 4 个数据子包源文件：

1. `data/chinese_dict.mbt` — `pub let chinese_dict : Map[Int, Int]`，繁→简码点映射
2. `data/mutil_pinyin_dict.mbt` — `pub let mutil_pinyin_dict : Map[String, String]`，词组拼音
3. `data/tongyong_pinyin_dict.mbt` — `pub let tongyong_pinyin_dict : Map[String, String]`，通用拼音
4. `data/pinyin_dict.mbt` — `pub let pinyin_dict : Map[String, String]`，单字拼音

四张字典是后续全部算法实现（R4 字典视图、R5-R7 各 Helper）的底层数据依赖。本任务在 R1（骨架）+ R2（基础类型）产出的项目结构上新增 `scripts/` 目录与 `data/*.mbt` 4 个文件，**不修改**任何已有文件。完成后 `moon check` 应通过（exit code 0，1 warnings `unused_package` 预期——主包仍不引用 `@data.xxx`，R4 字典视图任务后消除）。

### 源库文件名勘误

task_v3.md §任务上下文/源库字典格式 第 69 行将词组拼音字典文件名写为 `src/mutil_pinyin_dict.cj`，**实际源库文件名为 `src/mutil_pinyin.dict.cj`**（点号位于 `pinyin` 与 `dict` 之间，而非 `mutil_pinyin` 与 `dict.cj` 之间）。设计阶段已通过 `ls src/` 确认。生成脚本须使用实际文件名 `mutil_pinyin.dict.cj`。

### 实际条目数核对

task_v3.md §验证契约 给出的预期条目数部分有误（将文件总行数或近似值误认为条目数）。设计阶段已用 Python 实际解析源库核对，真实条目数如下：

| 字典 | task_v3.md 预期 | 实际核对 | 差异原因 |
|------|----------------|---------|---------|
| `chinese_dict` | 2556 | **2543** | 2556 是文件总行数；条目为第 13-2555 行，共 2543 条 |
| `mutil_pinyin_dict` | 856 | **845** | 858 行 - 2（声明+收尾）= 856，但前 12 行含注释/package/import/let 声明，实际条目第 13-857 行共 845 条 |
| `tongyong_pinyin_dict` | 83 | **82** | 92 行去 9 行头（注释+package+import+空行+let 声明）+ 1 行收尾 = 82 条 |
| `pinyin_dict` | 20903 | **20903** | 41806 行 / 2 = 20903 组，精确匹配 |

task_v3.md §验证契约 明确授权："若与上述预期不符，脚本应打印实际计数并断言失败，由编码 agent 核对源库后修正预期值（而非放宽断言）。" 设计阶段已完成核对，**断言值采用实际核对值**（2543 / 845 / 82 / 20903）。

## 文件规划

| 文件路径 | 操作 | 职责 |
|---------|------|------|
| `scripts/gen_pinyin_dict.py` | 新建 | Python 3 生成脚本：解析源库四张字典 → 断言条目数 → 按 key 排序 → 写入 4 个 `.mbt` 字面量文件 |
| `data/chinese_dict.mbt` | 新建（脚本生成） | `pub let chinese_dict : Map[Int, Int]`，2543 条繁→简码点映射（16 进制字面量） |
| `data/mutil_pinyin_dict.mbt` | 新建（脚本生成） | `pub let mutil_pinyin_dict : Map[String, String]`，845 条词组拼音 |
| `data/tongyong_pinyin_dict.mbt` | 新建（脚本生成） | `pub let tongyong_pinyin_dict : Map[String, String]`，82 条通用拼音 |
| `data/pinyin_dict.mbt` | 新建（脚本生成） | `pub let pinyin_dict : Map[String, String]`，20903 条单字拼音 |

**说明**：
- 路径均相对项目根目录 `D:\CodeWorkspace\forMoonbit\pinyin`。
- `scripts/` 为新建目录，仅含 Python 脚本，非 MoonBit 包成员（`moon` 工具链不扫描 `.py` 文件）。
- `data/*.mbt` 4 个文件位于数据子包 `data/` 目录内，被 `data/moon.pkg` 自动识别为源文件（R1 产出，已存在且零依赖）。
- 本任务**不修改** `moon.mod` / `moon.pkg` / `data/moon.pkg` / `README.mbt.md` / `README.md` / `pinyin_format.mbt` / `pinyin_error.mbt` / `pinyin_format_test.mbt` / `pinyin_error_test.mbt`（R1/R2 产出保持不变）。
- 本任务**不创建**后续任务文件（`pinyin_dicts.mbt` / `tone_conversion.mbt` / `pinyin_helper.mbt` / `chinese_helper.mbt` / `pinyin_spec.mbt` / 测试文件等）— 避免过度设计。

## 类型定义

本任务涉及两类"类型"：Python 脚本的函数签名（脚本本身）与 MoonBit 数据常量签名（生成产物）。

### Python 脚本模块结构（`scripts/gen_pinyin_dict.py`）

**形态**：Python 3 模块脚本（`if __name__ == "__main__": main()` 入口）
**职责**：解析源库四张字典，断言条目数，按 key 排序，写入 4 个 `.mbt` 字面量文件

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

# 预期条目数（设计阶段实际核对值，见 §概述/实际条目数核对）
EXPECTED_COUNTS: dict[str, int] = {
    "chinese_dict": 2543,
    "mutil_pinyin_dict": 845,
    "tongyong_pinyin_dict": 82,
    "pinyin_dict": 20903,
}
```

#### 函数签名

```python
def parse_chinese_dict(src_path: str) -> list[tuple[int, int]]:
    """解析 chinese.dict.cj，提取 (r'X', r'Y') 条目，
    返回 [(ord(X), ord(Y)), ...] 的码点对列表。"""

def parse_string_dict(src_path: str) -> list[tuple[str, str]]:
    """解析 mutil_pinyin.dict.cj 或 tongyong_pinyin_dict.cj，
    提取 ("key", "value") 条目，返回 [(key, value), ...] 列表。"""

def parse_pinyin_dict(src_path: str) -> list[tuple[str, str]]:
    """解析 pinyin.dict.txt（两行一组：汉字 / 拼音读音），
    返回 [(汉字, 拼音), ...] 列表。"""

def write_chinese_dict(items: list[tuple[int, int]], out_path: str) -> None:
    """将码点对列表按 Int key 升序排序后，
    写入 chinese_dict.mbt 为 `pub let chinese_dict : Map[Int, Int] = { 0xXXXX: 0xYYYY, ... }`。"""

def write_string_dict(var_name: str, items: list[tuple[str, str]], out_path: str) -> None:
    """将字符串对列表按 String key 字典序排序后，
    写入 .mbt 为 `pub let {var_name} : Map[String, String] = { "k": "v", ... }`。"""

def assert_count(name: str, actual: int, expected: int) -> None:
    """断言 actual == expected。不等则打印实际与预期值并 sys.exit(1)。"""

def main() -> None:
    """主函数：解析四张字典 → 断言条目数 → 排序 → 写入 4 个 .mbt 文件 → 打印生成摘要。"""
```

#### 解析逻辑规格

**`parse_chinese_dict`**：
- 输入文件编码：UTF-8（显式 `encoding="utf-8"`）
- 逐行扫描，正则匹配 `r'\(r\'(.)\'\s*,\s*r\'(.)\'\)'`（单字符 Rune 字面量）
- 对每条匹配，提取繁体字符 X 与简体字符 Y，转换为 `(ord(X), ord(Y))` 码点对
- 跳过非匹配行（注释、声明、空行、`])` 收尾行）
- 返回码点对列表

**`parse_string_dict`**：
- 输入文件编码：UTF-8（显式 `encoding="utf-8"`）
- 逐行扫描，正则匹配 `r'\("(.+?)"\s*,\s*"(.+?)"\)'`（字符串字面量，非贪婪匹配）
- 对每条匹配，提取 key 与 value 原样保留（含带调元音 UTF-8 字符）
- 跳过非匹配行
- 返回字符串对列表

**`parse_pinyin_dict`**：
- 输入文件编码：UTF-8（显式 `encoding="utf-8"`）
- 逐行读取，两行一组：奇数行为汉字（key），偶数行为拼音读音（value，逗号分隔多音）
- 跳过空行（若有）
- 返回 `[(汉字, 拼音), ...]` 列表，长度 = 行数 / 2

#### 输出格式规格

**`write_chinese_dict`**：
- 输出文件编码：UTF-8（显式 `encoding="utf-8"`）
- 按 Int key 升序排序（`sorted(items, key=lambda kv: kv[0])`）
- 文件头部：`///` 文档注释（说明来源、条目数、生成脚本）
- 常量声明：`pub let chinese_dict : Map[Int, Int] = {`
- 每条目一行：`  0xXXXX: 0xYYYY,`（16 进制大写码点，4 位以上不补零，直接 `hex()` 输出 `0x` 前缀小写或格式化为大写）
- 文件尾部：`}`
- 码点格式化：`f"0x{cp:X}"` 输出大写 16 进制（如 `0x81FA`）

**`write_string_dict`**：
- 输出文件编码：UTF-8（显式 `encoding="utf-8"`）
- 按 String key 字典序排序（`sorted(items, key=lambda kv: kv[0])`）
- 文件头部：`///` 文档注释
- 常量声明：`pub let {var_name} : Map[String, String] = {`
- 每条目一行：`  "key": "value",`（字符串字面量，key/value 中若含 `"` 需转义，但拼音数据不含 `"`，无需转义）
- 文件尾部：`}`

### MoonBit 数据常量签名（生成产物）

四个 `.mbt` 文件各定义一个 `pub let` 顶层常量，位于数据子包 `pinyin/pinyin/data`：

#### chinese_dict

**形态**：`pub let` 顶层绑定，`Map[Int, Int]` 字面量
**包路径**：`pinyin/pinyin/data`
**职责**：繁体→简体汉字码点映射

```moonbit
/// 繁体→简体汉字码点映射，由 scripts/gen_pinyin_dict.py 从源库 chinese.dict.cj 生成。
/// 共 2543 条，key 为繁体码点（Int），value 为简体码点（Int），16 进制字面量。
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
/// 共 845 条，key 为词组（String），value 为逗号分隔拼音（含带调元音）。
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

**可见性决策**：四个常量均使用 `pub let`（非 `pub(self) let`）。理由（task_v3.md §MoonBit Map 字面量语法 已确认）：
1. `pub(self) let` 仅当前包可见，主包无法通过 `@data` 引用，会阻断 R4 字典视图任务。
2. `pub let` 是最小充分可见性，数据子包常量是纯数据（`Map[Int,Int]` / `Map[String,String]`），无内部成员需公开，`pub let` 足矣，无需 `pub(all) let`。
3. 已查阅 wiki `language/packages.md:79-80` 确认：`pub` modifier 使 toplevel `let` 对其他包可见（可读取），符合跨包 `@data` 引用场景。

## 错误处理

本任务为**数据生成脚本**，错误处理采用 Python 惯例（异常 + 断言），不涉及 MoonBit `raise`/`catch`。

### 脚本错误处理策略

| 错误模式 | 检测方式 | 处置 |
|---------|---------|------|
| 源库文件不存在 | `open()` 抛 `FileNotFoundError` | 脚本自然终止，exit code ≠ 0；编码 agent 检查源库路径 |
| 源库文件编码错误 | `open(..., encoding="utf-8")` 抛 `UnicodeDecodeError` | 脚本自然终止；编码 agent 检查源库文件编码 |
| 条目数与预期不符 | `assert_count()` 显式断言 | 打印实际与预期值，`sys.exit(1)`；编码 agent 核对后修正 `EXPECTED_COUNTS` |
| 正则匹配零条目 | 解析后列表为空 → `assert_count` 断言失败 | 同上，提示正则或源库格式问题 |
| 输出目录不存在 | `open(out_path, "w")` 抛 `FileNotFoundError` | 脚本自然终止；编码 agent 确认 `data/` 目录存在（R1 已创建） |

### 生成产物（.mbt）错误处理

四个 `.mbt` 文件为纯数据字面量，**无运行时错误路径**：
- `Map` 字面量构造不抛错（MoonBit 内置 Map 字面量语法，编译期完成）
- 无方法、无逻辑、无 `raise` 声明
- 唯一可能的编译期错误：Map 字面量语法错误（由 `moon check` 检测，见 §行为契约/E 验证契约）

### 验证阶段潜在失败模式与处置

| 失败模式 | 根因 | 处置 |
|---------|------|------|
| Python 脚本运行失败（`FileNotFoundError`） | 源库路径错误或源库文件名变动 | 核对 `SOURCE_ROOT` 与源库文件名（注意 `mutil_pinyin.dict.cj` 实际文件名） |
| Python 脚本断言失败（条目数不符） | 正则匹配遗漏条目，或 `EXPECTED_COUNTS` 值有误 | 脚本打印实际计数，编码 agent 核对源库后修正正则或预期值 |
| `moon check` 报告 `data/*.mbt` 语法错误 | Map 字面量语法拼写、`pub let` 修饰符、类型标注 | 对照 wiki `stdlib/builtin.md:115` `let m : Map[String, Int] = { "a": 1, "b": 2 }` 示例与本文 §类型定义 签名修正 |
| `moon check` 报告 `unused_package` 警告 | 主包源文件未引用 `@data.xxx` | **预期警告**：接受，不阻断本任务验收；R4 字典视图任务后消除 |

## 行为契约

### A. `scripts/gen_pinyin_dict.py` 内容契约

**前置条件**：项目根目录 `D:\CodeWorkspace\forMoonbit\pinyin` 存在且可写；源库 `D:\CodeWorkspace\forCangjie\pinyin4cj` 存在且可读；`data/` 目录已存在（R1 产出）。

**文件内容要求**：
- Python 3 脚本，UTF-8 编码（文件头可含 `# -*- coding: utf-8 -*-`，非强制）
- 所有文件读写显式指定 `encoding="utf-8"`（强制，task_v3.md §MoonBit Map 字面量语法/生成脚本编码要求）
- 模块级常量定义源库路径、输出路径、预期条目数（见 §类型定义/模块级常量）
- 四个解析函数 + 两个输出函数 + 一个断言函数 + `main` 入口（见 §类型定义/函数签名）
- `if __name__ == "__main__": main()` 入口
- 脚本含注释（模块文档字符串、函数文档字符串、关键步骤注释），落实用户偏好"代码包含必要的注释和文档"

**后置条件**：
- 文件存在于 `D:\CodeWorkspace\forMoonbit\pinyin\scripts\gen_pinyin_dict.py`
- 脚本可独立运行：`python scripts/gen_pinyin_dict.py`（工作目录为项目根目录）
- 运行后在 `data/` 目录生成 4 个 `.mbt` 文件
- 运行退出码 0（成功）或 1（断言失败）

### B. 解析契约

**`parse_chinese_dict` 契约**：
- 输入：`D:\CodeWorkspace\forCangjie\pinyin4cj\src\chinese.dict.cj`（2556 行，UTF-8）
- 输出：`list[tuple[int, int]]`，长度 = 2543
- 每条目：源 `(r'臺', r'台'),` → 目标 `(0x81FA, 0x53F0)` 即 `(ord('臺'), ord('台'))`
- 正则：`r'\(r\'(.)\'\s*,\s*r\'(.)\'\)'`（单字符 Rune，`.` 匹配任意非换行字符）

**`parse_string_dict` 契约（mutil_pinyin_dict）**：
- 输入：`D:\CodeWorkspace\forCangjie\pinyin4cj\src\mutil_pinyin.dict.cj`（858 行，UTF-8，**注意实际文件名**）
- 输出：`list[tuple[str, str]]`，长度 = 845
- 每条目：源 `("阿訇", "ā,hōng"),` → 目标 `("阿訇", "ā,hōng")`（原样保留）
- 正则：`r'\("(.+?)"\s*,\s*"(.+?)"\)'`（非贪婪字符串匹配）

**`parse_string_dict` 契约（tongyong_pinyin_dict）**：
- 输入：`D:\CodeWorkspace\forCangjie\pinyin4cj\src\tongyong_pinyin_dict.cj`（92 行，UTF-8）
- 输出：`list[tuple[str, str]]`，长度 = 82
- 每条目：源 `("chi", "chih"),` → 目标 `("chi", "chih")`（纯 ASCII）
- 正则：同上

**`parse_pinyin_dict` 契约**：
- 输入：`D:\CodeWorkspace\forCangjie\pinyin4cj\resource\pinyin.dict.txt`（41806 行，UTF-8）
- 输出：`list[tuple[str, str]]`，长度 = 20903
- 解析：两行一组，奇数行汉字（key），偶数行拼音（value）
- 示例：第 1-2 行 `〇` / `líng` → `("〇", "líng")`；第 5-6 行 `丁` / `dīng,zhēng` → `("丁", "dīng,zhēng")`

### C. 输出契约

**`write_chinese_dict` 契约**：
- 输出文件：`D:\CodeWorkspace\forMoonbit\pinyin\data\chinese_dict.mbt`（UTF-8）
- 排序：按 Int key 升序（`sorted(items, key=lambda kv: kv[0])`）
- 文件结构：
  ```moonbit
  /// 繁体→简体汉字码点映射，由 scripts/gen_pinyin_dict.py 从源库 chinese.dict.cj 生成。
  /// 共 2543 条，key 为繁体码点（Int），value 为简体码点（Int），16 进制字面量。
  pub let chinese_dict : Map[Int, Int] = {
    0xXXXX: 0xYYYY,
    ...
  }
  ```
- 码点格式：`f"0x{cp:X}"`（大写 16 进制，如 `0x81FA`）
- 每条目一行，缩进 2 空格，以逗号结尾

**`write_string_dict` 契约（mutil_pinyin_dict / tongyong_pinyin_dict / pinyin_dict）**：
- 输出文件：`data/mutil_pinyin_dict.mbt` / `data/tongyong_pinyin_dict.mbt` / `data/pinyin_dict.mbt`（UTF-8）
- 排序：按 String key 字典序（`sorted(items, key=lambda kv: kv[0])`）
- 文件结构：
  ```moonbit
  /// {文档注释说明}
  pub let {var_name} : Map[String, String] = {
    "key": "value",
    ...
  }
  ```
- 每条目一行，缩进 2 空格，以逗号结尾

**确定性输出保证**（task_v3.md §MoonBit Map 字面量语法/生成脚本确定性输出要求）：
- 四张字典均按 key 排序输出，多次运行产生字节级一致产物
- `chinese_dict`：按 Int key 升序
- 其余三张：按 String key 字典序

### D. 完整性断言契约

**前置条件**：四张字典均已解析完成。

**断言规则**（task_v3.md §验证契约/完整性校验）：
- 四张字典均含精确条目数断言（严格相等，**不使用约等于容差**）
- 断言值采用设计阶段实际核对值（见 §概述/实际条目数核对）：

| 字典 | 断言值 | 来源 |
|------|--------|------|
| `chinese_dict` | 2543 | 设计阶段 Python 实际解析计数 |
| `mutil_pinyin_dict` | 845 | 设计阶段 Python 实际解析计数 |
| `tongyong_pinyin_dict` | 82 | 设计阶段 Python 实际解析计数 |
| `pinyin_dict` | 20903 | 41806 行 / 2 = 20903 组（精确值） |

**断言失败处置**：`assert_count()` 打印实际与预期值并 `sys.exit(1)`，编码 agent 核对源库后修正 `EXPECTED_COUNTS`（而非放宽断言）。

### E. 命名规范契约

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
| Python 函数 | `parse_chinese_dict` 等 | lower_snake | — |
| Python 常量 | `SOURCE_ROOT` 等 | UPPER_SNAKE | — |

### F. 与已有代码的交互契约

**前置条件**：R1 产出的项目骨架 + R2 产出的基础类型存在且 `moon check` 通过（exit code 0，1 warnings `unused_package`）。

**交互影响**：
- **`moon.mod`**：不受影响（本任务不修改；新 `.mbt` 文件由 `moon` 自动发现）。
- **`moon.pkg`**：不受影响（本任务不修改；不新增 `import`，主包仍不引用 `@data.xxx`）。
- **`data/moon.pkg`**：不受影响（本任务不修改；`data/` 目录新增 4 个 `.mbt` 文件被 `moon` 自动识别为数据子包源文件）。
- **`pinyin_format.mbt` / `pinyin_error.mbt` / 测试文件**：不受影响（本任务不修改、不引用）。
- **`unused_package` 警告**：持续存在（主包仍不引用 `@data.xxx`），与 R1/R2 状态一致，处置见 §行为契约/G 验证契约。

**后置条件**：
- 项目根目录新增 `scripts/` 目录（含 `gen_pinyin_dict.py`）。
- `data/` 目录新增 4 个 `.mbt` 文件（`chinese_dict.mbt` / `mutil_pinyin_dict.mbt` / `tongyong_pinyin_dict.mbt` / `pinyin_dict.mbt`）。
- 其余文件与 R1/R2 产出完全一致（字节级不变）。
- 数据子包现含 4 个源文件，定义 4 个公开常量（`pub let`）。

### G. 验证契约

**前置条件**：上述 5 个文件均已创建（脚本已编写并运行生成 4 个 `.mbt` 文件）。

**验证命令**（工作目录：`D:\CodeWorkspace\forMoonbit\pinyin`，即项目根目录）：

```sh
moon check
```

**预期输出**：成功（exit code 0），无错误。预期产生 `Warning (0029) (unused_package): Unused package 'pinyin/pinyin/data'`（根因：主包源文件未引用 `@data.xxx`，与 R1/R2 状态一致）。

**后置条件**：
- `moon check` exit code 0。
- 项目根目录结构在 R1/R2 基础上新增 `scripts/gen_pinyin_dict.py` 与 `data/*.mbt` 4 个文件。
- 数据子包含 4 个 `pub let` 常量，类型分别为 `Map[Int, Int]` 与 3 个 `Map[String, String]`。
- 四张字典条目数分别为 2543 / 845 / 82 / 20903。

**警告治理**（针对 `unused_package`，落实用户偏好"不忽略任何警告"）：
- (a) 警告类型与消息文本：`Warning (0029) (unused_package): Unused package 'pinyin/pinyin/data'`
- (b) 根因：主包源文件（`pinyin_format.mbt` / `pinyin_error.mbt`）均未引用 `@data.xxx` → import 的数据子包未被引用
- (c) 处置决策：接受为预期警告，不阻断本任务验收（与 R1/R2 状态一致）
- (d) 消除条件：后续 R4 字典视图任务（`pinyin_dicts.mbt` 引用 `@data.xxx`）后警告自动消除
- (e) 记录方式：在验证产出中记录警告原文与处置决策

**不执行的验证**（属后续任务）：
- `moon test`（本任务无测试文件，数据子包纯数据无公开行为 API；测试在后续算法实现任务中编写）。

## 依赖关系

### 本任务依赖的已有资源

| 资源 | 用途 |
|------|------|
| R1 产出：`moon.mod` | 模块根元数据，`moon` 工具链识别主包与数据子包 |
| R1 产出：`moon.pkg` | 主包配置，`import "pinyin/pinyin/data"`（本任务不引用但保留） |
| R1 产出：`data/moon.pkg` | 数据子包配置（零依赖，本任务新增 4 个 `.mbt` 文件被自动识别） |
| 源库：`src/chinese.dict.cj` | 繁→简字典转写输入（2556 行，2543 条目） |
| 源库：`src/mutil_pinyin.dict.cj` | 词组拼音字典转写输入（858 行，845 条目，**注意实际文件名**） |
| 源库：`src/tongyong_pinyin_dict.cj` | 通用拼音字典转写输入（92 行，82 条目） |
| 源库：`resource/pinyin.dict.txt` | 单字拼音字典转写输入（41806 行，20903 组） |
| Python 3 运行时 | 生成脚本执行环境 |
| MoonBit 语言：`pub let` + Map 字面量 | 数据子包常量定义语法，参考 wiki `stdlib/builtin.md:115` `let m : Map[String, Int] = { "a": 1, "b": 2 }` |

### 暴露给后续任务的公开接口

| 接口 | 消费任务 |
|------|---------|
| `@data.chinese_dict`（`Map[Int, Int]`，2543 条） | R4 字典视图构造（`pinyin_dicts.mbt`） |
| `@data.mutil_pinyin_dict`（`Map[String, String]`，845 条） | R4 字典视图构造 |
| `@data.tongyong_pinyin_dict`（`Map[String, String]`，82 条） | R4 字典视图构造 |
| `@data.pinyin_dict`（`Map[String, String]`，20903 条） | R4 字典视图构造 |
| `scripts/gen_pinyin_dict.py` | 字典数据再生（源库更新后重跑脚本） |

**后续任务边界**（本任务不创建）：
- `pinyin_dicts.mbt`（R4 字典视图构造，引用 `@data.*`）
- `tone_conversion.mbt`（R5 声调转换内部逻辑）
- `pinyin_helper.mbt`（R6 PinyinHelper 关联方法）
- `chinese_helper.mbt`（R7 ChineseHelper 关联方法）
- `pinyin_spec.mbt`（R8 形式化契约）
- 测试文件（R9+）
- `README.mbt.md` 填充（R10）