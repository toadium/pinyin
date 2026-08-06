# pinyin4cj → MoonBit 移植架构级 OOD 设计

> 输入：`requirements/202608062224_pinyin-port-to-moonbit/req_v1.md` + `deliberations/202608062236_review-req-v1/output_v1.md`
> 源库：`D:\CodeWorkspace\forCangjie\pinyin4cj` v1.0.5（Cangjie，纯计算型拼音库，9 源文件 + 1 外部字典）
> 目标：MoonBit 单模块，跨 wasm/js/native 三后端，语义对等移植

---

## 一、概述

### 1.1 设计目标

将 Cangjie 拼音库 `pinyin4cj` 完整移植为 MoonBit 库 `pinyin`，硬约束为**语义对等**（同输入同输出，含异常消息文本），软约束为**跨三后端可移植**与**MoonBit 惯例对齐**。

### 1.2 整体架构思路

源库本质是**纯函数计算 + 静态字典查表**模型：四张字典（繁简映射、词组拼音、通用拼音、单字拼音）启动时驻留内存，所有公开 API 都是给定输入查表 + 格式化输出。移植保留这一模型，仅替换三处与 MoonBit 生态冲突的机制：

1. **资源加载机制**：源库单字拼音表通过环境变量 + 文件系统运行时加载 → 改为构建期内嵌为 MoonBit 字面量，运行时直接构造为 `Map`。
2. **错误模型**：源库 `throw Pinyin4cjException` → 改为 MoonBit 检查式错误 `raise PinyinError`。
3. **API 组织**：源库 `class + static method` → 改为 MoonBit 类型关联方法（保留 `PinyinHelper::*` / `ChineseHelper::*` 命名空间）。

核心抽象为三类：**格式策略**（`PinyinFormat` 枚举）、**字典视图**（四张 `Map` 常量）、**转换器**（`PinyinHelper` / `ChineseHelper` 两个无状态命名空间类型）。无并发设计、无 FFI、无 IO。

### 1.3 核心抽象一览

| 抽象 | 类型形态 | 职责 |
|------|---------|------|
| `PinyinFormat` | `enum`（4 变体） | 输出格式策略 |
| `PinyinError` | `suberror` | 错误类型 |
| `PinyinHelper` | 空 `struct`（命名空间） | 拼音转换器 |
| `ChineseHelper` | 空 `struct`（命名空间） | 繁简互转器 |
| `PinyinDicts` | 全局 `let` 常量集合（不公开） | 字典视图聚合 |

---

## 二、模块划分

### 2.1 MoonBit 模块结构

单模块 `pinyin`（`moon.mod`），下挂两个包：主包 `pinyin`（根包）与数据子包 `pinyin/data`。

```
pinyin/                              # 模块根（moon.mod）
├── moon.mod                         # 模块元数据
├── moon.pkg                         # 主包配置
├── README.mbt.md                    # 含 10 个 mbt check 示例（对齐源库 README 10 例）
├── pinyin_spec.mbt                  # 形式化契约（declare 关键字声明）
├── pinyin_helper.mbt                # PinyinHelper 关联方法
├── chinese_helper.mbt               # ChineseHelper 关联方法
├── pinyin_format.mbt                # PinyinFormat 枚举 + name 方法
├── pinyin_error.mbt                 # PinyinError suberror 定义
├── pinyin_dicts.mbt                 # PinyinDicts 聚合 + 全局字典视图
├── pinyin_resource.mbt              # 字典加载/解析（从 @data 读取并构造 Map）
├── tone_conversion.mbt              # 声调格式转换内部逻辑（convert_with_tone_number 等）
├── pinyin_easy_test.mbt             # 黑盒测试 - 简单用例
├── pinyin_mid_test.mbt              # 黑盒测试 - 中等用例
├── pinyin_difficult_test.mbt        # 黑盒测试 - 困难用例（长句、通用拼音、issue 回归）
├── pinyin_snapshot_test.mbt         # snapshot 测试（10 个 README 示例输出对等）
└── data/                            # 字典数据子包
    ├── moon.pkg                     # 子包配置
    ├── chinese_dict.mbt             # 繁→简字典字面量（约 2556 行，脚本生成）
    ├── mutil_pinyin_dict.mbt        # 词组拼音字典字面量（约 858 行，脚本生成）
    ├── tongyong_pinyin_dict.mbt     # 通用拼音字典字面量（约 92 行，可手写或生成）
    └── pinyin_dict.mbt              # 单字拼音字典字面量（约 41806 行，脚本生成）
```

### 2.2 包边界与职责

| 包 | 职责 | 内容性质 |
|----|------|---------|
| `pinyin`（根包） | 公开 API + 转换逻辑 + 字典视图构造 + 测试 | 手写逻辑 + spec 契约 + 测试 |
| `pinyin/data` | 四张字典的字面量定义 | 纯数据，脚本生成，无逻辑 |

### 2.3 依赖方向

```
pinyin (根包) ──imports──> pinyin/data
pinyin/*_test.mbt ──black-box──> pinyin (自身)
```

- 主包单向依赖数据子包，数据子包不依赖任何包（仅 `moonbitlang/core`）。
- 测试文件为黑盒测试，自动引用所在包，无额外 import。
- **不引入** `moonbit-c-binding` / `make-moonbit-c-bindings` / `moonbit-proof`（源库无 C 依赖，非形式化验证场景）。

### 2.4 拆分数据子包的理由

1. **隔离生成代码**：四张字典合计约 45 KB 源码 + 244 KB 内嵌字典 = 约 330 KB，脚本生成，与手写逻辑边界清晰。
2. **版本控制聚焦**：字典数据的 diff 独立于逻辑 diff，review 时可单独忽略。
3. **生成脚本目标明确**：脚本输出目录固定为 `data/`，不污染主包。
4. **不影响调用点简洁性**：主包通过 `@data.chinese_dict` 等别名引用，开销与同包常量无异。

---

## 三、核心抽象

### 3.1 `PinyinFormat`（输出格式策略）

- **类型形态**：`pub(all) enum`，4 个变体 `WithToneMark` / `WithoutTone` / `WithToneNumber` / `FirstLetter`。
- **职责**：表示四种拼音输出格式，作为转换器的策略参数。
- **协作**：被 `PinyinHelper` 的多个方法接受为参数，驱动 `format_pinyin` 内部分支选择。
- **为何 `enum` 而非 `sealed class`**：4 个变体无附加数据，纯标签枚举，`enum` 是 MoonBit 表达固定封闭集合的惯用形态；`sealed class` 适合变体携带异构数据时，此处无此需求。
- **方法**：`fn name(self) -> String` 返回变体名（对齐源库 `getName()`，按 MoonBit 惯例改为方法 `name`，snake_case）。

### 3.2 `PinyinError`（错误类型）

- **类型形态**：`pub(all) suberror`，单变体 `PinyinError(String)`（携带消息）。
- **职责**：承载两个异常场景的错误消息，作为 `raise` 的载体。
- **协作**：被 `PinyinHelper::convert_to_pinyin_string`（空串输入）与 `PinyinHelper::has_multi_pinyin`（非汉字输入）`raise`；被调用方 `catch` 模式匹配。
- **为何 `suberror` 而非 `Exception` 子类**：MoonBit 用 `suberror` 声明检查式错误类型，配合 `raise`/`catch`，是 MoonBit 错误处理的惯用形态；源库的 `Exception` 子类是 Cangjie 的 OOP 异常模型，移植时按目标语言惯例转换。
- **命名决策**：采用 `PinyinError`（MoonBit 惯例 `XxxError`）而非 `Pinyin4cjException`。理由：移植版包名已是 `pinyin`，保留 `4cj` 后缀无溯源价值（溯源通过 README 与 CHANGELOG 说明），且 `Error` 后缀符合 MoonBit 生态。

### 3.3 `PinyinHelper`（拼音转换器命名空间）

- **类型形态**：`pub struct PinyinHelper`（空结构体，仅作方法命名空间）。
- **职责**：承载全部拼音转换公开 API 的类型关联方法。无实例状态，所有方法相当于源库的 `static`。
- **协作**：
  - 依赖 `ChineseHelper`（`isChinese`、`convertToSimplifiedChinese`）做汉字判定与繁简预处理。
  - 依赖 `PinyinDicts`（内部）查 `PINYIN_TABLE` / `MUTIL_PINYIN_TABLE` / `TONGYONG_PINYIN_TABLE`。
  - 依赖 `PinyinFormat` 驱动格式分支。
  - `raise PinyinError` 在两个边界场景。
- **为何空 `struct` + 关联方法而非顶层函数**：
  1. 保留源库 `PinyinHelper.*` 命名空间组织，调用点 `PinyinHelper::convert_to_pinyin_string(...)` 与源库 `PinyinHelper.convertToPinyinString(...)` 视觉对齐，降低移植 review 成本。
  2. 避免顶层函数名冲突（如 `convert_to_pinyin_string` 在不同上下文可能歧义）。
  3. MoonBit 类型关联方法无需实例化即可 `Type::method()` 调用，与 `static` 语义等价。
- **公开方法语义**（仅列职责，签名留待详细设计）：
  - `convert_to_pinyin_string`（2 重载，含默认 `WithToneMark`）：词句转拼音，词组优先匹配（最多 5 字前缀），非汉字穿插，空串 `raise PinyinError`。
  - `convert_to_pinyin_string_traditional`：先繁→简再转拼音。
  - `convert_to_pinyin_array`：单字所有读音数组，非汉字返回 `[]`。
  - `get_short_pinyin`：首字母格式，分隔符为空串。
  - `has_multi_pinyin`：是否多音字，非汉字 `raise PinyinError`。
  - `add_pinyin_dict_resource` / `add_mutil_pinyin_dict_resource`：追加自定义拼音/词组字典。
  - `to_tongyong_pinyin_string_array`：数字音标通用拼音，非汉字返回 `[]`。

### 3.4 `ChineseHelper`（繁简互转器命名空间）

- **类型形态**：`pub struct ChineseHelper`（空结构体，命名空间）。
- **职责**：繁简互转 + 汉字判定。无实例状态。
- **协作**：
  - 依赖 `PinyinDicts` 查 `CHINESE_MAP`（繁→简映射）与 `PINYIN_TABLE`（`isChinese` 判定）。
  - 被 `PinyinHelper` 依赖做繁简预处理与汉字判定。
- **为何空 `struct` + 关联方法**：同 `PinyinHelper`，保留命名空间组织。
- **公开方法语义**：
  - `convert_to_simplified_chinese`：繁→简，非汉字原样，空串返回空串。
  - `convert_to_traditional_chinese`：简→繁，**保留源库 O(n) 反查语义**（遍历 `CHINESE_MAP` 找值为输入字符的键），不主动优化为反向索引（需求 3.8 明确"不改变对外语义"，且源库此实现有歧义多映射行为，优化可能改变多映射场景的输出）。**性能特征**：n 为 `CHINESE_MAP` 大小（约 2556 条目），单字符反查为 O(n)；对长度为 L 的文本，整体复杂度为 O(L × n) = O(L × 2556)。大文本场景（L ≫ 1000）性能弱于正向查询，但与源库完全对等，下游实现不得改变此复杂度特征。
  - `is_traditional_chinese`：单字是否在 `CHINESE_MAP` 键集。
  - `is_chinese`：单字是否在 `PINYIN_TABLE`。
  - `contains_chinese`：字符串是否含汉字。
  - `add_chinese_dict_resource`：追加自定义繁简映射。

### 3.5 `PinyinDicts`（字典视图聚合，内部）

- **类型形态**：**倾向采用全局 `let` 常量集合**，不引入 `struct` 包装。四张字典各自以 `let` 绑定于 `pinyin_dicts.mbt` 顶层，通过 `pub(self)` 可见性仅包内可访问。
- **职责**：聚合四张字典的运行时视图，提供统一查询入口。
- **协作**：被 `PinyinHelper` / `ChineseHelper` 查询；从 `@data` 子包读取字面量并构造为 `Map`。
- **数据结构选型**：
  - `CHINESE_MAP`：`Map[Int, Int]`（码点 → 码点，对应源库 `HashMap<Rune, Rune>`，MoonBit `Char` 即 Unicode 码点）。
  - `PINYIN_TABLE` / `MUTIL_PINYIN_TABLE` / `TONGYONG_PINYIN_TABLE`：`Map[String, String]`。
  - **MoonBit `Map` 的可变性特征**：MoonBit 标准库 `Map` 是**可变的、保持插入顺序的**映射（`moonbit-agent-guide` SKILL.md:1064 "Map (Mutable, Insertion-Order Preserving)"，支持 `map["key"] = value` 原地修改）。全局 `let` 绑定本身不可重新赋值（不能 `map = new_map`），但 `Map` 对象内容可变（可 `map["key"] = value`）。此特性与源库 Cangjie `HashMap` 的可变语义对齐，使 `add_*_dict_resource` 可直接调用 `Map` 的可变操作原地合并，无需 `Ref[Map]` 包装（详见 §6.2）。
  - **为何 `Map` 而非 `HashMap`**：MoonBit 标准库无 `HashMap` 类型名，`Map` 即惯用映射（兼具查询语义与可变性）；源库 `HashMap` 是 Cangjie 命名，移植按目标语言惯例。
  - **为何不引入 `@hashmap.T` 第三方包**：标准库 `Map` 已覆盖需求，零外部依赖原则。
- **可变字典支持**：源库 `add_pinyin_dict_resource` 等通过 `HashMap.add(all:)` 原地合并。移植版利用 MoonBit `Map` 的可变性，直接在全局 `let` 绑定的 `Map` 上调用可变合并操作（见 §6.2）。

---

## 四、关键行为契约

### 4.1 词句转拼音主流程（`convert_to_pinyin_string`）

输入字符串 → 转 `Array[Char]` → 空则 `raise PinyinError("Please enter a word or sentence")` → 否则从左到右扫描：
1. 取剩余字符的 1..min(剩余长度+1, 6) 字前缀，查 `MUTIL_PINYIN_TABLE`，命中则按词组输出（最长前缀优先，对应源库 `getWords` 从短到长返回首个命中——实际源库返回 `[str]` 单元素，即首个命中前缀）。
2. 未命中词组则取单字：若 `is_chinese(c)` 或 `c == '〇'`（U+3007）则查 `PINYIN_TABLE` 取首音；否则原样穿插，并根据下一字符是否汉字决定是否追加分隔符。
3. 按 `PinyinFormat` 格式化每个音节（带调 / 无调 / 数字调 / 首字母）。
4. 末尾多余分隔符裁剪后返回。

**契约要点**：词组优先于单字；非汉字穿插保留原字符；分隔符仅在两汉字间或汉字与非汉字间插入（边界规则对齐源库 `convertToPinyinString` 第 157-203 行）。

### 4.2 声调格式转换（内部 `tone_conversion`）

- **带调 → 数字调**（`convert_with_tone_number`）：扫描音节字符，遇 24 个带调元音之一则替换为对应无调元音 + 声调数字（1-4），未遇带调元音则追加 `5`（轻声）。
- **带调 → 无调**（`convert_without_tone`）：24 个带调元音逐字符替换为对应无调元音，`ü` 替换为 `v`。
- **首字母**：无调转换后取首字符。
- **契约要点**：24 带调元音与 6 无调元音的算术映射（`index % 4 + 1` 得声调，`(index - index%4) / 4` 得无调元音索引）必须逐字符对齐源库。

### 4.3 繁简互转（`ChineseHelper`）

- **繁→简**：逐字符查 `CHINESE_MAP`，命中替换，未命中原样。
- **简→繁**：逐字符遍历 `CHINESE_MAP` 找值为该字符的键，命中替换为键，未命中原样。**保留 O(n) 反查语义**（需求 3.8）。
- **契约要点**：`CHINESE_MAP` 是繁→简单向映射，简→繁的反查在多映射（多个繁体对应同一简体）时返回首个命中键，此行为与源库一致，移植不得改变。

### 4.4 通用拼音（`to_tongyong_pinyin_string_array`）

输入单字 → `convert_to_pinyin_array` 得数字音标数组 → 对每个音节拆为"拼音部分 + 末尾数字" → 查 `TONGYONG_PINYIN_TABLE` 替换拼音部分 → 拼回数字。非汉字返回 `[]`。

### 4.5 自定义字典追加（`add_*_dict_resource`）

三个 `add_*` 方法接受用户字典，合并入全局字典视图。**契约要点**：合并后立即生效于后续转换调用；语义对齐源库 `HashMap.add(all:)`（键冲突时新值覆盖）。

---

## 五、错误处理策略

### 5.1 整体策略

| 场景 | 源库 | 移植版 | 理由 |
|------|------|--------|------|
| 空串输入 `convert_to_pinyin_string` | `throw Pinyin4cjException("Please enter a word or sentence")` | `raise PinyinError("Please enter a word or sentence")` | MoonBit 检查式错误惯例 |
| 非汉字输入 `has_multi_pinyin` | `throw Pinyin4cjException("Please enter a Chinese character")` | `raise PinyinError("Please enter a Chinese character")` | 同上 |
| 非汉字输入 `convert_to_pinyin_array` / `to_tongyong_pinyin_string_array` | 返回 `[]` | 返回 `[]` | 正常边界，非错误 |
| 字典查询未命中 | `NoneValueException` 或 `Option` 处理 | `Map::get` 返回 `Option`，用 `if let Some(v) = ...` 模式 | MoonBit `Option` 惯例 |
| 单字拼音字典加载失败 | `throw Pinyin4cjException("...")` | 不存在（构建期内嵌，加载期失败即编译失败） | 资源策略变更 |

### 5.2 `raise` vs `Result[T, PinyinError]` 的选择

**选择 `raise PinyinError`**，理由：
1. 符合 MoonBit 检查式错误惯例（`suberror` + `raise`/`catch`）。
2. 源库用 `throw`，移植为 `raise` 语义对等，调用方需显式 `catch` 或声明 `raise` 传播。
3. `Result` 会在每个调用点强制模式匹配，对拼音转换这种"正常路径占绝大多数"的 API 噪声过大。
4. 需求 3.5 将此决策留给下游，此处明确选 `raise`。

### 5.3 错误消息文本对等

两个 `raise` 点的消息文本逐字符对齐源库（已由审查报告验证）：
- `"Please enter a word or sentence"`（源库 `pinyin_helper.cj:153`）
- `"Please enter a Chinese character"`（源库 `pinyin_helper.cj:253`）

---

## 六、并发设计

### 6.1 线程模型

源库为纯计算 + 静态字典，天然线程安全；唯一可变全局状态是三个 `add_*_dict_resource` 修改的字典。移植版保留此模型：

- **四张基础字典**：构建期内嵌为字面量，运行时构造为 `Map`，全局 `let` 常量。MoonBit `Map` 虽可变，但基础字典在初始化后不被修改（仅 `add_*` 方法修改），只读访问无需同步。
- **自定义字典追加**：直接利用 MoonBit `Map` 的可变性，在全局 `let` 绑定的 `Map` 上原地合并。无需 `Ref[Map]` 包装（`Map` 本身可变），无需 `Mutex`（见 §6.2）。

### 6.2 自定义字典的并发安全策略

源库 `HashMap.add(all:)` 非线程安全，源库 `Reliability/` 压测也未验证并发追加。移植版设计：

- **采用方案**：全局 `let map : Map[...] = { ... }`，`add_*` 方法直接调用 `Map` 的可变操作（如遍历入参字典逐条 `map[k] = v`，或调用等价的批量合并方法）原地合并。
- **可行性依据**：MoonBit 标准库 `Map` 是可变映射（SKILL.md:1064, 1077-1078 演示 `map["new-key"] = 3` 可变操作）。全局 `let` 绑定不可重新赋值（不能 `map = new_map`），但 `Map` 对象内容可变（可 `map["key"] = value`），因此无需 `Ref[Map]` 包装即可实现原地合并语义。
- **与源库语义对齐**：此方案直接对应源库 `HashMap.add(all:)` 的原地合并语义，单线程下行为完全一致。
- **不引入 `Mutex`**：避免引入 `moonbitlang/async` 或 `sync` 依赖，保持纯计算库的零依赖特性；并发追加自定义字典是罕见场景，需求未要求线程安全保证。
- **多线程语义保留**：多线程下源库 `HashMap` 本身无保证（并发读可能看到部分更新），移植版 `Map` 同样无保证，不主动提供更强保证。这与源库语义对齐，不构成语义退化。

### 6.3 不移植 `Reliability/` 压测

需求 3.7 明确不原样移植 200 线程压测。可选实现等价吞吐基准测试（native 后端，`moon run --profile`），但非交付物强制项。

---

## 七、关键设计决策

### 7.1 目标后端：wasm / js / native 三后端

- **决策**：不限制 `supported-targets`，默认支持三后端。
- **理由**：源库纯计算无 FFI，移植版零外部依赖（仅 `moonbitlang/core`），天然跨后端。
- **约束**：不使用任何 native-only API（如 `@fs`、`@async`）；字符串与字符处理用 MoonBit 标准 `String` / `Char`（UTF-16 存储，`Char` 为 Unicode 码点），拼音字典均在 BMP 内，无代理对问题。

### 7.2 FFI 策略：无 FFI

- **决策**：不引入任何 `extern "c"` 或 native FFI。
- **理由**：源库无 C 依赖（审查报告验证无 `extern` 声明），`moonbit-c-binding` / `make-moonbit-c-bindings` skill 不适用。
- **skill 排除**：明确不使用上述两个 skill，避免误引入 FFI 复杂度。

### 7.3 单字拼音字典内嵌策略

- **决策**：构建期通过脚本将 `pinyin.dict.txt`（41806 行 / 20903 组）转写为 `data/pinyin_dict.mbt` 中的 `Map[String, String]` 字面量。
- **技术手段**：构建脚本（Python 或 MoonBit 脚本）读取 `pinyin.dict.txt`，每两行一组生成 `"汉字" => "拼音,拼音,..."` 字面量条目，输出为合法 `.mbt` 文件。
- **为何不用 `@embed` / `#embed`**：MoonBit 当前无稳定的二进制内嵌原语；字面量转写最稳妥，跨三后端一致，且 `moon check` 可静态验证字典完整性。
- **为何不用运行时解析字符串**：运行时解析 244 KB 字符串增加启动延迟与 GC 压力；字面量在编译期即被编译器优化为高效结构。
- **约束**：脚本生成产物入版本控制（便于 `moon check` 离线验证）；脚本本身亦入版本控制（`scripts/gen_pinyin_dict.py` 或类似）。

### 7.4 三张内嵌字典的转写

- **决策**：`chinese.dict.cj` / `mutil_pinyin.dict.cj` / `tongyong_pinyin_dict.cj` 同样脚本化转写为 `data/*.mbt` 字面量。
- **`chinese_dict`**：`HashMap<Rune, Rune>` → `Map[Int, Int]`（`Char.to_int()` 得码点）。保留 `r'臺'` → `Char::from_int(0x81FA)` 或直接 `'臺'` 字面量（MoonBit `Char` 字面量支持 Unicode）。
- **`mutil_pinyin_dict` / `tongyong_pinyin_dict`**：`HashMap<String, String>` → `Map[String, String]`，键值直接转写。

### 7.5 API 风格：类型关联方法 + snake_case

- **决策**：保留 `PinyinHelper` / `ChineseHelper` 命名空间，方法用 `Type::snake_case_method` 形式。
- **命名映射**（对齐需求 3.2）：
  - 类型：`PinyinHelper`、`ChineseHelper`、`PinyinFormat`、`PinyinError`（PascalCase）。
  - 枚举变体：`WithToneMark` / `WithoutTone` / `WithToneNumber` / `FirstLetter`（PascalCase）。
  - 方法：`convert_to_pinyin_string`、`convert_to_pinyin_array`、`get_short_pinyin`、`has_multi_pinyin`、`to_tongyong_pinyin_string_array`、`add_pinyin_dict_resource`、`add_mutil_pinyin_dict_resource`、`convert_to_simplified_chinese`、`convert_to_traditional_chinese`、`is_traditional_chinese`、`is_chinese`、`contains_chinese`、`add_chinese_dict_resource`、`name`（snake_case）。
- **调用形式**：`PinyinHelper::convert_to_pinyin_string("我是中国人", " ")`，与源库 `PinyinHelper.convertToPinyinString(...)` 视觉对齐。

### 7.6 字典数据结构选型

- **决策**：`Map[Int, Int]`（繁简）+ `Map[String, String]`（拼音）。
- **MoonBit `Map` 特性说明**：MoonBit 标准库 `Map` 是**可变的、保持插入顺序的**映射（SKILL.md:1064）。此可变性与源库 Cangjie `HashMap` 的可变语义对齐，使 `add_*_dict_resource` 可直接原地合并而无需额外包装。基础字典在初始化后仅只读访问，可变性仅用于 `add_*` 方法。
- **为何不用 `@hashmap.T`**：MoonBit 标准库 `Map` 足够，无需引入第三方 `hashmap` 包；`Map` 字面量构造简洁，查询语义对等。
- **为何不用 `HashMap`**：MoonBit 标准库无 `HashMap` 类型名（`Map` 即惯用映射，兼具查询与可变语义）；源库 `HashMap` 是 Cangjie 命名，移植按目标语言惯例。

### 7.7 `convert_to_traditional_chinese` 不优化

- **决策**：保留源库 O(n) 反查语义，不构建反向索引。
- **理由**：需求 3.8 明确"不主动优化"；源库反查在多映射场景（多繁体对应同一简体）返回首个命中键，构建反向索引会改变此行为，破坏语义对等。
- **性能特征**：单字符反查 O(n)，n ≈ 2556；大文本整体 O(L × n)。与源库完全对等，下游不得改变此复杂度。

### 7.8 模块发布名

- **决策**：模块名为 `pinyin`（`moon.mod` 中 `name = "<author>/pinyin"`，`<author>` 待定，发布到 mooncakes.io 时确定）。
- **约束**：与工作目录 `pinyin` 一致，符合 mooncakes 命名规范。

---

## 八、MoonBit 包结构

### 8.1 `moon.mod`（模块根）

```
name = "<author>/pinyin"
version = "0.1.0"
readme = "README.mbt.md"
license = "Apache-2.0"            # 对齐源库 LICENSE
keywords = ["pinyin", "chinese", "unicode"]
description = "MoonBit port of pinyin4cj: Chinese-to-pinyin conversion"
```

- 无 `import` 依赖（零外部依赖，仅 `moonbitlang/core` 隐式可用）。
- 不设置 `preferred-target`（三后端平等）。
- 不设置 `supported-targets`（不限制可移植性）。

### 8.2 主包 `moon.pkg`（根目录）

```
# 主包配置，无特殊 import（data 子包通过路径引用）
import {
  "<author>/pinyin/data",
}
```

- 不设置 `is-main`（库包）。
- 测试文件 `_test.mbt` 自动引用主包，无需额外 `for "test"` 配置。

### 8.3 数据子包 `data/moon.pkg`

```
# 纯数据包，无 import
```

- 不设置 `is-main`。
- 仅含字典字面量定义，无逻辑，无测试。

### 8.4 `pkg.generated.mbti` 管理

- 主包与数据子包各生成 `pkg.generated.mbti`，入版本控制。
- 数据子包的 `mbti` 仅导出四个字典常量，主包 `mbti` 导出全部公开 API。
- 每次 API 变更后 `moon info` 重新生成，diff 作为公开 API 变更信号。

---

## 九、测试架构

### 9.1 双轨策略：spec 契约 + 黑盒测试

按需求 3.7 与 `moonbit-spec-test-development` skill 规范，采用 spec-driven + 黑盒测试并行。

### 9.2 spec 契约文件 `pinyin_spec.mbt`

- **采用 `declare` 关键字**声明全部公开 API 签名（类型、方法、错误）。
- **`declare` 关键字 vs `#declaration_only` 的取舍**：`moonbit-agent-guide` SKILL.md:358-378 规范采用 `declare` 关键字声明 API 签名，是 MoonBit 当前推荐的 spec 契约声明方式；`#declaration_only` 是 `moonbit-spec-test-development` SKILL.md:21 提到的早期机制。本设计采用 `declare` 关键字，与 `moonbit-agent-guide` 最新规范一致，作为实现与测试的共同基准。
- 作为实现与测试的共同基准，创建后视为只读契约。
- 内容包括：
  - `pub(all) enum PinyinFormat` + 4 变体 + `name` 方法声明。
  - `pub(all) suberror PinyinError` + 变体声明。
  - `pub struct PinyinHelper` + 全部公开关联方法声明（含 `raise PinyinError` 标注）。
  - `pub struct ChineseHelper` + 全部公开关联方法声明。
- 实现在 `pinyin_helper.mbt` / `chinese_helper.mbt` 等文件中提供，spec 文件不包含实现。

### 9.3 黑盒测试文件分级

按 `moonbit-spec-test-development` skill 的 `<pkg>_easy_test.mbt` / `<pkg>_mid_test.mbt` / `<pkg>_difficult_test.mbt` 分级约定：

| 文件 | 覆盖范围 | 对齐源库 |
|------|---------|---------|
| `pinyin_easy_test.mbt` | 单字转换、繁简互转、`is_chinese` / `is_traditional_chinese` / `contains_chinese`、`PinyinFormat::name`、空串/非汉字边界、异常场景 | HLT 14 文件中的简单用例 |
| `pinyin_mid_test.mbt` | 词句转换（多分隔符、繁简混合、首字母、多音字）、`add_*_dict_resource` 自定义字典、`has_multi_pinyin` | HLT 14 文件中的组合用例 + LLT `test_pinyin_multi` / `test_pinyin_dict_*` |
| `pinyin_difficult_test.mbt` | 长句全格式四连测（如"河南麦收季…"）、通用拼音 30+ 断言、issue 回归（`test_issue_I89BPG` 等）、字典完整性 | LLT `test_pinyin_01~03` / `test_tongyong_01` / `test_issue*` / `test_chinese_dict_*` |
| `pinyin_snapshot_test.mbt` | 10 个 README 示例的精确输出对等 | 源库 README 10 个示例（审查报告 R1 修正：实际 10 例非 8 例） |

### 9.4 测试技术

- **snapshot 测试**：用 `inspect(value, content="...")` 对齐源库 `@Assert(expected, actual)`，`moon test --update` 自动维护。
- **异常测试**：用 `try PinyinHelper::convert_to_pinyin_string("", " ") catch { PinyinError::PinyinError(msg) => inspect(msg, content="Please enter a word or sentence") } noraise { _ => fail("expected to fail") }` 形式（对齐 `moonbit-agent-guide` 错误测试惯例）。
- **黑盒调用**：测试文件中通过 `@pinyin.PinyinHelper::convert_to_pinyin_string(...)` 或直接 `PinyinHelper::convert_to_pinyin_string(...)`（同包黑盒测试自动引用）。
- **不移植**：`FUZZ/` 模糊测试（MoonBit 无 fuzz 框架，可选属性测试替代但非强制）；`Reliability/` 200 线程压测（可选等价吞吐基准）。

### 9.5 验证循环

按 `moonbit-agent-guide` 的紧凑循环：
1. `moon check`（含 `--warn-list +unnecessary_annotation` 启用 warning 73）。
2. `moon test`（三后端分别 `--target wasm-gc` / `--target js` / `--target native`）。
3. `moon fmt`。
4. `moon info`（生成/更新 `pkg.generated.mbti`，review diff）。

---

## 十、设计决策汇总

| # | 决策点 | 选择 | 理由 |
|---|--------|------|------|
| D1 | 模块结构 | 单模块 + 主包 + 数据子包 | 隔离生成代码，保留源库单包逻辑组织 |
| D2 | API 组织 | 类型关联方法（`PinyinHelper::*`） | 保留命名空间，对齐源库视觉，避免顶层函数冲突 |
| D3 | 错误模型 | `raise PinyinError`（`suberror`） | MoonBit 检查式错误惯例，语义对齐源库 `throw` |
| D4 | 错误命名 | `PinyinError`（非 `Pinyin4cjException`） | MoonBit `XxxError` 惯例，包名已含溯源 |
| D5 | 字典数据结构 | `Map[Int, Int]` + `Map[String, String]`（可变） | MoonBit 惯用映射，可变性对齐源库 `HashMap`，字面量构造简洁 |
| D6 | 单字拼音字典内嵌 | 脚本生成 `.mbt` 字面量 | 最稳妥跨后端，编译期验证完整性 |
| D7 | 数据子包拆分 | 拆分 | 隔离生成代码，版本控制聚焦 |
| D8 | `convert_to_traditional_chinese` | 保留 O(n) 反查（O(L × 2556)） | 需求 3.8 不主动优化，避免改变多映射语义 |
| D9 | 目标后端 | wasm/js/native 三后端 | 源库纯计算无 FFI，天然跨后端 |
| D10 | FFI | 无 | 源库无 C 依赖，不引入 c-binding skill |
| D11 | 自定义字典并发 | 全局 `let map : Map` + 可变原地合并，无 `Ref` 包装，无 `Mutex` | 利用 MoonBit `Map` 可变性，直接对齐源库 `HashMap.add(all:)` 语义 |
| D12 | `PinyinFormat` 形态 | `enum`（4 变体） | 纯标签枚举，MoonBit 惯用形态 |
| D13 | `PinyinHelper` / `ChineseHelper` 形态 | 空 `struct`（命名空间） | 保留 static 语义，MoonBit 无 `static` 关键字 |
| D14 | 测试策略 | spec 契约（`declare` 关键字） + 分级黑盒 + snapshot | 对齐 `moonbit-agent-guide` 最新规范与 `moonbit-spec-test-development` skill |
| D15 | README 示例数 | 10 例（非 8 例） | 审查报告 R1 修正 |
| D16 | `PinyinDicts` 形态 | 全局 `let` 常量集合（非 `struct` 包装） | 减少抽象层次，`Map` 可变性已足够支持 `add_*` 语义 |

---

## 十一、与审查报告 `output_v1.md` 的呼应

本设计充分采纳审查报告的修订建议：

- **R1（README 示例 10 例）**：§9.3 表格明确"10 个 README 示例"，`pinyin_snapshot_test.mbt` 覆盖 10 例。
- **R2（源码 9 文件）**：§2.1 结构基于 9 源文件理解（`pinyin_helper` / `chinese_helper` / `pinyin_format` / `pinyin_resource` / `utils`→`pinyin_error` / `get_file_path`→不移植 / 三张字典→`data/`）。
- **R3（LLT pinyin_helper 17 文件）**：§9.3 测试覆盖对齐 LLT 17 文件语义。
- **R4（依赖列表）**：§7.1 明确零外部依赖，仅 `moonbitlang/core`；源库 `std.core.min` 对应 MoonBit 内置 `min`，`std.process` 不移植（构建脚本）。
- **R5（文件大小近似值）**：§7.3 用审查报告精确值 244 KB / 41806 行。

---

## 十二、不在范围内（对齐需求第四节）

- 不扩展源库能力（不新增拼音风格、不接入分词、不支持自定义声调方案）。
- 不保留 Cangjie 构建脚本（`build.cj` / `cjpm.toml` / `.gitignore`）。
- 不保留环境变量定位逻辑（`get_file_path.cj` 不移植）。
- 不原样移植 `Reliability/` 200 线程压测（可选等价基准）。
- 不移植 `FUZZ/` 模糊测试。
- 不引入第三方拼音数据源（仅用源库自带字典）。
- 不引入 `moonbit-c-binding` / `make-moonbit-c-bindings` / `moonbit-proof` skill。

---

## 修订说明（v2）

| 审查意见 | 修改措施 |
|---------|---------|
| **问题 1**：§3.5 声称 "MoonBit 标准库 `Map` 是惯用不可变映射"，事实性错误。MoonBit `Map` 实际是可变的、保持插入顺序的映射（SKILL.md:1064）。 | 修正 §3.5 数据结构选型说明：明确 `Map` 是可变映射，全局 `let` 绑定不可重新赋值但 `Map` 内容可变；补充与源库 `HashMap` 可变语义对齐的说明；调整"为何 `Map` 而非 `HashMap`"理由（MoonBit 标准库无 `HashMap` 类型名，`Map` 兼具查询与可变语义）。 |
| **问题 1（续）**：§6.2 基于错误前提排除方案 B（直接可变合并），采用 `Ref[Map]` 包装且理由错误。 | 重新设计 §6.2：采用方案 B（全局 `let map : Map` + `add_*` 直接调用 `Map` 可变操作原地合并），无需 `Ref[Map]` 包装；理由修正为"利用 MoonBit `Map` 可变性，直接对齐源库 `HashMap.add(all:)` 语义"；保留"不引入 `Mutex`"决策；多线程语义保留说明改为"源库 `HashMap` 本身无保证，移植版 `Map` 同样无保证，不构成语义退化"。 |
| **问题 1（续）**：§7.6 "Map 即惯用映射"表述需补充可变性特征。 | 修正 §7.6：新增"MoonBit `Map` 特性说明"段，明确 `Map` 是可变的、保持插入顺序的映射，可变性与源库 `HashMap` 对齐，基础字典初始化后仅只读、可变性仅用于 `add_*` 方法。 |
| **轻微**：§3.5 `PinyinDicts` 类型形态未明确（`struct` vs 全局常量集合）。 | 明确 §3.5 类型形态倾向：采用全局 `let` 常量集合，不引入 `struct` 包装；新增 D16 决策汇总条目说明此选择理由（减少抽象层次，`Map` 可变性已足够支持 `add_*` 语义）。 |
| **轻微**：§9.2 `declare` 关键字与 `#declaration_only` 关系未澄清。 | 修正 §9.2：明确采用 `declare` 关键字，新增"`declare` 关键字 vs `#declaration_only` 的取舍"说明，理由为 `declare` 与 `moonbit-agent-guide` 最新规范一致；D14 决策汇总补充"`declare` 关键字"标注。 |
| **轻微**：§3.4 `convert_to_traditional_chinese` 保留 O(n) 反查未说明性能影响量级。 | 修正 §3.4：在 `convert_to_traditional_chinese` 描述中补充性能特征说明（n ≈ 2556，单字符 O(n)，大文本 O(L × n)）；§7.7 同步补充性能特征；D8 决策汇总补充"O(L × 2556)"量级标注。 |
| **关联修正**：§6.1 并发设计需同步更新。 | 修正 §6.1：删除"自定义字典追加需 `Ref[Map]` 或 `Mutex[Map]`"表述，改为"直接利用 MoonBit `Map` 可变性原地合并，无需 `Ref[Map]` 包装"。 |
| **关联修正**：§1.3 核心抽象一览表中 `PinyinDicts` 形态描述需同步。 | 修正 §1.3：`PinyinDicts` 形态从"内部 `struct`/全局常量集合"明确为"全局 `let` 常量集合（不公开）"。 |