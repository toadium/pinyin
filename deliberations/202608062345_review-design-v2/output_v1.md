# design_v2.md 独立深入审查报告

## 审查结论

**[APPROVED_WITH_MINOR_REVISIONS]**

`design_v2.md` 整体质量高，架构级 OOD 设计完整、清晰、可实施。v2 修订已彻底解决 v1 的 `Map` 可变性事实性错误，各核心抽象职责划分合理，MoonBit 可行性论证充分，源库保真度高，skill 规范符合性好。但本次独立深入审查发现 **2 个中等严重度问题**（词组匹配优先级描述矛盾、许可证声明事实性错误）与 **5 个轻微问题**，建议修订后再进入下游详细设计。此前 `review_v2.md` 的 APPROVED 结论方向正确，但对 §4.1 词组匹配语义和 §8.1 许可证事实未做深入核验，本次审查在此两处有新增发现。

## 审查方法

- 逐行阅读 `design_v2.md` 全部 461 行。
- 逐文件阅读源库 `D:\CodeWorkspace\forCangjie\pinyin4cj\src\` 全部 9 个 `.cj` 源文件，重点核验 `pinyin_helper.cj`（311 行）与 `chinese_helper.cj`（140 行）的内部逻辑与公开 API。
- 逐目录清点 `test/HLT/`（14 文件）、`test/LLT/chinese_helper/`（5 文件）、`test/LLT/pinyin_helper/`（17 文件）。
- 阅读源库 `README.md`（验证 10 个示例）、`LICENSE`（验证许可证类型）、`cjpm.toml`（验证构建配置）、`build.cj`（验证 post-build 钩子）。
- 阅读 `moonbit-agent-guide/SKILL.md` 关键段落（§项目布局、§Map 可变性、§错误处理、§spec-driven、§命名规范、§验证循环）与 `moonbit-spec-test-development/SKILL.md` 全文。
- 对照需求文档 `req_v1.md` 与需求审查报告 `output_v1.md`，逐条核验需求符合性与修订建议采纳情况。
- 对照此前验证报告 `review_v2.md`，确认其审查范围与本次新增发现。

---

## 一、需求符合性

### 1.1 需求文档 req_v1.md 覆盖

**[通过]** 设计完整覆盖需求文档的全部移植需求：

| 需求条款 | 设计覆盖位置 | 判定 |
|---------|------------|------|
| 3.1 完整移植范围 | §1.1 设计目标 + §十二 不在范围内 | ✓ |
| 3.2 API 对等性（语义 + 命名） | §7.5 API 风格 + §三 核心抽象方法语义 | ✓ |
| 3.3 字典数据移植策略 | §7.4 三张内嵌字典转写 + §3.5 数据结构选型 | ✓ |
| 3.4 单字拼音外部资源加载 | §7.3 单字拼音字典内嵌策略 | ✓ |
| 3.5 异常模型转换 | §五 错误处理策略 + §3.2 PinyinError | ✓ |
| 3.6 目标后端 | §7.1 三后端 + §8.1 moon.mod 配置 | ✓ |
| 3.7 测试策略 | §九 测试架构 | ✓ |
| 3.8 非功能性要求 | §7.7 不优化 + §6 并发 + §9 测试 | ✓ |
| 3.9 工程规范 | §2 模块结构 + §8 包结构 + §9.5 验证循环 | ✓ |
| 第四节 不做什么 | §十二 不在范围内（逐条对应） | ✓ |
| 第五节 交付物清单 | §2.1 文件结构覆盖全部 7 项交付物 | ✓ |
| 第六节 开放问题 | §七 关键设计决策 D1-D16 逐条决策 | ✓ |

### 1.2 需求审查报告 output_v1.md 修订建议采纳

**[通过]** 设计充分采纳审查报告全部修订建议，§十一「与审查报告的呼应」逐条对应：

| 审查报告修订建议 | 设计采纳位置 | 判定 |
|---------------|------------|------|
| R1（README 示例 10 例） | §9.3 表格 + D15 决策 | ✓ |
| R2（源码 9 文件） | §2.1 结构基于 9 文件理解 | ✓ |
| R3（LLT pinyin_helper 17 文件） | §9.3 测试覆盖对齐 | ✓ |
| R4（依赖列表） | §7.1 零外部依赖 + §2.3 不引入 | ✓ |
| R5（文件大小精确值） | §7.3 用 244 KB / 41806 行 | ✓ |

---

## 二、架构合理性

### 2.1 职责划分

**[通过]** 五大核心抽象职责清晰、无重叠：

- `PinyinFormat`：纯格式策略（4 变体 enum），无副作用。
- `PinyinError`：纯错误消息载体（suberror），无逻辑。
- `PinyinHelper`：拼音转换命名空间，依赖 `ChineseHelper` + `PinyinDicts` + `PinyinFormat`。
- `ChineseHelper`：繁简互转 + 汉字判定命名空间，依赖 `PinyinDicts`。
- `PinyinDicts`：字典视图聚合（全局 let 常量），无外部依赖。

职责边界与源库 `PinyinHelper` / `ChineseHelper` / `PinyinResource` 三类划分对齐，无职责泄漏。

### 2.2 抽象层次

**[通过]** 抽象层次恰当，无过度设计亦无设计不足：

- 无抽象工厂、无依赖注入、无策略模式注入（源库亦无）。
- 保留源库命名空间组织（空 struct + 关联方法），降低移植 review 成本。
- `PinyinDicts` 采用全局 `let` 常量集合而非 `struct` 包装（D16），减少抽象层次，与 `Map` 可变性配合支持 `add_*` 语义。

### 2.3 协作模式

**[通过]** 协作关系形成闭环，无缺失环节：

```
PinyinHelper ──→ ChineseHelper（汉字判定 + 繁简预处理）
     │                    │
     ↓                    ↓
PinyinDicts ←─────────────┘
     ↑
     │
  @data 子包（字面量）
```

主包单向依赖数据子包，数据子包零依赖，无循环。

---

## 三、MoonBit 可行性

### 3.1 类型系统

**[通过]** 核心类型形态与 MoonBit 类型系统能力匹配：

- `pub(all) enum PinyinFormat`：4 变体无附加数据，MoonBit enum 惯用形态（SKILL.md:565 演示 `pub(all) enum`）。
- `pub(all) suberror PinyinError`：MoonBit 检查式错误类型惯用形态（SKILL.md:816-818, 826 演示 `suberror`）。
- `pub struct PinyinHelper` / `pub struct ChineseHelper`：空 struct + 类型关联方法作为命名空间，`Type::method()` 调用语义等价于源库 `static`。
- `Map[Int, Int]` / `Map[String, String]`：MoonBit 标准库 `Map`，字面量构造 `{ "k": "v" }` 语法支持（SKILL.md:1070）。

### 3.2 Map 可变性（v2 修订核验）

**[通过]** v2 修订已彻底修正 v1 的事实性错误：

- §3.5 正确引用 SKILL.md:1064 "Map (Mutable, Insertion-Order Preserving)"。
- §6.2 正确采用方案 B（全局 `let map : Map` + `add_*` 直接调用 `Map` 可变操作原地合并），无需 `Ref[Map]` 包装。
- §7.6 新增 "MoonBit `Map` 特性说明" 段，明确可变性与源库 `HashMap` 对齐。
- D5 / D11 决策汇总与正文一致。

**核验依据**：SKILL.md:1064 标题 "Map (Mutable, Insertion-Order Preserving)"；SKILL.md:1077-1078 演示 `map["new-key"] = 3` 可变操作。

### 3.3 错误处理

**[通过]** `raise PinyinError` + `catch` 模式匹配符合 MoonBit 检查式错误惯例：

- SKILL.md:801 "MoonBit uses checked error-throwing functions... you can declare your own error types using `suberror`"。
- SKILL.md:859-864 演示 `try ... catch { ... } noraise { ... }` 模式，与设计 §9.4 异常测试形式一致。
- 错误消息文本逐字符对齐源库（§5.3 已验证）。

### 3.4 包结构

**[通过]** `moon.mod` + `moon.pkg` 新格式符合 SKILL.md:93-110 规范：

- 单模块 + 主包 + 数据子包组织合理，依赖方向单向。
- 测试文件 `*_test.mbt` 自动引用所在包（SKILL.md:153-159 黑盒测试规范）。
- `pkg.generated.mbti` 入版本控制（SKILL.md:161-165）。

### 3.5 资源加载与跨后端

**[通过]** 构建期内嵌字面量策略可行：

- 源库 `pinyin_resource.cj` 的运行时文件系统加载（`getFilePath()` + `File(resourceName, ReadWrite)`）被替换为构建期脚本生成 `.mbt` 字面量，运行时直接构造为 `Map`。
- 跨 wasm/js/native 三后端一致，无运行时 IO，无环境变量依赖。
- MoonBit 当前无稳定 `@embed` / `#embed` 原语，字面量转写是最稳妥方案。

### 3.6 FFI 策略

**[通过]** 无 FFI 决策正确：源库无任何 `extern` 声明（已逐文件验证），不引入 `moonbit-c-binding` / `make-moonbit-c-bindings` skill。

---

## 四、源库保真度

### 4.1 公开 API 表面

**[通过]** 设计完整覆盖源库全部 15 个公开 API（`ChineseHelper` 6 + `PinyinHelper` 9 含 2 重载），方法语义描述与源码逐一对应：

| 设计 §3.3/§3.4 方法 | 源码位置 | 语义对齐 | 判定 |
|-------------------|---------|---------|------|
| `convert_to_pinyin_string`（2 重载） | pinyin_helper.cj:150, 231 | ✓ 空串 raise、词组优先、非汉字穿插 | ✓ |
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

### 4.2 异常消息文本

**[通过]** 两个 `raise` 点消息文本逐字符对齐源库：
- `"Please enter a word or sentence"`（pinyin_helper.cj:153）✓
- `"Please enter a Chinese character"`（pinyin_helper.cj:253）✓

### 4.3 词组匹配优先级

**[问题-中等]** §4.1 描述存在内部矛盾，可能导致下游实现错误。

**证据**：
- §4.1 正文："命中则按词组输出（**最长前缀优先**，对应源库 `getWords` 从短到长返回首个命中……）"
- 源库 `pinyin_helper.cj:131-140` 实际逻辑：
  ```cangjie
  for(i in 1..min(charArray.size + 1, 6)) {
      let str = String(charArray.slice(0, i))
      match(MUTIL_PINYIN_TABLE.get(str)) {
          case None => continue
          case Some(_) => return [str]
      }
  }
  ```
  循环变量 `i` 从 `1` 递增到 `min(size+1, 6)-1`（即 1→5），对每个长度 `i` 取前缀查表，**命中即返回**。因此源库实际语义是**最短前缀优先**（从短到长扫描，返回首个命中）。

**问题**：正文"最长前缀优先"与源库"最短前缀优先"语义相反；括注"从短到长返回首个命中"与正文"最长前缀优先"自相矛盾。若下游实现者据"最长前缀优先"实现，将改变词组匹配行为，破坏语义对等硬约束。

**建议修订**：将"最长前缀优先"改为"最短前缀优先（从 1 字到 5 字逐长度扫描，首个命中即返回）"，删除矛盾括注。

### 4.4 声调格式转换

**[通过]** §4.2 声调映射算术与源码对齐：
- 24 带调元音 + 6 无调元音（pinyin_helper.cj:15-16）✓
- `index % 4 + 1` 得声调、`(index - index%4) / 4` 得无调元音索引（pinyin_helper.cj:41-42）✓
- 轻声用数字 `5`（pinyin_helper.cj:51）✓
- `ü` 替换为 `v`（pinyin_helper.cj:71）✓

### 4.5 繁简互转 O(n) 反查

**[通过]** §3.4 / §4.3 / §7.7 保留源库 O(n) 反查语义，不构建反向索引，与需求 3.8 "不主动优化"一致。性能特征说明充分（O(L × 2556)）。

### 4.6 CHINESE_LING 特殊处理

**[通过]** §4.1 提及 `c == '〇'`（U+3007）作为汉字零的特殊处理，与源库 `CHINESE_LING = r'〇'`（pinyin_helper.cj:14）及 `convertToPinyinString` 中 `c == CHINESE_LING` 判定（pinyin_helper.cj:162）对齐。

### 4.7 不移植项

**[通过]** 以下源库组件正确排除：
- `get_file_path.cj`（环境变量定位）→ 不移植，§7.3 内嵌策略替代 ✓
- `build.cj`（post-build 钩子）→ 不移植，构建脚本替代 ✓
- `Reliability/`（200 线程压测）→ 不原样移植，§6.3 ✓
- `FUZZ/`（模糊测试）→ 不移植，§9.4 ✓

---

## 五、skill 规范符合性

### 5.1 moonbit-agent-guide

**[通过]** 核心规范符合：

| 规范点 | 设计符合位置 | SKILL.md 行号 | 判定 |
|-------|------------|-------------|------|
| `moon.mod` + `moon.pkg` 新格式 | §8.1, §8.2 | 93-110 | ✓ |
| 多小文件、内聚原则 | §2.1 文件组织 | 136-151 | ✓ |
| `moon check` → `moon test` → `moon fmt` → `moon info` | §9.5 验证循环 | 27-34 | ✓ |
| `--warn-list +unnecessary_annotation`（warning 73） | §9.5 | 28 | ✓ |
| `pkg.generated.mbti` 入版本控制 | §8.4 | 161-165 | ✓ |
| `Map` 可变映射 | §3.5, §7.6 | 1064, 1077-1078 | ✓ |
| `suberror` + `raise`/`catch` 错误处理 | §3.2, §5.2 | 801, 816-818 | ✓ |
| `declare` 关键字 spec 契约 | §9.2 | 358-378 | ✓ |
| `inspect()` snapshot 测试 | §9.4 | 317-318 | ✓ |
| `try...catch...noraise` 异常测试 | §9.4 | 329, 859-864 | ✓ |
| lower_snake 函数 + UpperCamel 类型 | §7.5 | 792 | ✓ |
| `pub(all)` 公开构造 | §3.1, §3.2 | 791 | ✓ |

### 5.2 moonbit-spec-test-development

**[通过，含观察]** spec 契约 + 分级黑盒测试符合规范：

- `<pkg>_spec.mbt` 形式化契约 ✓（SKILL.md:9, 20-24）
- `<pkg>_easy_test.mbt` / `<pkg>_mid_test.mbt` / `<pkg>_difficult_test.mbt` 分级 ✓（SKILL.md:28）
- 黑盒测试用公开 API ✓（SKILL.md:29）

**[观察-轻微]** §9.2 选择 `declare` 关键字（moonbit-agent-guide SKILL.md:358-378）而非 `#declaration_only`（moonbit-spec-test-development SKILL.md:21）。设计已给出明确取舍理由（以 moonbit-agent-guide 最新规范为准），处理得当。但两 skill 间存在规范张力，建议后续向 skill 维护方反馈统一。

**[问题-轻微]** §9.3 引入第 4 个测试文件 `pinyin_snapshot_test.mbt`，超出 skill 的 3 级分级约定（easy/mid/difficult）。SKILL.md:28 说"or similar"故不违规，但 snapshot 测试可并入 `pinyin_difficult_test.mbt`（10 个 README 示例属困难级）。当前拆分不影响正确性，仅增加一个文件。

### 5.3 moonbit-c-binding / make-moonbit-c-bindings / moonbit-proof

**[通过]** 正确排除：源库无 C 依赖（已逐文件验证无 `extern`），非形式化验证场景。§2.3 / §7.2 / §十二 均明确排除。

---

## 六、测试架构充分性

### 6.1 测试覆盖范围

**[通过]** §9.3 测试分级覆盖源库全部测试语义：

| 设计测试文件 | 覆盖范围 | 对齐源库 | 判定 |
|------------|---------|---------|------|
| `pinyin_easy_test.mbt` | 单字转换、繁简互转、判定方法、边界、异常 | HLT 14 文件简单用例 | ✓ |
| `pinyin_mid_test.mbt` | 词句转换、自定义字典、多音字 | HLT 组合 + LLT `test_pinyin_multi` / `test_pinyin_dict_*` | ✓ |
| `pinyin_difficult_test.mbt` | 长句四连测、通用拼音 30+、issue 回归、字典完整性 | LLT `test_pinyin_01~03` / `test_tongyong_01` / `test_issue*` / `test_chinese_dict_*` | ✓ |
| `pinyin_snapshot_test.mbt` | 10 个 README 示例精确输出 | 源库 README 10 例（R1 修正） | ✓ |

### 6.2 spec 契约

**[通过]** §9.2 `pinyin_spec.mbt` 采用 `declare` 关键字声明全部公开 API 签名（类型、方法、错误），作为实现与测试的共同基准，创建后视为只读契约。符合 moonbit-agent-guide SKILL.md:358-378 规范。

### 6.3 验证循环

**[通过]** §9.5 紧凑循环 `moon check` → `moon test`（三后端）→ `moon fmt` → `moon info` 符合 SKILL.md:27-34 规范，且明确三后端分别测试（`--target wasm-gc` / `--target js` / `--target native`）。

### 6.4 测试技术

**[通过]** §9.4 测试技术选择合理：
- snapshot 测试用 `inspect(value, content="...")` + `moon test --update` ✓
- 异常测试用 `try...catch...noraise` 模式 ✓
- 黑盒调用通过 `@pinyin` 或同包自动引用 ✓

---

## 七、清晰性与可实施性

### 7.1 设计清晰度

**[通过]** 设计结构清晰、无歧义：

- §一 概述 + §二 模块划分 + §三 核心抽象 + §四 行为契约 + §五 错误处理 + §六 并发 + §七 决策 + §八 包结构 + §九 测试 + §十 决策汇总 + §十一 呼应 + §十二 不在范围内，组织逻辑连贯。
- 每个核心抽象均给出类型形态、职责、协作、设计理由。
- 关键行为契约（§4.1-4.5）提供足够实现指导。

### 7.2 可实施性

**[通过，含轻微观察]** 下游可据此实施，但有一处内部方法文件归属未明确：

**[问题-轻微]** §2.1 文件结构列出 `pinyin_helper.mbt` / `tone_conversion.mbt` 等，但未明确源库内部方法（`formatPinyin`、`convertToPinyinArrays`、`getWords`、`convertToPinyinStringResult`、`findArrayKeyByValue`）的 MoonBit 文件归属。这些是 `pinyin_helper.cj` 的 `static`（非 public）方法，移植后应放入 `pinyin_helper.mbt` 或 `tone_conversion.mbt`。架构级设计可不留此细节，但明确归属可减少下游 ambiguity。

**建议**：在 §2.1 文件结构注释中补充 `pinyin_helper.mbt` 含 `get_words` / `convert_to_pinyin_string_result` 等内部方法，`tone_conversion.mbt` 含 `format_pinyin` / `convert_to_pinyin_arrays` / `find_array_key_by_value`。

### 7.3 重载实现方式

**[问题-轻微]** §3.3 称 `convert_to_pinyin_string` 有"2 重载，含默认 `WithToneMark`"。MoonBit 不支持传统方法重载，需通过 labeled 参数默认值（`format~ : PinyinFormat = PinyinFormat::WithToneMark`）或两个不同名方法实现。设计说"签名留待详细设计"，架构级不决策可接受，但建议明确提示下游用 labeled 参数默认值方案，避免歧义。

---

## 八、用户偏好符合性

| 偏好 | 设计体现 | 判定 |
|------|---------|------|
| MoonBit 语言 + moon + mooncakes | §8.1 moon.mod + §7.8 模块发布名 | ✓ |
| kebab-case 文档命名 | §2.1 文件名 + §8 包名 | ✓ |
| PascalCase 类型名 | §7.5 命名映射（PinyinHelper 等） | ✓ |
| 简体中文交互 + 英文术语 | 全文风格一致 | ✓ |
| 代码注释与文档 | §9.2 spec 契约 + README.mbt.md 含示例 | ✓ |
| spec-driven 测试 | §9.1 双轨策略 | ✓ |
| 详细需求分析 | §三 核心抽象 + §四 行为契约 + §七 决策 | ✓ |
| 行动导向 | 设计条款以决策式语句表述 | ✓ |
| 不引入第三方数据源 | §十二 明确 | ✓ |
| 彻底根因分析 | §6.2 并发安全多方案分析 + §7.7 不优化理由 | ✓ |

---

## 九、新增发现（此前 review_v2.md 未涉及）

### 9.1 许可证声明事实性错误

**[问题-中等]** §8.1 `moon.mod` 配置写 `license = "Apache-2.0"` 并注释"对齐源库 LICENSE"，但源库 `D:\CodeWorkspace\forCangjie\pinyin4cj\LICENSE` 实际为 **MIT License**（首行 "MIT License"，Copyright (c) 2017 sbiger）。

**证据**：
- 源库 LICENSE 文件第 1 行：`MIT License`
- 设计 §8.1：`license = "Apache-2.0"            # 对齐源库 LICENSE`

**影响**：事实性错误。若下游直接采用 `Apache-2.0`，与源库许可证不一致，可能引发合规问题。

**建议修订**：将 `license = "Apache-2.0"` 改为 `license = "MIT"` 以真正对齐源库；或在 §8.1 明确说明"移植版采用 Apache-2.0（与源库 MIT 不同），理由为……"并给出合理依据（如 MoonBit 生态惯例、用户偏好等）。

### 9.2 词组匹配优先级描述矛盾

**[问题-中等]** 详见 §4.3。§4.1 "最长前缀优先"与源库"最短前缀优先"语义相反，括注自相矛盾。此前 `review_v2.md` 未核验此行为契约的准确性。

---

## 十、修订建议（按优先级排序）

### P1 — 必须修订（事实性错误，影响下游实现正确性）

| 编号 | 问题 | 证据 | 建议修订 |
|------|------|------|---------|
| N1 | §4.1 词组匹配优先级写"最长前缀优先"，与源库"最短前缀优先"语义相反；括注"从短到长返回首个命中"与正文自相矛盾 | `pinyin_helper.cj:131-140` 循环 `for(i in 1..min(charArray.size + 1, 6))` 从短到长扫描，命中即 `return [str]` | 将"最长前缀优先"改为"最短前缀优先（从 1 字到 5 字逐长度扫描，首个命中即返回）"，删除矛盾括注 |
| N2 | §8.1 `license = "Apache-2.0"` 注释"对齐源库 LICENSE"，源库实际为 MIT License | 源库 LICENSE 文件首行 "MIT License" | 改为 `license = "MIT"`；或明确说明移植版采用 Apache-2.0 的理由 |

### P2 — 建议修订（轻微，提升清晰度）

| 编号 | 问题 | 证据 | 建议修订 |
|------|------|------|---------|
| N3 | §9.3 引入第 4 个测试文件 `pinyin_snapshot_test.mbt`，超出 skill 3 级约定 | SKILL.md:28 仅列 easy/mid/difficult | 可保留（skill 说"or similar"），或并入 `pinyin_difficult_test.mbt` |
| N4 | §2.1 未明确源库内部方法（`formatPinyin` / `getWords` 等）的 MoonBit 文件归属 | `pinyin_helper.cj` 含 5 个 `static`（非 public）方法 | 在 §2.1 注释中补充内部方法文件归属 |
| N5 | §3.3 "2 重载"未提示 MoonBit 实现方式（labeled 参数默认值 vs 两方法） | MoonBit 不支持传统重载 | 建议提示下游用 labeled 参数默认值方案 |

### P3 — 观察项（无需修订，记录备查）

| 编号 | 观察 | 说明 |
|------|------|------|
| O1 | §9.2 `declare` vs `#declaration_only` skill 间存在规范张力 | 设计已给出明确取舍理由，处理得当；建议后续向 skill 维护方反馈统一 |
| O2 | §8.1 引用 `supported-targets`（hyphen），SKILL.md:639 实际为 `supported_targets`（underscore） | 设计说"不设置"，仅命名引用差异，无功能影响 |

---

## 十一、与此前 review_v2.md 的对比

此前 `review_v2.md` 返回 [APPROVED]，确认 v2 已解决 v1 的全部问题（1 一般 + 3 轻微），逐维度审查通过。本次独立深入审查确认了 v2 的修订质量，但在更深层的行为契约核验和事实性核验中发现 2 个中等问题：

- **N1（中等）**：§4.1 词组匹配优先级描述与源库语义相反，此前审查未核验 `getWords` 的实际扫描方向。
- **N2（中等）**：§8.1 许可证事实性错误，此前审查未核验源库 LICENSE 文件。

本次审查在源库保真度验证深度上更进一步：逐方法核验了源库 `pinyin_helper.cj` 的 `getWords` 循环逻辑（验证最短前缀优先）、`convertWithToneNumber` / `convertWithoutTone` 的算术映射、`toTongyongPinyinStringArray` 的拆分逻辑；并核验了源库 LICENSE 文件、`cjpm.toml` 构建配置、`build.cj` post-build 钩子等工程事实。

**总体评价**：`design_v2.md` 架构设计质量高，N1 与 N2 均为局部事实性错误，修订成本低，不影响整体架构决策。修订后可进入下游详细设计。