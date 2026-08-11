# 详细设计（v6）

## 概述

本任务为 pinyin4cj → MoonBit 移植 R5（声调格式转换内部逻辑）。在主包根目录新建 `tone_conversion.mbt`，实现源库 `pinyin_helper.cj` 中 5 个 static 内部方法 + 3 个辅助常量，并新建 `tone_conversion_test.mbt` 覆盖 5 函数核心行为与边界。

### 设计目标

1. 实现声调转换底层函数，为 R6（`pinyin_helper.mbt` 拼音转换主流程）提供可调用的包内函数：`format_pinyin` / `convert_to_pinyin_arrays` 被 R6 公开方法调用
2. 5 函数行为逐音节/逐字符对齐源库 `pinyin_helper.cj:29-123` + `:279-289`，保留关键语义（如 `convert_with_tone_number` 每音节仅处理首个带调元音的 `break` 行为）
3. 采用 `inspect` 快照测试验证，覆盖 5 函数核心路径与边界（空字典命中、多音节切分、ü→v 替换、4 声调映射）

### 设计范围

- **新建两个文件**：`tone_conversion.mbt`（实现）+ `tone_conversion_test.mbt`（测试），均位于主包根目录
- **不修改**任何已有文件（R1/R2/R3 v4/R4 产出保持不变）
- **不处理** `text_segment_excceed` 警告（`data/pinyin_dict.mbt` 超 16384 行，设计变更，本任务不处理）

### 移植映射

对应源库 `pinyin_helper.cj:13-16`（辅助常量）+ `:29-55`（`convertWithToneNumber`）+ `:63-73`（`convertWithoutTone`）+ `:82-93`（`formatPinyin`）+ `:117-123`（`convertToPinyinArrays`）+ `:279-289`（`findArrayKeyByValue`）。源库用 Cangjie `String.replace`（替换所有匹配）→ MoonBit `String::replace_all`；源库 `toRuneArray()` → MoonBit `String::to_array`；源库 `String.split` 返回 `Array[String]` → MoonBit `String::split` 返回 `Iter[StringView]` 需转换。

## 文件规划

| 文件路径 | 操作 | 职责 |
|---------|------|------|
| `tone_conversion.mbt` | **新建** | 3 个辅助常量 + 5 个 `pub(self) fn` 内部函数，实现声调格式转换底层逻辑 |
| `tone_conversion_test.mbt` | **新建** | `inspect` 快照测试，覆盖 5 函数核心行为与边界（约 21 用例） |

**说明**：
- 路径相对项目根目录 `D:\CodeWorkspace\forMoonbit\pinyin`。
- 本任务**不修改**以下文件（R1/R2/R3 v4/R4 产出保持不变）：`moon.mod` / `moon.pkg` / `data/*` / `pinyin_format.mbt` / `pinyin_error.mbt` / `pinyin_dicts.mbt` / 所有已有测试文件 / `README.mbt.md` / `README.md` / `scripts/gen_pinyin_dict.py`。

## 类型定义

本任务仅涉及 MoonBit 顶层 `let` 常量绑定 + 顶层函数定义，无自定义类型。`PinyinFormat` 枚举由 R2 `pinyin_format.mbt` 提供，本任务引用。

### pinyin_separator

**形态**：`pub let` 顶层绑定，`String` 常量
**包路径**：`pinyin/pinyin`（主包根目录）
**职责**：拼音分隔符，跨文件共享（R6 `pinyin_helper.mbt` 亦用）

```moonbit
pub let pinyin_separator : String = ","
```

**公开接口**：`pinyin_separator : String`（`pub let` 顶层常量，跨包可引用）
**构造方式**：构建期字符串字面量
**类型关系**：无

### all_unmarked_vowel_array

**形态**：`let` 顶层绑定，`Array[Char]` 常量
**包路径**：`pinyin/pinyin`（主包根目录）
**职责**：无调元音数组，文件内私有（仅 `tone_conversion.mbt` 内 5 函数使用）

```moonbit
let all_unmarked_vowel_array : Array[Char] = ['a', 'e', 'i', 'o', 'u', 'v']
```

**公开接口**：无（`let` 文件内私有）
**构造方式**：构建期数组字面量
**类型关系**：与 `all_marked_vowel_array` 按索引分组对应（`all_marked_vowel_array[i]` 的无调形式为 `all_unmarked_vowel_array[(i - i % 4) / 4]`）

### all_marked_vowel_array

**形态**：`let` 顶层绑定，`Array[Char]` 常量
**包路径**：`pinyin/pinyin`（主包根目录）
**职责**：带调元音数组（24 个，6 元音 × 4 声调），文件内私有

```moonbit
let all_marked_vowel_array : Array[Char] = [
  'ā', 'á', 'ǎ', 'à',  // a 的 4 声调
  'ē', 'é', 'ě', 'è',  // e 的 4 声调
  'ī', 'í', 'ǐ', 'ì',  // i 的 4 声调
  'ō', 'ó', 'ǒ', 'ò',  // o 的 4 声调
  'ū', 'ú', 'ǔ', 'ù',  // u 的 4 声调
  'ǖ', 'ǘ', 'ǚ', 'ǜ',  // ü 的 4 声调
]
```

**公开接口**：无（`let` 文件内私有）
**构造方式**：构建期数组字面量
**类型关系**：与 `all_unmarked_vowel_array` 按索引分组对应；索引 `i` 的声调号为 `i % 4 + 1`，无调元音索引为 `(i - i % 4) / 4`

### find_array_key_by_value

**形态**：`pub(self) fn` 顶层函数
**包路径**：`pinyin/pinyin`（主包根目录）
**职责**：在 `all_marked_vowel_array` 中查找字符索引，未找到返回 -1

```moonbit
pub(self) fn find_array_key_by_value(ch : Char) -> Int
```

**公开接口**：`find_array_key_by_value(ch : Char) -> Int`（`pub(self) fn`，包内跨文件可见）
**构造方式**：顶层函数定义
**类型关系**：被 `convert_with_tone_number` 调用

### convert_with_tone_number

**形态**：`pub(self) fn` 顶层函数
**包路径**：`pinyin/pinyin`（主包根目录）
**职责**：带调拼音 → 数字调拼音数组（每音节仅处理首个带调元音，未找到则追加 "5"）

```moonbit
pub(self) fn convert_with_tone_number(str : String) -> Array[String]
```

**公开接口**：`convert_with_tone_number(str : String) -> Array[String]`（`pub(self) fn`，包内跨文件可见）
**构造方式**：顶层函数定义
**类型关系**：调用 `find_array_key_by_value`；被 `format_pinyin` 调用

### convert_without_tone

**形态**：`pub(self) fn` 顶层函数
**包路径**：`pinyin/pinyin`（主包根目录）
**职责**：带调拼音 → 无调拼音数组（逐字符替换所有带调元音 + ü→v）

```moonbit
pub(self) fn convert_without_tone(str : String) -> Array[String]
```

**公开接口**：`convert_without_tone(str : String) -> Array[String]`（`pub(self) fn`，包内跨文件可见）
**构造方式**：顶层函数定义
**类型关系**：被 `format_pinyin` 调用

### format_pinyin

**形态**：`pub(self) fn` 顶层函数
**包路径**：`pinyin/pinyin`（主包根目录）
**职责**：按 `PinyinFormat` 分发格式转换（`match` 模式匹配）

```moonbit
pub(self) fn format_pinyin(str : String, format : PinyinFormat) -> Array[String]
```

**公开接口**：`format_pinyin(str : String, format : PinyinFormat) -> Array[String]`（`pub(self) fn`，包内跨文件可见）
**构造方式**：顶层函数定义
**类型关系**：参数类型 `PinyinFormat` 来自 R2 `pinyin_format.mbt`；调用 `convert_with_tone_number` / `convert_without_tone`；被 R6 `pinyin_helper.mbt` 公开方法调用

### convert_to_pinyin_arrays

**形态**：`pub(self) fn` 顶层函数
**包路径**：`pinyin/pinyin`（主包根目录）
**职责**：单字转拼音数组（查 `pinyin_table`，命中则 `format_pinyin`，未命中返回空数组）

```moonbit
pub(self) fn convert_to_pinyin_arrays(c : Char, format : PinyinFormat) -> Array[String]
```

**公开接口**：`convert_to_pinyin_arrays(c : Char, format : PinyinFormat) -> Array[String]`（`pub(self) fn`，包内跨文件可见）
**构造方式**：顶层函数定义
**类型关系**：引用 R4 `pinyin_table`（`pub let`，`Map[String, String]`）；调用 `format_pinyin`；被 R6 `pinyin_helper.mbt` 主流程逐字符调用

### 可见性决策

| 符号 | 可见性 | 理由 |
|------|--------|------|
| `pinyin_separator` | `pub let` | 跨文件共享（R6 `pinyin_helper.mbt` 主流程亦用此分隔符）。`pub(self) let` 语法不合法（Error [3005]，R4 已验证），妥协为 `pub let` 公共常量暴露，同 R4 字典视图决策 |
| `all_unmarked_vowel_array` | `let` | 文件内私有。仅 `tone_conversion.mbt` 内 5 函数使用，无需跨文件暴露 |
| `all_marked_vowel_array` | `let` | 文件内私有。同上 |
| 5 个函数 | `pub(self) fn` | 包内跨文件可见。R6 `pinyin_helper.mbt` 需调用 `format_pinyin` / `convert_to_pinyin_arrays`。`pub(self) fn` 对函数合法（与 `pub(self) let` 对顶层常量不合法不同）。若 `pub(self) fn` 编译不通过，退用 `pub fn`（接受内部函数作为公开 API 暴露的妥协，同 `pinyin_separator` 的 `pub let` 妥协逻辑），并在实现报告中记录偏差 |

### 命名映射

| 源库 | MoonBit | 可见性 | 源码位置 |
|------|---------|--------|---------|
| `PINYIN_SEPARATOR` | `pinyin_separator` | `pub let` | pinyin_helper.cj:13 |
| `ALL_UNMARKED_VOWEL_ARRAY` | `all_unmarked_vowel_array` | `let` | pinyin_helper.cj:14 |
| `ALL_MARKED_VOWEL_ARRAY` | `all_marked_vowel_array` | `let` | pinyin_helper.cj:15-16 |
| `findArrayKeyByValue` | `find_array_key_by_value` | `pub(self) fn` | pinyin_helper.cj:279-289 |
| `convertWithToneNumber` | `convert_with_tone_number` | `pub(self) fn` | pinyin_helper.cj:29-55 |
| `convertWithoutTone` | `convert_without_tone` | `pub(self) fn` | pinyin_helper.cj:63-73 |
| `formatPinyin` | `format_pinyin` | `pub(self) fn` | pinyin_helper.cj:82-93 |
| `convertToPinyinArrays` | `convert_to_pinyin_arrays` | `pub(self) fn` | pinyin_helper.cj:117-123 |

## 错误处理

本任务 5 函数均为**纯计算函数，无运行时错误路径**：

| 潜在错误模式 | 检测方式 | 处置 |
|-------------|---------|------|
| `PinyinFormat` 枚举不存在 | `moon check` 编译期检测 | 编译失败（前置条件：R2 已定义 `pub(all) enum PinyinFormat`） |
| `pinyin_table` 不存在 | `moon check` 编译期检测 | 编译失败（前置条件：R4 已定义 `pub let pinyin_table`） |
| `String::split` / `replace_all` / `from_array` 等 API 签名不符 | `moon check` 编译期类型检查 | 编译失败（API 已用 `moon ide doc` 验证，moon 0.1.20260713） |
| 字典未命中（`convert_to_pinyin_arrays` 查 `pinyin_table` 返回 `None`） | 运行时 `Map.get` 返回 `Option` | 正常路径，返回空数组 `[]`，非错误 |

**运行时行为**：5 函数均为纯函数（除 `convert_to_pinyin_arrays` 读取只读 `pinyin_table`），无 IO / 无异常 / 无状态修改。

## 行为契约

### A. `tone_conversion.mbt` 文件内容契约

**前置条件**：
- 项目根目录 `D:\CodeWorkspace\forMoonbit\pinyin` 存在且可写
- R2 产出存在：`pinyin_format.mbt` 含 `pub(all) enum PinyinFormat { WithToneMark, WithoutTone, WithToneNumber, FirstLetter }`
- R4 产出存在：`pinyin_dicts.mbt` 含 `pub let pinyin_table : Map[String, String]`

**文件内容要求**：
- MoonBit 源文件，UTF-8 编码
- 文件头部：`///|` 文档注释标记 + 集合说明文档注释（说明用途、可见性、对应源库）
- 3 个常量绑定（1 个 `pub let` + 2 个 `let`），各带 `///` 单行文档注释
- 5 个 `pub(self) fn` 函数，各带 `///` 单行文档注释
- 文件含注释（文档注释 + 行内注释说明声调分组），落实用户偏好"代码包含必要的注释和文档"

**`///|` 标记说明**：`///|` 是 MoonBit 用于标记顶层结构 text segment 的文档注释规范（经编译验证合法，R4 `pinyin_dicts.mbt` 已采用），用于辅助编译器识别顶层结构边界。实现者应按本设计文件书写。

**文件结构**：

```moonbit
///|
/// 声调格式转换内部逻辑，对应源库 pinyin_helper.cj 中 5 个 static 内部方法 + 3 个辅助常量。
/// 5 个函数均为 pub(self) fn 可见性（包内跨文件可见），供 R6 pinyin_helper.mbt 调用。
/// all_unmarked_vowel_array / all_marked_vowel_array 为 let 文件内私有常量。

/// 拼音分隔符，对齐源库 PINYIN_SEPARATOR。pub let 跨文件共享（R6 pinyin_helper.mbt 亦用）。
pub let pinyin_separator : String = ","

/// 无调元音数组，对齐源库 ALL_UNMARKED_VOWEL_ARRAY。let 文件内私有（仅本文件用）。
let all_unmarked_vowel_array : Array[Char] = ['a', 'e', 'i', 'o', 'u', 'v']

/// 带调元音数组，对齐源库 ALL_MARKED_VOWEL_ARRAY（24 个，6 元音 × 4 声调）。let 文件内私有。
let all_marked_vowel_array : Array[Char] = [
  'ā', 'á', 'ǎ', 'à',  // a 的 4 声调
  'ē', 'é', 'ě', 'è',  // e 的 4 声调
  'ī', 'í', 'ǐ', 'ì',  // i 的 4 声调
  'ō', 'ó', 'ǒ', 'ò',  // o 的 4 声调
  'ū', 'ú', 'ǔ', 'ù',  // u 的 4 声调
  'ǖ', 'ǘ', 'ǚ', 'ǜ',  // ü 的 4 声调
]

/// 在带调元音数组中查找字符索引，未找到返回 -1。对齐源库 findArrayKeyByValue。
pub(self) fn find_array_key_by_value(ch : Char) -> Int {
  // 显式循环对齐源库 :279-289（MoonBit Iter 无 position 方法）
  for i in 0..<all_marked_vowel_array.length() {
    if all_marked_vowel_array[i] == ch {
      return i
    }
  }
  return -1
}

/// 带调拼音→数字调拼音数组。对齐源库 convertWithToneNumber。
/// 每音节仅处理首个带调元音（break），未找到带调元音则追加 "5"（轻声）。ü 替换为 v。
pub(self) fn convert_with_tone_number(str : String) -> Array[String] {
  let pinyin_array = str.split(pinyin_separator[:]).map(fn(x) { x.to_owned() }).to_array()
  for i in 0..<pinyin_array.length() {
    let original_pinyin = pinyin_array[i].replace_all(old="ü", new="v")
    let original_char_array = original_pinyin.to_array()
    let mut has_marked_char = false
    for j in 0..<original_char_array.length() {
      // 非 ASCII 小写字母即带调元音等（Char 实现 Compare trait，支持 < / > 运算符）
      if original_char_array[j] < 'a' || original_char_array[j] > 'z' {
        let index_in_all_marked = find_array_key_by_value(original_char_array[j])
        let tone_number = index_in_all_marked % 4 + 1
        let replace_char = all_unmarked_vowel_array[(index_in_all_marked - index_in_all_marked % 4) / 4]
        original_char_array[j] = replace_char
        pinyin_array[i] = String::from_array(original_char_array[:]) + tone_number.to_string()
        has_marked_char = true
        break
      }
    }
    if not(has_marked_char) {
      pinyin_array[i] = original_pinyin + "5"
    }
  }
  return pinyin_array
}

/// 带调拼音→无调拼音数组。对齐源库 convertWithoutTone。
/// 逐字符替换所有带调元音为对应无调元音，最后 ü→v，按分隔符切分返回。
pub(self) fn convert_without_tone(str : String) -> Array[String] {
  let mut s = str
  // 用 replace_all 替换所有匹配（对齐源库 Cangjie String.replace 语义）
  for i in 0..<all_marked_vowel_array.length() {
    let original_char = all_marked_vowel_array[i]
    let replace_char = all_unmarked_vowel_array[(i - i % 4) / 4]
    s = s.replace_all(old=original_char.to_string(), new=replace_char.to_string())
  }
  s = s.replace_all(old="ü", new="v")
  return s.split(pinyin_separator[:]).map(fn(x) { x.to_owned() }).to_array()
}

/// 按 PinyinFormat 分发格式转换。对齐源库 formatPinyin。
/// 用 match 模式匹配（技术方案 §6.3.3 推荐，优于源库字符串比较）。
pub(self) fn format_pinyin(str : String, format : PinyinFormat) -> Array[String] {
  match format {
    WithToneMark => str.split(pinyin_separator[:]).map(fn(x) { x.to_owned() }).to_array()
    WithToneNumber => convert_with_tone_number(str)
    WithoutTone => convert_without_tone(str)
    FirstLetter => convert_without_tone(str)
  }
}

/// 单字转拼音数组（查 pinyin_table，不区分首字母特殊处理）。对齐源库 convertToPinyinArrays。
pub(self) fn convert_to_pinyin_arrays(c : Char, format : PinyinFormat) -> Array[String] {
  let pinyin_array : Array[String] = []
  match pinyin_table.get(c.to_string()) {
    Some(v) => pinyin_array = format_pinyin(v, format)
    None => ()
  }
  return pinyin_array
}
```

**后置条件**：
- 文件存在于 `D:\CodeWorkspace\forMoonbit\pinyin\tone_conversion.mbt`
- 文件含 1 个 `///|` 标记 + 3 行集合说明 + 3 组常量定义 + 5 组函数定义
- `moon check` 编译通过（exit code 0）

### B. 函数行为契约

#### B.1 `find_array_key_by_value(ch : Char) -> Int`

**前置条件**：无
**后置条件**：
- 若 `ch` 存在于 `all_marked_vowel_array`，返回首个匹配索引 `i`（`0 <= i < 24`）
- 若 `ch` 不存在，返回 `-1`
**调用顺序**：被 `convert_with_tone_number` 在检测到非 ASCII 小写字母字符时调用
**状态变化**：无（纯函数）

#### B.2 `convert_with_tone_number(str : String) -> Array[String]`

**前置条件**：`str` 为合法拼音字符串（音节以 `pinyin_separator` 分隔）
**后置条件**：
- 按 `pinyin_separator` 切分 `str` 为音节数组
- 每音节：先将 `ü` 替换为 `v`；扫描字符，遇首个带调元音（`ch < 'a' || ch > 'z'`）则替换为对应无调元音 + 追加声调数字（`index % 4 + 1`），`break`；未找到带调元音则追加 `"5"`
- 返回转换后数组，长度 = 音节数
**关键语义**：每音节仅处理**首个**带调元音（`break`），对齐源库 `:29-55`
**状态变化**：无（纯函数）

#### B.3 `convert_without_tone(str : String) -> Array[String]`

**前置条件**：`str` 为合法拼音字符串
**后置条件**：
- 遍历 `all_marked_vowel_array`，将每个带调元音替换为对应无调元音（`all_unmarked_vowel_array[(i - i % 4) / 4]`），用 `replace_all` 替换**所有**匹配
- 将 `ü` 替换为 `v`
- 按 `pinyin_separator` 切分返回数组
**关键语义**：用 `replace_all`（非 `replace`）替换所有匹配，对齐源库 Cangjie `String.replace` 语义；多音节输入如 `"ā,á"` 两个 `ā`/`á` 均被替换
**状态变化**：无（纯函数）

#### B.4 `format_pinyin(str : String, format : PinyinFormat) -> Array[String]`

**前置条件**：`str` 为合法拼音字符串，`format` 为 `PinyinFormat` 枚举变体
**后置条件**：
- `WithToneMark` => 按 `pinyin_separator` 切分返回（原样）
- `WithToneNumber` => `convert_with_tone_number(str)`
- `WithoutTone` => `convert_without_tone(str)`
- `FirstLetter` => `convert_without_tone(str)`（复用无调转换，首字母提取在 R6 主流程处理）
**关键语义**：用 `match format` 模式匹配分发（技术方案 §6.3.3 推荐，优于源库字符串比较）
**状态变化**：无（纯函数）

#### B.5 `convert_to_pinyin_arrays(c : Char, format : PinyinFormat) -> Array[String]`

**前置条件**：`c` 为任意字符，`format` 为 `PinyinFormat` 枚举变体
**后置条件**：
- 查 `pinyin_table.get(c.to_string())`
- 命中 `Some(v)` => 返回 `format_pinyin(v, format)`
- 未命中 `None` => 返回空数组 `[]`
**关键语义**：不区分首字母特殊处理（对齐源库 `:117-123`），首字母提取在 R6 主流程处理
**状态变化**：无（仅读取只读 `pinyin_table`）

### C. `tone_conversion_test.mbt` 测试契约

**前置条件**：`tone_conversion.mbt` 已创建且 `moon check` 通过

**测试组织**：采用 `inspect(value, content="...")` 快照测试（技术方案 §8.4.1），每个测试前用 `///|` + 说明文档注释（R4 风格）。测试在主包内，直接引用 `pub(self) fn` 函数名（不加 `@pinyin.` 前缀，与 R4 `pinyin_dicts_test.mbt` 风格一致）。

**`inspect` 格式说明**：MoonBit `inspect` 对 `Array[String]` 的序列化格式为 `[元素1, 元素2, ...]`，元素直接用字符串内容，**不加引号、不加 `#` 前缀**（已验证：`["a","b"]` => `[a, b]`，`[]` => `[]`，`["yī"]` => `[yī]`）。空数组输出 `[]`。`Int` 直接输出数字（如 `0` => `0`，`-1` => `-1`）。

**测试用例清单**（共 21 用例）：

**`find_array_key_by_value`（4 用例）**：

| 用例名 | 调用 | 预期 | 说明 |
|--------|------|------|------|
| `find_array_key_by_value_returns_0_for_a_macron` | `find_array_key_by_value('ā')` | `0` | 首个带调元音 |
| `find_array_key_by_value_returns_23_for_v_grave` | `find_array_key_by_value('ǜ')` | `23` | 末个带调元音 |
| `find_array_key_by_value_returns_neg1_for_unmarked_a` | `find_array_key_by_value('a')` | `-1` | 无调元音，不在带调数组 |
| `find_array_key_by_value_returns_neg1_for_non_vowel_x` | `find_array_key_by_value('x')` | `-1` | 非元音 |

**`convert_with_tone_number`（7 用例）**：

| 用例名 | 调用 | 预期 | 说明 |
|--------|------|------|------|
| `convert_with_tone_number_a_macron_to_a1` | `convert_with_tone_number("ā")` | `[a1]` | 一声 |
| `convert_with_tone_number_a_acute_to_a2` | `convert_with_tone_number("á")` | `[a2]` | 二声 |
| `convert_with_tone_number_a_caron_to_a3` | `convert_with_tone_number("ǎ")` | `[a3]` | 三声 |
| `convert_with_tone_number_a_grave_to_a4` | `convert_with_tone_number("à")` | `[a4]` | 四声 |
| `convert_with_tone_number_plain_a_to_a5` | `convert_with_tone_number("a")` | `[a5]` | 无带调元音，轻声 5 |
| `convert_with_tone_number_multi_syllable` | `convert_with_tone_number("ā,á")` | `[a1, a2]` | 多音节，分隔符切分 |
| `convert_with_tone_number_l_v_grave_to_lv4` | `convert_with_tone_number("lǜ")` | `[lv4]` | ü 替换为 v + 四声 |

**`convert_without_tone`（3 用例）**：

| 用例名 | 调用 | 预期 | 说明 |
|--------|------|------|------|
| `convert_without_tone_a_macron_to_a` | `convert_without_tone("ā")` | `[a]` | 单音节去调 |
| `convert_without_tone_multi_syllable` | `convert_without_tone("ā,á")` | `[a, a]` | 多音节去调 |
| `convert_without_tone_l_v_grave_to_lv` | `convert_without_tone("lǜ")` | `[lv]` | ü 替换为 v |

**`format_pinyin`（4 用例）**：

| 用例名 | 调用 | 预期 | 说明 |
|--------|------|------|------|
| `format_pinyin_with_tone_mark` | `format_pinyin("ā", PinyinFormat::WithToneMark)` | `[ā]` | 原样切分 |
| `format_pinyin_with_tone_number` | `format_pinyin("ā", PinyinFormat::WithToneNumber)` | `[a1]` | 数字调 |
| `format_pinyin_without_tone` | `format_pinyin("ā", PinyinFormat::WithoutTone)` | `[a]` | 无调 |
| `format_pinyin_first_letter` | `format_pinyin("ā", PinyinFormat::FirstLetter)` | `[a]` | FirstLetter 复用 convert_without_tone |

**`convert_to_pinyin_arrays`（3 用例）**：

| 用例名 | 调用 | 预期 | 说明 |
|--------|------|------|------|
| `convert_to_pinyin_arrays_yi_with_tone_mark` | `convert_to_pinyin_arrays('一', PinyinFormat::WithToneMark)` | `[yī]` | 查 `pinyin_table["一"]` = `"yī"`，`format_pinyin("yī", WithToneMark)` = `[yī]` |
| `convert_to_pinyin_arrays_yi_with_tone_number` | `convert_to_pinyin_arrays('一', PinyinFormat::WithToneNumber)` | `[yi1]` | 数字调 |
| `convert_to_pinyin_arrays_non_han_returns_empty` | `convert_to_pinyin_arrays('x', PinyinFormat::WithToneMark)` | `[]` | 非汉字，字典未命中 |

**测试文件结构示例**（前两个用例展示风格）：

```moonbit
///|
/// 验证 find_array_key_by_value 对首个带调元音 'ā' 返回索引 0，
/// 对齐源库 findArrayKeyByValue 行为契约。
test "find_array_key_by_value_returns_0_for_a_macron" {
  inspect(find_array_key_by_value('ā'), content="0")
}

///|
/// 验证 find_array_key_by_value 对末个带调元音 'ǜ' 返回索引 23，
/// 对齐源库 findArrayKeyByValue 行为契约。
test "find_array_key_by_value_returns_23_for_v_grave" {
  inspect(find_array_key_by_value('ǜ'), content="23")
}

// ... 其余 19 用例同结构
```

**后置条件**：
- 文件存在于 `D:\CodeWorkspace\forMoonbit\pinyin\tone_conversion_test.mbt`
- 文件含 21 个 `test` 块，每个前有 `///|` + 说明
- `moon test` 全部通过

### D. 与已有代码的交互契约

**前置条件**：R1-R4 产出存在且 `moon check` 通过（exit code 0，1 warning `text_segment_excceed`，0 errors），`moon test` 42 用例全部通过。

**交互影响**：
- **`moon.mod`**：不受影响（本任务不修改）
- **`moon.pkg`**：不受影响（本任务不修改，`@data` import 已配置，本任务不引用 `@data`）
- **`pinyin_format.mbt`**：不受影响（本任务不修改，仅引用 `PinyinFormat` 枚举类型）
- **`pinyin_dicts.mbt`**：不受影响（本任务不修改，仅引用 `pinyin_table` 常量）
- **`pinyin_error.mbt`**：不受影响（本任务不修改、不引用）
- **所有已有测试文件**：不受影响（本任务不修改，新增测试文件独立）
- **`text_segment_excceed` 警告**：**持续存在**（`data/pinyin_dict.mbt` 仍超 16384 行，本任务不处理）

**后置条件**：
- `tone_conversion.mbt` + `tone_conversion_test.mbt` 存在于主包根目录
- 其余文件与 R1-R4 产出完全一致（字节级不变）
- 主包公共 API 扩展：新增 `pinyin_separator`（`pub let`）+ 5 个 `pub(self) fn` 函数（若退用 `pub fn` 则为公共 API）

### E. 验证契约

**前置条件**：`tone_conversion.mbt` + `tone_conversion_test.mbt` 已创建。

**验证命令**（工作目录：`D:\CodeWorkspace\forMoonbit\pinyin`）：

```sh
moon check
moon test
```

**预期输出**：

1. `moon check`：成功（exit code 0），**1 warning**，0 errors：
   - `Warning (0033) (text_segment_excceed)`：**持续**（`data/pinyin_dict.mbt` 超 16384 行软限制，exit code 0 不阻断，本任务不处理）

2. `moon test`：Total 63（现有 42 + 新增 21），passed 63, failed 0（全部通过）

**后置条件**：
- `moon check` exit code 0，**1 warning**（`text_segment_excceed`，预期，不阻断），0 errors
- `moon test` 63 tests 全部通过，0 失败
- 5 函数行为经 21 用例验证，与源库 `pinyin_helper.cj` 对齐

**警告治理**（落实用户偏好"不忽略任何警告"）：

- **`Warning (0033) (text_segment_excceed)`**：
  - (a) 消息：`Text segment is about to exceed the line limit. Consider mark ///| above the the top-level structures to splitting it into multiple segments.`
  - (b) 根因：`data/pinyin_dict.mbt` 共 20907 行，Map 字面量体超过 16384 行软限制
  - (c) 处置：接受为预期警告（编译成功，exit code 0，不影响功能），本任务不处理
  - (d) 消除条件：需拆分 `pinyin_dict` 为多常量（设计变更，改变 `@data.pinyin_dict` 单一常量接口），留待后续评估

## 依赖关系

### 本任务依赖的已有资源

| 资源 | 用途 |
|------|------|
| R2 产出：`pinyin_format.mbt`（`pub(all) enum PinyinFormat`） | `format_pinyin` / `convert_to_pinyin_arrays` 的 `format` 参数类型 |
| R4 产出：`pinyin_dicts.mbt`（`pub let pinyin_table : Map[String, String]`） | `convert_to_pinyin_arrays` 查单字拼音 |
| MoonBit 语言：`pub(self) fn` 顶层函数 + `pub let` / `let` 顶层常量 | 函数与常量定义语法 |
| MoonBit 标准库：`String::split` / `String::replace_all` / `String::to_array` / `String::from_array` / `Char::to_string` / `Char::Compare` / `Map::get` / `Iter::map` / `Iter::to_array` / `StringView::to_owned` | 字符串/字符/数组/迭代器/映射操作（均已用 `moon ide doc` 验证，moon 0.1.20260713） |

### 暴露给后续任务的公开接口

| 接口 | 消费任务 |
|------|---------|
| `pinyin_separator`（`pub let`，`String`） | R6 拼音转换（`pinyin_helper.mbt`，主流程音节切分） |
| `format_pinyin`（`pub(self) fn`，`String * PinyinFormat -> Array[String]`） | R6 拼音转换（`pinyin_helper.mbt` 的 `convert_to_pinyin_string` / `convert_to_pinyin_array` / `convert_to_pinyin_string_traditional` 公开方法调用） |
| `convert_to_pinyin_arrays`（`pub(self) fn`，`Char * PinyinFormat -> Array[String]`） | R6 拼音转换（`pinyin_helper.mbt` 的 `convert_to_pinyin_string` 主流程逐字符调用） |
| `convert_with_tone_number`（`pub(self) fn`） | R6 可能调用（若主流程需直接数字调转换） |
| `convert_without_tone`（`pub(self) fn`） | R6 可能调用（若主流程需直接无调转换） |
| `find_array_key_by_value`（`pub(self) fn`） | 仅本任务内部使用（`convert_with_tone_number` 调用），不预期被 R6 直接调用 |

**后续任务边界**（本任务不创建）：
- `pinyin_helper.mbt`（R6 拼音转换主流程，引用 `format_pinyin` / `convert_to_pinyin_arrays` / `pinyin_separator`）
- `chinese_helper.mbt`（R7 繁简互转）
- `pinyin_spec.mbt`（R8 形式化契约）
- `README.mbt.md` 填充（R10，需文档说明 `pinyin_separator` 为公共 API）
- `text_segment_excceed` 警告消除（设计变更，留待后续评估）

### MoonBit API 提示（均已用 `moon ide doc` 验证，moon 0.1.20260713）

**字符串操作**：
- `pub fn String::split(String, StringView) -> Iter[StringView]`：按分隔符切分字符串，返回**惰性迭代器**（非 `Array[String]`）。需 `.map(fn(x) { x.to_owned() }).to_array()` 转为 `Array[String]`。`String` 参数用 `sep[:]` 全切片适配 `StringView`。
- `pub fn String::replace_all(String, old~ : StringView, new~ : StringView) -> String`：**替换所有非重叠匹配**，命名参数调用 `s.replace_all(old=..., new=...)`。本任务 `convert_without_tone` 用此 API 对齐源库 Cangjie `String.replace` 替换所有匹配语义。
- `pub fn String::to_array(String) -> Array[Char]`：字符串转字符数组（对应源库 `toRuneArray()`）
- `pub fn String::from_array(ArrayView[Char]) -> String`：字符数组转字符串。参数是 `ArrayView[Char]`（非 `Array[Char]`），用 `arr[:]` 全切片转换：`String::from_array(arr[:])`

**字符操作**：
- `pub fn Char::to_string(Char) -> String`：字符转字符串
- `Char` 实现 `Compare` trait（`pub impl Compare for Char`），支持 `<` / `>` / `<=` / `>=` 运算符，可直接写 `ch < 'a' || ch > 'z'`（已验证编译通过）

**数组/迭代器操作**：
- `pub fn[X] Iter::to_array(Self[X]) -> Array[X]`：迭代器收集为数组
- `pub fn[X, Y] Iter::map(Self[X], (X) -> Y) -> Self[Y]`：迭代器映射（链式调用中闭包用 `fn(x) { ... }` 写法，`|x| ...` 短语法在链式调用中会解析失败）
- `pub fn StringView::to_owned(Self) -> String`：`StringView` 转为拥有所有权的 `String`
- `pub fn[T] Array[T].length() -> Int`：数组长度
- **查找索引**：MoonBit `Iter` 无 `position` 方法，`find_first` 返回元素而非索引。`find_array_key_by_value` 用显式循环 `for i in 0..<arr.length() { if arr[i] == ch { return i } }` 对齐源库 `:279-289` 写法

**映射操作**：
- `pub fn Map[K].get(key : K) -> Option[V]`：映射查找

**`ArrayView` 切片语法**：
- `arr[:]`：全切片，将 `Array[T]` 转为 `ArrayView[T]`（零拷贝视图）