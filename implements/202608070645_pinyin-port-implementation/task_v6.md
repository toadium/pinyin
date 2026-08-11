# 任务指令（v6）

## 动作
NEW

## 任务描述

在主包根目录创建 `tone_conversion.mbt`，实现声调格式转换内部逻辑（对应源库 `pinyin_helper.cj` 中 5 个 static 内部方法 + 3 个辅助常量），并新增 `tone_conversion_test.mbt` 测试。

### 预期文件路径

- `tone_conversion.mbt`（新建，主包根目录）
- `tone_conversion_test.mbt`（新建，主包根目录）

### `tone_conversion.mbt` 内容

#### 辅助常量（3 个，对应源库 `pinyin_helper.cj:13-16` + 技术方案 §4.3）

```moonbit
/// 拼音分隔符，对齐源库 PINYIN_SEPARATOR。pub let 跨文件共享（R6 pinyin_helper.mbt 亦用）。
pub let pinyin_separator : String = ","

/// 无调元音数组，对齐源库 ALL_UNMARKED_VOWEL_ARRAY。let 文件内私有（仅本文件用）。
let all_unmarked_vowel_array : Array[Char] = ['a', 'e', 'i', 'o', 'u', 'v']

/// 带调元音数组，对齐源库 ALL_MARKED_VOWEL_ARRAY（24 个，6 元音 × 4 声调）。let 文件内私有。
let all_marked_vowel_array : Array[Char] = [
  'ā', 'á', 'ǎ', 'à',  // a 的 4 声调
  'ē', 'é', 'ě', 'è',  // e 的 4 声调
  'ī', 'í', 'ǐ', 'ì',  // i 的 4 声调
  'ō', 'ó', 'ǒ', 'ò',  // o 的 4 声调
  'ū', 'ú', 'ǔ', 'ù',  // u 的 4 声调
  'ǖ', 'ǘ', 'ǚ', 'ǜ',  // ü 的 4 声调
]
```

#### 内部函数（5 个，对应源库 `pinyin_helper.cj` + 技术方案 §6.3 / §10.3）

**1. `find_array_key_by_value`**（源库 `pinyin_helper.cj:279-289`，技术方案 §6.3.4）

```moonbit
/// 在带调元音数组中查找字符索引，未找到返回 -1。对齐源库 findArrayKeyByValue。
pub(self) fn find_array_key_by_value(ch : Char) -> Int
```

行为：遍历 `all_marked_vowel_array`，返回首个等于 `ch` 的索引；未找到返回 `-1`。**用显式循环对齐源库 `:279-289` 写法**（MoonBit 标准库 `Iter` 无 `position` 方法，`find_first` 返回元素而非索引，均不适用）：

```moonbit
for i in 0..<all_marked_vowel_array.length() {
  if all_marked_vowel_array[i] == ch {
    return i
  }
}
return -1
```

**2. `convert_with_tone_number`**（源库 `pinyin_helper.cj:29-55`，技术方案 §6.3.1）

```moonbit
/// 带调拼音→数字调拼音数组。对齐源库 convertWithToneNumber。
pub(self) fn convert_with_tone_number(str : String) -> Array[String]
```

行为（逐音节对齐源库 `:29-55`）：
1. `pinyin_array = str.split(pinyin_separator[:]).map(fn(x) { x.to_owned() }).to_array()`（`String::split` 返回 `Iter[StringView]`，需 `map` + `to_owned` + `to_array` 转为 `Array[String]`；`pinyin_separator : String` 用 `[:]` 全切片适配 `StringView` 参数）
2. 逐音节 `i in 0..<pinyin_array.length()`：
   - `original_pinyin = pinyin_array[i].replace_all(old="ü", new="v")`（ü 替换为 v，用 `replace_all` 对齐源库替换所有匹配语义）
   - 转为字符数组 `original_char_array = original_pinyin.to_array()`
   - `has_marked_char = false`（**每音节开始时初始化为 `false`**）
   - 逐字符 `j in 0..<original_char_array.length()`：若 `original_char_array[j] < 'a' || original_char_array[j] > 'z'`（非 ASCII 小写字母，即带调元音等；**MoonBit `Char` 实现 `Compare` trait，支持 `<` / `>` 运算符，已验证**）：
     - `index_in_all_marked = find_array_key_by_value(original_char_array[j])`
     - `tone_number = index_in_all_marked % 4 + 1`
     - `replace_char = all_unmarked_vowel_array[(index_in_all_marked - index_in_all_marked % 4) / 4]`
     - 替换 `original_char_array[j] = replace_char`
     - `pinyin_array[i] = String::from_array(original_char_array[:]) + tone_number.to_string()`（`String::from_array` 参数为 `ArrayView[Char]`，用 `[:]` 全切片将 `Array[Char]` 转为 `ArrayView[Char]`）
     - `has_marked_char = true`，`break`（每音节仅处理首个带调元音）
   - 若 `!has_marked_char`：`pinyin_array[i] = original_pinyin + "5"`（轻声用 5）
3. 返回 `pinyin_array`

**3. `convert_without_tone`**（源库 `pinyin_helper.cj:63-73`，技术方案 §6.3.2）

```moonbit
/// 带调拼音→无调拼音数组。对齐源库 convertWithoutTone。
pub(self) fn convert_without_tone(str : String) -> Array[String]
```

行为（逐字符替换对齐源库 `:63-73`）：
1. `s = str`
2. 遍历 `i in 0..<all_marked_vowel_array.length()`：
   - `original_char = all_marked_vowel_array[i]`
   - `replace_char = all_unmarked_vowel_array[(i - i % 4) / 4]`
   - `s = s.replace_all(old=original_char.to_string(), new=replace_char.to_string())`（**用 `replace_all` 替换所有匹配**，对齐源库 Cangjie `String.replace` 语义；MoonBit `String::replace` 只替换首个匹配，会导致多音节输入如 `"ā,á"` 只替换首个 `ā` 得到错误结果）
3. `s = s.replace_all(old="ü", new="v")`
4. 返回 `s.split(pinyin_separator[:]).map(fn(x) { x.to_owned() }).to_array()`（`split` 返回 `Iter[StringView]`，转为 `Array[String]`）

**4. `format_pinyin`**（源库 `pinyin_helper.cj:82-93`，技术方案 §6.3.3）

```moonbit
/// 按 PinyinFormat 分发格式转换。对齐源库 formatPinyin。
pub(self) fn format_pinyin(str : String, format : PinyinFormat) -> Array[String]
```

行为（用 `match format` 模式匹配，技术方案 §6.3.3 推荐优于源库字符串比较）：
- `WithToneMark` => `str.split(pinyin_separator[:]).map(fn(x) { x.to_owned() }).to_array()`（`split` 返回 `Iter[StringView]`，转为 `Array[String]`）
- `WithToneNumber` => `convert_with_tone_number(str)`
- `WithoutTone` => `convert_without_tone(str)`
- `FirstLetter` => `convert_without_tone(str)`

**5. `convert_to_pinyin_arrays`**（源库 `pinyin_helper.cj:117-123`，技术方案 §10.3）

```moonbit
/// 单字转拼音数组（查 pinyin_table，不区分首字母特殊处理）。对齐源库 convertToPinyinArrays。
pub(self) fn convert_to_pinyin_arrays(c : Char, format : PinyinFormat) -> Array[String]
```

行为（对齐源库 `:117-123`）：
1. `pinyin_array = []`
2. 若 `pinyin_table.get(c.to_string())` 返回 `Some(v)`：`pinyin_array = format_pinyin(v, format)`
3. 返回 `pinyin_array`（未命中字典返回空数组）

### 可见性决策

- `pinyin_separator`：`pub let`。理由：跨文件共享（R6 `pinyin_helper.mbt` 主流程亦用此分隔符）。`pub(self) let` 语法不合法（Error [3005]，R4 已验证），妥协为 `pub let` 公共常量暴露，同 R4 字典视图决策。
- `all_unmarked_vowel_array` / `all_marked_vowel_array`：`let`（文件内私有）。仅 `tone_conversion.mbt` 内 5 函数使用，无需跨文件暴露。
- 5 个函数：`pub(self) fn`（包内跨文件可见）。R6 `pinyin_helper.mbt` 需调用 `format_pinyin` / `convert_to_pinyin_arrays`。若 `pub(self) fn` 编译不通过，退用 `pub fn`（接受内部函数作为公开 API 暴露的妥协，同 `pinyin_separator` 的 `pub let` 妥协逻辑），并在实现报告中记录偏差。

### `tone_conversion_test.mbt` 测试要求

采用 `inspect(value, content="...")` snapshot 测试（技术方案 §8.4.1）。覆盖 5 函数核心行为与边界：

**`find_array_key_by_value`**：
- `find_array_key_by_value('ā')` => `0`（首个带调元音）
- `find_array_key_by_value('ǜ')` => `23`（末个带调元音）
- `find_array_key_by_value('a')` => `-1`（无调元音，不在带调数组）
- `find_array_key_by_value('x')` => `-1`（非元音）

**`convert_with_tone_number`**：
- `convert_with_tone_number("ā")` => `[a1]`（一声）
- `convert_with_tone_number("á")` => `[a2]`（二声）
- `convert_with_tone_number("ǎ")` => `[a3]`（三声）
- `convert_with_tone_number("à")` => `[a4]`（四声）
- `convert_with_tone_number("a")` => `[a5]`（无带调元音，轻声 5）
- `convert_with_tone_number("ā,á")` => `[a1, a2]`（多音节，分隔符切分）
- `convert_with_tone_number("lǜ")` => `[lv4]`（ü 替换为 v + 四声）

**`convert_without_tone`**：
- `convert_without_tone("ā")` => `[a]`
- `convert_without_tone("ā,á")` => `[a, a]`（多音节去调）
- `convert_without_tone("lǜ")` => `[lv]`（ü 替换为 v）

**`format_pinyin`**：
- `format_pinyin("ā", PinyinFormat::WithToneMark)` => `[ā]`（原样切分）
- `format_pinyin("ā", PinyinFormat::WithToneNumber)` => `[a1]`
- `format_pinyin("ā", PinyinFormat::WithoutTone)` => `[a]`
- `format_pinyin("ā", PinyinFormat::FirstLetter)` => `[a]`（FirstLetter 复用 convert_without_tone）

**`convert_to_pinyin_arrays`**：
- `convert_to_pinyin_arrays('一', PinyinFormat::WithToneMark)` => 查 `pinyin_table["一"]` = `"yī"`，`format_pinyin("yī", WithToneMark)` = `[yī]`
- `convert_to_pinyin_arrays('一', PinyinFormat::WithToneNumber)` => `[yi1]`
- `convert_to_pinyin_arrays('x', PinyinFormat::WithToneMark)` => `[]`（非汉字，字典未命中）

**`inspect` 格式说明**：MoonBit `inspect` 对 `Array[String]` 的序列化格式为 `[元素1, 元素2, ...]`，元素直接用字符串内容，**不加引号、不加 `#` 前缀**（已验证：`["a","b"]` => `[a, b]`，`[]` => `[]`，`["yī"]` => `[yī]`）。空数组输出 `[]`。

### 验证命令

工作目录：`D:\CodeWorkspace\forMoonbit\pinyin`

```sh
moon check
moon test
```

预期：
- `moon check` exit code 0，1 warning（`text_segment_excceed` 持续），0 errors
- `moon test` 全部通过（现有 42 + 新增 tone_conversion 用例）

## 选择理由

声调转换是拼音转换主流程（R6 `pinyin_helper.mbt`）的核心子逻辑。`format_pinyin` 被 `pinyin_helper.mbt` 的 `convert_to_pinyin_string` / `convert_to_pinyin_array` / `convert_to_pinyin_string_traditional` 等公开方法调用；`convert_to_pinyin_arrays` 被 `convert_to_pinyin_string` 主流程逐字符调用。按"底层优先"原则，在 R6 之前先实现声调转换内部函数，为 R6 提供可调用的包内函数。5 个函数紧密相关（均围绕带调元音处理与格式分发），合并为一个任务符合粒度约定（1-3 个紧密相关类型/函数组）。

## 任务上下文

摘录技术方案 `tech_v1.md` 与源库 `pinyin_helper.cj` 中与当前任务直接相关的需求/设计/约束：

### 技术方案 §6.3 声调格式转换算法

- **§6.3.1 `convert_with_tone_number`**：扫描音节字符，遇 24 带调元音之一则 `tone_number = index % 4 + 1`，`replace_char = ALL_UNMARKED_VOWEL_ARRAY[(index - index%4) / 4]`，替换并追加声调数字。未遇带调元音则追加 `"5"`（轻声）。`ü` 替换为 `v`。
- **§6.3.2 `convert_without_tone`**：24 带调元音逐字符替换为对应无调元音：`ALL_MARKED_VOWEL_ARRAY[i]` → `ALL_UNMARKED_VOWEL_ARRAY[(i - i%4) / 4]`。最后 `ü` 替换为 `v`，按 `PINYIN_SEPARATOR` 分割返回数组。
- **§6.3.3 `format_pinyin`**：按 `PinyinFormat` 分支：`WithToneMark` → 直接分割；`WithToneNumber` → `convert_with_tone_number`；`WithoutTone` / `FirstLetter` → `convert_without_tone`。**推荐用 `match format` 模式匹配**（更地道，语义等价），亦可保留字符串比较对齐源库。
- **§6.3.4 `find_array_key_by_value`**：遍历 `ALL_MARKED_VOWEL_ARRAY` 找匹配字符，返回索引或 -1。技术方案原文推荐 `ALL_MARKED_VOWEL_ARRAY.iter().position(|c| c == ch)` 或显式循环。**修订注记（v6 r1）**：经 `moon ide doc` 验证 MoonBit `Iter` 无 `position` 方法，此推荐前半已失效，本任务采用显式循环（见上文行为描述）。

### 技术方案 §4.3 辅助常量

| 常量 | 源库 | MoonBit | 说明 |
|------|------|---------|------|
| `PINYIN_SEPARATOR` | `var = ","` | `let = ","` | 拼音分隔符（不可变） |
| `ALL_UNMARKED_VOWEL_ARRAY` | `Array<Rune>` (6) | `Array[Char]` (6) | 无调元音 `[a,e,i,o,u,v]` |
| `ALL_MARKED_VOWEL_ARRAY` | `Array<Rune>` (24) | `Array[Char]` (24) | 带调元音 `[ā,á,ǎ,à,...]` |

### 技术方案 §10.3 内部方法映射

| 源库内部方法 | 源码位置 | MoonBit 文件 | MoonBit 方法名 |
|------------|---------|------------|--------------|
| `convertWithToneNumber` | pinyin_helper.cj:29 | `tone_conversion.mbt` | `convert_with_tone_number` |
| `convertWithoutTone` | pinyin_helper.cj:63 | `tone_conversion.mbt` | `convert_without_tone` |
| `formatPinyin` | pinyin_helper.cj:82 | `tone_conversion.mbt` | `format_pinyin` |
| `convertToPinyinArrays` | pinyin_helper.cj:117 | `tone_conversion.mbt` | `convert_to_pinyin_arrays` |
| `findArrayKeyByValue` | pinyin_helper.cj:279 | `tone_conversion.mbt` | `find_array_key_by_value` |

### 源库 `pinyin_helper.cj:13-16` 辅助常量定义

```cangjie
var PINYIN_SEPARATOR = ","
let ALL_UNMARKED_VOWEL_ARRAY: Array<Rune> = [r'a', r'e', r'i', r'o', r'u', r'v']
let ALL_MARKED_VOWEL_ARRAY: Array<Rune> = [r'ā', r'á', r'ǎ', r'à', r'ē', r'é', r'ě', r'è', r'ī', r'í', r'ǐ', r'ì', r'ō', r'ó', r'ǒ', r'ò', r'ū', r'ú', r'ǔ', r'ù', r'ǖ', r'ǘ', r'ǚ', r'ǜ']
```

### 源库 `pinyin_helper.cj:29-123` + `:279-289` 函数实现（逐行对齐参考）

详见源库文件。关键语义点：
- `convertWithToneNumber`（`:29-55`）：每音节仅处理**首个**带调元音（`break`），未找到带调元音则追加 `"5"`
- `convertWithoutTone`（`:63-73`）：逐字符替换所有带调元音，最后 `ü`→`v`
- `formatPinyin`（`:82-93`）：源库用 `format.getName() == "WITH_TONE_MARK"` 字符串比较分发，MoonBit 推荐 `match format` 模式匹配
- `convertToPinyinArrays`（`:117-123`）：查 `PINYIN_TABLE.get(c.toString())`，命中则 `formatPinyin(v, format)`，未命中返回空数组
- `findArrayKeyByValue`（`:279-289`）：遍历 `ALL_MARKED_VOWEL_ARRAY` 找匹配，返回索引或 -1

### 命名映射

| 源库 | MoonBit |
|------|---------|
| `PINYIN_SEPARATOR` | `pinyin_separator` |
| `ALL_UNMARKED_VOWEL_ARRAY` | `all_unmarked_vowel_array` |
| `ALL_MARKED_VOWEL_ARRAY` | `all_marked_vowel_array` |
| `convertWithToneNumber` | `convert_with_tone_number` |
| `convertWithoutTone` | `convert_without_tone` |
| `formatPinyin` | `format_pinyin` |
| `convertToPinyinArrays` | `convert_to_pinyin_arrays` |
| `findArrayKeyByValue` | `find_array_key_by_value` |

### 约束

- **语义保真**：5 函数行为逐音节/逐字符对齐源库，不得改变算法语义（如 `convert_with_tone_number` 每音节仅处理首个带调元音的 `break` 行为必须保留）
- **`format_pinyin` 分发方式**：优先 `match format` 模式匹配（技术方案推荐），不强制字符串比较
- **可见性**：`pinyin_separator` 用 `pub let`（跨文件共享）；`all_*_vowel_array` 用 `let`（文件内私有）；5 函数用 `pub(self) fn`（包内跨文件可见），若不支持退用 `pub fn`
- **不修改**任何已有文件（R1/R2/R3 v4/R4 产出保持不变）
- **`text_segment_excceed` 警告**持续存在（`data/pinyin_dict.mbt` 超 16384 行，本任务不处理）
- 代码包含必要的注释和文档（落实用户偏好）

## 已有代码上下文

R1-R4 已建立的项目骨架与基础依赖：

### 项目结构（当前状态）

```
D:\CodeWorkspace\forMoonbit\pinyin\
├── moon.mod                          # R1: name=pinyin/pinyin, license=MIT
├── moon.pkg                          # R1: import { "pinyin/pinyin/data" }
├── README.mbt.md                     # R1: 占位
├── pinyin_format.mbt                 # R2: pub(all) enum PinyinFormat + name 方法
├── pinyin_format_test.mbt            # R2: 5 用例
├── pinyin_error.mbt                  # R2: pub(all) suberror PinyinError
├── pinyin_error_test.mbt             # R2: 3 用例
├── pinyin_dicts.mbt                  # R4: 4 个 pub let 字典视图常量
├── pinyin_dicts_test.mbt             # R4: 16 用例
├── chinese_dict_test.mbt             # R3: 字典完整性测试
├── mutil_pinyin_dict_test.mbt        # R3
├── pinyin_dict_test.mbt              # R3
├── tongyong_pinyin_dict_test.mbt     # R3
├── data/
│   ├── moon.pkg                      # R1: 纯数据包零依赖
│   ├── chinese_dict.mbt              # R3: pub let chinese_dict : Map[Int, Int] (2533 条)
│   ├── mutil_pinyin_dict.mbt         # R3: pub let mutil_pinyin_dict : Map[String, String] (843 条)
│   ├── tongyong_pinyin_dict.mbt      # R3: pub let tongyong_pinyin_dict : Map[String, String] (82 条)
│   ├── pinyin_dict.mbt               # R3: pub let pinyin_dict : Map[String, String] (20903 条)
│   └── pkg.generated.mbti
└── scripts/
    └── gen_pinyin_dict.py            # R3: 生成脚本
```

### 本任务直接依赖的已有代码

**`pinyin_format.mbt`（R2 产出）**——`format_pinyin` 的参数类型：

```moonbit
pub(all) enum PinyinFormat {
  WithToneMark
  WithoutTone
  WithToneNumber
  FirstLetter
}

pub fn PinyinFormat::name(self : PinyinFormat) -> String {
  match self {
    WithToneMark => "WITH_TONE_MARK"
    WithoutTone => "WITHOUT_TONE"
    WithToneNumber => "WITH_TONE_NUMBER"
    FirstLetter => "FIRST_LETTER"
  }
}
```

**`pinyin_dicts.mbt`（R4 产出）**——`convert_to_pinyin_arrays` 查字典依赖：

```moonbit
pub let chinese_map : Map[Int, Int] = @data.chinese_dict
pub let pinyin_table : Map[String, String] = @data.pinyin_dict
pub let mutil_pinyin_table : Map[String, String] = @data.mutil_pinyin_dict
pub let tongyong_pinyin_table : Map[String, String] = @data.tongyong_pinyin_dict
```

`convert_to_pinyin_arrays` 通过 `pinyin_table.get(c.to_string())` 查单字拼音。

### 当前编译/测试状态

- `moon check` exit code 0，1 warning（`text_segment_excceed`，`data/pinyin_dict.mbt` 超 16384 行），0 errors
- `moon test` Total 42, passed 42, failed 0
- `unused_package` 警告已消除（R4 解决）

### MoonBit API 提示（均已用 `moon ide doc` 验证，moon 0.1.20260713）

**字符串操作**：
- `pub fn String::split(String, StringView) -> Iter[StringView]`：按分隔符切分字符串，返回**惰性迭代器**（非 `Array[String]`）。需 `.map(fn(x) { x.to_owned() }).to_array()` 转为 `Array[String]`。`String` 参数用 `sep[:]` 全切片适配 `StringView`。
- `pub fn String::replace(String, old~ : StringView, new~ : StringView) -> String`：**只替换首个匹配**，命名参数调用 `s.replace(old=..., new=...)`。本任务**不使用**（语义与源库不符）。
- `pub fn String::replace_all(String, old~ : StringView, new~ : StringView) -> String`：**替换所有非重叠匹配**，命名参数调用 `s.replace_all(old=..., new=...)`。本任务 `convert_without_tone` 用此 API 对齐源库 Cangjie `String.replace` 替换所有匹配语义。
- `pub fn String::to_array(String) -> Array[Char]`：字符串转字符数组（对应源库 `toRuneArray()`）
- `pub fn String::from_array(ArrayView[Char]) -> String`：字符数组转字符串。参数是 `ArrayView[Char]`（非 `Array[Char]`），用 `arr[:]` 全切片转换：`String::from_array(arr[:])`。

**字符操作**：
- `pub fn Char::to_string(Char) -> String`：字符转字符串
- `pub fn Char::to_int(Char) -> Int`：字符转 Unicode 码点
- `Char` 实现 `Compare` trait（`pub impl Compare for Char`），支持 `<` / `>` / `<=` / `>=` 运算符，可直接写 `ch < 'a' || ch > 'z'`（已验证编译通过）。

**数组/迭代器操作**：
- `pub fn[T] Array::iter(Self[T]) -> Iter[T]`：数组转迭代器
- `pub fn[X] Iter::to_array(Self[X]) -> Array[X]`：迭代器收集为数组
- `pub fn[X, Y] Iter::map(Self[X], (X) -> Y) -> Self[Y]`：迭代器映射（链式调用中闭包用 `fn(x) { ... }` 写法，`|x| ...` 短语法在链式调用中会解析失败）
- `pub fn StringView::to_owned(Self) -> String`：`StringView` 转为拥有所有权的 `String`
- `pub fn[T] Array[T].length() -> Int`：数组长度
- **查找索引**：MoonBit `Iter` 无 `position` 方法，`find_first` 返回元素而非索引。`find_array_key_by_value` 用显式循环 `for i in 0..<arr.length() { if arr[i] == ch { return i } }` 对齐源库 `:279-289` 写法。

**映射操作**：
- `pub fn Map[K].get(key : K) -> Option[V]`：映射查找

**`ArrayView` 切片语法**：
- `arr[:]`：全切片，将 `Array[T]` 转为 `ArrayView[T]`（零拷贝视图）
- `arr[start:end]`：区间切片，如 `arr[1:4]`

---

## 修订说明（v6 r1）

本修订响应 `plan_review_v6_r1.md` 的 7 项发现（4 严重 / 1 一般 / 2 轻微），所有 API 均用 `moon ide doc`（moon 0.1.20260713）重新验证，并编写临时探针测试 `_tmp_api_probe.mbt` 实测编译与 `inspect` 输出格式后删除。

| 审查意见 | 修改措施 |
|---------|---------|
| **[严重] 发现 1**：`String::from_char_array` 不存在，实际 `String::from_array(ArrayView[Char])` 参数是 `ArrayView[Char]` 不是 `Array[Char]` | 行为描述 `:65` 改为 `String::from_array(original_char_array[:])`，用 `[:]` 全切片将 `Array[Char]` 转为 `ArrayView[Char]`。API 提示表更新为验证后的 `pub fn String::from_array(ArrayView[Char]) -> String`，补充 `arr[:]` 切片语法说明。 |
| **[严重] 发现 2**：`String::split` 返回 `Iter[StringView]` 非 `Array[String]`，三个函数依赖索引访问/赋值会编译失败 | 行为描述中所有 `str.split(pinyin_separator)` 改为 `str.split(pinyin_separator[:]).map(fn(x) { x.to_owned() }).to_array()`，明确 `Iter[StringView]` → `Array[String]` 转换链。API 提示表更新为 `pub fn String::split(String, StringView) -> Iter[StringView]`，补充 `StringView::to_owned` / `Iter::to_array` / `Iter::map` 转换 API，说明 `String` → `StringView` 用 `sep[:]` 适配，并提示链式调用闭包须用 `fn(x) { ... }` 写法（`\|x\| ...` 短语法在链式调用中解析失败）。 |
| **[严重] 发现 3**：`String::replace` 只替换首个匹配 + 签名错误（命名参数 `old~`/`new~`，类型 `StringView`），`convert_without_tone` 需替换所有匹配 | 行为描述 `:82-83` 改为 `s.replace_all(old=..., new=...)`。API 提示表区分 `String::replace`（只替换首个，本任务不使用）与 `String::replace_all`（替换所有，本任务使用），均标注命名参数调用方式与 `StringView` 参数类型。 |
| **[严重] 发现 4**：`Array::iter().position()` 不存在，MoonBit `Iter` 无 `position` 方法 | `find_array_key_by_value` 行为描述改为显式循环 `for i in 0..<all_marked_vowel_array.length() { if all_marked_vowel_array[i] == ch { return i } }` 对齐源库 `:279-289`。API 提示表删除 `position` 条目，补充"查找索引"说明（`Iter` 无 `position`，`find_first` 返回元素非索引，用显式循环）。 |
| **[一般] 发现 5**：`Char` 比较运算符 `<` / `>` 未确认 | 用 `moon ide doc "Char"` 验证 `pub impl Compare for Char`，编写探针实测 `'ā' < 'a' \|\| 'ā' > 'z'` 编译通过。行为描述保留 `original_char_array[j] < 'a' \|\| original_char_array[j] > 'z'` 写法，API 提示表补充 `Char` 实现 `Compare` trait 说明。 |
| **[轻微] 发现 6**：`inspect` 对 `Array[String]` 输出格式未说明 | 编写探针实测 `inspect` 格式：`["a","b"]` => `[a, b]`，`[]` => `[]`，`["yī"]` => `[yī]`（元素无引号、无 `#` 前缀）。测试用例预期值全部改为正确格式（如 `["a1"]` → `[a1]`），并在测试要求末尾补充 `inspect` 格式说明段。 |
| **[轻微] 发现 7**：`has_marked_char` 初始化与循环范围未明确 | `convert_with_tone_number` 行为描述明确：每音节开始时 `has_marked_char = false` 初始化；逐字符循环范围 `j in 0..<original_char_array.length()`；逐音节循环范围 `i in 0..<pinyin_array.length()`。 |