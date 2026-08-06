# pinyin4cj 移植到 MoonBit 的需求澄清

## 一、任务核心

将 Cangjie 语言实现的拼音库 `pinyin4cj`（位于 `D:\CodeWorkspace\forCangjie\pinyin4cj`，版本 v1.0.5）完整移植为 MoonBit 语言实现，产物工作目录为 `D:\CodeWorkspace\forMoonbit\pinyin`。移植须保持原库的全部功能语义与公开 API 表面（含义对等，命名按 MoonBit 惯例调整），并遵循项目内 `.codeartsdoer/skills` 目录下相关 skill 规范进行工程化落地。

## 二、源库事实摘要（澄清依据）

源库是一个纯计算型拼音转换库，无第三方依赖，仅依赖 Cangjie 标准库（`std.collection.HashMap`、`std.fs`、`std.io.StringReader`、`std.env`、`std.process`）。

**源码结构（`src/`，8 个文件）**

- `pinyin_helper.cj`（311 行）—— 核心拼音转换器 `PinyinHelper`，含声调格式转换、词组优先匹配、多音字、通用拼音等逻辑。
- `chinese_helper.cj`（140 行）—— 繁简互转器 `ChineseHelper`，基于 `CHINESE_MAP`（繁→简）单向映射，简→繁通过遍历反查实现。
- `pinyin_format.cj`（33 行）—— `PinyinFormat` 枚举：`WITH_TONE_MARK` / `WITHOUT_TONE` / `WITH_TONE_NUMBER` / `FIRST_LETTER`，附 `getName(): String`。
- `pinyin_resource.cj`（71 行）—— 资源加载器 `PinyinResource`，从外部文件 `pinyin.dict.txt` 读取单字拼音表；其余三张表来自源码内嵌字面量。
- `utils.cj`（25 行）—— `Pinyin4cjException <: Exception`，含 `getMessage()` 与 `toString()`。
- `get_file_path.cj`（43 行）—— 平台条件编译（Linux/Windows），通过环境变量 `LD_LIBRARY_PATH` / `Path` 定位 `pinyin.dict.txt` 所在目录。
- `chinese.dict.cj`（2556 行，56 KB）—— 内嵌繁→简字典字面量 `chinese_dict: HashMap<Rune, Rune>`。
- `mutil_pinyin.dict.cj`（858 行，27 KB）—— 内嵌词组拼音字典字面量 `mutil_pinyin_dict: HashMap<String, String>`，值用逗号分隔多字拼音。
- `tongyong_pinyin_dict.cj`（92 行，2 KB）—— 内嵌通用拼音映射字面量 `tongyong_pinyin_dict: HashMap<String, String>`。

**外部资源（`resource/`）**

- `pinyin.dict.txt`（250 KB，41806 行）—— 单字拼音字典，两行一组（汉字 / 拼音读音，多音用逗号分隔）。运行时由 `get_file_path.cj` 通过环境变量定位，`build.cj` 的 `post-build` 钩子负责把它复制到构建产物目录。

**公开 API 表面（移植必须对等覆盖）**

`ChineseHelper`（全部静态方法）：
- `convertToSimplifiedChinese(str: String): String` —— 繁→简，非汉字原样返回，空串返回空串。
- `convertToTraditionalChinese(str: String): String` —— 简→繁，语义同上。
- `isTraditionalChinese(c: Rune): Bool`
- `isChinese(c: Rune): Bool` —— 是否在拼音表中。
- `containsChinese(str: String): Bool`
- `addChineseDictResource(dict: HashMap<Rune, Rune>): Unit` —— 追加自定义繁简映射。

`PinyinHelper`（全部静态方法）：
- `convertToPinyinString(str, separator): String` —— 默认 `WITH_TONE_MARK` 重载。
- `convertToPinyinString(str, separator, format: PinyinFormat): String` —— 简体词句转拼音；空串抛 `Pinyin4cjException("Please enter a word or sentence")`；非汉字原样穿插；词组优先匹配（最多 5 字前缀查 `MUTIL_PINYIN_TABLE`）。
- `convertToPinyinStringTraditional(str, separator, format): String` —— 先繁→简再转拼音。
- `convertToPinyinArray(c: Rune, format: PinyinFormat): Array<String>` —— 单字所有读音；非汉字返回 `[]`。
- `getShortPinyin(str: String): String` —— 首字母格式，分隔符为空串。
- `hasMultiPinyin(c: Rune): Bool` —— 非汉字抛 `Pinyin4cjException("Please enter a Chinese character")`。
- `addPinyinDictResource(dict: HashMap<String, String>): Unit`
- `addMutilPinyinDictResource(dict: HashMap<String, String>): Unit`
- `toTongyongPinyinStringArray(char: Rune): Array<String>` —— 数字音标通用拼音；非汉字返回 `[]`。

`PinyinFormat` 枚举 + `getName()`；`Pinyin4cjException` 异常类。

**测试资产**

- `test/HLT/`（14 文件）—— 高层单元测试，覆盖各公开 API 的典型用例与边界（空串、纯非汉字、繁简混合、多分隔符等）。
- `test/LLT/chinese_helper/`（5 文件）与 `test/LLT/pinyin_helper/`（18 文件）—— 低层自测，含字典完整性、长句、传统拼音、通用拼音、issue 回归。
- `test/FUZZ/`（11 文件）—— 模糊测试桩。
- `test/Reliability/`（11 文件）—— 200 线程 × 10000 次并发压力测试与吞吐量统计。
- `test/DOC/`（1 文件）—— 文档用例。

**已识别的源库特性与隐含约束**

1. 单字拼音表是外部文件，依赖环境变量定位——这是 Cangjie 动态库打包机制所致，与 MoonBit 生态不符，需重新设计资源加载策略。
2. 三张内嵌字典用 `HashMap` 字面量初始化，启动时即驻留内存（约 85 KB 源码 → 数万条目）。
3. `convertToTraditionalChinese` 通过遍历 `CHINESE_MAP` 反查（O(n) 单字），性能弱于正向查询，移植时保留语义即可，不主动优化。
4. 词组匹配 `getWords` 取 `min(charArray.size + 1, 6)`，即最多匹配 5 字前缀。
5. 声调符号处理依赖 24 个带调元音 `ALL_MARKED_VOWEL_ARRAY` 与 6 个无调元音 `ALL_UNMARKED_VOWEL_ARRAY` 的算术映射；轻声用数字 `5` 表示。
6. `CHINESE_LING = r'〇'`（U+3007）作为汉字零的特殊处理。
7. 源库以 `dynamic` 库形式构建（`output-type = "dynamic"`），但本质是纯计算库，无 FFI。

## 三、移植需求（澄清后）

### 3.1 移植范围

**完整移植**，覆盖源库全部公开 API 与全部三张字典 + 单字拼音外部资源。不裁剪核心子集。理由：源库体量小（核心逻辑约 600 行 + 字典数据），裁剪不会显著降低工作量，反而会破坏 API 对等性。

**包含以下产物**：

- MoonBit 库实现（源码 + 字典数据）。
- 完整测试套件（对齐 HLT/LLT 用例语义，覆盖所有公开 API 与边界）。
- README 与 API 文档（对齐 `doc/feature_api.md` 的接口说明）。
- 示例代码（对齐 README 中的 8 个示例）。

**不在范围内**：

- 模糊测试桩（`test/FUZZ/`）的原样移植——MoonBit 无对应 fuzz 框架，改为属性测试或省略。
- `Reliability/` 的 200 线程并发压测原样移植——MoonBit 异步/并发模型与 Cangjie 不同，改为等价的吞吐量基准测试（可选）。
- `build.cj` 的 post-build 复制逻辑——MoonBit 资源机制不同，无需保留。
- `get_file_path.cj` 的环境变量定位逻辑——见 3.4，改用内嵌资源。

### 3.2 API 对等性要求

**语义对等**：每个移植后的公开函数对相同输入必须产出与源库完全相同的输出（含异常情形与异常消息文本）。这是硬性约束，下游设计者不得擅自改变边界行为（如把空串异常改为返回空串）。

**命名调整**（按 MoonBit 惯例，属合理推断，用户偏好已明确 PascalCase 类型名 + kebab-case 文档名 + MoonBit 惯例函数名）：

- 类型名保留 PascalCase：`PinyinHelper`、`ChineseHelper`、`PinyinFormat`、`Pinyin4cjException`（或按 MoonBit 习惯改为 `PinyinError`，见 3.5）。
- 函数名改为 snake_case：`convert_to_simplified_chinese`、`convert_to_pinyin_string`、`convert_to_pinyin_array`、`get_short_pinyin`、`has_multi_pinyin`、`to_tongyong_pinyin_string_array`、`add_pinyin_dict_resource`、`add_mutil_pinyin_dict_resource`、`add_chinese_dict_resource`、`is_traditional_chinese`、`is_chinese`、`contains_chinese` 等。
- 枚举变体保留 PascalCase：`WithToneMark` / `WithoutTone` / `WithToneNumber` / `FirstLetter`（MoonBit 枚举构造器惯例）。
- `PinyinFormat::get_name()` 改为方法 `fn name(self) -> String` 或保留为方法；按 MoonBit 惯例用方法。

**API 风格**：按 `moonbit-agent-guide` skill 建议，优先将静态方法组织为顶层函数或类型关联方法（MoonBit 无 `static` 概念），保持 `PinyinHelper::convert_to_pinyin_string(...)` 形式或顶层 `@pinyin.convert_to_pinyin_string(...)` 形式——具体由下游技术设计决定，需求层不约束。

### 3.3 字典数据移植策略

三张内嵌字典（`chinese_dict`、`mutil_pinyin_dict`、`tongyong_pinyin_dict`）在源库中以 `HashMap` 字面量直接写在 `.cj` 源文件中。移植到 MoonBit 时：

- **保留内嵌字面量形式**，将其转写为 MoonBit 的 `Map[Int, Int]`（繁简映射，Rune → MoonBit `Int` 码点）与 `Map[String, String]`（拼音映射）字面量。
- 字典数据体积大（合计约 85 KB 源码），可拆分为独立 `.mbt` 文件（如 `chinese_dict.mbt`、`mutil_pinyin_dict.mbt`、`tongyong_pinyin_dict.mbt`），按 `moonbit-agent-guide` 的"多小文件、内聚"原则组织。
- 不要求人工逐条转写，可脚本化生成（属实现细节，由下游决定）。

### 3.4 单字拼音外部资源加载策略（关键澄清）

源库的 `pinyin.dict.txt`（250 KB，41806 行）通过环境变量在运行时从文件系统加载。此机制与 MoonBit 跨后端、可移植的设计哲学冲突，必须重新设计。

**推荐方案（基于 MoonBit 生态推断）**：将 `pinyin.dict.txt` 的内容在构建期内嵌为 MoonBit 字符串字面量或 `Bytes` 常量，运行时直接解析为 `Map[String, String]`。具体技术手段（`@embed`、`#embed`、构建脚本生成 `.mbt`、或直接转写为字面量）由下游技术设计选定，需求层只约束：

1. **不依赖运行时文件系统与环境变量**——库初始化后即可用，跨 wasm/js/native 三后端一致。
2. **首字母 `〇`（U+3007）等特殊条目必须保留**，与源库字典逐行对等。
3. 内嵌后的字典容量与源库一致（41806 行 / 20903 组键值对）。

### 3.5 异常模型转换

源库用 `throw Pinyin4cjException(msg)` + `try/catch`。MoonBit 用 `raise`/`catch` + 检查式错误。

**要求**：

- 定义等价错误类型，命名按 MoonBit 惯例用 `PinyinError`（推断：MoonBit 错误类型惯用 `XxxError` 而非 `XxxException`）；若下游设计认为保留 `Pinyin4cjException` 命名更利于溯源，亦可。
- 两个异常触发点必须保留语义：
  - `convert_to_pinyin_string` 系列空串输入 → 错误消息含 `"Please enter a word or sentence"`。
  - `has_multi_pinyin` 非汉字输入 → 错误消息含 `"Please enter a Chinese character"`。
- 是用 `raise` 抛错误（推荐，符合 MoonBit 惯例）还是返回 `Result[T, PinyinError]`，由下游技术设计决定；需求层只约束错误场景与消息文本对等。

### 3.6 目标后端

**支持 wasm、js、native 三后端**（推断：拼音库是纯计算库，无 FFI 需求，天然跨后端；用户偏好 MoonBit 生态，未限定单一后端）。约束：

- 不得引入 `moonbit-c-binding` / `make-moonbit-c-bindings` 相关的 native FFI 依赖（这两个 skill 不适用于本任务，因源库本身无 C 依赖）。
- 不得使用 `supported-targets: ["native"]` 限制可移植性。
- 字符串与字符处理须注意 MoonBit 字符串为 UTF-16、`Char` 为 Unicode 码点，与 Cangjie `Rune` 概念对齐时需正确处理 BMP 外字符（拼音字典均在 BMP 内，但仍需类型正确）。

### 3.7 测试策略

**采用 spec-driven 测试 + 黑盒测试并行的双轨策略**（基于用户偏好"详细的需求分析与库对比" + 项目内 `moonbit-spec-test-development` skill 规范推断）：

1. **spec 契约**：按 `moonbit-spec-test-development` skill，先写 `<pkg>_spec.mbt` 形式化契约（用 `#declaration_only` 声明全部公开 API 签名），作为实现与测试的共同基准。
2. **黑盒测试**：在 `<pkg>_test.mbt` / `<pkg>_easy_test.mbt` / `<pkg>_mid_test.mbt` / `<pkg>_difficult_test.mbt` 中对齐源库 HLT/LLT 用例语义，至少覆盖：
   - 8 个 README 示例的精确输出对等。
   - HLT 14 文件的全部断言（含空串异常、纯非汉字、繁简混合、多分隔符、首字母、多音字、通用拼音）。
   - LLT 的长句用例（如"河南麦收季…"全格式四连测）与通用拼音 30+ 断言。
3. **验证循环**：按 `moonbit-agent-guide` 的 `moon check` → `moon test` → `moon fmt` → `moon info` 紧凑循环；最终 `pkg.generated.mbti` 入版本控制。

**不要求**：模糊测试原样移植；200 线程并发压测原样移植（可改为等价吞吐基准，可选）。

### 3.8 非功能性要求

- **正确性优先于性能**：与源库输出逐字符对等是硬约束，不得为性能牺牲任何边界用例。
- **性能对齐**（推断）：源库 README 称"支持版本几何性能持平"，移植版不应出现数量级退化；无需做主动性能优化，但 `convert_to_traditional_chinese` 的 O(n) 反查语义保留即可。
- **内存**：字典常驻内存，总量与源库同阶（数万条目），可接受。
- **API 兼容性**：移植版为 v0.1.0 起步，无历史兼容包袱；但公开 API 一经发布须按 `pkg.generated.mbti` 稳定管理。
- **代码注释**（用户偏好）：公开 API 须附 docstring，对齐源库 `doc/feature_api.md` 的接口说明；非公开内部逻辑按需注释。

### 3.9 工程规范（来自 skill）

按项目内 skill 规范落地工程：

- `moonbit-agent-guide` —— 项目布局（`moon.mod` + `moon.pkg`）、文件组织（多小文件、内聚）、`moon` 工具链使用、`pkg.generated.mbti` 管理。
- `moonbit-spec-test-development` —— spec-driven 契约优先工作流。
- `moonbit-orientation` —— 遇到 MoonBit 语言能力疑问时查阅权威来源，避免 stale 假设。
- `moonbit-refactoring` —— 移植过程中若需重构，按行为保持原则。
- 不使用 `moonbit-c-binding` / `make-moonbit-c-bindings`（无 C 依赖）。
- 不使用 `moonbit-proof`（非形式化验证场景）。

文档与产物命名遵循 kebab-case（用户偏好）；交互使用简体中文，技术术语保留英文（用户偏好）。

## 四、边界与不做什么

- **不改变功能语义**：不扩展源库能力（如不新增拼音风格、不接入分词、不支持自定义声调方案），仅做语言间等价移植。
- **不保留 Cangjie 构建脚本**：`build.cj`、`cjpm.toml`、`.gitignore` 等不移植，改用 MoonBit 的 `moon.mod` / `moon.pkg`。
- **不保留环境变量定位逻辑**：`get_file_path.cj` 不移植，资源加载见 3.4。
- **不做性能基准移植**：`Reliability/` 压测不原样移植（可选做等价基准）。
- **不做模糊测试移植**：`FUZZ/` 不移植。
- **不引入第三方拼音数据源**：仅用源库自带字典，不替换为 pypinyin 等其他数据。

## 五、交付物清单

1. MoonBit 模块（`moon.mod` + 包结构），实现全部公开 API。
2. 三张内嵌字典 + 单字拼音字典内嵌化产物。
3. spec 契约文件 `<pkg>_spec.mbt`。
4. 黑盒测试套件（easy/mid/difficult 分级或统一 `_test.mbt`），对齐 HLT/LLT 用例。
5. `README.md`（含 8 个示例的可运行代码块，对齐源库 README）。
6. API 文档（对齐 `doc/feature_api.md`）。
7. `pkg.generated.mbti` 入版本控制。

## 六、待下游技术设计决策的开放问题（需求层不决策）

以下问题留给技术设计阶段，需求层只列出选项与约束：

1. 单字拼音字典内嵌的具体技术（`@embed` / 构建脚本生成 `.mbt` / 字面量转写）——约束：跨三后端、不依赖文件系统。
2. 公开 API 组织形式（顶层函数 vs 类型关联方法 vs 模块函数）——约束：命名 snake_case、语义对等。
3. 错误模型（`raise` + `PinyinError` vs `Result[T, PinyinError]`）——约束：错误场景与消息文本对等。
4. 字典数据结构选型（`Map[Int, Int]` vs `HashMap` vs `@hashmap.T`）——约束：查询语义对等、启动时初始化。
5. 是否提供 `convert_to_traditional_chinese` 的反向索引优化——约束：不改变对外语义。
6. 模块发布名（mooncakes.io 上的包名）——约束：与工作目录 `pinyin` 一致或符合 mooncakes 命名规范。