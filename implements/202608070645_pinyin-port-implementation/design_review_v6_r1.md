# 设计审查报告（v6 r1）

## 审查结果
REJECTED

## 发现

### [严重] 发现 1：`convert_to_pinyin_arrays` 中 `let` 绑定重新赋值会编译失败

**位置**：detail_v6.md 第 298-305 行（文件内容契约 A 中的 `convert_to_pinyin_arrays` 实现）

```moonbit
pub(self) fn convert_to_pinyin_arrays(c : Char, format : PinyinFormat) -> Array[String] {
  let pinyin_array : Array[String] = []
  match pinyin_table.get(c.to_string()) {
    Some(v) => pinyin_array = format_pinyin(v, format)
    None => ()
  }
  return pinyin_array
}
```

`pinyin_array` 声明为 `let`（不可变绑定），但在 `Some(v)` 分支中 `pinyin_array = format_pinyin(v, format)` 是对变量的重新赋值（非数组元素赋值）。MoonBit 编译器报 **Error [4087]** `The variable pinyin_array is not mutable.`。

**实测确认**：编写探针 `let arr : Array[String] = []; match 1 { 1 => arr = ["a"] _ => () }`，`moon check` 报 `Error [4087] The variable arr is not mutable.`，编译失败。

**对比**：同文件中 `convert_with_tone_number` 的 `pinyin_array[i] = ...` 是数组元素赋值（`Array[T]` 是可变容器，元素赋值合法，`let` 绑定可接受），不会触发此错误。但 `convert_to_pinyin_arrays` 中 `pinyin_array = format_pinyin(v, format)` 是整个变量重新指向新数组，必须用 `let mut`。

---

### [一般] 发现 2：`not(has_marked_char)` 使用弃用函数，产生 deprecation warning

**位置**：detail_v6.md 第 265 行（`convert_with_tone_number` 实现）

```moonbit
if not(has_marked_char) {
```

MoonBit `not()` 函数已弃用。**实测确认**：`moon check` 对 `not(b)` 报 `Warning (deprecated): Use !expr instead`。

此弃用警告会使 `moon check` 产生额外 warning，与设计文档验证契约（第 477-484 行）声称的"**1 warning**（仅 `text_segment_excceed`），0 errors"不符，且违反用户偏好"不忽略任何警告"（requirement.md 第 39 行）。

---

### [一般] 发现 3：`inspect(Array[String])` 产生 deprecation warning，验证契约 warning 数量预期错误

**位置**：detail_v6.md 第 371-372 行（`inspect` 格式说明）+ 第 477-484 行（验证契约 E）

设计文档用 `inspect(value, content="...")` 对 `Array[String]` 做快照测试。**实测确认**：`inspect` 对 `Array[String]` 类型会产生 `Warning (deprecated): Use Debug instead of Show for debugging purposes`；而对 `Int` 和 `String` 类型不产生此 warning（现有项目 29 个 `inspect` 调用均为 `Int`/`String` 类型，故当前仅 1 warning）。

21 个测试用例中，**17 个**用 `inspect(Array[String])`（7 个 `convert_with_tone_number` + 3 个 `convert_without_tone` + 4 个 `format_pinyin` + 3 个 `convert_to_pinyin_arrays`），会产生 17 个 deprecation warning。加上 1 个 `text_segment_excceed`，**总计 18 warnings**。

设计文档验证契约（第 477-484 行）声称"**1 warning**（`text_segment_excceed`），0 errors"，实际会有 18 warnings。验证契约与实际严重不符，违反用户偏好"不忽略任何警告"。

**可选修正路径**（经探针实测验证）：
- MoonBit 提供 `debug_inspect(&Debug, ...)`（基于 `Debug` trait，不产生 deprecation warning）
- 但 `debug_inspect` 对 `Array[String]` 输出格式与 `inspect` **不同**：`inspect(["a1","a2"])` => `[a1, a2]`（元素无引号），`debug_inspect(["a1","a2"])` => `["a1", "a2"]`（元素有引号）；空数组 `[]` 两者一致

## 修改要求

### 发现 1（严重）：`let` 绑定重新赋值

**问题**：`convert_to_pinyin_arrays` 中 `let pinyin_array` 在 `match` 分支内被重新赋值 `pinyin_array = format_pinyin(v, format)`，MoonBit 不允许对 `let` 绑定重新赋值，编译报 Error [4087]。

**为什么是问题**：设计文档的文件内容契约 A 直接给出了会编译失败的代码，实现者照抄将无法通过 `moon check`，违背验收标准"moon check 通过"（requirement.md 第 44 行）。

**期望修正方向**：将 `let pinyin_array : Array[String] = []` 改为 `let mut pinyin_array : Array[String] = []`，使其成为可变绑定，允许在 `match` 分支内重新赋值。

### 发现 2（一般）：`not()` 弃用函数

**问题**：`not(has_marked_char)` 使用已弃用的 `not()` 函数，产生 deprecation warning。

**为什么是问题**：设计文档验证契约预期"1 warning"，实际会有 2 warnings（`text_segment_excceed` + `not` 弃用），验证契约与实际不符；且用户明确偏好"不忽略任何警告"（requirement.md 第 39 行），引入可避免的弃用警告违背此偏好。

**期望修正方向**：将 `if not(has_marked_char) {` 改为 `if !has_marked_char {`，使用 `!` 运算符（`Bool::op_not`），不产生弃用警告。

### 发现 3（一般）：`inspect(Array[String])` 弃用 warning + 验证契约错误

**问题**：17 个 `inspect(Array[String])` 调用各产生 1 个 deprecation warning，总计 18 warnings，与验证契约声称的"1 warning"严重不符。

**为什么是问题**：验证契约是实现者判断"是否完成"的依据。若实现者照抄设计，`moon check` 会输出 18 warnings 而非预期的 1 warning，实现者可能误判为引入了意外问题而回退修改，或忽略验证契约直接提交——无论哪种都偏离设计意图。同时违反用户偏好"不忽略任何警告"。

**期望修正方向**（推荐方案 A，彻底消除警告）：
- **方案 A**：将 17 个 `Array[String]` 测试用例的 `inspect` 改为 `debug_inspect`（基于 `Debug` trait，不产生 deprecation warning）；同步修改测试预期值格式——`[a1, a2]` => `["a1", "a2"]`，`[yī]` => `["yī"]`，`[]` => `[]`（不变）；4 个 `find_array_key_by_value` 的 `inspect(Int)` 可保留 `inspect` 或统一改为 `debug_inspect`（`Int` 输出格式一致）。更新 `inspect` 格式说明段（第 371-372 行）为 `debug_inspect` 格式说明。验证契约 warning 数量保持"1 warning"。
- **方案 B**（不推荐）：保留 `inspect`，将验证契约 warning 数量从 1 更正为 18。但这违反用户偏好"不忽略任何警告"，且 17 个弃用警告本质是技术债。