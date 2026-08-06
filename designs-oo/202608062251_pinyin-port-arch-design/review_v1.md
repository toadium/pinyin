# OOD 设计方案审查报告（v1）

## 审查结果

[REJECTED]

## 逐维度审查

### 1. 类型系统可行性

**[通过]** 核心类型形态选择与 MoonBit 类型系统能力匹配：
- `pub(all) enum PinyinFormat`（4 变体无附加数据）：MoonBit `enum` 是表达固定封闭集合的惯用形态，`pub(all)` 允许外部构造与模式匹配，符合 SKILL.md:1170 示例风格。
- `pub(all) suberror PinyinError`（单变体携带消息）：MoonBit 检查式错误类型的惯用形态，配合 `raise`/`catch` 使用，符合 SKILL.md:826-831 示例。
- `pub struct PinyinHelper` / `pub struct ChineseHelper`（空结构体 + 关联方法）：MoonBit 支持空 `struct` + 类型关联方法作为命名空间，`Type::method()` 调用语义等价于源库 `static`，符合 SKILL.md:175 "methods need explicit type prefix" 规范。
- `Map[Int, Int]` / `Map[String, String]`：MoonBit 标准库 `Map` 类型可用作字典视图，字面量构造 `{ "k" => "v" }` 语法支持（SKILL.md:1070）。
- 无复杂继承关系，无泛型抽象越界使用。

**[一般]** `Map` 可变性事实性错误：设计 §3.5 声称 "MoonBit 标准库 `Map` 是惯用不可变映射"，但 MoonBit 标准库 `Map` 实际是**可变的、保持插入顺序的**映射（`moonbit-agent-guide` SKILL.md:1064 标题 "Map (Mutable, Insertion-Order Preserving)"，SKILL.md:1077-1078 演示 `map["new-key"] = 3` 可变操作）。此错误进一步影响 §6.2 并发安全分析的前提（见维度 3）。

**[轻微]** `PinyinDicts` 类型形态未明确：设计 §3.5 说 "内部 `struct` 或直接全局常量集合，不公开"，两种方案都可行，但设计未明确选择。作为架构级设计留给下游决策是合理的，但建议明确倾向性以减少下游反复。

### 2. 标准库与生态覆盖

**[通过]** 设计中需要的能力均在 MoonBit 标准库覆盖范围内：
- 集合类型：`Map`、`Array`、`String`、`Char` 均为 `moonbitlang/core` 内置。
- 错误处理：`suberror` + `raise`/`catch` 为语言内置（SKILL.md:801）。
- 可变全局状态：`Ref[T]` 为标准库原语（SKILL.md:788 "use `Ref[T]` for primitive mutability"）。
- 字符串处理：`StringBuilder`、`split`、`replace` 等均为标准库能力。
- 字典数据结构选型合理：不引入 `@hashmap.T` 第三方包，`Map` 足够覆盖需求。
- 零外部依赖假设合理：源库纯计算无 FFI，移植版仅 `moonbitlang/core` 隐式可用。

**[通过]** 不引入 `moonbit-c-binding` / `make-moonbit-c-bindings` / `moonbit-proof` skill 的排除决策正确：源库无 C 依赖（已由审查报告验证源码无 `extern` 声明），非形式化验证场景。

### 3. 语言特性可行性

**[通过]** 错误处理策略与 MoonBit 能力匹配：
- `raise PinyinError` + `catch` 模式匹配：符合 MoonBit 检查式错误惯例（SKILL.md:799-903）。
- 错误消息文本逐字符对齐源库：两个 `raise` 点的消息已由审查报告验证准确。
- `raise` vs `Result[T, PinyinError]` 选择 `raise` 的理由充分：符合 MoonBit 惯例，避免调用点噪声。

**[通过]** 资源管理方案可行：构建期内嵌字面量，运行时直接构造为 `Map`，无运行时 IO，跨三后端一致。脚本生成 `.mbt` 字面量是最稳妥方案（MoonBit 当前无稳定 `@embed`/`#embed` 原语）。

**[通过]** 模块/包结构设计符合 MoonBit 项目组织方式：
- `moon.mod` + `moon.pkg` 新格式（非 legacy `moon.mod.json`），符合 SKILL.md:81-110 规范。
- 单模块 + 主包 + 数据子包的包组织合理，依赖方向单向（主包 → 数据子包），无循环依赖。
- 测试文件 `*_test.mbt` 自动引用所在包，符合 SKILL.md:153-159 黑盒测试规范。

**[一般]** §6.2 并发安全分析基于错误的 `Map` 不可变前提：设计说 "全局 `Ref[Map]`，`add_*` 方法用 `dicts.pinyin_table.set(dict)` 替换为合并后的新 `Map`（`Map` 不可变，替换引用）"。由于 MoonBit `Map` 实际是可变的，全局 `let map : Map[...] = {...}` 声明的绑定虽不可重新赋值，但 `Map` 对象内容可变（`map["key"] = value`）。因此：
  - 方案 A（设计当前）：用 `Ref[Map]` 包装并在 `add_*` 时替换整个引用——仍可行，但理由（"Map 不可变"）错误。
  - 方案 B（更直接）：全局 `let map : Map[...]` + `add_*` 时直接调用 `map` 的可变合并操作——无需 `Ref` 包装，更贴近源库 `HashMap.add(all:)` 语义。
  - 设计基于错误前提排除了方案 B 的可能性，需修正 `Map` 可变性认知后重新评估并发策略。

**[轻微]** spec 契约文件中 `declare` 关键字与 `#declaration_only` 的关系未澄清：设计 §9.2 用 `declare` 关键字声明 API 签名，与 `moonbit-agent-guide` SKILL.md:358-378 规范一致；但 `moonbit-spec-test-development` SKILL.md:21 提到 `#declaration_only`。两者可能是不同机制或新旧方式，设计未澄清关系。建议明确采用 `declare` 关键字（与 `moonbit-agent-guide` 最新规范一致）并说明与 `#declaration_only` 的取舍理由。

### 4. 设计一致性

**[通过]** 各抽象职责描述清晰无歧义：
- `PinyinFormat`（格式策略）、`PinyinError`（错误类型）、`PinyinHelper`（拼音转换）、`ChineseHelper`（繁简互转 + 汉字判定）、`PinyinDicts`（字典视图聚合）职责边界明确，无重叠。
- 协作关系形成闭环：`PinyinHelper` → `ChineseHelper`（汉字判定 + 繁简预处理）→ `PinyinDicts`（字典查询）← `PinyinHelper`（字典查询），无缺失环节。
- 行为契约描述完整：§4.1-4.5 覆盖词句转拼音、声调格式转换、繁简互转、通用拼音、自定义字典追加五大行为，契约要点明确（词组优先、非汉字穿插、分隔符规则、O(n) 反查语义保留等）。
- 模块间依赖方向合理：主包单向依赖数据子包，数据子包零依赖，无循环。

**[通过]** 与审查报告 `output_v1.md` 的呼应完整：R1（10 例 README 示例）、R2（9 源文件）、R3（17 LLT 文件）、R4（依赖列表）、R5（文件大小）均已在 §9.3、§2.1、§7.1、§7.3 中采纳修正。

**[通过]** 关键设计决策汇总（§十 D1-D15）与正文各节一致，无矛盾。

### 5. 设计质量

**[通过]** 职责划分遵循单一职责原则：
- `PinyinHelper` 仅负责拼音转换，`ChineseHelper` 仅负责繁简互转 + 汉字判定，`PinyinDicts` 仅负责字典视图聚合，`PinyinFormat` 仅表达格式策略，`PinyinError` 仅承载错误消息。
- 抽象层次恰当：不过度设计（无抽象工厂、无依赖注入、无策略模式注入），也不设计不足（核心抽象齐全）。
- 保留源库 `PinyinHelper` / `ChineseHelper` 命名空间的决策合理：降低移植 review 成本，避免顶层函数名冲突，MoonBit 类型关联方法与 `static` 语义等价。

**[通过]** 设计便于后续详细设计和实现：
- 模块划分、包结构、文件组织清晰，下游可直接按图索骥。
- 关键行为契约（§四）提供了足够的实现指导（词组优先匹配规则、声调映射算术、分隔符边界规则等）。

**[通过]** 设计便于单元测试：
- `PinyinHelper` / `ChineseHelper` 无实例状态，转换方法为纯函数（除全局字典追加外），可隔离测试。
- 字典视图通过 `@data` 子包隔离，测试可通过 `add_*_dict_resource` 注入自定义字典验证边界。
- spec 契约 + 分级黑盒测试 + snapshot 测试的测试架构符合 `moonbit-spec-test-development` skill 规范，可 mock、可隔离。

**[轻微]** `convert_to_traditional_chinese` 保留 O(n) 反查的决策虽符合需求 3.8"不主动优化"，但设计未说明此决策对大文本转换性能的影响量级（源库 `convertToTraditionalChinese` 逐字符 O(n) 反查，n 为 `CHINESE_MAP` 大小约 2556 条目，大文本场景为 O(文本长度 × 2556)）。作为架构级设计可接受，但建议在设计中注明此性能特征以提醒下游。

## 修改要求（REJECTED 时存在）

### 问题 1：`Map` 可变性事实性错误

- **问题**：设计 §3.5 声称 "MoonBit 标准库 `Map` 是惯用不可变映射"，§6.2 基于此声称 "全局 `Ref[Map]`，`add_*` 方法用 `dicts.pinyin_table.set(dict)` 替换为合并后的新 `Map`（`Map` 不可变，替换引用）"。
- **原因**：MoonBit 标准库 `Map` 实际是**可变的、保持插入顺序的**映射（`moonbit-agent-guide` SKILL.md:1064 "Map (Mutable, Insertion-Order Preserving)"，SKILL.md:1077-1078 演示可变操作 `map["new-key"] = 3`）。此事实性错误导致 §6.2 并发安全分析的前提不成立，可能误导下游实现采用不必要的 `Ref[Map]` 包装而非直接利用 `Map` 可变性。
- **建议方向**：
  1. 修正 §3.5 对 `Map` 可变性的描述：明确 MoonBit `Map` 是可变映射，全局 `let` 绑定不可重新赋值但 `Map` 内容可变。
  2. 重新评估 §6.2 自定义字典并发策略：考虑方案 B（全局 `let map : Map` + `add_*` 时直接可变合并，更贴近源库 `HashMap.add(all:)` 语义），或保留方案 A（`Ref[Map]`）但给出正确理由（如统一替换引用的原子性考虑，而非"Map 不可变"）。
  3. 修正 §7.6 字典数据结构选型中 "Map 即惯用映射" 的表述，补充可变性特征说明。