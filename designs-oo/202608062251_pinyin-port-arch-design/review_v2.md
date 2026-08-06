# OOD 设计方案审查报告（v2）

## 审查结果

[APPROVED]

## 上一轮问题解决情况核对

| review_v1 问题 | 等级 | design_v2 修订位置 | 解决情况 |
|---------------|------|-------------------|---------|
| §3.5/§6.2/§7.6 `Map` 可变性事实性错误 | 一般 | §3.5 数据结构选型段、§6.2 重写、§7.6 新增特性说明段、D5/D11 决策汇总、修订说明表 | 已解决 |
| §3.5 `PinyinDicts` 类型形态未明确 | 轻微 | §3.5 明确"全局 `let` 常量集合"、§1.3 表格同步、D16 新增决策 | 已解决 |
| §9.2 `declare` vs `#declaration_only` 关系未澄清 | 轻微 | §9.2 新增取舍说明段、D14 补充标注 | 已解决 |
| §3.4 O(n) 反查性能特征未说明 | 轻微 | §3.4 补充性能特征段、§7.7 同步、D8 补充量级标注 | 已解决 |

## 逐维度审查

### 1. 类型系统可行性

**[通过]** 核心类型形态选择与 MoonBit 类型系统能力匹配：
- `pub(all) enum PinyinFormat`（4 变体无附加数据）：MoonBit `enum` 是表达固定封闭集合的惯用形态，`pub(all)` 允许外部构造与模式匹配。
- `pub(all) suberror PinyinError`（单变体携带消息）：MoonBit 检查式错误类型的惯用形态，配合 `raise`/`catch` 使用。
- `pub struct PinyinHelper` / `pub struct ChineseHelper`（空结构体 + 关联方法）：MoonBit 支持空 `struct` + 类型关联方法作为命名空间，`Type::method()` 调用语义等价于源库 `static`。
- `Map[Int, Int]` / `Map[String, String]`：MoonBit 标准库 `Map` 类型可用作字典视图，字面量构造 `{ "k" => "v" }` 语法支持。
- 无复杂继承关系，无泛型抽象越界使用。

**[通过]** §3.5 `Map` 可变性描述已修正：明确引用 SKILL.md:1064 "Map (Mutable, Insertion-Order Preserving)"，说明全局 `let` 绑定不可重新赋值但 `Map` 对象内容可变（可 `map["key"] = value`），此特性与源库 Cangjie `HashMap` 可变语义对齐。事实性错误已消除。

**[通过]** §3.5 `PinyinDicts` 类型形态已明确：采用全局 `let` 常量集合，不引入 `struct` 包装；§1.3 核心抽象一览表同步更新为"全局 `let` 常量集合（不公开）"；D16 决策汇总条目说明选择理由（减少抽象层次，`Map` 可变性已足够支持 `add_*` 语义）。倾向性已明确，下游无需反复。

### 2. 标准库与生态覆盖

**[通过]** 设计中需要的能力均在 MoonBit 标准库覆盖范围内：
- 集合类型：`Map`、`Array`、`String`、`Char` 均为 `moonbitlang/core` 内置。
- 错误处理：`suberror` + `raise`/`catch` 为语言内置。
- 可变全局状态：v2 修正后无需 `Ref[Map]` 包装，直接利用 `Map` 可变性（标准库能力）。
- 字符串处理：`StringBuilder`、`split`、`replace` 等均为标准库能力。
- 字典数据结构选型合理：不引入 `@hashmap.T` 第三方包，`Map` 足够覆盖需求。
- 零外部依赖假设合理：源库纯计算无 FFI，移植版仅 `moonbitlang/core` 隐式可用。

**[通过]** 不引入 `moonbit-c-binding` / `make-moonbit-c-bindings` / `moonbit-proof` skill 的排除决策正确：源库无 C 依赖，非形式化验证场景。

### 3. 语言特性可行性

**[通过]** 错误处理策略与 MoonBit 能力匹配：
- `raise PinyinError` + `catch` 模式匹配：符合 MoonBit 检查式错误惯例。
- 错误消息文本逐字符对齐源库：两个 `raise` 点的消息已由审查报告验证准确。
- `raise` vs `Result[T, PinyinError]` 选择 `raise` 的理由充分：符合 MoonBit 惯例，避免调用点噪声。

**[通过]** 资源管理方案可行：构建期内嵌字面量，运行时直接构造为 `Map`，无运行时 IO，跨三后端一致。脚本生成 `.mbt` 字面量是最稳妥方案（MoonBit 当前无稳定 `@embed`/`#embed` 原语）。

**[通过]** 模块/包结构设计符合 MoonBit 项目组织方式：
- `moon.mod` + `moon.pkg` 新格式，符合 SKILL.md 规范。
- 单模块 + 主包 + 数据子包的包组织合理，依赖方向单向（主包 → 数据子包），无循环依赖。
- 测试文件 `*_test.mbt` 自动引用所在包，符合黑盒测试规范。

**[通过]** §6.2 并发安全分析已基于正确的 `Map` 可变性前提重新设计：
- 采用方案 B（全局 `let map : Map` + `add_*` 直接调用 `Map` 可变操作原地合并），无需 `Ref[Map]` 包装。
- 可行性依据正确：引用 SKILL.md:1064, 1077-1078 演示可变操作，明确全局 `let` 绑定不可重新赋值但 `Map` 内容可变。
- 与源库语义对齐：直接对应源库 `HashMap.add(all:)` 原地合并语义，单线程下行为完全一致。
- 不引入 `Mutex` 的理由合理：避免引入 `moonbitlang/async` 或 `sync` 依赖，保持纯计算库零依赖特性；并发追加自定义字典是罕见场景，需求未要求线程安全保证。
- 多线程语义保留说明合理：源库 `HashMap` 本身无并发保证，移植版 `Map` 同样无保证，不构成语义退化。
- §6.1 已同步删除"需 `Ref[Map]` 或 `Mutex[Map]`"表述，改为"直接利用 `Map` 可变性原地合并"。

**[通过]** §9.2 `declare` 关键字与 `#declaration_only` 关系已澄清：
- 明确采用 `declare` 关键字，与 `moonbit-agent-guide` SKILL.md:358-378 最新规范一致。
- `#declaration_only` 是 `moonbit-spec-test-development` SKILL.md:21 提到的早期机制，本设计不采用。
- 取舍理由明确：以 `moonbit-agent-guide` 最新规范为准。
- D14 决策汇总已补充 "`declare` 关键字" 标注。

### 4. 设计一致性

**[通过]** 各抽象职责描述清晰无歧义：
- `PinyinFormat`（格式策略）、`PinyinError`（错误类型）、`PinyinHelper`（拼音转换）、`ChineseHelper`（繁简互转 + 汉字判定）、`PinyinDicts`（字典视图聚合）职责边界明确，无重叠。
- 协作关系形成闭环：`PinyinHelper` → `ChineseHelper`（汉字判定 + 繁简预处理）→ `PinyinDicts`（字典查询）← `PinyinHelper`（字典查询），无缺失环节。
- 行为契约描述完整：§4.1-4.5 覆盖词句转拼音、声调格式转换、繁简互转、通用拼音、自定义字典追加五大行为，契约要点明确。
- 模块间依赖方向合理：主包单向依赖数据子包，数据子包零依赖，无循环。

**[通过]** 与审查报告 `output_v1.md` 的呼应完整：R1（10 例 README 示例）、R2（9 源文件）、R3（17 LLT 文件）、R4（依赖列表）、R5（文件大小）均已在 §9.3、§2.1、§7.1、§7.3 中采纳修正。

**[通过]** 关键设计决策汇总（§十 D1-D16）与正文各节一致，无矛盾。v2 新增 D16（`PinyinDicts` 形态）与 §3.5 明确倾向一致。

**[通过]** 修订说明表格（§修订说明）完整记录了所有修改措施，与正文实际修改一致，可追溯。

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

**[通过]** §3.4 `convert_to_traditional_chinese` 性能特征已补充：
- §3.4 明确"性能特征：n 为 `CHINESE_MAP` 大小（约 2556 条目），单字符反查为 O(n)；对长度为 L 的文本，整体复杂度为 O(L × n) = O(L × 2556)。大文本场景（L ≫ 1000）性能弱于正向查询，但与源库完全对等，下游实现不得改变此复杂度特征"。
- §7.7 同步补充性能特征说明。
- D8 决策汇总补充 "O(L × 2556)" 量级标注。
- 下游实现已获得充分的性能特征提醒。

## 总结

design_v2.md 已充分解决 review_v1.md 中的全部问题（1 个一般 + 3 个轻微），且修订过程中未引入新的严重或一般问题。各维度均通过审查，设计方案在 MoonBit 类型系统和语言特性层面具有可行性，可进入下一阶段详细设计。