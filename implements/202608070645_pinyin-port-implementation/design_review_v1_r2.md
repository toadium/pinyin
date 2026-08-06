# 设计审查报告（v1 r2）

## 审查结果
APPROVED

## 发现

- **[轻微]** 设计 §B 后置条件引用 `SKILL.md:163-164` 支持"测试文件 `_test.mbt` 自动引用主包"声明，但实际 `SKILL.md:163-164` 是关于 `pkg.generated.mbti` 接口文件的说明（"They provide a formal, concise overview of all exported types..."），正确引用行号应为 `SKILL.md:663`（"In `_test.mbt` or `_wbtest.mbt` files, the package being tested is auto-imported"）。声明本身正确，仅行号有误，不影响设计正确性或编码实现。

## 修改要求（仅 REJECTED 时）
不适用。

## 审查验证依据

### 实测验证
在临时目录复刻设计骨架（`moon.mod` + `moon.pkg` + `data/moon.pkg` + `README.mbt.md`），运行 `moon check`（moon 0.1.20260713，feature flags `rr_moon_mod` / `rr_moon_pkg` 已启用）：
- exit code 0 ✓
- 产生 `Warning (0029) (unused_package): Unused package 'pinyin/pinyin/data'` ✓
- 与设计 §E 预期输出完全一致 ✓

### r1 审查意见修订落实验证
| r1 审查意见 | 修订措施 | 落实情况 |
|------------|---------|---------|
| [一般] 警告类型与预期不符 | §E 预期输出明确声明 `unused_package` 警告；失败模式表第 4 行替换为 `unused_package` 条目；§C 移除"要求包至少有一个 `.mbt` 文件"预期 | ✓ 已落实，与实测一致 |
| [一般] 警告治理策略不完整 | §E 新增警告治理子项 (a)-(e)：警告类型、根因、处置决策、消除条件、记录方式 | ✓ 已落实，完整覆盖 |
| [轻微] 未提及 README.md 共存策略 | §D 新增"与已有 `README.md` 的共存策略"子节，说明职责区分 | ✓ 已落实 |
| [轻微] 验证命令未显式声明工作目录 | §E 验证命令显式声明工作目录为项目根目录 | ✓ 已落实 |
| [轻微] data/moon.pkg 注释文本差异 | §C 注释移除"（后续任务填充）"括注，对齐技术方案 §3.3 | ✓ 已落实 |

### SKILL.md 引用准确性验证
| 设计引用 | 实际内容 | 一致性 |
|---------|---------|--------|
| SKILL.md:598-616 (moon.mod 格式) | Typical Module configurations 示例 | ✓ |
| SKILL.md:620-637 (moon.pkg 格式) | Typical Package configuration 示例 | ✓ |
| SKILL.md:648 (包识别规则) | "Packages are per directory..." | ✓ |
| SKILL.md:652 (import 路径格式) | "Import format: module_name/package_path" | ✓ |
| SKILL.md:654 (默认别名) | "Default alias: Last part of path" | ✓ |
| SKILL.md:677 (moonbitlang/core 隐式可用) | "always available without adding it to moon.mod" | ✓ |
| SKILL.md:155-158 (README.mbt.md 文档测试) | "README.mbt.md files with mbt check code examples" | ✓ |
| SKILL.md:163-164 (_test.mbt 自动引用) | 实际为 pkg.generated.mbti 说明 | ✗ 行号有误（声明正确，正确行号为 663） |

### 设计完整性评估
- 文件规划：4 个文件职责清晰，边界明确 ✓
- 类型定义：明确无类型定义，列出后续任务类型 ✓
- 错误处理：失败模式表 4 行覆盖所有可预见验证失败 ✓
- 行为契约 A-E：前置/内容/后置条件完整，"精确到字节"口径一致 ✓
- 依赖关系：已有资源、暴露接口、后续边界三部分清晰 ✓
- 用户偏好符合性：license=MIT 落实 N2、警告治理落实"不忽略任何警告"、kebab-case 命名、PascalCase 类型名（本任务无类型）✓