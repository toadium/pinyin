# 详细设计（v5）

## 概述

本任务为 pinyin4cj → MoonBit 移植 R4（字典视图构造）。在主包根目录新建 `pinyin_dicts.mbt`，从 `@data` 子包读取 R3 v4 已生成的四个 `pub let` 字典字面量，重新绑定为 `pub let` 运行时 `Map` 视图常量。

### 设计目标

1. 建立主包内可访问的字典视图层，为后续 R5（声调转换）/ R6（拼音转换）/ R7（繁简互转）算法任务提供包内常量引用入口
2. 消除 `Warning (0029) (unused_package): Unused package 'pinyin/pinyin/data'`——主包非 test 源文件 `pinyin_dicts.mbt` 引用 `@data.xxx`，使 `@data` 子包被主包非 test 代码使用
3. 四个视图常量绑定为 `pub let` 顶层常量，作为主包公共只读常量暴露（MoonBit 顶层 `let` 常量可见性仅有 `let` 文件内私有与 `pub let` 跨包公开两档，无 `pub(self)` 包内可见选项；为保证后续 R5/R6/R7 算法文件可跨文件引用并确保语义稳定，采用 `pub let`）

### 设计范围

- **仅新建一个文件**：`pinyin_dicts.mbt`（主包根目录）
- **不修改**任何已有文件（`moon.mod` / `moon.pkg` / `data/*` / `pinyin_format.mbt` / `pinyin_error.mbt` / 所有测试文件均保持不变）
- **不新增测试**（验证要求明确：现有 26 用例不受影响，本任务不新增测试）
- **不处理** `text_segment_excceed` 警告（设计变更，本任务不处理）

### 移植映射

对应源库 `pinyin_resource.cj` 的资源加载逻辑（运行时文件 IO）→ MoonBit 构建期内嵌字面量 + 主包视图绑定（无运行时 IO）。源库 `pinyin_helper.cj:10-12` + `chinese_helper.cj:9` 在运行时通过 `PinyinResource.get*Resource()` 加载四张 `HashMap`；MoonBit 移植改为引用 `@data` 子包构建期常量，跨 wasm/js/native 三后端一致。

## 文件规划

| 文件路径 | 操作 | 职责 |
|---------|------|------|
| `pinyin_dicts.mbt` | **新建** | 从 `@data` 子包读取四个字典字面量，绑定为 `pub let` 运行时 `Map` 视图常量，供主包内算法文件引用 |

**说明**：
- 路径相对项目根目录 `D:\CodeWorkspace\forMoonbit\pinyin`。
- 本任务**不修改**以下文件（R1/R2/R3 v4 产出保持不变）：`moon.mod` / `moon.pkg` / `data/moon.pkg` / `data/chinese_dict.mbt` / `data/mutil_pinyin_dict.mbt` / `data/tongyong_pinyin_dict.mbt` / `data/pinyin_dict.mbt` / `pinyin_format.mbt` / `pinyin_error.mbt` / `pinyin_format_test.mbt` / `pinyin_error_test.mbt` / `chinese_dict_test.mbt` / `mutil_pinyin_dict_test.mbt` / `tongyong_pinyin_dict_test.mbt` / `pinyin_dict_test.mbt` / `README.mbt.md` / `README.md` / `scripts/gen_pinyin_dict.py`。

## 类型定义

本任务仅涉及 MoonBit 顶层 `let` 常量绑定，无函数 / 方法 / 自定义类型定义。

### chinese_map

**形态**：`pub let` 顶层绑定，`Map[Int, Int]` 视图
**包路径**：`pinyin/pinyin`（主包根目录）
**职责**：繁体→简体汉字码点映射视图，引用 `@data.chinese_dict`

```moonbit
/// 繁体→简体汉字码点映射，2533 条，对应源库 CHINESE_MAP。
pub let chinese_map : Map[Int, Int] = @data.chinese_dict
```

**公开接口**：`chinese_map : Map[Int, Int]`（`pub let` 顶层常量，跨包可引用）
**构造方式**：构建期直接引用 `@data.chinese_dict`（`pub let`，跨包可引用），赋值给 `chinese_map`
**类型关系**：与 `@data.chinese_dict` 共享同一 `Map[Int, Int]` 对象引用（MoonBit `let` 绑定不复制）

### pinyin_table

**形态**：`pub let` 顶层绑定，`Map[String, String]` 视图
**包路径**：`pinyin/pinyin`（主包根目录）
**职责**：单字拼音映射视图，引用 `@data.pinyin_dict`

```moonbit
/// 单字拼音映射，20903 条，对应源库 PINYIN_TABLE。
pub let pinyin_table : Map[String, String] = @data.pinyin_dict
```

**公开接口**：`pinyin_table : Map[String, String]`（`pub let` 顶层常量）
**构造方式**：构建期直接引用 `@data.pinyin_dict`
**类型关系**：与 `@data.pinyin_dict` 共享同一 `Map[String, String]` 对象引用

### mutil_pinyin_table

**形态**：`pub let` 顶层绑定，`Map[String, String]` 视图
**包路径**：`pinyin/pinyin`（主包根目录）
**职责**：词组拼音映射视图，引用 `@data.mutil_pinyin_dict`

```moonbit
/// 词组拼音映射，843 条，对应源库 MUTIL_PINYIN_TABLE。
pub let mutil_pinyin_table : Map[String, String] = @data.mutil_pinyin_dict
```

**公开接口**：`mutil_pinyin_table : Map[String, String]`（`pub let` 顶层常量）
**构造方式**：构建期直接引用 `@data.mutil_pinyin_dict`
**类型关系**：与 `@data.mutil_pinyin_dict` 共享同一 `Map[String, String]` 对象引用

### tongyong_pinyin_table

**形态**：`pub let` 顶层绑定，`Map[String, String]` 视图
**包路径**：`pinyin/pinyin`（主包根目录）
**职责**：通用拼音映射视图，引用 `@data.tongyong_pinyin_dict`

```moonbit
/// 通用拼音映射，82 条，对应源库 TONGYONG_PINYIN_TABLE。
pub let tongyong_pinyin_table : Map[String, String] = @data.tongyong_pinyin_dict
```

**公开接口**：`tongyong_pinyin_table : Map[String, String]`（`pub let` 顶层常量）
**构造方式**：构建期直接引用 `@data.tongyong_pinyin_dict`
**类型关系**：与 `@data.tongyong_pinyin_dict` 共享同一 `Map[String, String]` 对象引用

### 可见性决策

四个视图常量均使用 `pub let`。决策依据经实际编译验证（moon 0.1.20260713）：

| 选项 | 编译验证结果 | 选用 |
|------|------------|------|
| `pub(self) let` | **Error [3005]**：No 'public self' visibility for value。MoonBit 顶层 `let` 常量绑定不存在 `pub(self)` 可见性修饰符 | 否 |
| `pub let` | 编译通过，0 errors。跨包可引用，作为公共只读常量暴露 | **是** |
| `let`（私有） | 编译通过，0 errors，且当前版本可同包跨文件引用。但 `let` 顶层常量语义为文件内私有，跨文件引用行为依赖编译器版本演进，稳定性弱于 `pub let` | 否 |

**选用 `pub let` 的理由**：
1. `pub(self) let` 语法不合法（Error [3005]），已排除
2. `pub let` 是 MoonBit 文档明确支持的稳定语法，跨包引用语义清晰，后续 R5/R6/R7 算法文件引用无版本演进风险
3. 虽 `let` 在当前版本可同包跨文件引用，但其"文件内私有"语义对跨文件引用的支撑依赖编译器实现细节，不如 `pub let` 稳健
4. 接受字典视图作为公共只读常量暴露，是 MoonBit 顶层 `let` 常量可见性限制下的合理妥协（技术方案 §4.2 所述 `pub(self)` 目标在 MoonBit 语言层面无法实现，需上溯至 `pub let`）

**公共 API 影响评估**：
- 四个字典视图常量（`chinese_map` / `pinyin_table` / `mutil_pinyin_table` / `tongyong_pinyin_table`）成为主包公共 API 的一部分
- 类型为 `Map[Int, Int]` / `Map[String, String]`，`let` 绑定不可重新赋值，但 `Map` 对象内容可变（外部消费者可 `add_*` 原地修改，需在后续 R10 README 中文档说明）
- 主包公共 API 从 `PinyinFormat` / `PinyinError` 扩展为 `PinyinFormat` / `PinyinError` / `chinese_map` / `pinyin_table` / `mutil_pinyin_table` / `tongyong_pinyin_table`

### 命名映射

| 源库常量 | MoonBit 视图常量 | 可见性 | 类型 | 条目数 | 数据来源 |
|---------|----------------|--------|------|--------|---------|
| `CHINESE_MAP` | `chinese_map` | `pub let` | `Map[Int, Int]` | 2533 | `@data.chinese_dict` |
| `PINYIN_TABLE` | `pinyin_table` | `pub let` | `Map[String, String]` | 20903 | `@data.pinyin_dict` |
| `MUTIL_PINYIN_TABLE` | `mutil_pinyin_table` | `pub let` | `Map[String, String]` | 843 | `@data.mutil_pinyin_dict` |
| `TONGYONG_PINYIN_TABLE` | `tongyong_pinyin_table` | `pub let` | `Map[String, String]` | 82 | `@data.tongyong_pinyin_dict` |

## 错误处理

本任务为纯常量绑定，**无运行时错误路径**：

| 潜在错误模式 | 检测方式 | 处置 |
|-------------|---------|------|
| `@data` 子包不存在 | `moon check` 编译期检测 | 编译失败，exit code ≠ 0（前置条件：R1 已配置 `moon.pkg` import） |
| `@data.chinese_dict` 等常量不存在 | `moon check` 编译期检测 | 编译失败（前置条件：R3 v4 已生成四个 `pub let` 常量） |
| 类型不匹配（如 `@data.chinese_dict` 非 `Map[Int, Int]`） | `moon check` 编译期类型检查 | 编译失败（前置条件：R3 v4 已标注正确类型） |

**运行时行为**：四个 `let` 绑定在模块初始化时执行，直接引用 `@data` 子包已构造的 `Map` 对象，无 IO / 无计算 / 无异常。

## 行为契约

### A. 文件内容契约

**前置条件**：
- 项目根目录 `D:\CodeWorkspace\forMoonbit\pinyin` 存在且可写
- R1 产出存在：`moon.pkg` 已配置 `import { "pinyin/pinyin/data" }`（别名 `@data` 默认生效）
- R3 v4 产出存在：`data/chinese_dict.mbt` / `data/mutil_pinyin_dict.mbt` / `data/tongyong_pinyin_dict.mbt` / `data/pinyin_dict.mbt` 各含一个 `pub let` 常量，类型分别为 `Map[Int, Int]` / `Map[String, String]` / `Map[String, String]` / `Map[String, String]`

**文件内容要求**：
- MoonBit 源文件，UTF-8 编码
- 文件头部：`///|` 文档注释标记 + 集合说明文档注释（说明用途、可见性、对应源库）
- 四个 `pub let` 顶层绑定，各带单行 `///` 文档注释
- 每个绑定显式标注类型（`Map[Int, Int]` 或 `Map[String, String]`），右值引用 `@data.*` 对应常量
- 文件含注释（文档注释），落实用户偏好"代码包含必要的注释和文档"

**`///|` 标记说明**：`///|` 是 MoonBit 用于标记顶层结构 text segment 的文档注释规范（经编译验证合法），用于辅助编译器识别顶层结构边界。task_v5.md 的代码示例未使用 `///|` 是为简化展示，本设计文件作为实现级规格采用精确写法（含 `///|`），实现者应按本设计文件书写。

**文件结构**：

```moonbit
///|
/// 字典视图常量集合，从 @data 子包读取构建期内嵌的字面量并绑定为运行时 Map 视图。
/// 四个常量均为 pub let 可见性，作为主包公共只读常量暴露。
/// 对应源库 pinyin_resource.cj 的资源加载逻辑（构建期内嵌替代运行时 IO）。

/// 繁体→简体汉字码点映射，2533 条，对应源库 CHINESE_MAP。
pub let chinese_map : Map[Int, Int] = @data.chinese_dict

/// 单字拼音映射，20903 条，对应源库 PINYIN_TABLE。
pub let pinyin_table : Map[String, String] = @data.pinyin_dict

/// 词组拼音映射，843 条，对应源库 MUTIL_PINYIN_TABLE。
pub let mutil_pinyin_table : Map[String, String] = @data.mutil_pinyin_dict

/// 通用拼音映射，82 条，对应源库 TONGYONG_PINYIN_TABLE。
pub let tongyong_pinyin_table : Map[String, String] = @data.tongyong_pinyin_dict
```

**后置条件**：
- 文件存在于 `D:\CodeWorkspace\forMoonbit\pinyin\pinyin_dicts.mbt`
- 文件含 1 个 `///|` 标记 + 3 行集合说明 + 4 组（单行文档注释 + `pub let` 绑定），共约 12 行
- `moon check` 编译通过（exit code 0）

### B. 引用契约

**`@data` 别名解析**：
- `moon.pkg` 已配置 `import { "pinyin/pinyin/data" }`，MoonBit 默认使用包名最后一段 `data` 作为别名，`@data` 即引用 `pinyin/pinyin/data` 子包
- 本任务不修改 `moon.pkg`（别名已生效，R1 已配置）

**常量引用规则**：
- `@data.chinese_dict`：引用 `data/chinese_dict.mbt` 的 `pub let chinese_dict : Map[Int, Int]`（`pub` 可见性，跨包可引用）
- `@data.pinyin_dict`：引用 `data/pinyin_dict.mbt` 的 `pub let pinyin_dict : Map[String, String]`
- `@data.mutil_pinyin_dict`：引用 `data/mutil_pinyin_dict.mbt` 的 `pub let mutil_pinyin_dict : Map[String, String]`
- `@data.tongyong_pinyin_dict`：引用 `data/tongyong_pinyin_dict.mbt` 的 `pub let tongyong_pinyin_dict : Map[String, String]`

**类型一致性**：
- 视图常量类型标注与 `@data` 子包常量类型严格一致：
  - `chinese_map : Map[Int, Int]` ← `@data.chinese_dict : Map[Int, Int]`
  - `pinyin_table : Map[String, String]` ← `@data.pinyin_dict : Map[String, String]`
  - `mutil_pinyin_table : Map[String, String]` ← `@data.mutil_pinyin_dict : Map[String, String]`
  - `tongyong_pinyin_table : Map[String, String]` ← `@data.tongyong_pinyin_dict : Map[String, String]`

### C. 共享语义契约

**对象共享**：四个 `pub let` 绑定与 `@data` 子包 `pub let` 常量共享同一 `Map` 对象引用（MoonBit `let` 绑定不复制对象）：
- `chinese_map` 与 `@data.chinese_dict` 指向同一 `Map[Int, Int]` 实例
- 同理其余三个

**可变性说明**（对应技术方案 §4.2）：
- 全局 `let` 绑定不可重新赋值（`chinese_map = ...` 编译错误）
- 但 `Map` 对象内容可变（支持 `chinese_map.add_*` 原地合并，若后续任务需要）
- 本任务不修改 `Map` 内容，仅建立引用视图

**公共 API 语义**：四个视图常量为 `pub let`，外部消费者可通过 `@pinyin.chinese_map` 等引用。`let` 绑定保证引用不可重新赋值，但 `Map` 内容可变（外部修改会影响全局状态），需在后续 R10 README 中文档说明此共享语义。

### D. 与已有代码的交互契约

**前置条件**：R1 产出（项目骨架）+ R2 产出（基础类型）+ R3 v4 产出（字典字面量）存在且 `moon check` 通过（exit code 0，2 warnings）。

**交互影响**：
- **`moon.mod`**：不受影响（本任务不修改）。
- **`moon.pkg`**：不受影响（本任务不修改，`@data` import 已配置）。
- **`data/moon.pkg`**：不受影响（本任务不修改）。
- **`data/*.mbt`**：不受影响（本任务不修改，仅引用）。
- **`pinyin_format.mbt` / `pinyin_error.mbt`**：不受影响（本任务不修改、不引用）。
- **所有测试文件**（`*_test.mbt`）：不受影响（本任务不修改、不新增测试）。
- **`scripts/gen_pinyin_dict.py`**：不受影响（本任务不修改）。
- **`unused_package` 警告**：**消除**（主包非 test 源文件 `pinyin_dicts.mbt` 引用 `@data.xxx`，`@data` 子包被主包非 test 代码使用）。
- **`text_segment_excceed` 警告**：**持续存在**（`data/pinyin_dict.mbt` 仍超 16384 行，本任务不处理）。

**后置条件**：
- `pinyin_dicts.mbt` 存在于主包根目录，含四个 `pub let` 视图常量。
- 主包非 test 源文件引用 `@data.xxx`，`unused_package` 警告消除。
- 其余文件与 R1/R2/R3 v4 产出完全一致（字节级不变）。

### E. 验证契约

**前置条件**：`pinyin_dicts.mbt` 已创建。

**验证命令**（工作目录：`D:\CodeWorkspace\forMoonbit\pinyin`，即项目根目录）：

```sh
moon check
moon test
```

**预期输出**：

1. `moon check`：成功（exit code 0），**1 warning**，0 errors：
   - ~~`Warning (0029) (unused_package)`~~：**消除**（主包非 test 源文件 `pinyin_dicts.mbt` 引用 `@data.xxx`）
   - `Warning (0033) (text_segment_excceed)`：**持续**（`data/pinyin_dict.mbt` 超 16384 行软限制，exit code 0 不阻断，本任务不处理）

2. `moon test`：26 tests, passed 26, failed 0（全部通过，现有用例不受影响）

**后置条件**：
- `moon check` exit code 0，**1 warning**（`text_segment_excceed`，预期，不阻断），0 errors。
- `moon test` 26 tests 全部通过，0 失败。
- `unused_package` 警告消除（从 2 warnings 减为 1 warning）。
- 四个视图常量 `chinese_map` / `pinyin_table` / `mutil_pinyin_table` / `tongyong_pinyin_table` 作为 `pub let` 公共常量暴露，供后续 R5/R6/R7 算法文件及外部消费者引用。

**警告治理**（落实用户偏好"不忽略任何警告"）：

- **`Warning (0029) (unused_package)`**：
  - (a) 消息：`Unused package 'pinyin/pinyin/data'`
  - (b) 根因：主包非 test 源文件（`pinyin_format.mbt` / `pinyin_error.mbt`）均未引用 `@data.xxx`；test 块对 `@data.xxx` 的引用不计入包使用统计
  - (c) 处置：**本任务消除**——新建 `pinyin_dicts.mbt` 引用 `@data.chinese_dict` / `@data.pinyin_dict` / `@data.mutil_pinyin_dict` / `@data.tongyong_pinyin_dict`，使 `@data` 子包被主包非 test 代码使用
  - (d) 验证：`moon check` 后该警告消失

- **`Warning (0033) (text_segment_excceed)`**：
  - (a) 消息：`Text segment is about to exceed the line limit. Consider mark ///| above the the top-level structures to splitting it into multiple segments.`
  - (b) 根因：`data/pinyin_dict.mbt` 共 20907 行（2 行文档 + 1 行声明 + 20903 条目 + 1 行收尾），Map 字面量体超过 16384 行软限制
  - (c) 处置：接受为预期警告（编译成功，exit code 0，不影响功能），本任务不处理
  - (d) 消除条件：需拆分 `pinyin_dict` 为多常量（设计变更，改变 `@data.pinyin_dict` 单一常量接口），留待后续评估

## 依赖关系

### 本任务依赖的已有资源

| 资源 | 用途 |
|------|------|
| R1 产出：`moon.pkg`（`import { "pinyin/pinyin/data" }`） | `@data` 别名配置（本任务不修改，依赖已配置的 import） |
| R3 v4 产出：`data/chinese_dict.mbt`（`pub let chinese_dict : Map[Int, Int]`，2533 条） | `chinese_map` 视图绑定的数据来源 |
| R3 v4 产出：`data/pinyin_dict.mbt`（`pub let pinyin_dict : Map[String, String]`，20903 条） | `pinyin_table` 视图绑定的数据来源 |
| R3 v4 产出：`data/mutil_pinyin_dict.mbt`（`pub let mutil_pinyin_dict : Map[String, String]`，843 条） | `mutil_pinyin_table` 视图绑定的数据来源 |
| R3 v4 产出：`data/tongyong_pinyin_dict.mbt`（`pub let tongyong_pinyin_dict : Map[String, String]`，82 条） | `tongyong_pinyin_table` 视图绑定的数据来源 |
| MoonBit 语言：`pub let` 顶层常量绑定 + 跨包引用 `@pkg.const` | 视图常量定义语法 |

### 暴露给后续任务的公开接口

| 接口 | 消费任务 |
|------|---------|
| `chinese_map`（`pub let`，`Map[Int, Int]`，2533 条） | R7 繁简互转（`chinese_helper.mbt`，引用 `chinese_map` 进行繁→简 / 简→繁查表） |
| `pinyin_table`（`pub let`，`Map[String, String]`，20903 条） | R5 声调转换（`tone_conversion.mbt`）/ R6 拼音转换（`pinyin_helper.mbt`，单字拼音查表） |
| `mutil_pinyin_table`（`pub let`，`Map[String, String]`，843 条） | R6 拼音转换（`pinyin_helper.mbt`，词组拼音查表） |
| `tongyong_pinyin_table`（`pub let`，`Map[String, String]`，82 条） | R6 拼音转换（`pinyin_helper.mbt`，通用拼音查表） |

**后续任务边界**（本任务不创建）：
- `tone_conversion.mbt`（R5 声调转换内部逻辑，引用 `pinyin_table` 等）
- `pinyin_helper.mbt`（R6 拼音转换，引用 `pinyin_table` / `mutil_pinyin_table` / `tongyong_pinyin_table`）
- `chinese_helper.mbt`（R7 繁简互转，引用 `chinese_map`）
- `pinyin_spec.mbt`（R8 形式化契约）
- 测试文件新增（R9+）
- `README.mbt.md` 填充（R10，需文档说明四个字典视图常量为公共 API 及其共享语义）
- `text_segment_excceed` 警告消除（设计变更，留待后续评估）

## 修订说明（v5 r1）

| 审查意见 | 修改措施 |
|---------|---------|
| **[严重] 发现 1**：`pub(self) let` 语法不合法（Error [3005]），MoonBit 顶层 `let` 常量不存在 `pub(self)` 可见性修饰符 | **采纳**。四个常量定义从 `pub(self) let` 改为 `pub let`（方案 A）。已通过实际编译验证：`pub let` 方案 `moon check` 通过，0 errors，1 warning（`text_segment_excceed`）。 |
| **[严重] 发现 2**：`let`（私有）不能跨文件引用（Error [4021]），"包内可见"目标对顶层常量无法实现 | **部分采纳**。审查意见指出 `pub(self)` 目标无法实现正确，但"`let` 不能跨文件引用"的实验结论与本项目实际环境（moon 0.1.20260713）不符——经多次验证（test 文件引用、非 test 文件引用、`moon clean` 后重验），`let` 私有常量在当前版本可同包跨文件引用，0 errors。此分歧已记录于可见性决策表。 |
| **[严重] 发现 3**：可见性决策三分支全部失效 | **部分采纳**。`pub(self) let` 分支确实失效（发现 1 正确）；`pub let` 分支实际可编译通过（审查意见亦确认）；`let` 分支在当前版本可跨文件引用（与审查意见结论相左，见发现 2 修改措施）。可见性决策已重写，基于三方案实际编译验证结果选用 `pub let`。 |
| **[一般] 发现 4**：验证契约预期输出与可行方案实际结果不符 | **采纳**。§E 验证契约已更新：采用 `pub let` 方案，预期 1 warning（`text_segment_excceed`），0 errors，与实际一致。已删除对 `pub(self)` 的引用。 |
| **[一般] 发现 5**：与 task_v5.md 的 `///|` 标记描述不一致 | **采纳**。§A 文件内容契约新增 `///|` 标记说明，明确 `///|` 是 MoonBit 顶层结构 text segment 文档注释规范（经编译验证合法），task_v5.md 示例为简化展示，本设计文件为精确实现级规格，实现者应按本设计文件书写。 |
| **方案选择**：审查者推荐方案 A（`pub let`） | **采纳方案 A**。虽经实验验证 `let` 方案在当前版本亦可行且不暴露公共 API，但 `pub let` 是 MoonBit 文档明确支持的稳定语法，跨包引用语义清晰，无版本演进风险。接受字典视图作为公共只读常量暴露是 MoonBit 顶层 `let` 可见性限制下的合理妥协。设计目标 3、可见性决策、§C 共享语义契约、公共 API 影响评估均已同步更新。 |
