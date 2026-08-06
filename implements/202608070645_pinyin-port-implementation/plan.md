# 实现计划

任务描述：将 Cangjie 拼音库 pinyin4cj 移植为 MoonBit 实现（源码 + 单元测试），基于已验证的技术方案 tech_v1.md
项目根目录：D:\CodeWorkspace\forMoonbit\pinyin

---

## R1 NEW 项目骨架与包配置

任务：创建 MoonBit 模块骨架——`moon.mod`（模块元数据，license=MIT，零外部依赖）、主包 `moon.pkg`（import 数据子包）、数据子包 `data/moon.pkg`（无 import，纯数据包）、占位 `README.mbt.md`。预期文件路径：`moon.mod`、`moon.pkg`、`data/moon.pkg`、`README.mbt.md`。验证 `moon check` 通过（空骨架）。

选择理由：所有后续任务（字典字面量、类型定义、算法实现、测试）均依赖项目骨架与包配置。底层优先，先建立可编译的空项目骨架，确保工具链与包边界正确。

上下文：
- 技术方案 §2.2 文件结构、§3.1-3.3 包配置、§十一 T1-T5 决策
- moon 工具链 `moon 0.1.20260713`（rr_moon_mod / rr_moon_pkg feature flags 已启用，支持新格式 moon.mod/moon.pkg）
- 模块名 `pinyin/pinyin`（作者占位），license=MIT（对齐源库 LICENSE，落实审查建议 N2）
- 零外部依赖（无 import 块，仅 moonbitlang/core 隐式可用）
- 主包单向依赖数据子包，数据子包零依赖
- 三后端平等（不设置 preferred-target，不设置 supported_targets）
- 项目根目录当前为空（仅有 .codeartsdoer/ .git/ deliberations/ designs-oo/ designs-tech/ implements/ README.md requirements/ 目录，无 MoonBit 源文件）