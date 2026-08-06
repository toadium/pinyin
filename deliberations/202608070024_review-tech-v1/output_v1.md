# tech_v1.md 独立深入审查报告

## 审查结论

**[APPROVED_WITH_MINOR_REVISIONS]**

`tech_v1.md` 整体质量高，技术方案设计完整、清晰、可实施。完整落实了架构设计 `design_v2.md` 的全部 16 个架构决策（D1-D16）与架构审查报告 `output_v1.md` 的全部 5 条修订建议（N1-N5），技术选型合理可行，MoonBit 生态符合性好，源库保真度高，skill 规范符合性好，可实施性强，测试充分，用户偏好全面体现。本次独立深入审查发现 **1 个轻微事实性偏差**（字典容量"条"与"行"数不一致）与 **2 个观察项**，不影响可实施性，建议修订后进入编码阶段。

## 审查方法

- 逐行阅读 `tech_v1.md` 全部 623 行。
- 逐文件阅读源库 `D:\CodeWorkspace\forCangjie\pinyin4cj\src\` 全部 9 个 `.cj` 源文件，重点核验 `pinyin_helper.cj`（311 行）与 `chinese_helper.cj`（140 行）的内部逻辑、公开 API、内部方法。
- 逐目录清点 `test/HLT/`（14 文件）、`test/LLT/chinese_helper/`（5 文件）、`test/LLT/pinyin_helper/`（17 文件）、`test/FUZZ/`（11 文件）、`test/Reliability/`（11 文件）、`test/DOC/`（1 文件）。
- 阅读源库 `README.md`（验证 10 个示例）、`LICENSE`（验证 MIT 许可证）、`cjpm.toml`（验证构建配置）、`build.cj`（验证 post-build 钩子）、`pinyin_resource.cj`（验证资源加载逻辑）。
- 验证 `pinyin.dict.txt` 行数（41806 行）、`chinese.dict.cj`/`mutil_pinyin.dict.cj`/`tongyong_pinyin_dict.cj` 行数与条目数。
- 运行 `moon version` 验证工具链版本（`moon 0.1.20260713`，Feature flags: rr_moon_mod, rr_moon_pkg）。
- 阅读 `moonbit-agent-guide/SKILL.md` 关键段落（§项目布局 §Map 可变性 §错误处理 §spec-driven §命名规范 §验证循环 §StringBuilder）与 `moonbit-spec-test-development/SKILL.md` 全文。
- 对照架构设计 `design_v2.md`、架构审查报告 `output_v1.md`、需求文档 `req_v1.md`、需求审查报告 `output_v1.md`，逐条核验架构落实性、审查建议落实与需求符合性。

---

## 一、架构落实性

### 1.1 架构决策 D1-D16 落实

**[通过]** 技术方案完整落实了 `design_v2.md` 的全部 16 个架构决策，§十四 提供逐条对应表：

| 架构决策 | tech_v1.md 落实位置 | 判定 |
|---------|-------------------|------|
| D1 单模块 + 主包 + 数据子包 | §2.2 文件结构 + §3 包配置 | ✓ |
| D2 类型关联方法 | §7.3 API 方法清单 | ✓ |
| D3 raise PinyinError | §7.4 错误处理策略 | ✓ |
| D4 PinyinError 命名 | §7.1 类型形态 | ✓ |
| D5 Map[Int,Int] + Map[String,String] | §4.1 字典数据结构 | ✓ |
| D6 单字拼音字典内嵌 | §5.2.4 转写规则 | ✓ |
| D7 数据子包拆分 | §2.2 文件结构 + §3.3 子包配置 | ✓ |
| D8 保留 O(n) 反查 | §6.5.2 繁简反查算法 + T14 | ✓ |
| D9 三后端 | §2.1 工具链版本 + T2 | ✓ |
| D10 无 FFI | §9 FFI 路径 + T15 | ✓ |
| D11 全局 let map + 可变原地合并 | §4.2 存储策略 + §6.7 自定义字典追加 | ✓ |
| D12 PinyinFormat enum | §7.1 类型形态 | ✓ |
| D13 PinyinHelper/ChineseHelper 空 struct | §7.1 类型形态 | ✓ |
| D14 spec 契约 + 分级黑盒 + snapshot | §8 测试技术路径 | ✓ |
| D15 README 10 例 | §8.3 测试分级 + §10.4 测试映射 | ✓ |
| D16 PinyinDicts 全局 let 常量集合 | §4.2 存储策略 + §5.3 字典视图构造 | ✓ |

### 1.2 文件结构偏离

**[观察-轻微]** 架构设计 `design_v2.md` §2.1 文件结构包含 `pinyin_resource.mbt`（字典加载/解析）与 `pinyin_snapshot_test.mbt` 两个文件，技术方案 §2.2 文件结构中均未出现：

- `pinyin_resource.mbt`：技术方案将其职责合并入 `pinyin_dicts.mbt`（§10.1 映射表明确 `pinyin_resource.cj` → `pinyin_dicts.mbt`）。这是合理简化——资源加载改为构建期内嵌后，运行时只需从 `@data` 读取字面量构造 Map，无需单独文件。但 §十四 衔接表未明确说明此合并。
- `pinyin_snapshot_test.mbt`：技术方案 §8.3 明确将 10 个 README snapshot 并入 `pinyin_difficult_test.mbt`（落实审查建议 N3），§十五 已说明。处理得当。

**影响**：无功能影响，仅 §十四 衔接表可补充说明 `pinyin_resource.mbt` 的合并。

---

## 二、审查建议落实

### 2.1 架构审查报告 N1-N5 落实

**[通过]** 技术方案完整落实了架构审查报告 `output_v1.md` 的全部 5 条修订建议，§十五 提供逐条对应表：

| 审查建议 | 优先级 | tech_v1.md 落实位置 | 落实方式 | 判定 |
|---------|--------|-------------------|---------|------|
| N1 词组匹配"最短前缀优先" | P1 | §6.2 词组匹配算法 + T13 | 明确"最短前缀优先（1→5 字逐长度扫描，首个命中返回）"，修正 design_v2.md "最长前缀优先"错误 | ✓ |
| N2 license 改为 MIT | P1 | §3.1 moon.mod 配置 + T4 | `license = "MIT"`，对齐源库 LICENSE | ✓ |
| N3 snapshot 测试文件归属 | P2 | §8.3 测试文件分级 + T12 | 10 个 README snapshot 并入 `pinyin_difficult_test.mbt`，保持 skill 3 级约定 | ✓ |
| N4 内部方法文件归属 | P2 | §2.2 文件职责注释 + §10.3 内部方法映射 + T16 | 明确 `pinyin_helper.mbt` / `tone_conversion.mbt` /1 / `chinese_helper.mbt` 各自含哪些内部方法 | ✓ |
| N5 重载用 labeled 参数默认值 | P2 | §7.2 重载实现技术路径 + T9 | `format~ : PinyinFormat = WithToneMark` 默认参数方案 | ✓ |

### 2.2 需求审查报告 R1-R4 落实

**[通过]** 需求审查报告的修订建议已通过架构设计 `design_v2.md` 传导至技术方案：

| 需求审查建议 | tech_v1.md 体现 | 判定 |
|------------|---------------|------|
| R1 README 示例 10 例 | §8.3 + §8.4.1 + §10.4 明确 10 例 | ✓ |
| R2 源码 9 文件 | §1.3 + §10.1 基于 9 文件理解 | ✓ |
| R3 LLT pinyin_helper 17 文件 | §10.4 测试映射对齐 17 文件 | ✓ |
| R4 依赖列表 | §3.1 零外部依赖 + T5 | ✓ |

---

## 三、技术选型合理性

### 3.1 moon 工具链版本

**[通过]** §2.1 声明 `moon 0.1.20260713`，已通过 `moon version` 实测验证：

```
moon 0.1.20260713 (75c7e1f 2026-07-13)
Feature flags enabled: rr_moon_mod,rr_moon_pkg
```

Feature flags `rr_moon_mod` / `rr_moon_pkg` 已启用，确认支持新格式 `moon.mod` / `moon.pkg`。技术方案声明准确。

### 3.2 目标后端

**[通过]** §2.1 声明 wasm-gc / js / native 三后端平等支持，不设置 `preferred-target`，不设置 `supported_targets` 限制。源库纯计算无 FFI，天然跨后端，选型合理。

### 3.3 字典数据结构选型

**[通过]** §4.1 选用 `Map[Int, Int]`（繁简）+ `Map[String, String]`（拼音），理由充分：

- MoonBit 标准库 `Map` 是可变的、保持插入顺序的映射（SKILL.md:1064 "Map (Mutable, Insertion-Order Preserving)"，SKILL.md:1077-1078 演示 `map["new-key"] = 3` 可变操作）。
- 可变性与源库 Cangjie `HashMap` 对齐，使 `add_*_dict_resource` 可直接原地合并。
- `Map[Int, Int]` 而非 `Map[Char, Char]`：便于生成脚本统一输出 16 进制码点，两者等价。
- 不引入 `@hashmap.T`：标准库 `Map` 足够，零外部依赖原则。

### 3.4 字典存储与加载策略

**[通过]** §4.2 选用构建期内嵌为 MoonBit 字面量，运行时直接构造 Map。理由充分：

- 跨 wasm/js/native 三后端一致，无运行时 IO。
- MoonBit 当前无稳定 `@embed` / `#embed` 原语，字面量转写最稳妥。
- `moon check` 可静态验证字典完整性。
- 不用运行时解析字符串：避免启动延迟与 GC 压力。

### 3.5 重载实现技术路径

**[通过]** §7.2 选用 labeled 参数默认值 `format~ : PinyinFormat = WithToneMark` 实现 `convertToPinyinString` 的 2 重载。MoonBit 不支持传统方法重载，labeled 参数默认值语义对齐源库重载，调用点简洁。选型合理。

### 3.6 错误模型选型

**[通过]** §7.4 选用 `raise PinyinError`（suberror），符合 MoonBit 检查式错误惯例（SKILL.md:801, 816-818），语义对齐源库 `throw`。错误消息文本逐字符对齐源库。选型合理。

### 3.7 spec 契约选型

**[通过]** §8.2 选用 `declare` 关键字声明 API 签名，与 `moonbit-agent-guide` SKILL.md:358-378 最新规范一致。`#declaration_only` 是 `moonbit-spec-test-development` SKILL.md:21 的早期机制，技术方案明确给出取舍理由。选型合理。

### 3.8 FFI 策略

**[通过]** §9 无 FFI 决策正确：源库 9 个 `.cj` 源文件无任何 `extern` 声明（已逐文件验证），不引入 `moonbit-c-binding` / `make-moonbit-c-bindings` skill，不配置 `native-stub/` 与 `link.native`。

### 3.9 生成脚本选型

**[通过]** §5.1 选用 Python 3 脚本 `scripts/gen_pinyin_dict.py`，输入源库字典，输出 MoonBit 字面量。脚本与产物均入版本控制。选型合理，源库字典格式简单，Python 处理文本高效。

---

## 四、MoonBit 生态符合性

### 4.1 moon.mod / moon.pkg 配置

**[通过]** §3.1-3.3 配置符合 SKILL.md:93-110 规范：

- `moon.mod` 新格式（非 legacy `moon.mod.json`）✓
- 模块名 `pinyin/pinyin`（`<author>/pinyin` 形式）✓
- `license = "MIT"`（对齐源库 LICENSE）✓
- 零外部依赖（无 `import` 块，仅 `moonbitlang/core` 隐式）✓
- 不设置 `preferred-target`（三后端平等）✓
- 不设置 `supported_targets`（underscore 形式，符合 SKILL.md:639 规范）✓
- 主包 `moon.pkg` import 数据子包 ✓
- 数据子包 `moon.pkg` 无 import ✓

**核验依据**：SKILL.md:639 `Use supported_targets = "native"`（underscore）。技术方案已修正架构设计 `design_v2.md` 的 `supported-targets`（hyphen）形式。

### 4.2 pkg.generated.mbti 管理

**[通过]** §3.4 符合 SKILL.md:161-165 规范：主包与数据子包各生成 `pkg.generated.mbti`，入版本控制，`moon info` 重新生成，diff 作为公开 API 变更信号。

### 4.3 Map 可变性

**[通过]** §4.1-4.2 正确引用 SKILL.md:1064 "Map (Mutable, Insertion-Order Preserving)"，明确全局 `let` 绑定不可重新赋值但 `Map` 内容可变，与源库 `HashMap` 可变语义对齐。

### 4.4 错误处理

**[通过]** §7.4 符合 SKILL.md:801, 816-818, 859-864 规范：`suberror` + `raise`/`catch` + `try...catch...noraise` 模式。

### 4.5 spec 契约

**[通过]** §8.2 符合 SKILL.md:358-378 规范：`declare` 关键字声明 API 签名，spec 文件不包含实现。

### 4.6 验证循环

**[通过]** §8.5 符合 SKILL.md:27-34 规范：`moon check`（含 `--warn-list +unnecessary_annotation`）→ `moon test`（三后端）→ `moon fmt` → `moon info`。

### 4.7 字符迭代

**[通过]** §6.1 `for c in str { ... }` 安全迭代 Unicode 码点，符合 SKILL.md:984 演示。

---

## 五、源库保真度

### 5.1 公开 API 表面

**[通过]** §7.3 映射表完整覆盖源库全部 15 个公开 API（`ChineseHelper` 6 + `PinyinHelper` 9 含 2 重载），方法签名轮廓、异常标注与源码逐一对应：

| tech_v1.md API | 源码位置 | 语义对齐 | 判定 |
|---------------|---------|---------|------|
| `convert_to_pinyin_string`（labeled 默认值） | pinyin_helper.cj:150, 231 | ✓ 空串 raise、词组优先、非汉字穿插 | ✓ |
| `convert_to_pinyin_string_traditional` | pinyin_helper.cj:209 | ✓ 先繁→简再转拼音 | ✓ |
| `convert_to_pinyin_array` | pinyin_helper.cj:102 | ✓ 非汉字返回 [] | ✓ |
| `get_short_pinyin` | pinyin_helper.cj:241 | ✓ 首字母 + 空分隔符 | ✓ |
| `has_multi_pinyin` | pinyin_helper.cj:251 | ✓ 非汉字 raise | ✓ |
| `add_pinyin_dict_resource` / `add_mutil_pinyin_dict_resource` | pinyin_helper.cj:265, 275 | ✓ 原地合并 | ✓ |
| `to_tongyong_pinyin_string_array` | pinyin_helper.cj:295 | ✓ 数字音标 + 通用拼音替换 | ✓ |
| `convert_to_simplified_chinese` | chinese_helper.cj:53 | ✓ 逐字符查 CHINESE_MAP | ✓ |
| `convert_to_traditional_chinese` | chinese_helper.cj:69 | ✓ O(n) 反查保留 | ✓ |
| `is_traditional_chinese` / `is_chinese` / `contains_chinese` | chinese_helper.cj:89, 105, 121 | ✓ | ✓ |
| `add_chinese_dict_resource` | chinese_helper.cj:137 | ✓ | ✓ |
| `PinyinFormat::name` | pinyin_format.cj:25 | ✓ | ✓ |

### 5.2 内部方法映射

**[通过]** §10.3 内部方法映射表完整覆盖源库全部 9 个内部方法，文件归属明确：

| 源库内部方法 | 源码位置 | MoonBit 文件 | 判定 |
|------------|---------|------------|------|
| `convertWithToneNumber` | pinyin_helper.cj:29 | tone_conversion.mbt | ✓ |
| `convertWithoutTone` | pinyin_helper.cj:63 | tone_conversion.mbt | ✓ |
| `formatPinyin` | pinyin_helper.cj:82 | tone_conversion.mbt | ✓ |
| `convertToPinyinArrays` | pinyin_helper.cj:117 | tone_conversion.mbt | ✓ |
| `getWords` | pinyin_helper.cj:131 | pinyin_helper.mbt | ✓ |
| `convertToPinyinStringResult` | pinyin_helper.cj:214 | pinyin_helper.mbt | ✓ |
| `findArrayKeyByValue` | pinyin_helper.cj:279 | tone_conversion.mbt | ✓ |
| `convertCharToSimplifiedChinese` | chinese_helper.cj:22 | chinese_helper.mbt | ✓ |
| `convertCharToTraditionalChinese` | chinese_helper.cj:38 | chinese_helper.mbt | ✓ |

### 5.3 异常消息文本

**[通过]** §7.4 两个 raise 点消息文本逐字符对齐源库：
- `"Please enter a word or sentence"`（pinyin_helper.cj:153）✓
- `"Please enter a Chinese character"`（pinyin_helper.cj:253）✓

### 5.4 词组匹配语义

**[通过]** §6.2 正确描述源库 `getWords` 语义为"最短前缀优先（1→5 字逐长度扫描，首个命中返回）"，修正了架构设计 `design_v2.md` §4.1 "最长前缀优先"的事实性错误。

**核验依据**：源码 pinyin_helper.cj:131-140 循环 `for(i in 1..min(charArray.size + 1, 6))` 从短到长扫描，命中即 `return [str]`。

### 5.5 声调格式转换

**[通过]** §6.3 声调映射算术与源码对齐：
- 24 带调元音 + 6 无调元音（pinyin_helper.cj:15-16）✓
- `index % 4 + 1` 得声调、`(index - index%4) / 4` 得无调元音索引（pinyin_helper.cj:41-42）✓
- 轻声用数字 `5`（pinyin_helper.cj:51）✓
- `ü` 替换为 `v`（pinyin_helper.cj:71）✓

### 5.6 繁简互转 O(n) 反查

**[通过]** §6.5.2 保留源库 O(n) 反查语义，不构建反向索引，与需求 3.8 "不主动优化"一致。性能特征说明充分（O(L × 2556)）。§6.5.2 正确描述源库 `unsafe { str.rawData() }` + `Rune.fromUtf8` 实现细节，MoonBit 用 `for c in str` 安全迭代替代。

### 5.7 CHINESE_LING 特殊处理

**[通过]** §4.3 + §6.4 提及 `c == '〇'`（U+3007）作为汉字零的特殊处理，与源库 `CHINESE_LING = r'〇'`（pinyin_helper.cj:14）及 `convertToPinyinString` 中 `c == CHINESE_LING` 判定（pinyin_helper.cj:162）对齐。

### 5.8 辅助常量

**[通过]** §4.3 辅助常量表对齐源库：
- `PINYIN_SEPARATOR`：源库 `var = ","` → MoonBit `let = ","`（不可变改进，源库未重新赋值，语义不变）✓
- `CHINESE_LING`：源库 `var : Rune = r'〇'` → MoonBit `let : Char = '〇'`（同上）✓
- `ALL_UNMARKED_VOWEL_ARRAY` / `ALL_MARKED_VOWEL_ARRAY`：源库 `Array<Rune>` → MoonBit `Array[Char]` ✓

### 5.9 字典容量描述

**[问题-轻微]** §4.1 表格"容量"列对三张内嵌字典的"条"数描述存在事实性偏差，写的是源文件行数而非字典条目数：

| 字典 | tech_v1.md 描述 | 实际条目数 | 实际行数 | 偏差 |
|------|---------------|----------|---------|------|
| `CHINESE_MAP` | "2556 条" | 2543 条 | 2556 行 | 13 |
| `MUTIL_PINYIN_TABLE` | "约 856 条" | 845 条 | 858 行 | 11 |
| `TONGYONG_PINYIN_TABLE` | "83 条" | 82 条 | 92 行 | 1 |
| `PINYIN_TABLE` | "20903 条" | 20903 条 | 41806 行（两行一组） | 0（正确） |

§5.2.3 写"tongyong_pinyin_dict.cj（92 行，83 条目）"，实际 92 行 82 条目。

**证据**：通过 `Select-String -Pattern '^\s*\('` 计数源库字典文件条目数：chinese.dict.cj 2543 条、mutil_pinyin_dict.cj 845 条、tongyong_pinyin_dict.cj 82 条。`PINYIN_TABLE` 的 20903 条是正确的（41806 行 / 2 = 20903 组）。

**影响**：不影响设计决策（容量是描述性信息，`PINYIN_TABLE` 的关键容量 20903 已正确），但"条"应指条目数而非行数，存在术语不一致。

### 5.10 不移植项

**[通过]** §10.1 + §十三 正确排除以下源库组件：
- `get_file_path.cj`（环境变量定位）→ 不移植，构建脚本替代 ✓
- `build.cj`（post-build 钩子）→ 不移植，构建脚本替代 ✓
- `Reliability/`（200 线程压测）→ 不原样移植 ✓
- `FUZZ/`（模糊测试）→ 不移植 ✓
- `test_performance_01.cj`（性能测试）→ 不移植（可选等价基准）✓

### 5.11 移植映射表完整性

**[通过]** §10.1 源库模块 → MoonBit 包映射表完整覆盖源库全部 9 源文件 + 1 外部资源 + 构建配置 + 测试目录 + 文档，无遗漏。§10.4 源库测试 → MoonBit 测试映射表完整覆盖源库全部 HLT 14 文件 + LLT 22 文件（pinyin_helper 17 + chinese_helper 5）+ README 10 示例 + DOC 1 文件，无遗漏。

---

## 六、skill 规范符合性

### 6.1 moonbit-agent-guide

**[通过]** 核心规范全面符合：

| 规范点 | tech_v1.md 符合位置 | SKILL.md 行号 | 判定 |
|-------|-------------------|-------------|------|
| `moon.mod` + `moon.pkg` 新格式 | §3.1-3.3 | 93-110 | ✓ |
| 多小文件、内聚原则 | §2.2 文件组织 | 136-151 | ✓ |
| `moon check` → `moon test` → `moon fmt` → `moon info` | §8.5 验证循环 | 27-34 | ✓ |
| `--warn-list +unnecessary_annotation`（warning 73） | §8.5 | 28 | ✓ |
| `pkg.generated.mbti` 入版本控制 | §3.4 | 161-165 | ✓ |
| `Map` 可变映射 | §4.1-4.2 | 1064, 1077-1078 | ✓ |
| `suberror` + `raise`/`catch` 错误处理 | §7.1, §7.4 | 801, 816-818 | ✓ |
| `declare` 关键字 spec 契约 | §8.2 | 358-378 | ✓ |
| `inspect()` snapshot 测试 | §8.4.1 | 317-318 | ✓ |
| `try...catch...noraise` 异常测试 | §8.4.2 | 859-864 | ✓ |
| lower_snake 函数 + UpperCamel 类型 | §7.3 | 792 | ✓ |
| `pub(all)` 公开构造 | §7.1 | 791 | ✓ |
| `for c in str` 字符迭代 | §6.1 | 984 | ✓ |
| `supported_targets`（underscore） | §3.1 | 639 | ✓ |

### 6.2 moonbit-spec-test-development

**[通过]** spec 契约 + 分级黑盒测试符合规范：

- `<pkg>_spec.mbt` 形式化契约 ✓（SKILL.md:9, 20-24）
- `<pkg>_easy_test.mbt` / `<pkg>_mid_test.mbt` / `<pkg>_difficult_test.mbt` 三级分级 ✓（SKILL.md:28）
- 黑盒测试用公开 API ✓（SKILL.md:29）
- snapshot 测试并入 `pinyin_difficult_test.mbt`，保持 skill 3 级约定（落实审查建议 N3）✓

**`declare` vs `#declaration_only` 取舍**：技术方案 §8.2 明确采用 `declare` 关键字（moonbit-agent-guide SKILL.md:358-378 最新规范），而非 `#declaration_only`（moonbit-spec-test-development SKILL.md:21 早期机制）。取舍理由明确（以 moonbit-agent-guide 最新规范为准），处理得当。

### 6.3 moonbit-c-binding / make-moonbit-c-bindings / moonbit-proof

**[通过]** 正确排除：源库无 C 依赖（已逐文件验证无 `extern`），非形式化验证场景。§2.3 + §9 + §十三 均明确排除。

---

## 七、可实施性

### 7.1 设计清晰度

**[通过]** 技术方案结构清晰、无歧义：

- §一 概述 + §二 工具链与布局 + §三 包配置 + §四 数据结构 + §五 字典构建 + §六 算法路径 + §七 API 形态 + §八 测试路径 + §九 FFI + §十 移植映射表 + §十一 决策汇总 + §十二 需验证假设 + §十三 不在范围内 + §十四 架构衔接 + §十五 审查建议落实，组织逻辑连贯。
- 每个核心技术路径均给出源库语义 + MoonBit 实现路径 + 关键约束。
- §十 移植映射表提供源库 → MoonBit 的完整映射（模块、API、内部方法、测试）。
- §十一 关键技术决策汇总 T1-T18 每条含决策点、选择、理由、落实审查建议。
- §十二 需验证的技术假设列出 7 个假设，均有验证方式与风险等级。

### 7.2 内部方法文件归属

**[通过]** §2.2 文件职责注释 + §10.3 内部方法映射表明确归属：
- `pinyin_helper.mbt`：`get_words` / `convert_to_pinyin_string_result`
- `tone_conversion.mbt`：`convert_with_tone_number` / `convert_without_tone` / `format_pinyin` / `convert_to_pinyin_arrays` / `find_array_key_by_value`
- `chinese_helper.mbt`：`convert_char_to_simplified_chinese` / `convert_char_to_traditional_chinese`

### 7.3 重载实现方式

**[通过]** §7.2 明确 labeled 参数默认值方案，给出伪代码示意与调用点示例，无歧义。

### 7.4 StringBuilder 来源

**[观察-轻微]** §6.1 写"推荐用 StringBuilder + to_string() 对齐源库 resultPinyinStrBuf 模式"，但 StringBuilder 来源描述为"@buffer 包或内置"有些模糊。

**核验依据**：SKILL.md:1004 演示 `let sb = StringBuilder()` 直接构造，`sb <+ "..."` 追加。StringBuilder 是 MoonBit 内置类型，无需 `@buffer` 包。

**影响**：不影响可实施性（编码者可从 SKILL.md:1004-1011 找到正确用法），但建议明确为"MoonBit 内置 StringBuilder 类型"以减少歧义。

### 7.5 算法实现路径

**[通过]** §6 核心算法技术实现路径覆盖全部关键算法：
- §6.1 字符串与字符处理 ✓
- §6.2 词组匹配算法（含源库语义 + MoonBit 实现路径 + 关键约束）✓
- §6.3 声调格式转换算法（4 个子方法逐一描述）✓
- §6.4 词句转拼音主流程（含源库行号 + 实现路径）✓
- §6.5 繁简互转算法（2 个子方法逐一描述）✓
- §6.6 通用拼音算法 ✓
- §6.7 自定义字典追加算法 ✓

---

## 八、测试充分性

### 8.1 测试覆盖范围

**[通过]** §8.3 测试分级覆盖源库全部测试语义：

| tech_v1.md 测试文件 | 覆盖范围 | 对齐源库 | 判定 |
|-------------------|---------|---------|------|
| `pinyin_easy_test.mbt` | 单字转换、繁简互转、判定方法、边界、异常 | HLT 14 文件简单用例 | ✓ |
| `pinyin_mid_test.mbt` | 词句转换、自定义字典、多音字 | HLT 组合 + LLT `test_pinyin_multi` / `test_pinyin_dict_*` | ✓ |
| `pinyin_difficult_test.mbt` | 长句四连测、通用拼音 30+、issue 回归、字典完整性、10 个 README snapshot | LLT `test_pinyin_01~03` / `test_tongyong_01` / `test_issue*` / `test_chinese_dict_*` + README 10 例 | ✓ |

### 8.2 spec 契约

**[通过]** §8.2 `pinyin_spec.mbt` 采用 `declare` 关键字声明全部公开 API 签名（类型、方法、错误），作为实现与测试的共同基准，创建后视为只读契约。符合 moonbit-agent-guide SKILL.md:358-378 规范。

### 8.3 测试技术

**[通过]** §8.4 测试技术选择合理：
- snapshot 测试用 `inspect(value, content="...")` + `moon test --update` ✓
- 异常测试用 `try...catch...noraise` 模式 ✓
- 黑盒调用通过同包自动引用或显式 `@pinyin` ✓
- 不移植 `FUZZ/` 与 `Reliability/` ✓

### 8.4 验证循环

**[通过]** §8.5 紧凑循环 `moon check` → `moon test`（三后端）→ `moon fmt` → `moon info` 符合 SKILL.md:27-34 规范，且明确三后端分别测试。批量验证策略（用户偏好 P8）已体现。

### 8.5 README 示例覆盖

**[通过]** §8.4.1 明确 10 个 README 示例精确输出对等，分类正确：

| 分类 | 数量 | 对应 README 示例 |
|------|------|---------------|
| 繁简互转 | 2 例 | 示例 1（繁→简）+ 示例 2（简→繁） |
| 词句转拼音 | 2 例 | 示例 3（词句转拼音）+ 示例 4（自定义输出格式） |
| 自定义字典 | 3 例 | 示例 5-7（自定义拼音/词组/中文字典） |
| 多音字 | 1 例 | 示例 8（多音字转拼音集合） |
| 繁简体转拼音 | 1 例 | 示例 9（繁简体转拼音） |
| 通用拼音 | 1 例 | 示例 10（繁简体转通用拼音） |
| **合计** | **10 例** | ✓ |

**核验依据**：源库 README.md 中"示例代码如下："出现 10 次（行 90, 110, 130, 150, 170, 193, 215, 238, 257, 276）。

---

## 九、用户偏好符合性

| 偏好 | tech_v1.md 体现 | 判定 |
|------|---------------|------|
| MoonBit 语言 + moon + mooncakes | §2.1 工具链 + §3 包配置 + §7.8 模块发布名 | ✓ |
| PascalCase 类型名 | §7.1 类型形态（PinyinHelper / ChineseHelper / PinyinFormat / PinyinError） | ✓ |
| snake_case 方法名 | §7.3 命名规范（convert_to_pinyin_string 等） | ✓ |
| 简体中文交互 + 英文术语 | 全文风格一致 | ✓ |
| 代码注释与文档 | §8.2 spec 契约 + README.mbt.md 含 10 个 mbt check 示例 | ✓ |
| spec-driven 测试 | §8.1 双轨策略 | ✓ |
| 详细需求分析 | §6 算法路径 + §10 移植映射表 + §11 决策汇总 | ✓ |
| 行动导向 | 技术条款以决策式语句表述 | ✓ |
| 不引入第三方数据源 | §十三 明确 | ✓ |
| 批量验证策略 | §8.5 引用用户偏好 P8 | ✓ |
| kebab-case 文档命名 | 文件名 pinyin_helper.mbt 等 + 文档名 tech_v1.md | ✓ |

---

## 十、修订建议（按优先级排序）

### P1 — 建议修订（事实性偏差，提升精确度）

| 编号 | 问题 | 证据 | 建议修订 |
|------|------|------|---------|
| M1 | §4.1 表格"容量"列对 `CHINESE_MAP` / `MUTIL_PINYIN_TABLE` / `TONGYONG_PINYIN_TABLE` 的"条"数写的是源文件行数而非字典条目数；§5.2.3 写"83 条目" | `Select-String` 计数：chinese.dict.cj 2543 条（非 2556）、mutil_pinyin_dict.cj 845 条（非 856）、tongyong_pinyin_dict.cj 82 条（非 83）；`PINYIN_TABLE` 的 20903 条正确 | 将 §4.1 表格"容量"列改为实际条目数（2543 / 845 / 82），或明确标注为"行数"而非"条"；§5.2.3 "83 条目"改为"82 条目" |

### P2 — 观察项（无需修订，记录备查）

| 编号 | 观察 | 说明 |
|------|------|------|
| O1 | §6.1 StringBuilder 来源描述为"@buffer 包或内置"有些模糊 | SKILL.md:1004 演示 StringBuilder 是 MoonBit 内置类型，直接 `StringBuilder()` 构造；建议明确为"MoonBit 内置 StringBuilder 类型"以减少歧义，但不影响可实施性 |
| O2 | §2.2 文件结构合并了架构设计 `design_v2.md` 的 `pinyin_resource.mbt` 与 `pinyin_dicts.mbt` 为一个文件 | 合理简化（资源加载改为构建期内嵌后无需单独文件），§10.1 映射表已明确，但 §十四 衔接表未补充说明此合并 |
| O3 | §6.4 词句转拼音主流程"i += words.length"中 `words.length` 语义略模糊 | 源码为 `i += words.toRuneArray().size`（词组字符数）；技术方案标注"伪代码示意（非最终实现）"，可接受，但建议明确为 `words.to_array().length()` 或 `words.char_count()` |

---

## 十一、与此前 review_v1.md 的对比

此前 `review_v1.md`（technical-design-harness verifier）返回 [APPROVED]，确认技术方案完整落实架构决策与审查建议，逐维度审查通过。本次独立深入审查确认了技术方案的质量，在更深层的事实性核验中发现 1 个轻微问题：

- **M1（轻微）**：§4.1 字典容量"条"与"行"数不一致，此前审查未核验源库字典文件的实际条目数。

本次审查在源库保真度验证深度上更进一步：逐方法核验了源库 `pinyin_helper.cj` 的 `getWords` 循环逻辑（验证最短前缀优先）、`convertWithToneNumber` / `convertWithoutTone` 的算术映射、`toTongyongPinyinStringArray` 的拆分逻辑、`convertToPinyinString` 主流程；核验了源库 `chinese_helper.cj` 的 `convertToTraditionalChinese` 的 `unsafe rawData` 实现；逐文件计数了三张内嵌字典的条目数；并通过 `moon version` 实测验证了工具链版本与 feature flags。

**总体评价**：`tech_v1.md` 技术方案设计质量高，M1 为轻微事实性偏差，修订成本低，不影响整体技术路径与可实施性。修订后可进入编码阶段。