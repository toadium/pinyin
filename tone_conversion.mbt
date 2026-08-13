///|
/// 声调格式转换内部逻辑，对齐源库 pinyin4cj 的 `pinyin_helper.cj` 中 5 个 static 内部方法
/// 与 3 个辅助常量。供 `pinyin_helper.mbt` 主流程调用，不对外暴露。
///
/// 对应源库：
/// - `PINYIN_SEPARATOR`（`pinyin_helper.cj:13`）
/// - `ALL_UNMARKED_VOWEL_ARRAY` / `ALL_MARKED_VOWEL_ARRAY`（`pinyin_helper.cj:15-16`）
/// - `convertWithToneNumber`（`:29-55`）
/// - `convertWithoutTone`（`:63-73`）
/// - `formatPinyin`（`:82-93`）
/// - `convertToPinyinArrays`（`:117-123`，内部方法，无 FIRST_LETTER 特殊处理）
/// - `findArrayKeyByValue`（`:279-289`）

///|
/// 拼音分隔符，对齐源库 `PINYIN_SEPARATOR`。`pub let` 跨文件共享（`pinyin_helper.mbt` 亦用）。
pub let pinyin_separator : String = ","

///|
/// 无调元音数组，对齐源库 `ALL_UNMARKED_VOWEL_ARRAY`。文件内私有。
let all_unmarked_vowel_array : Array[Char] = ['a', 'e', 'i', 'o', 'u', 'v']

///|
/// 带调元音数组，对齐源库 `ALL_MARKED_VOWEL_ARRAY`（24 个，6 元音 × 4 声调）。文件内私有。
let all_marked_vowel_array : Array[Char] = [
  'ā', 'á', 'ǎ', 'à', 'ē', 'é', 'ě', 'è', 'ī', 'í', 'ǐ', 'ì', 'ō', 'ó',
  'ǒ', 'ò', 'ū', 'ú', 'ǔ', 'ù', 'ǖ', 'ǘ', 'ǚ', 'ǜ',
]

///|
/// 在带调元音数组中查找字符索引，未找到返回 -1。对齐源库 `findArrayKeyByValue`。
///
/// 用显式循环对齐源库 `:279-289` 写法（MoonBit 标准库 `Iter` 无 `position` 方法）。
fn find_array_key_by_value(ch : Char) -> Int {
  for i in 0..<all_marked_vowel_array.length() {
    if all_marked_vowel_array[i] == ch {
      return i
    }
  }
  -1
}

///|
/// 带调拼音→数字调拼音数组。对齐源库 `convertWithToneNumber`。
///
/// 逐音节扫描，遇 24 带调元音之一则计算声调数字并替换为无调元音 + 数字；
/// 每音节仅处理首个带调元音（`break`）；未遇带调元音则追加 `"5"`（轻声）；`ü` 替换为 `v`。
fn convert_with_tone_number(str : String) -> Array[String] {
  let pinyin_array = str
    .split(pinyin_separator[:])
    .map(fn(x) { x.to_owned() })
    .to_array()
  for i in 0..<pinyin_array.length() {
    let original_pinyin = pinyin_array[i].replace_all(old="ü", new="v")
    let original_char_array = original_pinyin.to_array()
    let mut has_marked_char = false
    for j in 0..<original_char_array.length() {
      let original_char = original_char_array[j]
      if original_char < 'a' || original_char > 'z' {
        let index_in_all_marked = find_array_key_by_value(original_char)
        let tone_number = index_in_all_marked % 4 + 1
        let replace_char = all_unmarked_vowel_array[(
            index_in_all_marked - index_in_all_marked % 4
          ) /
          4]
        original_char_array[j] = replace_char
        pinyin_array[i] = String::from_array(original_char_array[:]) +
          tone_number.to_string()
        has_marked_char = true
        break
      }
    }
    if !has_marked_char {
      pinyin_array[i] = original_pinyin + "5"
    }
  }
  pinyin_array
}

///|
/// 带调拼音→无调拼音数组。对齐源库 `convertWithoutTone`。
///
/// 24 带调元音逐字符替换为对应无调元音，最后 `ü`→`v`，按 `pinyin_separator` 分割返回数组。
fn convert_without_tone(str : String) -> Array[String] {
  let mut s = str
  for i in 0..<all_marked_vowel_array.length() {
    let original_char = all_marked_vowel_array[i]
    let replace_char = all_unmarked_vowel_array[(i - i % 4) / 4]
    s = s.replace_all(
      old=original_char.to_string(),
      new=replace_char.to_string(),
    )
  }
  s = s.replace_all(old="ü", new="v")
  s.split(pinyin_separator[:]).map(fn(x) { x.to_owned() }).to_array()
}

///|
/// 按 `PinyinFormat` 分发格式转换。对齐源库 `formatPinyin`。
///
/// 用 `match format` 模式匹配（技术方案 §6.3.3 推荐，语义等价于源库字符串比较）。
fn format_pinyin(str : String, format : PinyinFormat) -> Array[String] {
  match format {
    WithToneMark =>
      str.split(pinyin_separator[:]).map(fn(x) { x.to_owned() }).to_array()
    WithToneNumber => convert_with_tone_number(str)
    WithoutTone => convert_without_tone(str)
    FirstLetter => convert_without_tone(str)
  }
}

///|
/// 单字转拼音数组（查 `pinyin_table`，不区分首字母特殊处理）。对齐源库 `convertToPinyinArrays`。
///
/// 命中字典则 `format_pinyin(v, format)`，未命中返回空数组。
fn convert_to_pinyin_arrays(c : Char, format : PinyinFormat) -> Array[String] {
  let pinyin_array : Array[String] = []
  match pinyin_table.get(c.to_string()) {
    Some(v) => return format_pinyin(v, format)
    None => ()
  }
  pinyin_array
}
