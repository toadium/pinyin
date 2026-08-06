# 详细设计（v1）

## 概述

本任务为 pinyin4cj → MoonBit 移植的**首个编码任务**，目标是从零建立可编译的 MoonBit 模块空骨架：模块根元数据 `moon.mod`、主包配置 `moon.pkg`、数据子包配置 `data/moon.pkg`、占位 `README.mbt.md`。完成后 `moon check` 应在零源文件状态下通过，为后续任务（字典字面量、类型定义、算法实现、测试）提供可编译的工具链与包边界基础。

本任务**不涉及**任何 `.mbt` 源文件、类型定义、方法签名、错误类型或算法实现——仅产出配置文件与占位 README。后续任务在此骨架上逐步填充。

## 文件规划

| 文件路径 | 操作 | 职责 |
|---------|------|------|
| `moon.mod` | 新建 | 模块根元数据：模块名、版本、license、关键字、描述；零外部依赖；不设置 preferred-target / supported_targets |
| `moon.pkg` | 新建 | 主包配置：单向 import 数据子包 `pinyin/pinyin/data`；库包（不设置 is-main） |
| `data/moon.pkg` | 新建 | 数据子包配置：纯数据包，零 import；库包（不设置 is-main） |
| `README.mbt.md` | 新建 | 占位 README：标题 + 一行简介；后续任务填充 10 个 `mbt check` 示例 |

**说明**：
- 路径均相对项目根目录 `D:\CodeWorkspace\forMoonbit\pinyin`。
- `data/` 目录由创建 `data/moon.pkg` 隐式建立（`moon.pkg` 文件存在即标识包，SKILL.md:648）。
- 本任务**不创建**任何 `.mbt` 源文件、`pkg.generated.mbti` 接口文件、`scripts/` 目录、`.mbt.md` 测试文件——这些属后续任务。
- `pkg.generated.mbti` 在空包状态下由 `moon info` 生成（可选，本任务不强制）；若 `moon check` 不要求则不生成。
- 项目根目录已存在 `README.md`（项目顶层说明，非 MoonBit 工具链消费），与新建 `README.mbt.md` 共存，两者职责区分见 §D。

## 类型定义

本任务**无类型定义**。仅产出配置文件（`moon.mod` / `moon.pkg`）与 Markdown 占位文件，不涉及 MoonBit 语言层面的类型、方法、枚举或接口。

后续任务将在此骨架上定义 `PinyinFormat` / `PinyinError` / `PinyinHelper` / `ChineseHelper` 等类型，属本任务范围之外。

## 错误处理

本任务**无错误处理设计**。配置文件为声明式元数据，不涉及运行时错误。

**验证阶段**的潜在失败模式与处置（编码 agent 需关注）：

| 失败模式 | 根因 | 处置 |
|---------|------|------|
| `moon check` 报告 `moon.mod` 格式错误 | 字段名拼写、缺引号、缺 `=` | 对照 SKILL.md:598-616 新格式语法修正 |
| `moon check` 报告 `moon.pkg` 格式错误 | import 路径错误、缺逗号、JSON 拘旧格式 | 对照 SKILL.md:620-637 新格式语法修正；确认使用 `import { ... }` 而非 JSON |
| `moon check` 报告包 `pinyin/pinyin/data` 不存在 | `data/moon.pkg` 未创建或路径错误 | 确认 `data/moon.pkg` 存在且 `data/` 目录位于项目根下 |
| `moon check` 产生 `Warning (0029) (unused_package): Unused package 'pinyin/pinyin/data'` | 主包无源文件，import 的数据子包未被引用 | **预期警告**：接受，不阻断本任务验收；后续任务添加引用 `@data.xxx` 的源文件后自动消除（详见 §E 警告治理） |

## 行为契约

### A. `moon.mod` 内容契约

**前置条件**：项目根目录 `D:\CodeWorkspace\forMoonbit\pinyin` 存在且可写。

**文件内容**（精确到字节，编码 agent 直接照抄）：

```
name = "pinyin/pinyin"
version = "0.1.0"
readme = "README.mbt.md"
repository = ""
license = "MIT"
keywords = ["pinyin", "chinese", "unicode"]
description = "MoonBit port of pinyin4cj: Chinese-to-pinyin conversion"
```

**后置条件**：
- 文件存在于 `D:\CodeWorkspace\forMoonbit\pinyin\moon.mod`。
- **无** `import` 块（零外部依赖，仅 `moonbitlang/core` 隐式可用，SKILL.md:677）。
- **无** `options(...)` 块（不设置 `preferred-target`，三后端 wasm-gc / js / native 平等）。
- **无** 顶层 `supported_targets = ...`（不限制可移植性）。
- 字段顺序遵循 SKILL.md:598-616 示例：`name` → `version` → `readme` → `repository` → `license` → `keywords` → `description`。
- `license = "MIT"` 落实审查建议 N2（对齐源库 LICENSE，Copyright (c) 2017 sbiger）。
- `name = "pinyin/pinyin"` 为 `<author>/pinyin` 形式，作者命名空间暂用工作目录名 `pinyin` 占位。

### B. `moon.pkg`（主包）内容契约

**前置条件**：`moon.mod` 已创建。

**文件内容**（精确到字节）：

```
import {
  "pinyin/pinyin/data",
}
```

**后置条件**：
- 文件存在于 `D:\CodeWorkspace\forMoonbit\pinyin\moon.pkg`。
- `import` 块仅含 `"pinyin/pinyin/data"`（单向依赖数据子包）。
- **无** `for "test"` / `for "wbtest"` 子句（测试文件 `_test.mbt` 自动引用主包，SKILL.md:163-164）。
- **无** `options(...)` 块（不设置 `is-main`，库包）。
- **无** 顶层 `supported_targets`。
- import 路径格式 `"module_name/package_path"` 符合 SKILL.md:652；默认别名 `data`（末段，SKILL.md:654），后续主包源文件以 `@data.xxx` 访问数据子包导出。

### C. `data/moon.pkg`（数据子包）内容契约

**前置条件**：`moon.mod` 已创建；`data/` 目录存在（由创建文件隐式建立）。

**文件内容**（精确到字节，空配置文件，注释文本对齐技术方案 §3.3）：

```
// 纯数据包：无 import，不设置 is-main
// 仅含字典字面量定义，无逻辑，无测试
```

**后置条件**：
- 文件存在于 `D:\CodeWorkspace\forMoonbit\pinyin\data\moon.pkg`。
- **无** `import` 块（纯数据包，零依赖，仅 `moonbitlang/core` 隐式可用）。
- **无** `options(...)` 块（不设置 `is-main`，库包）。
- **无** 顶层 `supported_targets`。
- 文件仅含注释（说明包职责）；注释不影响 `moon check` 语义。

**关于空包合法性**：
- moon 0.1.20260713 允许无 `.mbt` 源文件的包通过 `moon check`（包配置存在即合法，源文件在后续任务填充）。
- 空骨架下 `moon check` 会产生 `Warning (0029) (unused_package): Unused package 'pinyin/pinyin/data'`（根因：主包无源文件，import 的数据子包未被引用），该警告为预期产物，处置见 §E 警告治理。
- 本任务**不添加**占位 `.mbt` 源文件以消除警告——警告在后续任务添加引用 `@data.xxx` 的源文件后自然消除。

### D. `README.mbt.md` 内容契约

**前置条件**：`moon.mod` 已创建（`readme = "README.mbt.md"` 字段引用此文件）。

**文件内容**（精确到字节）：

```markdown
# pinyin

MoonBit port of pinyin4cj: Chinese-to-pinyin conversion.
```

**后置条件**：
- 文件存在于 `D:\CodeWorkspace\forMoonbit\pinyin\README.mbt.md`。
- 含一级标题 `# pinyin` 与一行简介。
- **不含** `mbt check` 代码块（后续任务填充 10 个示例，对齐源库 README 10 例）。
- `README.mbt.md` 被 `moon.mod` 的 `readme` 字段引用；moon 工具链将其识别为含测试代码块的 Markdown 文档（SKILL.md:155-158）。本任务占位内容无代码块，不触发测试。

**与已有 `README.md` 的共存策略**：
- 项目根目录已存在 `README.md`（项目顶层说明，非 MoonBit 工具链消费）。
- `README.md` 与 `README.mbt.md` 职责区分：
  - `README.md`：项目顶层说明文档，供 GitHub/仓库浏览者阅读，不参与 moon 工具链校验。
  - `README.mbt.md`：moon 工具链识别的含 `mbt check` 代码块的文档（SKILL.md:155-158），由 `moon.mod` 的 `readme` 字段显式引用。
- 编码 agent **不应删除或修改** `README.md`，仅新建 `README.mbt.md`。两者共存无技术冲突。

### E. 验证契约

**前置条件**：上述四文件均已创建。

**验证命令**（工作目录：`D:\CodeWorkspace\forMoonbit\pinyin`，即项目根目录）：

```sh
moon check
```

**预期输出**：成功（exit code 0），无错误。预期产生 `Warning (0029) (unused_package): Unused package 'pinyin/pinyin/data'`（根因：主包无源文件，import 的数据子包未被引用）。

**后置条件**：
- `moon check` exit code 0。
- 项目根目录结构符合技术方案 §2.2 的骨架子集（仅 `moon.mod` / `moon.pkg` / `README.mbt.md` / `data/moon.pkg`，其余文件后续任务填充）。
- 包边界符合技术方案 §2.3：`pinyin (根包) ──imports──> pinyin/data`，`data/ ──无 import──>`。

**警告治理**（针对 `unused_package`，落实用户偏好"不忽略任何警告"，requirement.md:39）：
- (a) 警告类型与消息文本：`Warning (0029) (unused_package): Unused package 'pinyin/pinyin/data'`
- (b) 根因：主包零源文件 → import 的数据子包未被引用
- (c) 处置决策：接受为预期警告，不阻断本任务验收
- (d) 消除条件：后续任务添加使用 `@data.xxx` 的源文件（如 `pinyin_helper.mbt`）后警告自动消除；若后续任务完成后警告仍存在则视为缺陷
- (e) 记录方式：在编码产出说明中记录警告原文与处置决策

**不执行的验证**（属后续任务）：
- `moon test`（无测试文件）。
- `moon info`（无公开 API，`pkg.generated.mbti` 为空或不存在；本任务不强制生成）。
- `moon fmt`（无 `.mbt` 源文件）。

## 依赖关系

### 本任务依赖的已有资源

| 资源 | 用途 |
|------|------|
| moon 工具链 `0.1.20260713` | `moon check` 验证骨架合法性；feature flags `rr_moon_mod` / `rr_moon_pkg` 已启用（新格式支持） |
| `moonbit-agent-guide` SKILL.md:598-616, 620-637, 648, 677 | `moon.mod` / `moon.pkg` 新格式语法、包识别规则、`moonbitlang/core` 隐式可用 |
| 技术方案 `tech_v1.md` §2.1, §3.1, §3.2, §3.3 | 工具链版本、模块根配置、主包配置、数据子包配置 |
| 技术方案审查 `output_v1.md` §4.1, §3.1 | 确认 moon.mod / moon.pkg 配置通过审查 |
| 源库 `pinyin4cj/LICENSE` | 确认 MIT License，落实审查建议 N2 |

### 本任务暴露给后续任务的公开接口

本任务**不暴露** MoonBit 语言层面的公开接口（无类型、无方法、无常量）。

本任务暴露的**结构性接口**（后续任务依赖）：

| 结构 | 后续任务依赖方式 |
|------|---------------|
| 模块 `pinyin/pinyin` 存在且可编译 | 后续所有任务在此模块内添加包、源文件 |
| 主包（根目录）存在且 import `pinyin/pinyin/data` | 后续任务在根目录添加 `.mbt` 源文件，以 `@data.xxx` 访问数据子包导出 |
| 数据子包 `pinyin/pinyin/data` 存在且零依赖 | 后续任务在 `data/` 添加 `chinese_dict.mbt` / `mutil_pinyin_dict.mbt` / `tongyong_pinyin_dict.mbt` / `pinyin_dict.mbt` 字典字面量 |
| `README.mbt.md` 存在 | 后续任务填充 10 个 `mbt check` 示例 |
| `moon check` 可通过 | 后续任务每次添加源文件后以 `moon check` 验证 |

### 后续任务边界（不在本任务范围内）

以下属后续任务，本任务**不预创建**、**不预留占位**（避免过度设计）：

- `pinyin_spec.mbt` / `pinyin_helper.mbt` / `chinese_helper.mbt` / `pinyin_format.mbt` / `pinyin_error.mbt` / `pinyin_dicts.mbt` / `tone_conversion.mbt`（主包源文件）
- `data/chinese_dict.mbt` / `data/mutil_pinyin_dict.mbt` / `data/tongyong_pinyin_dict.mbt` / `data/pinyin_dict.mbt`（数据子包源文件）
- `pinyin_easy_test.mbt` / `pinyin_mid_test.mbt` / `pinyin_difficult_test.mbt`（测试文件）
- `scripts/gen_pinyin_dict.py`（字典生成脚本）
- `pkg.generated.mbti`（接口文件，由 `moon info` 生成）

## 修订说明（v1 r1）

| 审查意见 | 修改措施 |
|---------|---------|
| [一般] 实际 `moon check` 警告类型与设计预期不符：设计预期"缺少源文件"警告，实测产生 `unused_package` 警告 | 1. §E 预期输出将"可能含零源文件相关警告"替换为明确声明预期产生 `Warning (0029) (unused_package): Unused package 'pinyin/pinyin/data'`，exit code 0。2. 错误处理失败模式表第 4 行由"缺少源文件"替换为 `unused_package` 警告条目，根因为"主包无源文件，import 的数据子包未被引用"，处置为"预期警告，接受；后续任务添加引用 `@data.xxx` 的源文件后自动消除"。3. §C"关于空包合法性"移除"moon 工具链要求包至少有一个 `.mbt` 文件"的预期，明确 moon 0.1.20260713 允许空包通过 `moon check`，并声明本任务不添加占位 `.mbt` 源文件以消除警告。 |
| [一般] 警告治理策略不完整："记录但不阻断"未明确记录位置、形式与不阻断依据 | §E 后置条件新增"警告治理"子项，明确 (a) 警告类型与消息文本；(b) 根因；(c) 处置决策；(d) 消除条件；(e) 记录方式，落实用户偏好"不忽略任何警告"。 |
| [轻微] 未提及项目根目录已存在 `README.md` 与新建 `README.mbt.md` 共存策略 | §D 后置条件新增"与已有 `README.md` 的共存策略"子节，说明两者职责区分（`README.md` 项目顶层说明非工具链消费，`README.mbt.md` moon 工具链识别的含 `mbt check` 代码块文档），并明确编码 agent 不应删除或修改 `README.md`。文件规划说明亦补充共存提示。 |
| [轻微] §E 验证命令 `moon check` 未显式声明工作目录 | §E 验证命令显式声明工作目录为 `D:\CodeWorkspace\forMoonbit\pinyin`（项目根目录），与行为契约 A-D 绝对路径描述保持一致。 |
| [轻微] §C `data/moon.pkg` 注释文本与技术方案 §3.3 存在细微差异（设计增加"（后续任务填充）"括注） | §C 文件内容注释移除"（后续任务填充）"括注，对齐技术方案 §3.3 原文"仅含字典字面量定义，无逻辑，无测试"，避免"精确到字节"口径下注释文本不统一。 |
