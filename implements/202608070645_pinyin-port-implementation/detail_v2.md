# 详细设计（v2）

## 概述

本任务为 pinyin4cj → MoonBit 移植的**第二个编码任务**，目标是在主包（项目根目录）定义两个基础类型，为后续全部公开 API 提供类型基础：

1. **`PinyinFormat`**（`pub(all) enum`，4 变体 + `name` 方法）— 拼音输出格式枚举，是所有拼音转换方法（`convert_to_pinyin_string` / `convert_to_pinyin_array` / `get_short_pinyin` 等）的参数类型。
2. **`PinyinError`**（`pub(all) suberror`，单变体携带消息）— 拼音库统一错误类型，是所有可抛错方法（`convert_to_pinyin_string` 空串 / `has_multi_pinyin` 非汉字 / `get_short_pinyin` 空串）的异常类型。

本任务在 R1 产出的项目骨架（`moon.mod` / `moon.pkg` / `data/moon.pkg` / `README.mbt.md`）上新增两个 `.mbt` 源文件，**不修改**任何已有文件，**不引用**数据子包（`@data.xxx`），**不添加** `import`。完成后 `moon check` 应通过（exit code 0），`unused_package` 警告仍存在（预期，本任务不引用数据子包，后续字典加载任务后消除）。

本任务**不涉及**算法实现、字典数据、其他类型定义（`PinyinHelper` / `ChineseHelper` / `PinyinDicts` / `ToneConversion` 等）— 这些属后续任务。

## 文件规划

| 文件路径 | 操作 | 职责 |
|---------|------|------|
| `pinyin_format.mbt` | 新建 | `PinyinFormat` 枚举类型定义 + `name` 方法；对齐源库 `pinyin_format.cj` |
| `pinyin_error.mbt` | 新建 | `PinyinError` suberror 类型定义；对齐源库 `utils.cj` 的 `Pinyin4cjException` |

**说明**：
- 路径均相对项目根目录 `D:\CodeWorkspace\forMoonbit\pinyin`（主包根目录）。
- 两文件位于主包根目录，与 `moon.pkg` 同级，被主包自动识别为源文件（SKILL.md:648）。
- 本任务**不修改** `moon.mod` / `moon.pkg` / `data/moon.pkg` / `README.mbt.md` / `README.md`（R1 产出保持不变）。
- 本任务**不创建**后续任务文件（`pinyin_helper.mbt` / `chinese_helper.mbt` / `pinyin_dicts.mbt` / `tone_conversion.mbt` / `pinyin_spec.mbt` / 测试文件 / `data/*.mbt` 等）— 避免过度设计。

## 类型定义

### PinyinFormat

**形态**：`pub(all) enum`（公开所有变体与方法）
**包路径**：`pinyin/pinyin`（主包，根目录）
**职责**：拼音输出格式枚举，作为所有拼音转换方法的参数类型

**类型签名定义**（精确到字节，编码 agent 直接照抄至 `pinyin_format.mbt`）：

```moonbit
/// 拼音输出格式枚举，对齐源库 pinyin4cj 的 PinyinFormat。
/// 4 个变体分别对应：带声调标记 / 不带声调 / 带声调数字 / 首字母。
pub(all) enum PinyinFormat {
  WithToneMark
  WithoutTone
  WithToneNumber
  FirstLetter
}
```

**公开接口**：

```moonbit
/// 返回格式名称字符串（大写下划线形式），逐字符对齐源库 getName()。
pub fn PinyinFormat::name(self : PinyinFormat) -> String
```

**方法实现**（精确到字节，编码 agent 直接照抄）：

```moonbit
pub fn PinyinFormat::name(self : PinyinFormat) -> String {
  match self {
    WithToneMark => "WITH_TONE_MARK"
    WithoutTone => "WITHOUT_TONE"
    WithToneNumber => "WITH_TONE_NUMBER"
    FirstLetter => "FIRST_LETTER"
  }
}
```

**构造方式**：直接使用变体构造器 `WithToneMark` / `WithoutTone` / `WithToneNumber` / `FirstLetter`（无参数变体）。

**类型关系**：无继承、无实现、无组合，独立枚举类型。后续任务的公开 API 以 `PinyinFormat` 作为参数类型（如 `convert_to_pinyin_string(str : String, format~ : PinyinFormat = WithToneMark) -> String raise PinyinError`）。

### PinyinError

**形态**：`pub(all) suberror`（公开所有变体，MoonBit 检查式错误惯例）
**包路径**：`pinyin/pinyin`（主包，根目录）
**职责**：拼音库统一错误类型，承载错误消息字符串，对齐源库 `Pinyin4cjException`

**类型签名定义**（精确到字节，编码 agent 直接照抄至 `pinyin_error.mbt`）：

```moonbit
/// 拼音库统一错误类型，对齐源库 pinyin4cj 的 Pinyin4cjException。
/// 单变体携带错误消息字符串，后续方法以 `raise PinyinError("msg")` 抛错，
/// 调用方以 `try expr catch { PinyinError::PinyinError(msg) => ... }` 捕获。
pub(all) suberror PinyinError {
  PinyinError(String)
}
```

**公开接口**：
- 变体构造器：`PinyinError(String)` — 接受错误消息字符串，构造错误值
- 错误传播：通过 `raise PinyinError("msg")` 在方法中抛出
- 错误捕获：通过 `try expr catch { PinyinError::PinyinError(msg) => ... }` 在调用方捕获

**构造方式**：`PinyinError("message")` — 传入错误消息字符串构造错误值。

**类型关系**：`suberror` 声明 `PinyinError` 是内置 `Error` 类型的子类型，可自动提升为 `Error`，可被 `try...catch` 模式匹配捕获。后续所有可抛错方法在签名中声明 `raise PinyinError`。

**关于源库 `toString()` / `getMessage()` 的映射决策**：
- 源库 `Pinyin4cjException` 含 `getMessage()` 返回消息字段、`toString()` 返回 `"Pinyin4cjException: ${messages}"`。
- MoonBit `suberror` 自动生成 `Show` / `ToJson`（配合 `derive`），其 `to_string()` 输出形式为 `PinyinError("msg")`，与源库 `toString()` 形式不同。
- 本任务**不实现** `to_string` / `get_message` 对应方法（task_v2.md 未要求），仅定义类型与变体。后续任务如需对齐源库 `toString()` 输出形式，可显式定义 `pub fn PinyinError::to_string(self) -> String` 覆盖默认实现，属后续任务范围。
- 错误消息文本的逐字符对齐属后续任务（在具体抛错点对齐源库消息文本），本任务仅定义类型载体。

## 错误处理

本任务**仅定义错误类型**，不涉及具体抛错点。错误处理策略如下：

- **错误模型**：采用 `raise PinyinError`（非 `Result[T, PinyinError]`），符合 MoonBit 检查式错误惯例（`suberror` + `raise`/`catch`），语义对齐源库 `throw Pinyin4cjException`（技术方案 §7.4）。
- **错误类型**：`PinyinError`（`pub(all) suberror`，单变体 `PinyinError(String)` 携带消息）。
- **传播策略**：后续可抛错方法在签名中声明 `raise PinyinError`，调用方按需 `try...catch` 捕获或继续传播。
- **捕获语法**：`try expr catch { PinyinError::PinyinError(msg) => handler(msg) }`，亦可 `try expr catch e => ...` 后模式匹配。
- **本任务无运行时错误路径**：`PinyinFormat::name` 为纯函数（对每个变体返回常量字符串，不抛错）；`PinyinError` 仅定义类型，不触发构造。

**验证阶段**的潜在失败模式与处置（编码 agent 需关注）：

| 失败模式 | 根因 | 处置 |
|---------|------|------|
| `moon check` 报告 `pinyin_format.mbt` 语法错误 | `pub(all) enum` 语法拼写、变体名 PascalCase 不一致、`match` 分支缺失 | 对照 wiki `libs/time.md:104` `pub(all) enum Weekday` 示例与本文 §类型定义/PinyinFormat 签名修正 |
| `moon check` 报告 `pinyin_error.mbt` 语法错误 | `pub(all) suberror` 语法拼写、变体名与类型名重名冲突、缺大括号 | 对照 wiki `libs/json5.md:22` `pub(all) suberror ParseError` 示例与本文 §类型定义/PinyinError 签名修正 |
| `moon check` 报告 `name` 方法签名错误 | `pub fn PinyinFormat::name(self : PinyinFormat) -> String` 拼写错误、`match` 分支返回类型不统一 | 对照本文 §类型定义/PinyinError 方法实现修正 |
| `moon check` 报告未使用警告（`unused`） | `name` 方法或变体未被引用 | 本任务类型与方法为公开 API，`pub(all)` 与 `pub fn` 应避免未使用警告；若出现则检查可见性修饰符 |
| `moon check` 产生 `Warning (0029) (unused_package): Unused package 'pinyin/pinyin/data'` | 主包源文件未引用 `@data.xxx` | **预期警告**：接受，不阻断本任务验收；后续字典加载任务添加 `@data.xxx` 引用后自动消除（详见 §行为契约/E 验证契约） |

## 行为契约

### A. `pinyin_format.mbt` 内容契约

**前置条件**：项目根目录 `D:\CodeWorkspace\forMoonbit\pinyin` 存在且可写；R1 产出的 `moon.mod` / `moon.pkg` 已存在。

**文件内容**（精确到字节，编码 agent 直接照抄）：

```moonbit
/// 拼音输出格式枚举，对齐源库 pinyin4cj 的 PinyinFormat。
/// 4 个变体分别对应：带声调标记 / 不带声调 / 带声调数字 / 首字母。
pub(all) enum PinyinFormat {
  WithToneMark
  WithoutTone
  WithToneNumber
  FirstLetter
}

/// 返回格式名称字符串（大写下划线形式），逐字符对齐源库 getName()。
pub fn PinyinFormat::name(self : PinyinFormat) -> String {
  match self {
    WithToneMark => "WITH_TONE_MARK"
    WithoutTone => "WITHOUT_TONE"
    WithToneNumber => "WITH_TONE_NUMBER"
    FirstLetter => "FIRST_LETTER"
  }
}
```

**后置条件**：
- 文件存在于 `D:\CodeWorkspace\forMoonbit\pinyin\pinyin_format.mbt`。
- `PinyinFormat` 为 `pub(all) enum`，4 变体 `WithToneMark` / `WithoutTone` / `WithToneNumber` / `FirstLetter`（PascalCase，对齐源库 `WITH_TONE_MARK` 等大写下划线变体名）。
- `name` 方法为 `pub fn PinyinFormat::name(self : PinyinFormat) -> String`，对每个变体返回对应的大写下划线形式字符串字面量（**非**变体名 PascalCase 形式）。
- `name` 方法返回值逐字符对齐源库 `getName()`：
  | 变体 | 返回值 | 源库对应 |
  |------|--------|---------|
  | `WithToneMark` | `"WITH_TONE_MARK"` | `WITH_TONE_MARK => "WITH_TONE_MARK"` |
  | `WithoutTone` | `"WITHOUT_TONE"` | `WITHOUT_TONE => "WITHOUT_TONE"` |
  | `WithToneNumber` | `"WITH_TONE_NUMBER"` | `WITH_TONE_NUMBER => "WITH_TONE_NUMBER"` |
  | `FirstLetter` | `"FIRST_LETTER"` | `FIRST_LETTER => "FIRST_LETTER"` |
- 文件含注释（`///` 文档注释），落实用户偏好"代码包含必要的注释和文档"。
- **无** `import` 语句（不引用数据子包或其他包）。
- **无** `derive` 子句（task_v2.md 未要求，后续任务如需 `derive(Eq, Show)` 等再加）。

### B. `pinyin_error.mbt` 内容契约

**前置条件**：项目根目录 `D:\CodeWorkspace\forMoonbit\pinyin` 存在且可写；R1 产出的 `moon.mod` / `moon.pkg` 已存在。

**文件内容**（精确到字节，编码 agent 直接照抄）：

```moonbit
/// 拼音库统一错误类型，对齐源库 pinyin4cj 的 Pinyin4cjException。
/// 单变体携带错误消息字符串，后续方法以 `raise PinyinError("msg")` 抛错，
/// 调用方以 `try expr catch { PinyinError::PinyinError(msg) => ... }` 捕获。
pub(all) suberror PinyinError {
  PinyinError(String)
}
```

**后置条件**：
- 文件存在于 `D:\CodeWorkspace\forMoonbit\pinyin\pinyin_error.mbt`。
- `PinyinError` 为 `pub(all) suberror`，单变体 `PinyinError(String)`（变体名与类型名同名，MoonBit `suberror` 惯例，参考 wiki `libs/json5.md:22` `pub(all) suberror ParseError { ParseError(ParseErrorData) }`）。
- 变体载荷为 `String`（错误消息字符串），对齐源库 `Pinyin4cjException.messages` 字段。
- `PinyinError` 是内置 `Error` 类型的子类型（`suberror` 声明），可自动提升为 `Error`，可被 `try...catch` 模式匹配捕获。
- 文件含注释（`///` 文档注释），落实用户偏好"代码包含必要的注释和文档"。
- **无** `import` 语句。
- **无** `derive` 子句（task_v2.md 未要求；`suberror` 自动生成 `Eq`/`Show`/`ToJson`，无需显式 derive）。
- **无** `to_string` / `get_message` 方法定义（task_v2.md 未要求，后续任务如需对齐源库 `toString()` 再加）。

### C. 命名规范契约

| 元素 | 命名 | 规范 | 源库对应 |
|------|------|------|---------|
| 类型名 | `PinyinFormat` | PascalCase | `PinyinFormat` |
| 类型名 | `PinyinError` | PascalCase | `Pinyin4cjException` |
| 枚举变体 | `WithToneMark` | PascalCase | `WITH_TONE_MARK` |
| 枚举变体 | `WithoutTone` | PascalCase | `WITHOUT_TONE` |
| 枚举变体 | `WithToneNumber` | PascalCase | `WITH_TONE_NUMBER` |
| 枚举变体 | `FirstLetter` | PascalCase | `FIRST_LETTER` |
| suberror 变体 | `PinyinError(String)` | PascalCase（与类型同名） | `Pinyin4cjException(messages)` |
| 方法名 | `name` | lower_snake（self 参数） | `getName()` |
| 文件名 | `pinyin_format.mbt` / `pinyin_error.mbt` | lower_snake | `pinyin_format.cj` / `utils.cj` |

### D. 与已有代码的交互契约

**前置条件**：R1 产出的项目骨架存在且 `moon check` 通过（exit code 0，1 warnings `unused_package`）。

**交互影响**：
- **`moon.mod`**：不受影响（本任务不修改；新源文件由 `moon` 自动发现，无需在 `moon.mod` 注册）。
- **`moon.pkg`**：不受影响（本任务不修改；不新增 `import`，不新增 `for "test"` 子句）。
- **`data/moon.pkg`**：不受影响（本任务不修改、不引用数据子包）。
- **`README.mbt.md`**：不受影响（本任务不修改；不填充 `mbt check` 代码块，属后续任务）。
- **`README.md`**：不受影响（项目顶层说明文档，非 MoonBit 工具链消费）。
- **`unused_package` 警告**：持续存在（本任务不引用 `@data.xxx`），与 R1 状态一致，处置见 §E 验证契约。

**后置条件**：
- 项目根目录新增 `pinyin_format.mbt` / `pinyin_error.mbt` 两个 `.mbt` 源文件。
- 其余文件与 R1 产出完全一致（字节级不变）。
- 主包现含 2 个源文件，定义 2 个公开类型（`PinyinFormat` / `PinyinError`）与 1 个公开方法（`PinyinFormat::name`）。

### E. 验证契约

**前置条件**：上述两文件均已创建。

**验证命令**（工作目录：`D:\CodeWorkspace\forMoonbit\pinyin`，即项目根目录）：

```sh
moon check
```

**预期输出**：成功（exit code 0），无错误。预期产生 `Warning (0029) (unused_package): Unused package 'pinyin/pinyin/data'`（根因：主包源文件未引用 `@data.xxx`，与 R1 状态一致）。

**后置条件**：
- `moon check` exit code 0。
- 项目根目录结构在 R1 基础上新增 `pinyin_format.mbt` / `pinyin_error.mbt`。
- 主包公开 API 包含 `PinyinFormat`（enum，4 变体）+ `PinyinFormat::name` 方法 + `PinyinError`（suberror，1 变体）。
- `PinyinFormat::name` 方法对 4 变体返回值逐字符对齐源库 `getName()`。

**警告治理**（针对 `unused_package`，落实用户偏好"不忽略任何警告"，requirement.md:39）：
- (a) 警告类型与消息文本：`Warning (0029) (unused_package): Unused package 'pinyin/pinyin/data'`
- (b) 根因：主包源文件（`pinyin_format.mbt` / `pinyin_error.mbt`）均未引用 `@data.xxx` → import 的数据子包未被引用
- (c) 处置决策：接受为预期警告，不阻断本任务验收（与 R1 状态一致）
- (d) 消除条件：后续字典加载任务（`pinyin_dicts.mbt` 引用 `@data.xxx`）后警告自动消除；若后续任务完成后警告仍存在则视为缺陷
- (e) 记录方式：在编码产出说明中记录警告原文与处置决策

**不执行的验证**（属后续任务）：
- `moon test`（本任务无测试文件，属后续任务；`PinyinFormat::name` 的行为测试在后续测试任务中编写）。
- `moon info`（本任务可生成 `pkg.generated.mbti` 暴露公开 API，但非本任务强制；若 `moon check` 触发则接受）。
- `moon fmt`（可选，编码 agent 可执行以规范化格式，非本任务强制）。

## 依赖关系

### 本任务依赖的已有资源

| 资源 | 用途 |
|------|------|
| R1 产出：`moon.mod` | 模块根元数据，`moon` 工具链识别主包 |
| R1 产出：`moon.pkg` | 主包配置，`import "pinyin/pinyin/data"`（本任务不引用但保留） |
| R1 产出：`data/moon.pkg` | 数据子包配置（本任务不引用但保留） |
| moon 工具链 `0.1.20260713` | `moon check` 验证类型定义合法性；feature flags `rr_moon_mod` / `rr_moon_pkg` 已启用 |
| MoonBit 语言：`pub(all) enum` | 公开枚举语法，参考 wiki `libs/time.md:104` `pub(all) enum Weekday` |
| MoonBit 语言：`pub(all) suberror` | 公开子错误类型语法，参考 wiki `libs/json5.md:22` `pub(all) suberror ParseError` |
| MoonBit 语言：`raise` / `try` / `catch` | 检查式错误处理，参考 wiki `language/error-handling.md` |
| 技术方案 `tech_v1.md` §7.1, §7.3, §7.4, §10.1, §十一 T9/T10 | 类型形态、命名映射、错误处理策略、移植映射表、关键技术决策 |
| 源库 `pinyin4cj/pinyin_format.cj`（33行） | `PinyinFormat` 枚举与 `getName()` 方法对齐基准 |
| 源库 `pinyin4cj/utils.cj`（25行） | `Pinyin4cjException` 类对齐基准（映射为 `PinyinError` suberror） |

### 本任务暴露给后续任务的公开接口

| 公开接口 | 后续任务依赖方式 |
|---------|---------------|
| `PinyinFormat` 类型（4 变体） | 后续所有拼音转换方法以 `PinyinFormat` 作为 `format~` 参数类型（技术方案 T9：labeled 参数默认值 `format~ = WithToneMark`） |
| `PinyinFormat::WithToneMark` / `WithoutTone` / `WithToneNumber` / `FirstLetter` 变体 | 后续方法默认值（`WithToneMark`）、测试用例构造、`match` 分支匹配 |
| `PinyinFormat::name` 方法 | 后续测试可能调用断言格式名；README 示例可能展示 |
| `PinyinError` 类型（1 变体 `PinyinError(String)`） | 后续所有可抛错方法在签名声明 `raise PinyinError`，在错误路径 `raise PinyinError("msg")` 抛错 |
| `PinyinError::PinyinError(String)` 构造器 | 后续方法构造错误值，测试用例捕获错误并断言消息 |

### 后续任务边界（不在本任务范围内）

以下属后续任务，本任务**不预创建**、**不预留占位**（避免过度设计）：

- `pinyin_helper.mbt`（`PinyinHelper` 类型与拼音转换算法）— 依赖本任务 `PinyinFormat` / `PinyinError`
- `chinese_helper.mbt`（`ChineseHelper` 类型与汉字判定）— 依赖本任务 `PinyinError`
- `pinyin_dicts.mbt`（`PinyinDicts` 字典加载）— 依赖本任务类型 + `@data.xxx` 数据子包
- `tone_conversion.mbt`（`ToneConversion` 声调转换）— 依赖本任务 `PinyinFormat`
- `pinyin_spec.mbt`（spec 契约声明）— 依赖本任务类型签名
- `data/chinese_dict.mbt` / `data/mutil_pinyin_dict.mbt` / `data/tongyong_pinyin_dict.mbt` / `data/pinyin_dict.mbt`（数据子包字典字面量）— 不依赖本任务
- `pinyin_easy_test.mbt` / `pinyin_mid_test.mbt` / `pinyin_difficult_test.mbt`（测试文件）— 依赖本任务类型与方法的可测行为
- `PinyinError::to_string` / `get_message` 等方法（对齐源库 `toString()` / `getMessage()`）— 若后续任务需要对齐源库输出形式再加
- `derive(Eq, Show, ToJson)` 等派生（若后续任务需要自动生成 `Eq`/`Show` 等再加）

## 修订说明（v2 r1）

本任务为 NEW 动作（非审查反馈修订），无前序审查意见。本节为占位，保留供后续审查轮次追加修订说明。