# pinyin4cj → MoonBit 移植技术方案设计

> 架构输入：`designs-oo/202608062251_pinyin-port-arch-design/design_v2.md`（已验证架构级 OOD 设计）
> 审查输入：`deliberations/202608062345_review-design-v2/output_v1.md`（独立深入审查，含 N1-N5 修订建议）
> 需求输入：`requirements/202608062224_pinyin-port-to-moonbit/req_v1.md` + `deliberations/202608062236_review-req-v1/output_v1.md`
> 源库：`D:\CodeWorkspace\forCangjie\pinyin4cj` v1.0.5（Cangjie，9 源文件 + 1 外部字典，MIT License）
> 目标：MoonBit 单模块 `pinyin`，跨 wasm/js/native 三后端，语义对等移植

---

## 一、概述

### 1.1 技术方案定位

本方案衔接架构设计 `design_v2.md` 与编码实现，落实到**库与技术路径级别**的决策：MoonBit 工具链版本、`moon.mod`/`moon.pkg` 具体配置、数据结构选型与存储策略、字典资源构建脚本路径、核心算法实现路径、API 技术形态（含重载实现方式）、测试技术路径、移植映射表等。不涉及逐字段类型定义与逐方法签名实现（属编码阶段）。

### 1.2 架构决策继承

本方案继承 `design_v2.md` 全部架构决策（D1-D16），并落实审查报告 `output_v1.md` 的修订建议：

| 审查建议 | 本方案落实位置 |
|---------|--------------|
| N1（P1）：词组匹配"最短前缀优先" | §6.2 词组匹配算法路径 |
| N2（P1）：license 改为 MIT | §3.1 moon.mod 配置 |
| N3（P2）：snapshot 测试文件归属 | §8.3 测试文件分级 |
| N4（P2）：内部方法文件归属 | §2.2 文件职责注释 |
| N5（P2）：重载用 labeled 参数默认值 | §7.2 重载实现技术路径 |

### 1.3 源库技术事实摘要

- **9 源文件**：`pinyin_helper.cj`(311行) / `chinese_helper.cj`(140行) / `pinyin_format.cj`(33行) / `pinyin_resource.cj`(71行) / `utils.cj`(25行) / `get_file_path.cj`(43行，不移植) / `chinese.dict.cj`(2556行) / `mutil_pinyin.dict.cj`(858行) / `tongyong_pinyin_dict.cj`(92行)
- **1 外部资源**：`resource/pinyin.dict.txt`（41806 行 / 20903 组，244 KB）
- **15 公开 API**：`ChineseHelper` 6 方法 + `PinyinHelper` 9 方法（含 2 `convertToPinyinString` 重载）
- **2 异常点**：空串 → `"Please enter a word or sentence"`；`hasMultiPinyin` 非汉字 → `"Please enter a Chinese character"`
- **词组匹配语义**：`getWords` 从 1 字到 5 字逐长度扫描，**首个命中即返回**（最短前缀优先）
- **繁简反查**：`convertToTraditionalChinese` 遍历 `CHINESE_MAP` O(n) 反查（n ≈ 2556）
- **声调算术映射**：24 带调元音 `ALL_MARKED_VOWEL_ARRAY` + 6 无调元音 `ALL_UNMARKED_VOWEL_ARRAY`，`index % 4 + 1` 得声调，`(index - index%4) / 4` 得无调元音索引；轻声用数字 `5`；`ü` 替换为 `v`
- **特殊字符**：`CHINESE_LING = r'〇'`（U+3007）作为汉字零特殊处理
- **LICENSE**：MIT License（Copyright (c) 2017 sbiger）
- **构建配置**：`cjpm.toml` cjc v1.1.3，`output-type = "dynamic"`，`build.cj` post-build 钩子复制 `pinyin.dict.txt`

---

## 二、MoonBit 工具链与项目布局

### 2.1 工具链版本

- **moon 工具链**：`moon 0.1.20260713`（已验证支持 `rr_moon_mod` / `rr_moon_pkg` feature flags，即新格式 `moon.mod` / `moon.pkg`）
- **目标后端**：wasm-gc / js / native 三后端平等支持，不设置 `preferred-target`，不设置 `supported_targets` 限制
- **源目录**：默认 `.`（模块根即主包根），数据子包 `data/` 下挂

### 2.2 项目文件结构

```
pinyin/                              # 模块根（moon.mod）
├── moon.mod                         # 模块元数据
├── moon.pkg                         # 主包配置
├── README.mbt.md                    # 含 10 个 mbt check 示例（对齐源库 README 10 例）
├── pinyin_spec.mbt                  # 形式化契约（declare 关键字声明全部公开 API）
├── pinyin_helper.mbt                # PinyinHelper 关联方法（含 get_words / convert_to_pinyin_string_result 内部方法）
├── chinese_helper.mbt               # ChineseHelper 关联方法（含 convert_char_to_simplified/traditional 内部方法）
├── pinyin_format.mbt                # PinyinFormat 枚举 + name 方法
├── pinyin_error.mbt                 # PinyinError suberror 定义
├── pinyin_dicts.mbt                 # 全局字典视图常量集合（CHINESE_MAP / PINYIN_TABLE / MUTIL_PINYIN_TABLE / TONGYONG_PINYIN_TABLE）
├── tone_conversion.mbt              # 声调格式转换内部逻辑（convert_with_tone_number / convert_without_tone / format_pinyin / convert_to_pinyin_arrays / find_array_key_by_value）
├── pinyin_easy_test.mbt             # 黑盒测试 - 简单用例
├── pinyin_mid_test.mbt              # 黑盒测试 - 中等用例
├── pinyin_difficult_test.mbt        # 黑盒测试 - 困难用例（长句、通用拼音、issue 回归、字典完整性、10 个 README snapshot）
├── scripts/                         # 字典生成脚本目录
│   └── gen_pinyin_dict.py           # Python 脚本：源库字典 → MoonBit 字面量
└── data/                            # 字典数据子包
    ├── moon.pkg                     # 子包配置（无 import）
    ├── chinese_dict.mbt             # 繁→简字典字面量（约 2556 行，脚本生成）
    ├── mutil_pinyin_dict.mbt        # 词组拼音字典字面量（约 858 行，脚本生成）
    ├── tongyong_pinyin_dict.mbt     # 通用拼音字典字面量（约 92 行，脚本生成）
    └── pinyin_dict.mbt              # 单字拼音字典字面量（约 41806 行，脚本生成）
```

**文件职责注释**（落实审查建议 N4）：
- `pinyin_helper.mbt`：含公开方法 + 内部方法 `get_words` / `convert_to_pinyin_string_result`（对应源库 `getWords` / `convertToPinyinStringResult`）
- `tone_conversion.mbt`：含内部方法 `convert_with_tone_number` / `convert_without_tone` / `format_pinyin` / `convert_to_pinyin_arrays` / `find_array_key_by_value`（对应源库同名 static 方法）
- `chinese_helper.mbt`：含公开方法 + 内部方法 `convert_char_to_simplified_chinese` / `convert_char_to_traditional_chinese`

### 2.3 包边界与依赖方向

```
pinyin (根包) ──imports──> pinyin/data
pinyin/*_test.mbt ──black-box──> pinyin (自身，自动引用)
data/ ──无 import──> (仅 moonbitlang/core 隐式)
```

- 主包单向依赖数据子包，数据子包零依赖（仅 `moonbitlang/core` 隐式可用）
- 测试文件 `_test.mbt` 自动引用所在包（黑盒测试），无需额外 `for "test"` 配置
- **不引入** `moonbit-c-binding` / `make-moonbit-c-bindings` / `moonbit-proof`（源库无 C 依赖，非形式化验证场景）

---

## 三、包与依赖管理配置

### 3.1 `moon.mod`（模块根）

```
name = "pinyin/pinyin"
version = "0.1.0"
readme = "README.mbt.md"
repository = ""
license = "MIT"
keywords = ["pinyin", "chinese", "unicode"]
description = "MoonBit port of pinyin4cj: Chinese-to-pinyin conversion"

// 无 import 依赖（零外部依赖，仅 moonbitlang/core 隐式可用）
// 不设置 preferred-target（三后端平等）
// 不设置 supported_targets（不限制可移植性）
```

**关键决策**：
- **`license = "MIT"`**（落实审查建议 N2）：对齐源库 `LICENSE` 文件（MIT License, Copyright (c) 2017 sbiger）。审查报告 N2 指出 `design_v2.md` 写 `Apache-2.0` 为事实性错误。
- **模块名 `pinyin/pinyin`**：`<author>/pinyin` 形式，作者命名空间暂用工作目录名 `pinyin` 占位，发布到 mooncakes.io 时确定正式作者名。与工作目录 `pinyin` 一致，符合 mooncakes 命名规范。
- **零外部依赖**：无 `import` 块，仅 `moonbitlang/core` 隐式可用。源库 `std.core.min` 对应 MoonBit 内置 `min` 函数（`moonbitlang/core` 提供），`std.process` / `std.fs` / `std.env` 不移植（构建脚本替代）。

### 3.2 主包 `moon.pkg`（根目录）

```
import {
  "pinyin/pinyin/data",
}
// 不设置 is-main（库包）
// 测试文件 _test.mbt 自动引用主包，无需 for "test" 配置
```

### 3.3 数据子包 `data/moon.pkg`

```
// 纯数据包，无 import
// 不设置 is-main
// 仅含字典字面量定义，无逻辑，无测试
```

### 3.4 `pkg.generated.mbti` 管理

- 主包与数据子包各生成 `pkg.generated.mbti`，**入版本控制**（SKILL.md:161-165）
- 数据子包 `mbti` 仅导出四个字典常量（`chinese_dict` / `mutil_pinyin_dict` / `tongyong_pinyin_dict` / `pinyin_dict`）
- 主包 `mbti` 导出全部公开 API（`PinyinFormat` / `PinyinError` / `PinyinHelper` / `ChineseHelper`）
- 每次 API 变更后 `moon info` 重新生成，diff 作为公开 API 变更信号

---

## 四、核心数据结构技术选型

### 4.1 字典数据结构

| 字典 | 源库类型 | MoonBit 类型 | 容量 | 用途 |
|------|---------|------------|------|------|
| `CHINESE_MAP` | `HashMap<Rune, Rune>` | `Map[Int, Int]` | 2556 条 | 繁→简映射（码点→码点） |
| `PINYIN_TABLE` | `HashMap<String, String>` | `Map[String, String]` | 20903 条 | 单字拼音（汉字→逗号分隔多音） |
| `MUTIL_PINYIN_TABLE` | `HashMap<String, String>` | `Map[String, String]` | 约 856 条 | 词组拼音（词→逗号分隔拼音） |
| `TONGYONG_PINYIN_TABLE` | `HashMap<String, String>` | `Map[String, String]` | 83 条 | 通用拼音映射 |

**选型理由**：
- **MoonBit 标准库 `Map`**：可变的、保持插入顺序的映射（SKILL.md:1064 "Map (Mutable, Insertion-Order Preserving)"）。可变性与源库 Cangjie `HashMap` 对齐，使 `add_*_dict_resource` 可直接原地合并。
- **`Map[Int, Int]` 而非 `Map[Char, Char]`**：源库 `Rune` 即 Unicode 码点，MoonBit `Char` 即 Unicode 码点。采用 `Int` 存储码点（`Char::to_int()` / `Char::from_int()` 转换）便于字面量生成脚本统一处理；查询时 `chinese_map[c.to_int()]`。亦可直接用 `Map[Char, Char]`，两者等价，**推荐 `Map[Int, Int]`** 以与生成脚本输出一致。
- **不引入 `@hashmap.T`**：标准库 `Map` 足够，零外部依赖原则。
- **不用 `HashMap`**：MoonBit 标准库无 `HashMap` 类型名，`Map` 即惯用映射。

### 4.2 字典存储与加载策略

- **构建期内嵌为 MoonBit 字面量**：四张字典在构建期通过脚本转写为 `data/*.mbt` 中的 `Map` 字面量，运行时直接构造为 `Map` 对象。
- **全局 `let` 常量集合**（`pinyin_dicts.mbt`）：四张字典各自以 `let` 绑定于顶层，`pub(self)` 可见性仅包内可访问。全局 `let` 绑定不可重新赋值，但 `Map` 对象内容可变（支持 `add_*` 原地合并）。
- **不依赖运行时文件系统与环境变量**：跨 wasm/js/native 三后端一致，无运行时 IO。
- **不用 `@embed` / `#embed`**：MoonBit 当前无稳定二进制内嵌原语；字面量转写最稳妥，`moon check` 可静态验证字典完整性。
- **不用运行时解析字符串**：运行时解析 244 KB 字符串增加启动延迟与 GC 压力；字面量在编译期即被编译器优化为高效结构。

### 4.3 辅助常量

| 常量 | 源库 | MoonBit | 说明 |
|------|------|---------|------|
| `PINYIN_SEPARATOR` | `var = ","` | `let = ","` | 拼音分隔符（不可变） |
| `CHINESE_LING` | `var : Rune = r'〇'` | `let : Char = '〇'` | 汉字零（U+3007） |
| `ALL_UNMARKED_VOWEL_ARRAY` | `Array<Rune>` (6) | `Array[Char]` (6) | 无调元音 `[a,e,i,o,u,v]` |
| `ALL_MARKED_VOWEL_ARRAY` | `Array<Rune>` (24) | `Array[Char]` (24) | 带调元音 `[ā,á,ǎ,à,...]` |

---

## 五、字典资源构建技术路径

### 5.1 生成脚本

- **脚本路径**：`scripts/gen_pinyin_dict.py`（Python 3，入版本控制）
- **脚本输入**：源库 `D:\CodeWorkspace\forCangjie\pinyin4cj\src\*.dict.cj` + `resource/pinyin.dict.txt`
- **脚本输出**：`data/chinese_dict.mbt` / `data/mutil_pinyin_dict.mbt` / `data/tongyong_pinyin_dict.mbt` / `data/pinyin_dict.mbt`
- **脚本入版本控制**，生成产物（`data/*.mbt`）亦入版本控制（便于 `moon check` 离线验证）

### 5.2 转写规则

#### 5.2.1 `chinese_dict.mbt`（繁→简）

- 源：`chinese.dict.cj` 中 `HashMap<Rune, Rune>([(r'臺', r'台'), ...])`
- 目标：`let chinese_dict : Map[Int, Int] = { 0x81FA: 0x53F0, ... }`（码点字面量）
- 转写：`r'臺'` → `Char::to_int('臺')` = `0x81FA`；或直接 `'臺'.to_int()`。生成脚本输出 16 进制码点以保持可读性。

#### 5.2.2 `mutil_pinyin_dict.mbt`（词组拼音）

- 源：`mutil_pinyin.dict.cj` 中 `HashMap<String, String>([("阿訇", "ā,hōng"), ...])`
- 目标：`let mutil_pinyin_dict : Map[String, String] = { "阿訇": "ā,hōng", ... }`
- 转写：键值直接转写，含带调元音的 UTF-8 字符串原样保留。

#### 5.2.3 `tongyong_pinyin_dict.mbt`（通用拼音）

- 源：`tongyong_pinyin_dict.cj`（92 行，83 条目）
- 目标：`let tongyong_pinyin_dict : Map[String, String] = { "chi": "chih", ... }`
- 转写：键值直接转写（纯 ASCII）。

#### 5.2.4 `pinyin_dict.mbt`（单字拼音，外部资源内嵌）

- 源：`resource/pinyin.dict.txt`（41806 行 / 20903 组，两行一组：汉字 / 拼音读音）
- 目标：`let pinyin_dict : Map[String, String] = { "〇": "líng", "一": "yī", "丁": "dīng,zhēng", ... }`
- 转写：每两行一组生成 `"汉字": "拼音,拼音,..."` 字面量条目。
- **完整性约束**：生成产物条目数必须 = 20903，与源库一致。脚本含断言校验。

### 5.3 字典视图构造（`pinyin_dicts.mbt`）

主包 `pinyin_dicts.mbt` 从 `@data` 子包读取字面量并构造为运行时 `Map` 视图：

```moonbit
// 伪代码示意（非最终实现）
let chinese_map : Map[Int, Int] = @data.chinese_dict
let pinyin_table : Map[String, String] = @data.pinyin_dict
let mutil_pinyin_table : Map[String, String] = @data.mutil_pinyin_dict
let tongyong_pinyin_table : Map[String, String] = @data.tongyong_pinyin_dict
```

- `@data` 子包导出四个 `let` 常量，主包通过 `import "pinyin/pinyin/data"` 引用，别名 `@data`。
- 主包 `pinyin_dicts.mbt` 重新绑定为 `pub(self)` 可见性，仅包内可访问。

---

## 六、核心算法技术实现路径

### 6.1 字符串与字符处理

- **MoonBit `String` 为 UTF-16 存储，`Char` 为 Unicode 码点**。拼音字典均在 BMP 内（CJK 统一汉字 U+4E00-U+9FFF、带调拼音字母 U+0100-U+024F），无代理对问题。
- **字符迭代**：`for c in str { ... }` 安全迭代 Unicode 码点（SKILL.md:984 演示）。
- **字符数组转换**：源库 `str.toRuneArray()` → MoonBit `str.to_array()`（返回 `Array[Char]`）或逐字符迭代收集。
- **字符串拼接**：源库 `StringBuilder` → MoonBit `StringBuilder`（`@buffer` 包或内置）。推荐用 `StringBuilder` + `to_string()` 对齐源库 `resultPinyinStrBuf` 模式。
- **字符串切片**：源库 `str[..lastIndex]` / `str[(size-1)..]` → MoonBit `str[:end]` / `str[start:]`（StringView，注意 UTF-16 边界，拼音场景安全）。

### 6.2 词组匹配算法（`get_words`，落实审查建议 N1）

- **源库语义**（`pinyin_helper.cj:131-140`）：`for(i in 1..min(charArray.size + 1, 6))`，从 1 字到 5 字逐长度扫描，**首个命中即返回 `[str]`**。即**最短前缀优先**。
- **MoonBit 实现路径**：`for i in 1..<min(char_array.length(), 6) + 1 { let prefix = ...; if mutil_pinyin_table.contains(prefix) { return [prefix] } }`，命中即返回。
- **关键约束**：不得改为"最长前缀优先"（会改变词组匹配行为，破坏语义对等硬约束）。审查报告 N1 明确指出 `design_v2.md` §4.1 "最长前缀优先"为事实性错误，本方案修正为"最短前缀优先"。

### 6.3 声调格式转换算法（`tone_conversion.mbt`）

#### 6.3.1 `convert_with_tone_number`（带调→数字调）

- 扫描音节字符，遇 24 带调元音之一则：`tone_number = index % 4 + 1`，`replace_char = ALL_UNMARKED_VOWEL_ARRAY[(index - index%4) / 4]`，替换并追加声调数字。
- 未遇带调元音则追加 `"5"`（轻声）。
- `ü` 替换为 `v`（`originalPinyin.replace("ü", "v")`）。

#### 6.3.2 `convert_without_tone`（带调→无调）

- 24 带调元音逐字符替换为对应无调元音：`ALL_MARKED_VOWEL_ARRAY[i]` → `ALL_UNMARKED_VOWEL_ARRAY[(i - i%4) / 4]`。
- 最后 `ü` 替换为 `v`，按 `PINYIN_SEPARATOR` 分割返回数组。

#### 6.3.3 `format_pinyin`（格式分发）

- 按 `PinyinFormat` 分支：`WithToneMark` → 直接分割；`WithToneNumber` → `convert_with_tone_number`；`WithoutTone` / `FirstLetter` → `convert_without_tone`。
- **源库用 `format.getName() == "WITH_TONE_MARK"` 字符串比较分发**。MoonBit 实现推荐用 `match format { WithToneMark => ...; WithToneNumber => ...; ... }` 模式匹配（更地道，语义等价）。亦可保留字符串比较对齐源库，但模式匹配更优。

#### 6.3.4 `find_array_key_by_value`（带调元音索引查找）

- 遍历 `ALL_MARKED_VOWEL_ARRAY` 找匹配字符，返回索引或 -1。
- MoonBit 可用 `ALL_MARKED_VOWEL_ARRAY.iter().position(|c| c == ch)` 或保留显式循环。

### 6.4 词句转拼音主流程（`convert_to_pinyin_string`）

源库 `pinyin_helper.cj:150-207` 逻辑：

1. 输入 `str.to_array()` → 空则 `raise PinyinError("Please enter a word or sentence")`
2. 从左到右扫描（`while i < str_len`）：
   - 取剩余字符的 `get_words` 结果：命中词组则按词组输出（`format_pinyin` 后逐音节追加 + 分隔符），`i += words.length`
   - 未命中词组则取单字 `c = char_array[i]`：
     - 若 `is_chinese(c) || c == CHINESE_LING`：查 `PINYIN_TABLE` 取首音，`format_pinyin` 后追加 + 分隔符；未命中则原样追加 `c`
     - 否则（非汉字）：原样追加 `c`，并根据下一字符是否汉字决定是否追加分隔符
   - `i++`
3. 末尾多余分隔符裁剪（`convert_to_pinyin_string_result`）：若分隔符非空且末尾是分隔符则裁剪。

**MoonBit 实现路径**：保留源库 `StringBuilder` + `while` 循环模式。`FIRST_LETTER` 格式特殊处理（取首字符）。分隔符追加边界规则逐字符对齐源库第 157-203 行。

### 6.5 繁简互转算法（`chinese_helper.mbt`）

#### 6.5.1 `convert_to_simplified_chinese`（繁→简）

- 逐字符查 `CHINESE_MAP`，命中替换为 `Char::from_int(chinese_map[c.to_int()])`，未命中原样。
- 空串返回空串。

#### 6.5.2 `convert_to_traditional_chinese`（简→繁，O(n) 反查）

- 逐字符遍历 `CHINESE_MAP` 找值为该字符的键，命中替换为键，未命中原样。
- **保留 O(n) 反查语义**（需求 3.8 "不主动优化"）：不构建反向索引。源库反查在多映射场景（多繁体对应同一简体）返回首个命中键，构建反向索引会改变此行为。
- **性能特征**：单字符反查 O(n)，n ≈ 2556；大文本整体 O(L × n)。与源库完全对等，下游不得改变此复杂度。
- **源库实现细节**：`chinese_helper.cj:69-80` 用 `unsafe { str.rawData() }` + `Rune.fromUtf8` 逐 UTF-8 字符迭代。MoonBit 实现用 `for c in str { ... }` 安全迭代 Unicode 码点，语义等价且无 `unsafe`。

### 6.6 通用拼音算法（`to_tongyong_pinyin_string_array`）

- 输入单字 → `convert_to_pinyin_array(char, WithToneNumber)` 得数字音标数组
- 对每个音节拆为"拼音部分 + 末尾数字"：`num = pinyin[pinyin.length()-1..]`，`pinyin_part = pinyin[..pinyin.length()-1]`
- 查 `TONGYONG_PINYIN_TABLE` 替换拼音部分：命中则 `t + num`，未命中则原样
- 非汉字返回 `[]`

### 6.7 自定义字典追加算法（`add_*_dict_resource`）

- 利用 MoonBit `Map` 可变性，在全局 `let` 绑定的 `Map` 上原地合并。
- 实现路径：遍历入参字典逐条 `map[k] = v`（键冲突时新值覆盖，对齐源库 `HashMap.add(all:)` 语义）。
- 无需 `Ref[Map]` 包装（`Map` 本身可变），无需 `Mutex`（保持纯计算库零依赖；并发追加是罕见场景，源库 `HashMap` 本身亦无并发保证）。

---

## 七、API 技术形态

### 7.1 类型形态

| 类型 | 形态 | 可见性 | 说明 |
|------|------|--------|------|
| `PinyinFormat` | `pub(all) enum` | 公开 | 4 变体 `WithToneMark` / `WithoutTone` / `WithToneNumber` / `FirstLetter` |
| `PinyinError` | `pub(all) suberror` | 公开 | 单变体 `PinyinError(String)` 携带消息 |
| `PinyinHelper` | `pub struct`（空） | 公开 | 命名空间，类型关联方法 |
| `ChineseHelper` | `pub struct`（空） | 公开 | 命名空间，类型关联方法 |

### 7.2 重载实现技术路径（落实审查建议 N5）

MoonBit **不支持传统方法重载**。源库 `convertToPinyinString` 有 2 重载（含默认 `WITH_TONE_MARK`），移植采用 **labeled 参数默认值**方案：

```moonbit
// 伪代码示意（非最终实现）
pub fn PinyinHelper::convert_to_pinyin_string(
  str : String,
  separator : String,
  format~ : PinyinFormat = PinyinFormat::WithToneMark  // 默认值
) -> String raise PinyinError {
  ...
}
```

- 调用点：`PinyinHelper::convert_to_pinyin_string("我是中国人", " ")`（省略 `format`，用默认值）或 `PinyinHelper::convert_to_pinyin_string("我是中国人", " ", format=WithToneNumber)`。
- 与源库 `PinyinHelper.convertToPinyinString(str, separator)` / `PinyinHelper.convertToPinyinString(str, separator, format)` 视觉对齐。
- **不拆为两个不同名方法**：保留单一方法名 + 默认参数，调用点更简洁，语义对齐源库重载。

### 7.3 公开 API 方法清单与命名映射

| 源库 API | MoonBit API | 签名轮廓 | 异常 |
|---------|------------|---------|------|
| `ChineseHelper.convertToSimplifiedChinese(str)` | `ChineseHelper::convert_to_simplified_chinese(str : String) -> String` | 繁→简 | 无 |
| `ChineseHelper.convertToTraditionalChinese(str)` | `ChineseHelper::convert_to_traditional_chinese(str : String) -> String` | 简→繁（O(n) 反查） | 无 |
| `ChineseHelper.isTraditionalChinese(c)` | `ChineseHelper::is_traditional_chinese(c : Char) -> Bool` | 是否繁体 | 无 |
| `ChineseHelper.isChinese(c)` | `ChineseHelper::is_chinese(c : Char) -> Bool` | 是否汉字 | 无 |
| `ChineseHelper.containsChinese(str)` | `ChineseHelper::contains_chinese(str : String) -> Bool` | 是否含汉字 | 无 |
| `ChineseHelper.addChineseDictResource(dict)` | `ChineseHelper::add_chinese_dict_resource(dict : Map[Int, Int]) -> Unit` | 追加繁简映射 | 无 |
| `PinyinHelper.convertToPinyinString(str, sep)` | `PinyinHelper::convert_to_pinyin_string(str, sep, format~ = WithToneMark)` | 词句转拼音 | `raise PinyinError`（空串） |
| `PinyinHelper.convertToPinyinString(str, sep, format)` | 同上（labeled 参数默认值） | 同上 | 同上 |
| `PinyinHelper.convertToPinyinStringTraditional(str, sep, format)` | `PinyinHelper::convert_to_pinyin_string_traditional(str, sep, format~ = WithToneMark) -> String raise PinyinError` | 先繁→简再转拼音 | `raise PinyinError` |
| `PinyinHelper.convertToPinyinArray(c, format)` | `PinyinHelper::convert_to_pinyin_array(c : Char, format~ : PinyinFormat = WithToneMark) -> Array[String]` | 单字所有读音 | 无（非汉字返回 `[]`） |
| `PinyinHelper.getShortPinyin(str)` | `PinyinHelper::get_short_pinyin(str : String) -> String raise PinyinError` | 首字母格式 | `raise PinyinError`（空串） |
| `PinyinHelper.hasMultiPinyin(c)` | `PinyinHelper::has_multi_pinyin(c : Char) -> Bool raise PinyinError` | 是否多音字 | `raise PinyinError`（非汉字） |
| `PinyinHelper.addPinyinDictResource(dict)` | `PinyinHelper::add_pinyin_dict_resource(dict : Map[String, String]) -> Unit` | 追加单字拼音字典 | 无 |
| `PinyinHelper.addMutilPinyinDictResource(dict)` | `PinyinHelper::add_mutil_pinyin_dict_resource(dict : Map[String, String]) -> Unit` | 追加词组拼音字典 | 无 |
| `PinyinHelper.toTongyongPinyinStringArray(char)` | `PinyinHelper::to_tongyong_pinyin_string_array(char : Char) -> Array[String]` | 通用拼音 | 无（非汉字返回 `[]`） |
| `PinyinFormat.getName()` | `PinyinFormat::name(self) -> String` | 变体名 | 无 |

**命名规范**：
- 类型名 PascalCase：`PinyinHelper` / `ChineseHelper` / `PinyinFormat` / `PinyinError`
- 枚举变体 PascalCase：`WithToneMark` / `WithoutTone` / `WithToneNumber` / `FirstLetter`
- 方法名 lower_snake：`convert_to_pinyin_string` / `convert_to_simplified_chinese` 等
- 调用形式：`PinyinHelper::convert_to_pinyin_string("我是中国人", " ")`，与源库 `PinyinHelper.convertToPinyinString(...)` 视觉对齐

### 7.4 错误处理策略

- **采用 `raise PinyinError`**（非 `Result[T, PinyinError]`）：符合 MoonBit 检查式错误惯例（`suberror` + `raise`/`catch`），语义对齐源库 `throw`，调用方需显式 `catch` 或声明 `raise` 传播。
- **错误消息文本逐字符对齐源库**：
  - `convert_to_pinyin_string` 空串 → `"Please enter a word or sentence"`（源库 `pinyin_helper.cj:153`）
  - `has_multi_pinyin` 非汉字 → `"Please enter a Chinese character"`（源库 `pinyin_helper.cj:253`）
- **边界场景**（非错误，返回空数组）：`convert_to_pinyin_array` / `to_tongyong_pinyin_string_array` 非汉字输入返回 `[]`。
- **字典查询未命中**：`Map::get` 返回 `Option[T]`，用 `if let Some(v) = map.get(k)` 或 `match map.get(k) { Some(v) => ...; None => ... }` 模式处理。

---

## 八、测试技术路径

### 8.1 双轨策略：spec 契约 + 黑盒测试

按需求 3.7 与 `moonbit-spec-test-development` skill 规范，采用 spec-driven + 黑盒测试并行。

### 8.2 spec 契约文件 `pinyin_spec.mbt`

- **采用 `declare` 关键字**声明全部公开 API 签名（类型、方法、错误），作为实现与测试的共同基准，创建后视为只读契约。
- **`declare` vs `#declaration_only` 取舍**：`moonbit-agent-guide` SKILL.md:358-378 规范采用 `declare` 关键字（最新规范）；`#declaration_only` 是 `moonbit-spec-test-development` SKILL.md:21 提到的早期机制。本方案采用 `declare` 关键字，与 `moonbit-agent-guide` 最新规范一致。
- **内容**：
  - `declare pub(all) enum PinyinFormat` + 4 变体 + `name` 方法声明
  - `declare pub(all) suberror PinyinError` + 变体声明
  - `declare pub struct PinyinHelper` + 全部公开关联方法声明（含 `raise PinyinError` 标注）
  - `declare pub struct ChineseHelper` + 全部公开关联方法声明
- 实现在 `pinyin_helper.mbt` / `chinese_helper.mbt` 等文件中提供，spec 文件不包含实现。

### 8.3 黑盒测试文件分级（落实审查建议 N3）

按 `moonbit-spec-test-development` skill 的 `<pkg>_easy_test.mbt` / `<pkg>_mid_test.mbt` / `<pkg>_difficult_test.mbt` 三级约定。**10 个 README snapshot 示例并入 `pinyin_difficult_test.mbt`**（审查建议 N3：snapshot 测试属困难级，不单独拆第 4 个文件，保持 skill 3 级约定）。

| 文件 | 覆盖范围 | 对齐源库 |
|------|---------|---------|
| `pinyin_easy_test.mbt` | 单字转换、繁简互转、`is_chinese` / `is_traditional_chinese` / `contains_chinese`、`PinyinFormat::name`、空串/非汉字边界、异常场景 | HLT 14 文件中的简单用例 |
| `pinyin_mid_test.mbt` | 词句转换（多分隔符、繁简混合、首字母、多音字）、`add_*_dict_resource` 自定义字典、`has_multi_pinyin` | HLT 14 文件中的组合用例 + LLT `test_pinyin_multi` / `test_pinyin_dict_*` |
| `pinyin_difficult_test.mbt` | 长句全格式四连测（如"河南麦收季…"）、通用拼音 30+ 断言、issue 回归（`test_issue_I89BPG` 等）、字典完整性、**10 个 README 示例 snapshot** | LLT `test_pinyin_01~03` / `test_tongyong_01` / `test_issue*` / `test_chinese_dict_*` + README 10 例 |

### 8.4 测试技术

#### 8.4.1 snapshot 测试

- 用 `inspect(value, content="...")` 对齐源库 `@Assert(expected, actual)`。
- `moon test --update` 自动维护 `content=` 参数。
- 10 个 README 示例精确输出对等（繁简互转 2 例 + 词句转拼音 2 例 + 自定义字典 3 例 + 多音字 1 例 + 繁简体转拼音 1 例 + 通用拼音 1 例）。

#### 8.4.2 异常测试

- 用 `try ... catch { PinyinError::PinyinError(msg) => inspect(msg, content="...") } noraise { _ => fail("expected to fail") }` 形式（SKILL.md:859-864）。
- 对齐源库 `test_issue_I89BPG.cj` 的空串异常测试模式。

#### 8.4.3 黑盒调用

- 测试文件中通过 `PinyinHelper::convert_to_pinyin_string(...)` 或 `ChineseHelper::convert_to_simplified_chinese(...)` 直接调用（同包黑盒测试自动引用）。
- 亦可显式 `@pinyin.PinyinHelper::...`（若测试包独立）。

#### 8.4.4 不移植的测试

- `FUZZ/` 模糊测试：MoonBit 无 fuzz 框架，不移植（可选属性测试替代但非强制）。
- `Reliability/` 200 线程压测：不原样移植（可选等价吞吐基准，native 后端 `moon run --profile`，非交付物强制项）。

### 8.5 验证循环

按 `moonbit-agent-guide` SKILL.md:27-34 紧凑循环：

1. **`moon check`**（含 `--warn-list +unnecessary_annotation` 启用 warning 73，检测冗余标注与过度限定构造器）
2. **`moon test`**（三后端分别测试）：
   - `moon test --target wasm-gc`
   - `moon test --target js`
   - `moon test --target native`
3. **`moon fmt`**（格式化）
4. **`moon info`**（生成/更新 `pkg.generated.mbti`，review diff 作为公开 API 变更信号）

**批量验证策略**（用户偏好 P8）：编码阶段批量完成修改后统一运行验证循环，而非逐步验证。

---

## 九、FFI 与 native-stub 技术路径

### 9.1 无 FFI 决策

- **不引入任何 `extern "c"` 或 native FFI**。
- **理由**：源库无 C 依赖（已逐文件验证 9 个 `.cj` 源文件无 `extern` 声明），`moonbit-c-binding` / `make-moonbit-c-bindings` skill 不适用。
- **不配置 `native-stub/` 目录**，不配置 `link.native`。
- **不使用 native-only API**（如 `@fs`、`@async`）：字符串与字符处理用 MoonBit 标准 `String` / `Char`，跨三后端一致。

---

## 十、移植映射表

### 10.1 源库模块 → MoonBit 包映射

| 源库模块 | MoonBit 包/文件 | 移植方式 |
|---------|---------------|---------|
| `pinyin_helper.cj`（311行） | `pinyin/pinyin_helper.mbt` + `pinyin/tone_conversion.mbt` | 手写逻辑，公开方法 + 内部方法拆分两文件 |
| `chinese_helper.cj`（140行） | `pinyin/chinese_helper.mbt` | 手写逻辑 |
| `pinyin_format.cj`（33行） | `pinyin/pinyin_format.mbt` | 手写逻辑 |
| `pinyin_resource.cj`（71行） | `pinyin/pinyin_dicts.mbt` | 资源加载改为构建期内嵌，运行时直接构造 Map |
| `utils.cj`（25行） | `pinyin/pinyin_error.mbt` | `Pinyin4cjException` → `PinyinError` suberror |
| `get_file_path.cj`（43行） | **不移植** | 环境变量定位逻辑由构建脚本替代 |
| `chinese.dict.cj`（2556行） | `pinyin/data/chinese_dict.mbt` | 脚本生成字面量 |
| `mutil_pinyin.dict.cj`（858行） | `pinyin/data/mutil_pinyin_dict.mbt` | 脚本生成字面量 |
| `tongyong_pinyin_dict.cj`（92行） | `pinyin/data/tongyong_pinyin_dict.mbt` | 脚本生成字面量 |
| `resource/pinyin.dict.txt`（41806行） | `pinyin/data/pinyin_dict.mbt` | 脚本生成字面量（外部资源内嵌） |
| `build.cj`（post-build 钩子） | `pinyin/scripts/gen_pinyin_dict.py` | 构建脚本替代 |
| `cjpm.toml` | `pinyin/moon.mod` + `moon.pkg` | 构建配置转换 |
| `test/HLT/`（14文件） | `pinyin_easy_test.mbt` + `pinyin_mid_test.mbt` | 测试用例转写 |
| `test/LLT/pinyin_helper/`（17文件） | `pinyin_mid_test.mbt` + `pinyin_difficult_test.mbt` | 测试用例转写 |
| `test/LLT/chinese_helper/`（5文件） | `pinyin_easy_test.mbt` + `pinyin_difficult_test.mbt` | 测试用例转写 |
| `test/FUZZ/`（11文件） | **不移植** | MoonBit 无 fuzz 框架 |
| `test/Reliability/`（11文件） | **不移植**（可选等价基准） | 并发模型不同 |
| `test/DOC/`（1文件） | `README.mbt.md` mbt check 示例 | 文档测试 |
| `README.md`（10示例） | `README.mbt.md`（10 mbt check 示例） | 示例转写 |
| `doc/feature_api.md` | `README.mbt.md` + `pkg.generated.mbti` | API 文档 |
| `LICENSE`（MIT） | `moon.mod` 中 `license = "MIT"` | 许可证声明 |

### 10.2 源库 API → MoonBit API 映射

详见 §7.3 公开 API 方法清单与命名映射表。

### 10.3 源库内部方法 → MoonBit 文件归属映射（落实审查建议 N4）

| 源库内部方法 | 源码位置 | MoonBit 文件 | MoonBit 方法名 |
|------------|---------|------------|--------------|
| `convertWithToneNumber` | pinyin_helper.cj:29 | `tone_conversion.mbt` | `convert_with_tone_number` |
| `convertWithoutTone` | pinyin_helper.cj:63 | `tone_conversion.mbt` | `convert_without_tone` |
| `formatPinyin` | pinyin_helper.cj:82 | `tone_conversion.mbt` | `format_pinyin` |
| `convertToPinyinArrays` | pinyin_helper.cj:117 | `tone_conversion.mbt` | `convert_to_pinyin_arrays` |
| `getWords` | pinyin_helper.cj:131 | `pinyin_helper.mbt` | `get_words` |
| `convertToPinyinStringResult` | pinyin_helper.cj:214 | `pinyin_helper.mbt` | `convert_to_pinyin_string_result` |
| `findArrayKeyByValue` | pinyin_helper.cj:279 | `tone_conversion.mbt` | `find_array_key_by_value` |
| `convertCharToSimplifiedChinese` | chinese_helper.cj:22 | `chinese_helper.mbt` | `convert_char_to_simplified_chinese` |
| `convertCharToTraditionalChinese` | chinese_helper.cj:38 | `chinese_helper.mbt` | `convert_char_to_traditional_chinese` |

### 10.4 源库测试 → MoonBit 测试映射

| 源库测试文件 | MoonBit 测试文件 | 转写要点 |
|------------|----------------|---------|
| `HLT/pinyin_convertToPinyinString_001.cj`（6 TestCase） | `pinyin_mid_test.mbt` | `@Assert` → `inspect`，多分隔符用例 |
| `HLT/pinyin_convertToPinyinArray_001~002.cj` | `pinyin_easy_test.mbt` + `pinyin_mid_test.mbt` | 单字读音数组 |
| `HLT/pinyin_convertToSimplifiedChinese_001.cj` | `pinyin_easy_test.mbt` | 繁→简 |
| `HLT/pinyin_convertToTraditionalChinese_001.cj` | `pinyin_easy_test.mbt` | 简→繁 |
| `HLT/pinyin_getName_001.cj` | `pinyin_easy_test.mbt` | `PinyinFormat::name` |
| `HLT/pinyin_getShortPinyin_001.cj` | `pinyin_mid_test.mbt` | 首字母格式 |
| `HLT/pinyin_hasMultiPinyin_001.cj` | `pinyin_mid_test.mbt` | 多音字判定 |
| `HLT/pinyin_isChinese_001.cj` / `pinyin_isTraditionalChinese_001.cj` | `pinyin_easy_test.mbt` | 汉字判定 |
| `HLT/pinyin_add*DictResource_001.cj`（3文件） | `pinyin_mid_test.mbt` | 自定义字典追加 |
| `LLT/pinyin_helper/test_pinyin_01~03.cj` | `pinyin_difficult_test.mbt` | 长句四连测（河南麦收季…） |
| `LLT/pinyin_helper/test_tongyong_01.cj`（30+ 断言） | `pinyin_difficult_test.mbt` | 通用拼音 |
| `LLT/pinyin_helper/test_issue_I89BPG.cj` / `test_issue.cj` | `pinyin_difficult_test.mbt` | issue 回归（空串异常） |
| `LLT/pinyin_helper/test_pinyin_dict_01~02.cj` | `pinyin_mid_test.mbt` | 自定义字典 + 多音字 |
| `LLT/pinyin_helper/test_pinyin_covertToPinyinArray_01~05.cj` | `pinyin_mid_test.mbt` + `pinyin_difficult_test.mbt` | 单字读音详测 |
| `LLT/pinyin_helper/test_pinyin_multi.cj` / `test_pinyin_traditional.cj` / `test_pinyin_getShort.cj` / `test_hasMulti.cj` | `pinyin_mid_test.mbt` | 组合用例 |
| `LLT/chinese_helper/test_chinese_dict_01~02.cj` | `pinyin_difficult_test.mbt` | 字典完整性 + 自定义繁简 |
| `LLT/chinese_helper/test_chinese_helper_01~02.cj` | `pinyin_easy_test.mbt` | 繁简互转 |
| `LLT/chinese_helper/test_performance_01.cj` | **不移植**（可选等价基准） | 性能测试 |
| `README.md` 10 示例 | `pinyin_difficult_test.mbt`（snapshot） + `README.mbt.md`（mbt check） | 10 个示例精确输出对等 |

---

## 十一、关键技术决策汇总

| # | 决策点 | 选择 | 理由 | 落实审查建议 |
|---|--------|------|------|------------|
| T1 | moon 工具链版本 | `moon 0.1.20260713`（rr_moon_mod / rr_moon_pkg） | 已验证支持新格式 moon.mod/moon.pkg | - |
| T2 | 目标后端 | wasm-gc / js / native 三后端平等 | 源库纯计算无 FFI，天然跨后端 | - |
| T3 | 模块名 | `pinyin/pinyin`（作者占位） | 与工作目录一致，符合 mooncakes 规范 | - |
| T4 | license | `MIT` | 对齐源库 LICENSE（MIT, Copyright (c) 2017 sbiger） | N2 |
| T5 | 零外部依赖 | 无 import 块，仅 moonbitlang/core 隐式 | 源库纯计算，标准库 Map 足够 | - |
| T6 | 字典数据结构 | `Map[Int, Int]` + `Map[String, String]` | MoonBit 惯用可变映射，可变性对齐源库 HashMap | - |
| T7 | 字典存储策略 | 构建期脚本生成 `.mbt` 字面量 | 最稳妥跨后端，编译期验证完整性，无运行时 IO | - |
| T8 | 生成脚本 | `scripts/gen_pinyin_dict.py`（Python 3） | 源库字典格式简单，Python 处理文本高效 | - |
| T9 | 重载实现 | labeled 参数默认值 `format~ = WithToneMark` | MoonBit 不支持传统重载，默认参数语义对齐源库重载 | N5 |
| T10 | 错误模型 | `raise PinyinError`（suberror） | MoonBit 检查式错误惯例，语义对齐源库 throw | - |
| T11 | spec 契约 | `declare` 关键字 | moonbit-agent-guide 最新规范（SKILL.md:358-378） | - |
| T12 | 测试分级 | easy / mid / difficult 三级（snapshot 并入 difficult） | 对齐 skill 3 级约定，避免第 4 个文件 | N3 |
| T13 | 词组匹配 | 最短前缀优先（1→5 字逐长度扫描，首个命中返回） | 对齐源库 getWords 实际语义 | N1 |
| T14 | 繁简反查 | 保留 O(n) 反查，不构建反向索引 | 需求 3.8 不主动优化，避免改变多映射语义 | - |
| T15 | FFI | 无 FFI，无 native-stub，无 link.native | 源库无 C 依赖 | - |
| T16 | 内部方法归属 | pinyin_helper.mbt / tone_conversion.mbt / chinese_helper.mbt 分文件 | 内聚原则，明确归属减少下游 ambiguity | N4 |
| T17 | format 分发 | `match format { ... }` 模式匹配 | 比 source 字符串比较更地道，语义等价 | - |
| T18 | 字符迭代 | `for c in str { ... }` 安全迭代 | 替代源库 unsafe rawData + Rune.fromUtf8 | - |

---

## 十二、需验证的技术假设

| 假设 | 验证方式 | 风险等级 |
|------|---------|---------|
| MoonBit `Map` 字面量支持 20903 条目而无性能问题 | 编码阶段 `moon check` + `moon test --target native` 验证 | 低（标准库 Map 设计支持大规模） |
| `Map[Int, Int]` 字面量用 16 进制码点可读性与编译效率可接受 | 编码阶段 `moon check` 验证 | 低 |
| `StringBuilder` 拼接长句拼音性能对齐源库 | 编码阶段 `moon test --target native` 长句用例验证 | 低 |
| `for c in str` 迭代 BMP 内 CJK 字符无代理对问题 | 编码阶段字典完整性测试验证 | 低（字典均在 BMP 内） |
| `StringView` 切片 `str[:end]` / `str[start:]` 在拼音场景无 UTF-16 边界错误 | 编码阶段 `moon test` 全用例验证 | 低（拼音字符均在 BMP 内） |
| `declare` 关键字声明的 spec 契约与实现分离在 `moon check` 通过 | 编码阶段 `moon check` 验证 | 低（SKILL.md:358-378 已验证） |
| 三后端 `moon test` 全通过 | 编码阶段三后端分别测试 | 低（纯计算无 FFI） |

---

## 十三、不在范围内（对齐需求第四节）

- 不扩展源库能力（不新增拼音风格、不接入分词、不支持自定义声调方案）
- 不保留 Cangjie 构建脚本（`build.cj` / `cjpm.toml` / `.gitignore`）
- 不保留环境变量定位逻辑（`get_file_path.cj` 不移植）
- 不原样移植 `Reliability/` 200 线程压测（可选等价基准）
- 不移植 `FUZZ/` 模糊测试
- 不引入第三方拼音数据源（仅用源库自带字典）
- 不引入 `moonbit-c-binding` / `make-moonbit-c-bindings` / `moonbit-proof` skill
- 不构建 `convert_to_traditional_chinese` 反向索引优化（保留 O(n) 反查语义）
- 不改变词组匹配优先级（保留最短前缀优先语义）

---

## 十四、与架构设计 `design_v2.md` 的衔接

本技术方案完整继承 `design_v2.md` 的架构决策（D1-D16），并落实到技术路径级别：

| 架构决策 | 本方案落实位置 |
|---------|--------------|
| D1 单模块 + 主包 + 数据子包 | §2.2 文件结构 + §3 包配置 |
| D2 类型关联方法 | §7.3 API 方法清单 |
| D3 raise PinyinError | §7.4 错误处理策略 |
| D4 PinyinError 命名 | §7.1 类型形态 |
| D5 Map[Int,Int] + Map[String,String] | §4.1 字典数据结构 |
| D6 单字拼音字典内嵌 | §5.2.4 转写规则 |
| D7 数据子包拆分 | §2.2 文件结构 + §3.3 子包配置 |
| D8 保留 O(n) 反查 | §6.5.2 繁简反查算法 + T14 |
| D9 三后端 | §2.1 工具链版本 + T2 |
| D10 无 FFI | §9 FFI 路径 + T15 |
| D11 全局 let map + 可变原地合并 | §4.2 存储策略 + §6.7 自定义字典追加 |
| D12 PinyinFormat enum | §7.1 类型形态 |
| D13 PinyinHelper/ChineseHelper 空 struct | §7.1 类型形态 |
| D14 spec 契约 + 分级黑盒 + snapshot | §8 测试技术路径 |
| D15 README 10 例 | §8.3 测试分级 + §10.4 测试映射 |
| D16 PinyinDicts 全局 let 常量集合 | §4.2 存储策略 + §5.3 字典视图构造 |

---

## 十五、与审查报告 `output_v1.md` 修订建议的落实

| 审查建议 | 优先级 | 本方案落实位置 | 落实方式 |
|---------|--------|--------------|---------|
| N1：词组匹配"最短前缀优先" | P1 | §6.2 词组匹配算法 + T13 | 明确"最短前缀优先（1→5 字逐长度扫描，首个命中返回）"，修正 design_v2.md "最长前缀优先"错误 |
| N2：license 改为 MIT | P1 | §3.1 moon.mod 配置 + T4 | `license = "MIT"`，对齐源库 LICENSE |
| N3：snapshot 测试文件归属 | P2 | §8.3 测试文件分级 + T12 | 10 个 README snapshot 并入 `pinyin_difficult_test.mbt`，保持 skill 3 级约定 |
| N4：内部方法文件归属 | P2 | §2.2 文件职责注释 + §10.3 内部方法映射 + T16 | 明确 `pinyin_helper.mbt` / `tone_conversion.mbt` / `chinese_helper.mbt` 各自含哪些内部方法 |
| N5：重载用 labeled 参数默认值 | P2 | §7.2 重载实现技术路径 + T9 | `format~ : PinyinFormat = WithToneMark` 默认参数方案 |