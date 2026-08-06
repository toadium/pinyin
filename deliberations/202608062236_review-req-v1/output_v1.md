# req_v1.md 独立审查报告

## 审查结论

**[APPROVED_WITH_MINOR_REVISIONS]**

需求文档 `req_v1.md` 整体质量高，对源库 `pinyin4cj` 的描述与实际源码高度吻合，API 表面、数据结构、隐含约束、测试资产等关键事实经过逐项验证均准确。skill 规范引用正确，可行性判断合理，用户偏好全面体现。存在 4 处需修订的事实性偏差（1 项中等、3 项轻微），不影响下游技术设计的可执行性，但建议修订以提升文档精确度。

## 审查方法

- 逐文件阅读源库 `D:\CodeWorkspace\forCangjie\pinyin4cj\src\` 全部 9 个 `.cj` 源文件，验证 API 签名、行数、内部逻辑。
- 逐目录清点 `test/` 下全部测试文件数量。
- 阅读源库 `cjpm.toml`、`build.cj`、`README.md`、`doc/feature_api.md`，验证构建配置、示例数量、API 文档。
- 阅读项目内 `moonbit-agent-guide`、`moonbit-spec-test-development`、`moonbit-c-binding`、`moonbit-orientation`、`moonbit-refactoring` 五个 skill 的 SKILL.md，验证 skill 规范符合性。
- 对照原始需求 `requirement.md` 与此前审查 `review_v1.md`，验证忠实性与已发现问题的处置。

---

## 一、准确性审查

### 1.1 源码结构验证

**[通过]** 源码文件逐一验证，全部 9 个文件存在且用途描述准确：

| 文件 | req_v1.md 行数 | 实际行数 | 用途描述 | 判定 |
|------|--------------|---------|---------|------|
| `pinyin_helper.cj` | 311 | 311 | 核心拼音转换器 | ✓ |
| `chinese_helper.cj` | 140 | 140 | 繁简互转器 | ✓ |
| `pinyin_format.cj` | 33 | 33 | PinyinFormat 枚举 | ✓ |
| `pinyin_resource.cj` | 71 | 71 | 资源加载器 | ✓ |
| `utils.cj` | 25 | 25 | 异常类 | ✓ |
| `get_file_path.cj` | 43 | 43 | 平台条件编译路径定位 | ✓ |
| `chinese.dict.cj` | 2556 | 2556 | 繁→简字典字面量 | ✓ |
| `mutil_pinyin.dict.cj` | 858 | 858 | 词组拼音字典字面量 | ✓ |
| `tongyong_pinyin_dict.cj` | 92 | 92 | 通用拼音映射字面量 | ✓ |

**[问题-轻微]** 源码结构小节标题写"src/，8 个文件"，实际为 9 个文件。正文已完整列出全部 9 个文件，仅标题计数笔误。（此前 `review_v1.md` 已发现此问题。）

### 1.2 公开 API 表面验证

**[通过]** `ChineseHelper` 公开方法（6 个）全部验证准确：

| 方法 | 源码签名 | req_v1.md 描述 | 判定 |
|------|---------|--------------|------|
| `convertToSimplifiedChinese(str: String): String` | ✓ (chinese_helper.cj:53) | ✓ | ✓ |
| `convertToTraditionalChinese(str: String): String` | ✓ (chinese_helper.cj:69) | ✓ | ✓ |
| `isTraditionalChinese(c: Rune): Bool` | ✓ (chinese_helper.cj:89) | ✓ | ✓ |
| `isChinese(c: Rune): Bool` | ✓ (chinese_helper.cj:105) | ✓ | ✓ |
| `containsChinese(str: String): Bool` | ✓ (chinese_helper.cj:121) | ✓ | ✓ |
| `addChineseDictResource(dict: HashMap<Rune, Rune>): Unit` | ✓ (chinese_helper.cj:137) | ✓ | ✓ |

> 注：源库 `doc/feature_api.md:247` 将 `addChineseDictResource` 签名误写为 `HashMap<String, String>`，实际源码为 `HashMap<Rune, Rune>`。req_v1.md 正确采用源码签名，比源库自身文档更准确。

**[通过]** `PinyinHelper` 公开方法（9 个，含 2 个 `convertToPinyinString` 重载）全部验证准确：

| 方法 | 源码位置 | req_v1.md 描述 | 判定 |
|------|---------|--------------|------|
| `convertToPinyinString(str, separator): String` | pinyin_helper.cj:231 | ✓ 默认 WITH_TONE_MARK 重载 | ✓ |
| `convertToPinyinString(str, separator, format): String` | pinyin_helper.cj:150 | ✓ 空串抛异常、词组优先 | ✓ |
| `convertToPinyinStringTraditional(str, separator, format): String` | pinyin_helper.cj:209 | ✓ 先繁→简再转拼音 | ✓ |
| `convertToPinyinArray(c: Rune, format): Array<String>` | pinyin_helper.cj:102 | ✓ 非汉字返回 [] | ✓ |
| `getShortPinyin(str: String): String` | pinyin_helper.cj:241 | ✓ 首字母格式 | ✓ |
| `hasMultiPinyin(c: Rune): Bool` | pinyin_helper.cj:251 | ✓ 非汉字抛异常 | ✓ |
| `addPinyinDictResource(dict): Unit` | pinyin_helper.cj:265 | ✓ | ✓ |
| `addMutilPinyinDictResource(dict): Unit` | pinyin_helper.cj:275 | ✓ | ✓ |
| `toTongyongPinyinStringArray(char: Rune): Array<String>` | pinyin_helper.cj:295 | ✓ 非汉字返回 [] | ✓ |

**[通过]** 内部方法（`convertWithToneNumber`、`convertWithoutTone`、`formatPinyin`、`convertToPinyinArrays`、`getWords`、`convertToPinyinStringResult`、`findArrayKeyByValue`、`convertCharToSimplifiedChinese`、`convertCharToTraditionalChinese`）均未加 `public`，req_v1.md 正确地未将其列入公开 API 表面。

**[通过]** `PinyinFormat` 枚举 4 个变体（`WITH_TONE_MARK` / `WITHOUT_TONE` / `WITH_TONE_NUMBER` / `FIRST_LETTER`）+ `getName(): String` 方法验证准确（pinyin_format.cj:14-32）。

**[通过]** `Pinyin4cjException <: Exception` 含 `getMessage()` 与 `toString()` 验证准确（utils.cj:10-24）。

### 1.3 异常消息文本验证

**[通过]** 两个异常触发点的消息文本逐字符对等：
- `convertToPinyinString` 空串输入 → `"Please enter a word or sentence"`（pinyin_helper.cj:153）✓
- `hasMultiPinyin` 非汉字输入 → `"Please enter a Chinese character"`（pinyin_helper.cj:253）✓

### 1.4 隐含约束验证

**[通过]** 全部 7 条隐含约束逐条验证：

1. 单字拼音表外部文件 + 环境变量定位 ✓（pinyin_resource.cj:22-23, get_file_path.cj:12-42）
2. 三张内嵌字典 `HashMap` 字面量初始化 ✓（chinese.dict.cj:12, mutil_pinyin.dict.cj:12, tongyong_pinyin_dict.cj:9）
3. `convertToTraditionalChinese` O(n) 反查 ✓（chinese_helper.cj:38-45，遍历 `CHINESE_MAP`）
4. 词组匹配 `min(charArray.size + 1, 6)`，最多 5 字前缀 ✓（pinyin_helper.cj:132）
5. 24 带调元音 `ALL_MARKED_VOWEL_ARRAY` + 6 无调元音 `ALL_UNMARKED_VOWEL_ARRAY` ✓（pinyin_helper.cj:15-16，数组元素计数确认）
6. 轻声用数字 `5` 表示 ✓（pinyin_helper.cj:51）
7. `CHINESE_LING = r'〇'`（U+3007）✓（pinyin_helper.cj:14）
8. `output-type = "dynamic"` 但纯计算无 FFI ✓（cjpm.toml:10，源码无任何 `extern` 声明）

### 1.5 测试资产验证

**[通过]** 测试目录文件计数验证：

| 目录 | req_v1.md | 实际 | 判定 |
|------|----------|------|------|
| `test/HLT/` | 14 文件 | 14 文件 | ✓ |
| `test/LLT/chinese_helper/` | 5 文件 | 5 文件 | ✓ |
| `test/LLT/pinyin_helper/` | 18 文件 | **17 文件** | ✗ |
| `test/FUZZ/` | 11 文件 | 11 文件 | ✓ |
| `test/Reliability/` | 11 文件 | 11 文件 | ✓ |
| `test/DOC/` | 1 文件 | 1 文件 | ✓ |

**[问题-轻微]** `test/LLT/pinyin_helper/` 实际为 17 文件，req_v1.md 写"18 文件"。（此前 `review_v1.md` 已发现此问题。）

### 1.6 外部资源验证

**[通过]** `pinyin.dict.txt` 行数 41806 ✓，两行一组 → 20903 组键值对 ✓。

**[问题-可忽略]** `pinyin.dict.txt` 实际大小 244.4 KB，req_v1.md 写"250 KB"；`chinese.dict.cj` 实际 54.9 KB 写"56 KB"；`mutil_pinyin.dict.cj` 实际 26.6 KB 写"27 KB"。均为向上取整的近似值，不影响任何设计决策。

### 1.7 依赖列表验证

**[问题-轻微]** req_v1.md 第 9 行称源库"仅依赖 Cangjie 标准库（`std.collection.HashMap`、`std.fs`、`std.io.StringReader`、`std.env`、`std.process`）"。实际源码 import 情况：

| 模块 | 实际使用位置 | req_v1.md 列出 | 判定 |
|------|------------|--------------|------|
| `std.collection.HashMap` | 多个源文件 | ✓ | ✓ |
| `std.core.min` | pinyin_helper.cj:8 | ✗ 未列出 | 偏差 |
| `std.fs` | pinyin_resource.cj, get_file_path.cj | ✓ | ✓ |
| `std.io.StringReader` | pinyin_resource.cj:9 | ✓ | ✓ |
| `std.env` | get_file_path.cj:8 | ✓ | ✓ |
| `std.process` | **仅 build.cj:5**（构建脚本，非库源码） | ✓ 列出 | 偏差 |

`std.process` 仅用于 `build.cj` 构建脚本（post-build 钩子复制资源文件），不属于库运行时依赖；`std.core.min` 用于 `pinyin_helper.cj:132` 的 `min()` 调用，是库运行时依赖但未列出。此偏差不影响移植决策（req_v1.md 已明确不移植 `build.cj` 和 `get_file_path.cj`），但"纯计算型库、仅依赖标准库"的结论依然成立。

### 1.8 README 示例数量验证

**[问题-中等]** req_v1.md 在第 79 行、第 144 行、第 188 行三处提及"对齐 README 中的 8 个示例"或"8 个 README 示例的精确输出对等"。实际源库 `README.md` 包含 **10 个**功能示例（`示例代码如下：`出现 10 次）：

1. 繁体转简体（README.md:88-106）
2. 简体转繁体（README.md:108-126）
3. 词、句转换成拼音（README.md:128-146）
4. 自定义输出格式（README.md:148-166）
5. 添加自定义拼音字典（README.md:168-189）
6. 添加自定义拼音组合字典（README.md:191-211）
7. 添加自定义中文字典（README.md:213-234）
8. 多音字转拼音集合（README.md:236-253）
9. 繁简体转拼音（README.md:255-272）
10. 繁简体转通用拼音（README.md:274-294）

此为事实性计数错误，可能导致下游测试设计遗漏 2 个示例的输出对等验证。

---

## 二、完整性审查

**[通过]** 移植范围明确：3.1 节"完整移植" + "包含产物" 4 项 + "不在范围内" 4 项，边界清晰，无模糊地带。

**[通过]** 公开 API 表面完整覆盖：`ChineseHelper` 6 方法 + `PinyinHelper` 9 方法 + `PinyinFormat` 4 变体 + `Pinyin4cjException` 异常类，与源码 `public` 声明逐一对应。

**[通过]** 三张内嵌字典 + 单字拼音外部资源全部纳入移植范围，无遗漏。

**[通过]** 非功能性要求覆盖正确性、性能、内存、API 兼容性、注释五维度，且明确"正确性优先于性能"的硬约束优先级。

**[通过]** 已识别的 7 条源库隐含约束全部写入需求，下游无需重新发现。

**[通过]** 交付物清单 7 项明确，可逐项验收。

**[通过]** 不在范围内的项目（FUZZ、Reliability、build.cj、get_file_path.cj）均有合理排除理由。

---

## 三、可行性审查

**[通过]** 三后端支持（wasm/js/native）：源库为纯计算库，无 FFI、无文件系统运行时依赖（`get_file_path.cj` 已排除），天然跨后端。需求中"不依赖运行时文件系统与环境变量"的约束合理可行。

**[通过]** 单字拼音字典内嵌化：将 244.4 KB / 41806 行 / 20903 组的 `pinyin.dict.txt` 内嵌为 MoonBit 字符串字面量或 `Bytes` 常量，运行时解析为 `Map[String, String]`，技术上完全可行。需求层不限定具体技术手段（`@embed` / 构建脚本生成 / 字面量转写），留给下游决策，处理得当。

**[通过]** 异常模型转换：`throw Pinyin4cjException` → `raise PinyinError` 或 `Result[T, PinyinError]`，两种方案在 MoonBit 中均可行。需求层只约束错误场景与消息文本对等，不强制选型，合理。

**[通过]** 字典数据结构选型：`HashMap<Rune, Rune>` → `Map[Int, Int]`（码点映射），`HashMap<String, String>` → `Map[String, String]`，在 MoonBit 中可行。需求层将具体选型（`Map` vs `HashMap` vs `@hashmap.T`）留给下游，合理。

**[通过]** 无 FFI 需求判定正确：源库无任何 `extern` 声明，不适用 `moonbit-c-binding` / `make-moonbit-c-bindings` skill 的结论准确。

---

## 四、skill 规范符合性审查

**[通过]** `moonbit-agent-guide` 规范引用正确：
- `moon.mod` + `moon.pkg` 项目布局 ✓（SKILL.md:93-110，新格式非 legacy `moon.mod.json`）
- "多小文件、内聚"原则 ✓（SKILL.md:136-151）
- `moon check` → `moon test` → `moon fmt` → `moon info` 验证循环 ✓（SKILL.md:27-34）
- `pkg.generated.mbti` 入版本控制 ✓（SKILL.md:161-165）

**[通过]** `moonbit-spec-test-development` 规范引用正确：
- `<pkg>_spec.mbt` 形式化契约 ✓（SKILL.md:9, 20-24）
- `#declaration_only` 声明 API 签名 ✓（SKILL.md:21）
- `<pkg>_easy_test.mbt` / `<pkg>_mid_test.mbt` / `<pkg>_difficult_test.mbt` 分级测试 ✓（SKILL.md:28）

**[通过]** `moonbit-c-binding` 正确排除：该 skill 专用于 C 库 FFI 绑定（SKILL.md:10-22），源库无 C 依赖，不适用。

**[通过]** `make-moonbit-c-bindings` 正确排除：同上理由。

**[通过]** `moonbit-proof` 正确排除：该 skill 专用于形式化验证/证明携带代码，非本移植场景。

**[通过]** `moonbit-orientation` 引用合理：用于 MoonBit 语言能力疑问查阅，避免 stale 假设。

**[通过]** `moonbit-refactoring` 引用合理：用于移植过程中行为保持的重构。

---

## 五、清晰性审查

**[通过]** 移植范围边界清晰：3.1 节"完整移植" + "包含产物" / "不在范围内"双清单，下游可准确判断移植边界。

**[通过]** API 对等性要求无歧义：3.2 节以"语义对等"为硬约束，命名调整规则（PascalCase 类型、snake_case 函数、PascalCase 枚举变体）逐一列出，"具体组织形式由下游技术设计决定"避免越界。

**[通过]** 资源加载策略约束精确：3.4 节"不依赖运行时文件系统与环境变量""跨 wasm/js/native 三后端一致""字典容量与源库一致（41806 行 / 20903 组）"，下游不会误保留环境变量定位机制。

**[通过]** 异常模型约束精确：3.5 节保留两个异常触发点的消息文本，下游不会擅自改变边界行为。

**[通过]** 开放问题清单（第六节）以"需求层不决策"开篇，每个问题给出选项 + 约束，边界清晰，不与下游技术设计职责冲突。

**[通过]** 推断性内容均显式标注"推断"字样，读者可清晰区分用户原意与推断。

---

## 六、用户偏好符合性审查

| 偏好 | req_v1.md 体现 | 判定 |
|------|--------------|------|
| MoonBit 语言 + moon + mooncakes | 3.6 节三后端、3.9 节 skill 规范 | ✓ |
| kebab-case 文档命名 | 3.9 节"文档与产物命名遵循 kebab-case" | ✓ |
| PascalCase 类型名 | 3.2 节"类型名保留 PascalCase" | ✓ |
| 简体中文交互 + 英文术语 | 全文风格一致 | ✓ |
| 代码注释与文档 | 3.8 节"公开 API 须附 docstring" | ✓ |
| spec-driven 测试 | 3.7 节双轨策略 | ✓ |
| 详细需求分析 | 源库事实摘要 + 隐含约束 7 条 | ✓ |
| 行动导向 | 需求条款以约束式语句表述 | ✓ |
| 不引入第三方数据源 | 第四节"不做什么"明确 | ✓ |

---

## 七、修订建议（按优先级排序）

### P1 — 建议修订（事实性错误，影响测试覆盖）

| 编号 | 问题 | 证据 | 建议修订 |
|------|------|------|---------|
| R1 | README 示例数量写"8 个"，实际为 10 个 | `README.md` 中"示例代码如下："出现 10 次，涵盖繁简互转、词句转拼音、自定义格式、3 种自定义字典、多音字集合、繁简体转拼音、通用拼音共 10 例 | 将第 79、144、188 行的"8 个示例"改为"10 个示例"，确保测试策略覆盖全部 10 个 README 示例的输出对等 |

### P2 — 建议修订（计数笔误，不影响设计但影响精确度）

| 编号 | 问题 | 证据 | 建议修订 |
|------|------|------|---------|
| R2 | 源码结构标题写"8 个文件"，实际 9 个 | `src/` 目录实测 9 个 `.cj` 文件 | 将"8 个文件"改为"9 个文件" |
| R3 | `test/LLT/pinyin_helper/` 写"18 文件"，实际 17 文件 | 目录实测 17 个 `.cj` 文件 | 将"18 文件"改为"17 文件" |

### P3 — 建议修订（依赖列表细微偏差）

| 编号 | 问题 | 证据 | 建议修订 |
|------|------|------|---------|
| R4 | 依赖列表列出 `std.process`（仅用于 `build.cj` 构建脚本，非库运行时依赖），遗漏 `std.core.min`（用于 `pinyin_helper.cj:132` 的 `min()` 调用） | `build.cj:5` import `std.process`；`pinyin_helper.cj:8` import `std.core.min` | 将依赖列表改为"`std.collection.HashMap`、`std.fs`、`std.io.StringReader`、`std.env`、`std.core.min`（库运行时）；`std.process`（仅构建脚本 `build.cj`）" |

### P4 — 可选修订（文件大小近似值）

| 编号 | 问题 | 证据 | 建议修订 |
|------|------|------|---------|
| R5 | `pinyin.dict.txt` 写"250 KB"实际 244.4 KB；`chinese.dict.cj` 写"56 KB"实际 54.9 KB；`mutil_pinyin.dict.cj` 写"27 KB"实际 26.6 KB | 文件系统实测大小 | 可改为精确值或标注"约"，优先级最低 |

---

## 八、与此前 review_v1.md 的对比

此前 `review_v1.md` 返回 [APPROVED]，已发现 R2（源码文件数 8→9）和 R3（LLT pinyin_helper 文件数 18→17）两处轻微问题。本次独立审查确认了这两处问题，并新发现：

- **R1（中等）**：README 示例数量 8→10，此前审查未发现，是本次审查的主要新增发现。
- **R4（轻微）**：依赖列表 `std.process` / `std.core.min` 偏差，此前审查未涉及。
- **R5（可忽略）**：文件大小近似值偏差。

本次审查在准确性验证深度上更进一步：逐方法验证了全部 15 个公开 API 的源码签名与位置，逐条验证了 7 条隐含约束的源码出处，并完整清点了 README 示例与测试文件数量。