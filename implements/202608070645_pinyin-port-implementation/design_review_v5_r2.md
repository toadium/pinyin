# 设计审查报告（v5 r2）

## 审查结果
APPROVED

## 发现

本轮独立审查基于 detail_v5.md 当前交付物，未参考 r1 审查结论。所有关键技术事实声明均经实际编译验证（moon 0.1.20260713）。

### 已独立验证的事实

| 设计声明 | 验证方式 | 验证结果 |
|---------|---------|---------|
| `pub let` 方案编译通过，1 warning（`text_segment_excceed`），0 errors，`unused_package` 消除 | 创建临时 `pinyin_dicts.mbt` 按 §A 文件结构代码块实现，`moon clean` + `moon check` | ✓ 一致 |
| `pub(self) let` 方案 Error [3005] "No 'public self' visibility for value."，4 errors | 临时改写为 `pub(self) let` 四常量，`moon check` | ✓ 一致（4 个 Error [3005]） |
| `let`（私有）在当前版本可同包跨文件引用，0 errors | 临时改写为 `let` 四常量 + 新建非 test 探针文件 `_probe_ref.mbt` 引用四常量，`moon clean` + `moon check` | ✓ 一致（0 errors，仅 deprecated `size` 警告来自探针） |
| `moon test` Total 26, passed 26, failed 0 | `pub let` 方案下 `moon clean` + `moon test` | ✓ 一致 |
| 四个 `data/*.mbt` 存在，类型/条目数 2533/20903/843/82 | 直接读取文件头 | ✓ 一致 |
| `moon.pkg` 已配置 `import { "pinyin/pinyin/data" }` | 直接读取 | ✓ 一致 |
| 当前编译状态 2 warnings, 0 errors | `moon check`（审查前基线） | ✓ 一致 |

**关于 r1 发现 2 的事实分歧**：r1 审查意见声称"`let` 不能跨文件引用（Error [4021]）"，detail_v5.md 修订说明对此提出异议。本轮独立验证（新建非 test 探针文件跨文件引用 `let` 私有常量，`moon clean` 后 `moon check` 0 errors）支持 detail_v5.md 的事实声明——`let` 顶层常量在 moon 0.1.20260713 确实可同包跨文件引用。r1 该项实验结论有误。

### 发现清单

- **[轻微]** task_v5.md 与 detail_v5.md 的可见性修饰符不一致：task_v5.md 代码示例及 §4.2/§5.3/命名映射表均用 `pub(self) let`，detail_v5.md 最终实现用 `pub let`。设计 §A 文件内容契约仅说明了 `///|` 标记的差异，未显式说明可见性修饰符的差异。但修订说明已完整记录发现 1 的变更原因，且 §A 文件结构代码块是 `pub let`，实现者按 detail_v5.md 实现即可，不影响正确性。

- **[轻微]** 设计目标 3 措辞"为保证后续 R5/R6/R7 算法文件可跨文件引用并确保语义稳定，采用 `pub let`"暗示 `pub let` 是为跨文件引用而选，但已验证 `let` 也能跨文件引用。真正差异化理由是"语义稳定性 + 跨包引用有文档明确支撑"。可见性决策表的论证是完整的，设计目标 3 的措辞略有简化，不构成误导性缺陷。

- **[轻微]** 设计选 `pub let` 而非 `let`，使四个字典视图成为跨包公开 API，偏离技术方案 §4.2 的"仅包内可访问"意图。`let` 方案不暴露公共 API 且当前版本可跨文件引用，更接近原意。设计选 `pub let` 的理由"`let` 跨文件引用依赖编译器实现细节，稳定性弱于 `pub let`"是保守立场——`pub let` 的跨包语义确有 MoonBit 文档支撑，但 `let` 跨文件引用的"不稳定性"属对未来版本行为的推测，无文档证据。设计已在公共 API 影响评估、§C 共享语义契约、后续任务边界（R10 README 文档说明）中诚实记录此偏离与共享可变风险，属可接受的工程妥协。建议后续若 MoonBit 文档明确 `let` 跨文件引用为稳定语义，可考虑回退至 `let` 以收紧公共 API 边界。

### 设计质量评估

- **修订合理性**：r1 的 5 项发现均有对应修改措施，且与设计正文一致。发现 1（`pub(self) let` → `pub let`）、发现 4（验证契约更新）、发现 5（`///|` 标记说明）已完整落实。发现 2、3 基于本轮独立验证，设计修订对 r1 实验结论的纠正成立。
- **文件结构可实现性**：§A 文件结构代码块经实际创建验证，`moon check` 0 errors，`moon test` 26 passed。
- **验证契约准确性**：§E 预期 1 warning / 0 errors / 26 tests passed，与实际完全一致。
- **任务覆盖**：消除 `unused_package` 警告 ✓、建立字典视图层 ✓、不新增测试 ✓、不处理 `text_segment_excceed` ✓、不修改任何已有文件 ✓。
- **警告治理**：`unused_package` 根因分析与处置完整，`text_segment_excceed` 接受为预期并说明消除条件，落实用户偏好"不忽略任何警告"。
- **共享语义透明**：§C 明确说明 `let` 绑定不复制对象、`Map` 内容可变风险、公共 API 语义，后续 R10 文档说明已规划。