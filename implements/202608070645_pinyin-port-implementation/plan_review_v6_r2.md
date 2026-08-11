# 计划审查报告（v6 r2）

## 审查结果
APPROVED

## 发现

### 上一轮 r1 驳回的 7 项问题修订验证

逐项核对 task_v6.md §修订说明（v6 r1）与正文修订，并用探针实测（moon 0.1.20260713）：

1. **[已修正] 发现 1（`String::from_char_array` 不存在）**：行为描述 `:65` 改为 `String::from_array(original_char_array[:])`，API 提示 `:327` 更新为 `pub fn String::from_array(ArrayView[Char]) -> String` 并补充 `arr[:]` 切片语法。探针编译通过。
2. **[已修正] 发现 2（`String::split` 返回类型错误）**：三处 `split` 调用（`:65`/`:94`/`:104`）均补充 `.map(fn(x) { x.to_owned() }).to_array()` 转换链，`pinyin_separator` 用 `[:]` 适配 `StringView`。API 提示 `:323` 更新为 `pub fn String::split(String, StringView) -> Iter[StringView]`，补充 `StringView::to_owned` / `Iter::to_array` / `Iter::map` 转换 API 与闭包语法提示。探针编译通过。
3. **[已修正] 发现 3（`String::replace` 语义错误）**：`convert_with_tone_number` `:67` 与 `convert_without_tone` `:92-93` 均改为 `replace_all(old=, new=)`。API 提示 `:324-325` 区分 `String::replace`（只替换首个，不使用）与 `String::replace_all`（替换所有，使用）。探针实测 `convert_without_tone("ā,á")`=`[a, a]` 正确。
4. **[已修正] 发现 4（`position` 不存在）**：`find_array_key_by_value` `:48-54` 改为显式循环 `for i in 0..<all_marked_vowel_array.length()`。API 提示 `:340` 删除 `position` 条目，补充查找索引说明。探针编译通过。
5. **[已修正] 发现 5（`Char` 比较运算符未确认）**：行为描述 `:70` 保留 `original_char_array[j] < 'a' || original_char_array[j] > 'z'`，API 提示 `:332` 补充 `Char` 实现 `Compare` trait 说明。探针实测编译通过。
6. **[已修正] 发现 6（`inspect` 格式未说明）**：测试要求 `:162` 补充 `inspect` 格式说明段，测试预期值全部改为正确格式（`[a1]`/`[a1, a2]`/`[]`/`[yī]` 等）。探针实测 4 个 `inspect` 断言全部通过。
7. **[已修正] 发现 7（`has_marked_char` 初始化未明确）**：行为描述 `:69` 明确每音节 `has_marked_char = false` 初始化，`:66`/`:70` 明确循环范围 `0..<pinyin_array.length()` / `0..<original_char_array.length()`。

### 源库语义保真独立验证

读取源库 `D:\CodeWorkspace\forCangjie\pinyin4cj\src\pinyin_helper.cj` 逐行对比 task_v6.md 行为描述：

- **`convert_with_tone_number`**：task_v6.md `:64-78` 对齐源库 `:29-55`。每音节仅处理首个带调元音（`break`）、未找到追加 `"5"`、`ü`→`v` 替换在带调元音检测前。探针实测 8 用例（含 `lǜ`→`[lv4]`、`lü`→`[lv5]`）全部通过。
- **`convert_without_tone`**：task_v6.md `:87-94` 对齐源库 `:63-73`。先逐字符替换 24 带调元音（含 `ǖ/ǘ/ǚ/ǜ`→`v`），最后 `ü`→`v`，按分隔符切分返回。探针实测 4 用例全部通过。
- **`format_pinyin`**：task_v6.md `:99-107` 用 `match format` 模式匹配对齐源库 `:82-93` 字符串比较分发。**关键确认**：源库 `:89-90` 对 `FIRST_LETTER` 确实调用 `convertWithoutTone(str)`（首字母提取在更上层 `convertToPinyinArray` `:105-109` 处理），task_v6.md `:107` `FirstLetter => convert_without_tone(str)` 语义保真。
- **`convert_to_pinyin_arrays`**：task_v6.md `:112-119` 对齐源库 `:117-123`，查 `pinyin_table` 命中则 `format_pinyin`，未命中返回空数组，不区分首字母特殊处理。
- **`find_array_key_by_value`**：task_v6.md `:42-54` 显式循环对齐源库 `:279-289`。

### API 提示独立验证

编写临时探针 `_tmp_probe.mbt` 实测 task_v6.md §MoonBit API 提示中所有 API（编译 + 运行），结果：
- `String::from_array(ArrayView[Char])` + `arr[:]` 切片：✅
- `String::split(String, StringView) -> Iter[StringView]` + `.map(fn(x) { x.to_owned() }).to_array()` 转换链：✅
- `String::replace_all(old=, new=)` 替换所有匹配：✅
- `Char` 比较 `<`/`>`（`Compare` trait）：✅
- `inspect` 对 `Array[String]` 格式 `[元素1, 元素2, ...]`（无引号无 `#` 前缀）：✅
- 行为保真：`convert_with_tone_number("lǜ")`=`[lv4]`、`convert_with_tone_number("lü")`=`[lv5]`、`convert_without_tone("lǜ")`=`[lv]`、`convert_without_tone("lü")`=`[lv]`：✅

探针测试 46 passed / 0 failed（含原有 42 + 探针 4 test 块），清理后项目恢复 42 passed。

### 其他角度审查

- **测试覆盖**：5 函数共 21 用例，覆盖核心行为与边界（首/末带调元音、无调元音、非元音、4 声调、轻声 5、多音节、ü 替换、字典命中/未命中）。`format_pinyin` 的 `FirstLetter` 分支仅测单音节 `"ā"`=>`[a]`，未测多音节，但行为描述正确（源库 `:89-90` 确认 `FirstLetter` 复用 `convert_without_tone`），覆盖不足不影响正确性。
- **`convert_with_tone_number` 循环上界**：task_v6.md `:70` 用 `original_char_array.length()`，源库 `:37` 用 `originalPinyin.size`（UTF-8 字节数）。两者在 `break` 保护下行为等价（含带调元音的音节 `break` 前触发；纯 ASCII 音节字节数=字符数），task_v6.md 写法更健壮，不构成语义偏离。
- **不修改已有文件约束**：task_v6.md `:245` 明确不修改 R1/R2/R3 v4/R4 产出，仅新建 `tone_conversion.mbt` + `tone_conversion_test.mbt`，与 plan.md R5 任务边界一致。

### [轻微] 发现 8：`pub(self) fn` 可见性不合法，退路明确但可在计划阶段直接确定

task_v6.md `:125`/`:154`/`:244` 将 `pub(self) fn` 作为 5 个内部函数的可见性首选，退路为 `pub fn`。经探针实测：`pub(self) fn` 触发 **Error [3005]: No 'public self' visibility for function**，不合法。

task_v6.md 已明确预见此情况并给出退路（退用 `pub fn`，接受内部函数作为公开 API 暴露的妥协，同 `pinyin_separator` 的 `pub let` 妥协逻辑，并在实现报告中记录偏差），实现者不会卡住。

建议在计划阶段直接采用 `pub fn` 作为首选（5 行探针即可验证），避免实现阶段一次编译失败-回退迭代。不影响正确性，不影响后续环节推进。