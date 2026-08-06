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

---

## R1 PASSED 项目骨架与包配置

结果：创建 `moon.mod`（name=`pinyin/pinyin`，version=`0.1.0`，license=MIT，零外部依赖）、`moon.pkg`（import `pinyin/pinyin/data`）、`data/moon.pkg`（纯数据包零依赖）、`README.mbt.md`（占位）。模块空骨架建立，包边界正确。
测试：无 `.mbt` 测试文件（骨架任务无公开接口）。`moon check` exit code 0，1 warnings（`unused_package` 预期警告，主包零源文件致数据子包未引用，后续任务添加 `@data.xxx` 引用后自动消除），0 errors。

---

## R2 NEW 基础类型定义（PinyinFormat + PinyinError）

任务：在主包定义 `PinyinFormat`（`pub(all) enum`，4 变体 `WithToneMark` / `WithoutTone` / `WithToneNumber` / `FirstLetter`，含 `name` 方法返回变体名）与 `PinyinError`（`pub(all) suberror`，单变体 `PinyinError(String)` 携带消息）。预期文件路径：`pinyin_format.mbt`、`pinyin_error.mbt`。验证 `moon check` 通过，`unused_package` 警告仍存在（预期，本任务不引用数据子包）。

选择理由：`PinyinFormat` 是所有拼音转换方法的参数类型，`PinyinError` 是所有可抛错方法的异常类型。两者是全部公开 API 的基础类型依赖，无需字典数据，属最底层。按"底层优先"原则，在字典字面量与算法实现之前先定义基础类型，为后续 `PinyinHelper` / `ChineseHelper` 方法签名提供类型基础。两类型紧密相关（均为基础枚举/错误类型），合并为一个任务符合粒度约定（1-3 个紧密相关类型）。

上下文：
- 技术方案 §7.1 类型形态（PinyinFormat pub(all) enum 4 变体 / PinyinError pub(all) suberror 单变体）、§7.3 公开 API 方法清单（PinyinFormat::name）、§7.4 错误处理策略（raise PinyinError 检查式错误）、§10.1 移植映射表（pinyin_format.cj → pinyin_format.mbt / utils.cj → pinyin_error.mbt）、§十一 T9/T10 决策
- 源库 `pinyin_format.cj`（33行）：enum PinyinFormat 4 变体 + getName() 方法，match 返回变体名字符串
- 源库 `utils.cj`（25行）：class Pinyin4cjException <: Exception，携带 messages 字段，getMessage() / toString()
- MoonBit suberror 惯例：`pub(all) suberror PinyinError { PinyinError(String) }`，调用方 `raise PinyinError` / `catch { PinyinError::PinyinError(msg) => ... }`
- 命名映射：WITH_TONE_MARK→WithToneMark / WITHOUT_TONE→WithoutTone / WITH_TONE_NUMBER→WithToneNumber / FIRST_LETTER→FirstLetter / getName→name
- R1 已建立模块骨架（moon.mod / moon.pkg / data/moon.pkg / README.mbt.md），`moon check` 通过
- 本任务不引用数据子包（`@data.xxx`），`unused_package` 警告将持续至后续字典加载任务