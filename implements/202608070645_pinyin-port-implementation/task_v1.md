# 任务指令（v1）

## 动作
NEW

## 任务描述

创建 MoonBit 模块骨架与包配置，建立可编译的空项目骨架。

**预期文件路径与内容**：

1. `D:\CodeWorkspace\forMoonbit\pinyin\moon.mod`（模块根元数据）
   - `name = "pinyin/pinyin"`（`<author>/pinyin` 形式，作者占位）
   - `version = "0.1.0"`
   - `readme = "README.mbt.md"`
   - `repository = ""`
   - `license = "MIT"`（对齐源库 LICENSE，落实审查建议 N2）
   - `keywords = ["pinyin", "chinese", "unicode"]`
   - `description = "MoonBit port of pinyin4cj: Chinese-to-pinyin conversion"`
   - 无 `import` 块（零外部依赖，仅 moonbitlang/core 隐式可用）
   - 不设置 `preferred-target`（三后端平等：wasm-gc / js / native）
   - 不设置 `supported_targets`（不限制可移植性）

2. `D:\CodeWorkspace\forMoonbit\pinyin\moon.pkg`（主包配置）
   - `import { "pinyin/pinyin/data" }`（单向依赖数据子包）
   - 不设置 `is-main`（库包）

3. `D:\CodeWorkspace\forMoonbit\pinyin\data\moon.pkg`（数据子包配置）
   - 无 `import`（纯数据包，零依赖）
   - 不设置 `is-main`

4. `D:\CodeWorkspace\forMoonbit\pinyin\README.mbt.md`（占位，后续任务填充 10 个 mbt check 示例）
   - 最小占位内容：标题 + 简介一行

**验证**：`moon check` 通过（空骨架，无源文件）。如 `moon check` 报告缺少源文件或包配置错误，需修正。

## 选择理由

- **底层优先**：所有后续任务（字典字面量、类型定义、算法实现、测试）均依赖项目骨架与包配置。先建立可编译的空项目骨架，确保工具链与包边界正确，再逐步填充。
- **当前优先级**：最高。无骨架则后续任务无法 `moon check`。
- **与已完成任务的依赖关系**：无（首个任务）。

## 任务上下文

**摘录自技术方案 tech_v1.md**：

§2.1 工具链版本：
- moon 工具链 `moon 0.1.20260713`（已验证支持 rr_moon_mod / rr_moon_pkg feature flags，即新格式 moon.mod / moon.pkg）
- 目标后端：wasm-gc / js / native 三后端平等支持，不设置 preferred-target，不设置 supported_targets 限制
- 源目录：默认 `.`（模块根即主包根），数据子包 `data/` 下挂

§3.1 moon.mod（模块根）关键决策：
- `license = "MIT"`（落实审查建议 N2）：对齐源库 LICENSE 文件（MIT License, Copyright (c) 2017 sbiger）。审查报告 N2 指出 design_v2.md 写 Apache-2.0 为事实性错误。
- 模块名 `pinyin/pinyin`：`<author>/pinyin` 形式，作者命名空间暂用工作目录名 pinyin 占位，发布到 mooncakes.io 时确定正式作者名。
- 零外部依赖：无 import 块，仅 moonbitlang/core 隐式可用。

§3.2 主包 moon.pkg（根目录）：
- import 数据子包
- 不设置 is-main（库包）
- 测试文件 _test.mbt 自动引用主包，无需 for "test" 配置

§3.3 数据子包 data/moon.pkg：
- 纯数据包，无 import
- 不设置 is-main
- 仅含字典字面量定义，无逻辑，无测试

§3.4 pkg.generated.mbti 管理：
- 主包与数据子包各生成 pkg.generated.mbti，入版本控制
- 每次 API 变更后 `moon info` 重新生成

§2.3 包边界与依赖方向：
```
pinyin (根包) ──imports──> pinyin/data
data/ ──无 import──> (仅 moonbitlang/core 隐式)
```

§十一 关键技术决策汇总：
- T1: moon 工具链版本 `moon 0.1.20260713`（rr_moon_mod / rr_moon_pkg）
- T2: 目标后端 wasm-gc / js / native 三后端平等
- T3: 模块名 `pinyin/pinyin`（作者占位）
- T4: license `MIT`（落实审查建议 N2）
- T5: 零外部依赖（无 import 块，仅 moonbitlang/core 隐式）

**审查报告 output_v1.md 相关确认**：
- §4.1 moon.mod / moon.pkg 配置 [通过]：新格式、模块名、license=MIT、零外部依赖、不设置 preferred-target、不设置 supported_targets（underscore 形式）均符合 SKILL.md:93-110, 639 规范
- §3.1 moon 工具链版本 [通过]：已通过 `moon version` 实测验证，Feature flags 已启用

## 已有代码上下文

项目根目录 `D:\CodeWorkspace\forMoonbit\pinyin` 当前状态：

```
pinyin/                              # 工作目录（即将成为 MoonBit 模块根）
├── .codeartsdoer/                   # Skills 目录（含 moonbit-agent-guide 等 skill）
├── .git/                            # Git 仓库
├── deliberations/                  # 审议报告目录
├── designs-oo/                     # 架构设计目录
├── designs-tech/                   # 技术方案目录
├── implements/                     # 实现任务目录（本任务所在）
├── README.md                       # 项目 README（非 MoonBit 的 README.mbt.md）
└── requirements/                   # 需求文档目录
```

**无 MoonBit 源文件、无 moon.mod/moon.pkg、无 data/ 子包**。本任务从零建立 MoonBit 模块骨架。

**源库参考**（`D:\CodeWorkspace\forCangjie\pinyin4cj`）：
- `cjpm.toml`：Cangjie 构建配置，对应 MoonBit 的 moon.mod + moon.pkg
- `LICENSE`：MIT License (Copyright (c) 2017 sbiger)，对应 moon.mod 中 `license = "MIT"`
- 9 源文件 + 1 外部资源（resource/pinyin.dict.txt），后续任务逐步移植