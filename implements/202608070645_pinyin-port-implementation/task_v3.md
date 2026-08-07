# 任务指令（v3）

## 动作
NEW

## 任务描述

创建 Python 3 生成脚本 `scripts/gen_pinyin_dict.py`，从源库 `D:\CodeWorkspace\forCangjie\pinyin4cj` 转写四张字典为 MoonBit 字面量，运行脚本生成 4 个数据子包源文件：

1. `data/chinese_dict.mbt` — `let chinese_dict : Map[Int, Int]`，约 2556 条繁→简映射，16 进制码点字面量（如 `0x81FA: 0x53F0`）
2. `data/mutil_pinyin_dict.mbt` — `let mutil_pinyin_dict : Map[String, String]`，约 856 条词组拼音
3. `data/tongyong_pinyin_dict.mbt` — `let tongyong_pinyin_dict : Map[String, String]`，83 条通用拼音
4. `data/pinyin_dict.mbt` — `let pinyin_dict : Map[String, String]`，20903 条单字拼音

预期文件路径：`scripts/gen_pinyin_dict.py`、`data/chinese_dict.mbt`、`data/mutil_pinyin_dict.mbt`、`data/tongyong_pinyin_dict.mbt`、`data/pinyin_dict.mbt`。

验证：`moon check` 通过（exit code 0，0 errors，1 warnings `unused_package` 预期——主包仍不引用 `@data.xxx`，持续至 R4 字典视图任务消除）。`pinyin_dict.mbt` 条目数 = 20903（脚本含断言校验）。

## 选择理由

四张字典是全部算法实现的底层数据依赖：
- `pinyin_dicts.mbt`（R4 字典视图）直接引用 `@data.*` 四个常量
- `tone_conversion.mbt` / `pinyin_helper.mbt` / `chinese_helper.mbt` 通过 `pinyin_dicts.mbt` 间接依赖

按"底层优先"原则，在算法实现之前先建立字典数据子包。四张字典均为纯数据字面量（非复杂行为类型），紧密相关，合并为一个任务符合粒度约定（纯数据类型可合并）。生成脚本入版本控制，产物亦入版本控制（便于 `moon check` 离线验证，落实技术方案 §5.1）。

当前优先级：最高。R1（骨架）/ R2（基础类型）已完成，本任务为 R3，是 R4-R8 的前置依赖。

## 任务上下文

### 技术方案依据（tech_v1.md）

- **§4.1 字典数据结构选型**：
  | 字典 | MoonBit 类型 | 容量 | 用途 |
  |------|------------|------|------|
  | `chinese_dict` | `Map[Int, Int]` | 2556 条 | 繁→简映射（码点→码点） |
  | `pinyin_dict` | `Map[String, String]` | 20903 条 | 单字拼音（汉字→逗号分隔多音） |
  | `mutil_pinyin_dict` | `Map[String, String]` | 约 856 条 | 词组拼音（词→逗号分隔拼音） |
  | `tongyong_pinyin_dict` | `Map[String, String]` | 83 条 | 通用拼音映射 |

- **§4.2 存储策略**：构建期内嵌为 MoonBit 字面量，运行时直接构造为 Map 对象。不依赖运行时文件系统，跨 wasm/js/native 三后端一致。

- **§5.1 生成脚本**：
  - 脚本路径：`scripts/gen_pinyin_dict.py`（Python 3，入版本控制）
  - 脚本输入：源库 `src/*.dict.cj` + `resource/pinyin.dict.txt`
  - 脚本输出：`data/chinese_dict.mbt` / `data/mutil_pinyin_dict.mbt` / `data/tongyong_pinyin_dict.mbt` / `data/pinyin_dict.mbt`
  - 生成产物入版本控制（便于 `moon check` 离线验证）

- **§5.2 转写规则**：
  - **5.2.1 `chinese_dict.mbt`（繁→简）**：源 `HashMap<Rune, Rune>([(r'臺', r'台'), ...])` → 目标 `let chinese_dict : Map[Int, Int] = { 0x81FA: 0x53F0, ... }`（16 进制码点字面量，保持可读性）
  - **5.2.2 `mutil_pinyin_dict.mbt`（词组拼音）**：源 `HashMap<String, String>([("阿訇", "ā,hōng"), ...])` → 目标 `let mutil_pinyin_dict : Map[String, String] = { "阿訇": "ā,hōng", ... }`（键值直接转写，含带调元音 UTF-8 字符串原样保留）
  - **5.2.3 `tongyong_pinyin_dict.mbt`（通用拼音）**：源 92 行 83 条目 → 目标 `let tongyong_pinyin_dict : Map[String, String] = { "chi": "chih", ... }`（纯 ASCII 直接转写）
  - **5.2.4 `pinyin_dict.mbt`（单字拼音）**：源 `resource/pinyin.dict.txt` 41806 行 / 20903 组（两行一组：汉字 / 拼音读音）→ 目标 `let pinyin_dict : Map[String, String] = { "〇": "líng", "一": "yī", "丁": "dīng,zhēng", ... }`。**完整性约束**：生成产物条目数必须 = 20903，脚本含断言校验。

- **§十一关键技术决策**：T6（Map[Int,Int] + Map[String,String]）、T7（构建期脚本生成 .mbt 字面量）、T8（Python 3 脚本）

### 源库字典格式（转写输入）

1. **`src/chinese.dict.cj`（2556 行）**：
   ```cangjie
   let chinese_dict: HashMap<Rune, Rune> = HashMap<Rune, Rune>([
      (r'臺', r'台'),
      (r'萬', r'万'),
      ...
   ])
   ```
   解析：每行 `(r'X', r'Y')` 形式，提取繁体字符 X 与简体字符 Y，转写为 `X.to_int(): Y.to_int()` 的 16 进制码点。

2. **`src/mutil_pinyin_dict.cj`（858 行）**：
   ```cangjie
   let mutil_pinyin_dict: HashMap<String, String> = HashMap<String, String>([
      ("阿訇", "ā,hōng"),
      ("阿罗汉", "ā,luó,hàn"),
      ...
   ])
   ```
   解析：每行 `("key", "value")` 形式，键值直接转写为 MoonBit 字符串字面量。

3. **`src/tongyong_pinyin_dict.cj`（92 行）**：
   ```cangjie
   let tongyong_pinyin_dict: HashMap<String, String> = HashMap<String, String>([
       ("chi", "chih"),
       ("chui", "chuei"),
       ...
   ])
   ```
   解析：同上，纯 ASCII 键值直接转写。

4. **`resource/pinyin.dict.txt`（41806 行 / 20903 组）**：
   ```
   〇
   líng
   一
   yī
   丁
   dīng,zhēng
   ...
   ```
   解析：两行一组，奇数行为汉字（键），偶数行为拼音读音（值，逗号分隔多音）。转写为 `"汉字": "拼音,拼音,..."` 字面量条目。

### MoonBit Map 字面量语法

- `Map[Int, Int]` 字面量：`let chinese_dict : Map[Int, Int] = { 0x81FA: 0x53F0, 0x842C: 0x4E07, ... }`
- `Map[String, String]` 字面量：`let pinyin_dict : Map[String, String] = { "〇": "líng", "一": "yī", ... }`
- 顶层 `let` 绑定，数据子包常量必须使用 `pub let`（对包外可见，主包可通过 `@data` 引用）。
- **可见性决策（已确认）**：使用 `pub let`，**不要**使用 `pub(self) let`。理由：
  1. `pub(self) let` 语义是仅当前包可见，主包**无法**通过 `@data` 引用，会阻断 R4 字典视图任务。
  2. `pub let` 是最小充分可见性，数据子包常量是纯数据（`Map[Int,Int]` / `Map[String,String]`），无内部成员需公开，`pub let` 足矣，无需 `pub(all) let`。
  3. 已查阅 wiki `language/packages.md:79-80` 确认：`pub` modifier 使 toplevel `let` 对其他包可见（可读取），符合跨包 `@data` 引用场景。
- **生成脚本编码要求（强制）**：脚本所有文件读写必须显式指定 `encoding="utf-8"`（如 `open(path, "r", encoding="utf-8")` / `open(path, "w", encoding="utf-8")`）。源库 `resource/pinyin.dict.txt` 与 `src/mutil_pinyin_dict.cj` 含带调元音字符（如 `líng`、`ā,hōng`），Windows 平台 Python 3 默认编码非 UTF-8（如 GBK cp936），未显式指定将导致字符损坏，缺陷隐蔽（`moon check` 可能通过但运行时拼音数据错误）。
- **生成脚本确定性输出要求（强制）**：脚本输出条目必须按 key 排序，确保多次运行产生字节级一致的产物：
  1. `chinese_dict.mbt`：按 Int key 升序排列（`sorted(items, key=lambda kv: kv[0])`）
  2. `pinyin_dict.mbt` / `mutil_pinyin_dict.mbt` / `tongyong_pinyin_dict.mbt`：按 String key 字典序排列（`sorted(items, key=lambda kv: kv[0])`）
  理由：`pinyin_dict.mbt` 有 20903 条目，若顺序不稳定，版本控制 diff 将极难审阅，且脚本可重复性无法保证。

### 验证契约

- **验证命令**（工作目录：`D:\CodeWorkspace\forMoonbit\pinyin`）：`moon check`
- **预期输出**：成功（exit code 0，0 errors，1 warnings `Warning (0029) (unused_package): Unused package 'pinyin/pinyin/data'`——主包仍不引用 `@data.xxx`，与 R1/R2 状态一致，R4 字典视图任务后消除）
- **完整性校验（四张字典均精确断言）**：脚本解析后必须对四张字典均含精确条目数断言（与预期值严格相等，**不使用约等于容差**），若解析逻辑漏掉若干条目，断言立即失败：
  - `pinyin_dict.mbt` 条目数 == 20903（源 `resource/pinyin.dict.txt` 41806 行 / 2 = 20903 组，精确值）
  - `tongyong_pinyin_dict.mbt` 条目数 == 83（源 `src/tongyong_pinyin_dict.cj` 92 行去空行/注释后精确值）
  - `chinese_dict.mbt` 条目数 == 2556（源 `src/chinese.dict.cj` 2556 行精确值，脚本解析后实际计数与此比较）
  - `mutil_pinyin_dict.mbt` 条目数 == 856（源 `src/mutil_pinyin_dict.cj` 858 行去 2 行声明/收尾后精确值，脚本解析后实际计数与此比较）
  - **注**：`chinese_dict` 与 `mutil_pinyin_dict` 的精确值由脚本解析源库后实际计数确定，若与上述预期不符，脚本应打印实际计数并断言失败，由编码 agent 核对源库后修正预期值（而非放宽断言）。
- **不执行的验证**：`moon test`（本任务无测试文件，数据子包纯数据无公开行为 API；测试在后续算法实现任务中编写）

## 已有代码上下文

### R1 产出（项目骨架，本任务依赖）

- `moon.mod`：模块名 `pinyin/pinyin`，version `0.1.0`，license MIT，零外部依赖
- `moon.pkg`：主包配置，`import "pinyin/pinyin/data"`（本任务不引用但保留）
- `data/moon.pkg`：数据子包配置，纯数据包零依赖（无 import）
- `README.mbt.md`：占位（本任务不修改）

### R2 产出（基础类型，本任务不依赖）

- `pinyin_format.mbt`：`PinyinFormat` enum + `name` 方法
- `pinyin_error.mbt`：`PinyinError` suberror
- `pinyin_format_test.mbt` / `pinyin_error_test.mbt`：8 测试用例

### 当前项目根目录结构

```
D:\CodeWorkspace\forMoonbit\pinyin\
├── moon.mod
├── moon.pkg
├── README.mbt.md
├── README.md
├── pinyin_format.mbt
├── pinyin_error.mbt
├── pinyin_format_test.mbt
├── pinyin_error_test.mbt
└── data/
    └── moon.pkg
```

本任务新增 `scripts/` 目录与 `data/*.mbt` 4 个文件，不修改已有文件。

### 源库路径

`D:\CodeWorkspace\forCangjie\pinyin4cj`
- `src/chinese.dict.cj`（2556 行）
- `src/mutil_pinyin_dict.cj`（858 行）
- `src/tongyong_pinyin_dict.cj`（92 行）
- `resource/pinyin.dict.txt`（41806 行）

### 后续任务边界（本任务不创建）

- `pinyin_dicts.mbt`（R4 字典视图构造，引用 `@data.*`）
- `tone_conversion.mbt`（R5 声调转换内部逻辑）
- `pinyin_helper.mbt`（R6 PinyinHelper 关联方法）
- `chinese_helper.mbt`（R7 ChineseHelper 关联方法）
- `pinyin_spec.mbt`（R8 形式化契约）
- 测试文件 `pinyin_easy_test.mbt` / `pinyin_mid_test.mbt` / `pinyin_difficult_test.mbt`（R9+）
- `README.mbt.md` 填充（R10）

避免过度设计，本任务仅生成字典数据字面量与生成脚本。

## 修订说明（v3 r1）

| 审查意见 | 修改措施 |
|---------|---------|
| **[严重]** 可见性修饰符描述自相矛盾：第 105 行同时提供 `pub let`（正确）与 `pub(self) let`（错误，主包不可见）两个备选，并错误声称 `pub(self)` 可被主包通过 `@data` 引用，会误导编码 agent 选择 `pub(self) let` 阻断 R4 任务链 | 删除 `pub(self) let` 备选项与错误陈述。明确要求数据子包常量使用 `pub let`（最小充分可见性），给出 3 条理由（`pub(self)` 语义错误 / `pub let` 足矣 / wiki 确认），并注明已查阅 wiki `language/packages.md:79-80` 确认 `pub let` 在跨包 `@data` 引用场景下的正确性 |
| **[一般]** 生成脚本未明确要求以 UTF-8 编码读写文件，Windows 平台 Python 3 默认编码非 UTF-8，将导致带调元音字符损坏 | 在 §MoonBit Map 字面量语法 中补充"生成脚本编码要求（强制）"小节，明确要求所有文件读写显式指定 `encoding="utf-8"`，并说明缺陷隐蔽性 |
| **[一般]** 生成脚本未要求确定性输出顺序，`pinyin_dict.mbt` 20903 条目若顺序不稳定，版本控制 diff 极难审阅 | 在 §MoonBit Map 字面量语法 中补充"生成脚本确定性输出要求（强制）"小节，明确要求按 key 排序输出（`chinese_dict` 按 Int key 升序，其余按 String key 字典序），确保多次运行字节级一致 |
| **[轻微]** 完整性校验仅对 `pinyin_dict.mbt` 和 `tongyong_pinyin_dict.mbt` 要求精确等于，对 `chinese_dict.mbt` 和 `mutil_pinyin_dict.mbt` 使用约等于容差，会让校验形同虚设 | 修改 §验证契约 完整性校验，对四张字典均要求精确条目数断言（严格相等，不使用约等于容差），并补充说明：若 `chinese_dict` / `mutil_pinyin_dict` 实际计数与预期不符，脚本应打印实际计数并断言失败，由编码 agent 核对源库后修正预期值（而非放宽断言） |