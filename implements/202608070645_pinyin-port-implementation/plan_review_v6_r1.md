# 计划审查报告（v6 r1）

## 审查结果
REJECTED

## 发现

### [严重] 发现 1：`String::from_char_array` API 不存在，行为描述与 API 提示均使用错误 API 名

task_v6.md 在 `convert_with_tone_number` 行为描述（`:65`）中写 `pinyin_array[i] = String::from_char_array(original_char_array) + tone_number.to_string()`，并在 API 提示（`:318`）中写 `String::from_char_array(arr : Array[Char]) -> String`。

经 `moon ide doc "String::from_char_array"` 验证（moon 0.1.20260713）：**No results found**。MoonBit 标准库中不存在 `String::from_char_array`。

实际 API 为 `pub fn String::from_array(ArrayView[Char]) -> String`（`moonbitlang/core/string`），参数类型是 `ArrayView[Char]`，不是 `Array[Char]`。`original_char_array` 来自 `original_pinyin.to_array()`，返回 `Array[Char]`，与 `ArrayView[Char]` 不匹配。

task_v6.md 在 API 提示中标注了"需确认 MoonBit 标准库确切 API 名"，但行为描述中直接使用了未确认的 `String::from_char_array` 作为确定性伪代码，会误导实现者直接采用此 API 名导致编译失败。且即便改名为 `String::from_array`，`Array[Char]` → `ArrayView[Char]` 的类型转换路径也未说明。

### [严重] 发现 2：`String::split` 返回类型与参数类型均错误

task_v6.md 在 API 提示（`:310`）中写 `String::split(sep : String) -> Array[String]`。

经 `moon ide doc "String::split"` 验证：实际签名为 `pub fn String::split(String, StringView) -> Iter[StringView]`。

- 返回类型是 `Iter[StringView]`，不是 `Array[String]`。`Iter` 是惰性迭代器，不支持索引访问与索引赋值。
- 参数类型是 `StringView`，不是 `String`。

task_v6.md 的 `convert_with_tone_number`（`:56`）、`convert_without_tone`（`:84`）、`format_pinyin`（`:94`）三个函数均依赖 `str.split(pinyin_separator)` 并将结果当作 `Array[String]` 使用（如 `pinyin_array[i] = ...` 索引赋值、`pinyin_array[i].replace(...)` 索引读取）。实现者按 task_v6.md 描述写出 `let pinyin_array = str.split(pinyin_separator)` 后，`pinyin_array[i]` 编译失败（`Iter` 无索引访问），且 `pinyin_array[i] = ...` 编译失败（`Iter` 不可变）。

实现者需要额外步骤：将 `Iter[StringView]` 转为 `Array[String]`（如 `.map(|s| s.to_owned()).to_array()` 或等价写法），并将 `String` 类型的 `pinyin_separator` 适配为 `StringView`。task_v6.md 完全未提及这些转换。

### [严重] 发现 3：`String::replace` 语义与签名均错误，会导致 `convert_without_tone` 行为偏离源库

task_v6.md 在 API 提示（`:311`）中写 `String::replace(from : String, to : String) -> String`，描述为"字符串替换"。

经 `moon ide doc "String"` 验证：实际有两个方法：
- `pub fn String::replace(String, old~ : StringView, new~ : StringView) -> String` — **只替换第一个匹配**
- `pub fn String::replace_all(String, old~ : StringView, new~ : StringView) -> String` — 替换所有匹配

三重错误：
1. **签名错误**：参数是命名参数 `old~` / `new~`，类型是 `StringView`，不是位置参数 `from : String, to : String`。
2. **语义错误**：`String::replace` 只替换第一个匹配，而源库 Cangjie 的 `String.replace`（`pinyin_helper.cj:69`）替换所有匹配。`convert_without_tone` 需要逐字符替换所有带调元音（24 个），若用 `String::replace`，每个带调元音只替换首个出现，多音节输入（如 `"ā,á"`）会得到错误结果。
3. **API 选择错误**：应使用 `String::replace_all` 对齐源库语义。

task_v6.md 的 `convert_without_tone` 行为描述（`:82`）写 `s = s.replace(original_char.to_string(), replace_char.to_string())`，实现者按此写出 `s.replace(old=..., new=...)` 只替换首个匹配，违反"语义保真"约束（task_v6.md `:230` 明确要求"5 函数行为逐音节/逐字符对齐源库，不得改变算法语义"）。

### [严重] 发现 4：`Array::iter().position()` API 不存在

task_v6.md 在 API 提示（`:315`）中写 `Array::iter().position(|c| c == ch) -> Option[int]`，并在 `find_array_key_by_value` 行为描述（`:46`）中推荐 `all_marked_vowel_array.iter().position(|c| c == ch)`。

经 `moon ide doc "Iter"` 与 `moon ide doc "Array"` 验证：MoonBit 标准库中**不存在** `position` 方法。`Iter` 仅有 `find_first((X) -> Bool) -> X?`（返回元素而非索引）、`fold`、`each`、`eachi` 等。

实现者按 task_v6.md 描述写出 `all_marked_vowel_array.iter().position(|c| c == ch)` 会编译失败。需改用显式循环（源库 `:279-289` 的原始写法）或 `eachi` + 提前返回等模式。task_v6.md 虽提到"或保留显式循环"作为备选，但将不存在的 `position` API 作为首选推荐且写入 API 提示表，属于确定性错误。

### [一般] 发现 5：`Char` 比较运算符 `<` / `>` 未确认，行为描述直接使用

task_v6.md 在 `convert_with_tone_number` 行为描述（`:60`）中写 `若 original_char < 'a' || original_char > 'z'`，用于判断非 ASCII 小写字母。

源库 `pinyin_helper.cj:39` 用 `UInt32(originalChar) < UInt32(r'a') || UInt32(originalChar) > UInt32(r'z')` 比较。MoonBit 中 `Char` 类型是否支持 `<` / `>` 运算符未在 task_v6.md 中确认。API 提示（`:314`）列出了 `Char::to_int() -> Int`，但未说明在 `convert_with_tone_number` 中应如何用它构造比较表达式（如 `ch.to_int() < 'a'.to_int() || ch.to_int() > 'z'.to_int()`）。

实现者若直接写 `original_char < 'a'`，可能触发编译错误（取决于 MoonBit `Char` 是否实现 `Ord`），需回溯探索正确写法。

### [轻微] 发现 6：`inspect` 对 `Array[String]` 的输出格式未说明

测试用例（`:128-150`）使用 `["a1"]`、`["a1", "a2"]`、`["a"]`、`["a", "a"]`、`["lv"]`、`["lv4"]`、`["yī"]`、`["yi1"]`、`[]` 等格式作为 `inspect` 的 `content` 预期值。MoonBit `inspect` 对 `Array[String]` 的序列化格式（是否含引号、分隔符、`#[]` vs `[]` 等）未说明，实现者可能需反复试错调整 `content` 字符串。

### [轻微] 发现 7：`has_marked_char` 初始化与循环范围未明确

`convert_with_tone_number` 行为描述（`:57-67`）提到 `has_marked_char = true` 和 `若 !has_marked_char`，但未明确说明每个音节开始时 `has_marked_char` 初始化为 `false`。同样，"逐字符 `original_char_array[j]`"未明确循环范围 `0..<original_char_array.length()`。从上下文可推断，但作为实现规格不够精确。

## 修改要求（仅 REJECTED 时）

### 问题 1（`String::from_char_array` 不存在）

**问题**：行为描述与 API 提示使用了不存在的 `String::from_char_array`，且实际 `String::from_array` 参数类型是 `ArrayView[Char]` 不是 `Array[Char]`。

**为什么是问题**：实现者按描述写出 `String::from_char_array(original_char_array)` 会编译失败；即便改名为 `String::from_array`，`Array[Char]` → `ArrayView[Char]` 的转换路径也未说明，仍会卡住。

**期望修正方向**：
1. 用 `moon ide doc` 确认 `String::from_array` 的确切签名与 `Array[Char]` → `ArrayView[Char]` 的转换方式（可能需 `arr[: ]` 视图语法或 `Buffer` 替代方案）。
2. 在行为描述中用确认后的正确 API 替换 `String::from_char_array`，或在伪代码中标注"此处需将 `Array[Char]` 转为字符串，具体 API 实现者确认"。
3. 更新 API 提示表 `:318` 为经验证的正确签名。

### 问题 2（`String::split` 返回 `Iter[StringView]` 非 `Array[String]`）

**问题**：API 提示声称 `String::split(sep : String) -> Array[String]`，实际返回 `Iter[StringView]`，三个函数依赖索引访问与赋值会全部失败。

**为什么是问题**：`convert_with_tone_number` 需要对 `pinyin_array[i]` 索引赋值（`:65`），`convert_without_tone` 和 `format_pinyin` 需要返回 `Array[String]`。`Iter[StringView]` 既不支持索引也不可变，实现者按描述写出后编译失败，且无转换路径指引。

**期望修正方向**：
1. 在行为描述中明确 `str.split(pinyin_separator)` 返回 `Iter[StringView]`，需转为 `Array[String]`（如 `.map(|s| s.to_owned()).to_array()` 或等价写法），并说明 `StringView` → `String` 的转换方法（`to_owned` 或 `data`）。
2. 更新 API 提示表 `:310` 为 `pub fn String::split(String, StringView) -> Iter[StringView]`，并补充 `StringView::to_owned` / `Iter::to_array` 等转换 API。
3. 说明 `pinyin_separator : String` 如何适配 `StringView` 参数（隐式转换或显式 `.to_string_view()`）。

### 问题 3（`String::replace` 只替换首个匹配 + 签名错误）

**问题**：API 提示声称 `String::replace(from : String, to : String) -> String`，实际只替换第一个匹配且参数为命名参数 `old~` / `new~`。`convert_without_tone` 需替换所有匹配。

**为什么是问题**：源库 Cangjie `String.replace` 替换所有匹配，MoonBit `String::replace` 只替换首个。用 `String::replace` 会导致 `convert_without_tone("ā,á")` 得到 `["a,á"]`（只替换首个 `ā`）而非 `["a", "a"]`，违反语义保真约束。且签名错误导致编译失败。

**期望修正方向**：
1. 在 `convert_without_tone` 行为描述（`:82`）中明确使用 `String::replace_all`（替换所有匹配），对齐源库语义。
2. 更新 API 提示表 `:311` 为 `pub fn String::replace_all(String, old~ : StringView, new~ : StringView) -> String`，并说明命名参数调用方式（`s.replace_all(old=..., new=...)`）。
3. 补充 `String::replace`（只替换首个）与 `String::replace_all`（替换所有）的语义区别说明，避免实现者误选。

### 问题 4（`position` API 不存在）

**问题**：API 提示声称 `Array::iter().position(|c| c == ch) -> Option[int]`，MoonBit 中不存在 `position` 方法。

**为什么是问题**：实现者按描述写出 `all_marked_vowel_array.iter().position(|c| c == ch)` 会编译失败。

**期望修正方向**：
1. 删除 API 提示表 `:315` 中的 `position` 条目。
2. 在 `find_array_key_by_value` 行为描述中改为推荐显式循环（对齐源库 `:279-289` 写法），或用 `Iter::eachi` + 提前返回、或 `for i in 0..<arr.length()` + `if arr[i] == ch` 模式。
3. 若存在其他返回索引的 API（如 `StringView::find` 返回 `Int?`），可补充说明但需注意其适用范围。

### 问题 5（`Char` 比较运算符未确认）

**问题**：行为描述使用 `original_char < 'a' || original_char > 'z'`，未确认 MoonBit `Char` 是否支持 `<` / `>`。

**为什么是问题**：实现者可能写出编译失败的比较表达式，需回溯探索正确写法。

**期望修正方向**：
1. 用 `moon ide doc` 或小测试确认 MoonBit `Char` 是否支持 `<` / `>` 运算符。
2. 若不支持，在行为描述中改为 `ch.to_int() < 'a'.to_int() || ch.to_int() > 'z'.to_int()` 或等价写法。
3. 在 API 提示中补充 `Char::to_int` 的使用示例。