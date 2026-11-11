///|
/// 拼音分隔符，对齐源库 PINYIN_SEPARATOR。pub let 跨文件共享。
pub let pinyin_separator : String = ","

///|
/// 无调元音数组，对齐源库 ALL_UNMARKED_VOWEL_ARRAY。
pub let all_unmarked_vowel_array : Array[Char] = ['a', 'e', 'i', 'o', 'u', 'v']

///|
/// 带调元音数组，对齐源库 ALL_MARKED_VOWEL_ARRAY（24 个，6 元音 × 4 声调）。
pub let all_marked_vowel_array : Array[Char] = [
  'ā', 'á', 'ǎ', 'à', 'ē', 'é', 'ě', 'è', 'ī', 'í', 'ǐ', 'ì', 'ō', 'ó',
  'ǒ', 'ò', 'ū', 'ú', 'ǔ', 'ù', 'ǖ', 'ǘ', 'ǚ', 'ǜ',
]

///|
/// 汉字零（U+3007），对齐源库 CHINESE_LING。is_chinese 将其视为汉字。
pub let chinese_ling : Char = '〇'

///|
/// 在带调元音数组中查找字符索引，未找到返回 -1。对齐源库 findArrayKeyByValue。
pub fn find_array_key_by_value(ch : Char) -> Int32 {
  for i in 0..<all_marked_vowel_array.length() {
    if all_marked_vowel_array[i] == ch {
      return i
    }
  }
  -1
}

///|
/// 去除单个拼音音节的声调标记，返回无调拼音。
/// 带调元音 → 无调元音，ü → v。
pub fn strip_tone(pinyin : String) -> String {
  let mut s = pinyin
  for i in 0..<all_marked_vowel_array.length() {
    let original_char = all_marked_vowel_array[i]
    let replace_char = all_unmarked_vowel_array[(i - i % 4) / 4]
    s = s.replace_all(
      old=original_char.to_string(),
      new=replace_char.to_string(),
    )
  }
  s.replace_all(old="ü", new="v")
}

///|
/// 去除数字声调后缀（如 "zhong1" → "zhong"），返回无调无数字拼音。
pub fn strip_tone_number(pinyin : String) -> String {
  let chars = pinyin.to_array()
  if chars.length() > 0 {
    let last = chars[chars.length() - 1]
    if last >= '0' && last <= '5' {
      return pinyin[:pinyin.length() - 1].to_owned()
    }
  }
  pinyin
}

///|
/// 带调拼音→数字调拼音数组。对齐源库 convertWithToneNumber。
/// 每音节仅处理首个带调元音，未找到带调元音则追加 "5"（轻声）。ü 替换为 v。
pub fn convert_with_tone_number(str : String) -> Array[String] {
  let pinyin_array = str
    .split(pinyin_separator[:])
    .map(fn(x) { x.to_owned() })
    .to_array()
  for i in 0..<pinyin_array.length() {
    let original_pinyin = pinyin_array[i].replace_all(old="ü", new="v")
    let original_char_array = original_pinyin.to_array()
    let mut has_marked_char = false
    for j in 0..<original_char_array.length() {
      let ch = original_char_array[j]
      if ch < 'a' || ch > 'z' {
        let index_in_all_marked = find_array_key_by_value(ch)
        if index_in_all_marked >= 0 {
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
    }
    if !has_marked_char {
      pinyin_array[i] = original_pinyin + "5"
    }
  }
  pinyin_array
}

///|
/// 带调拼音→无调拼音数组。对齐源库 convertWithoutTone。
/// 逐字符替换所有带调元音为对应无调元音，最后 ü 替换为 v。
pub fn convert_without_tone(str : String) -> Array[String] {
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
/// 按 PinyinFormat 分发格式转换。对齐源库 formatPinyin。
/// 用 match 模式匹配（技术方案推荐，比源库字符串比较更地道）。
pub fn format_pinyin(str : String, format : PinyinFormat) -> Array[String] {
  match format {
    WithToneMark =>
      str.split(pinyin_separator[:]).map(fn(x) { x.to_owned() }).to_array()
    WithToneNumber => convert_with_tone_number(str)
    WithoutTone => convert_without_tone(str)
    FirstLetter => convert_without_tone(str)
  }
}

///|
/// 从带调拼音中提取声调数字 (1-4)，无调或轻声返回 0。
pub fn get_tone_number(pinyin : String) -> Int32 {
  let chars = pinyin.to_array()
  for ch in chars {
    let idx = find_array_key_by_value(ch)
    if idx >= 0 {
      return idx % 4 + 1
    }
  }
  if chars.length() > 0 {
    let last = chars[chars.length() - 1]
    if last >= '1' && last <= '4' {
      return last.to_int() - '0'.to_int()
    }
  }
  0
}

///|
/// 判断字符是否为元音（a, e, i, o, u, v）。
pub fn is_vowel_char(ch : Char) -> Bool {
  ch == 'a' || ch == 'e' || ch == 'i' || ch == 'o' || ch == 'u' || ch == 'v'
}

///|
/// 将无调拼音 + 声调数字 → 带调拼音。
/// 声调标记位置遵循汉语拼音规则：a > e > o > iu(ui标在后) > 最后元音。
pub fn set_tone(pinyin_without_tone : String, tone : Int32) -> String {
  if tone < 1 || tone > 4 {
    return pinyin_without_tone
  }
  let chars = pinyin_without_tone.to_array()
  let n = chars.length()
  let mut tone_pos = -1
  for i in 0..<n {
    if chars[i] == 'a' {
      tone_pos = i
      break
    }
  }
  if tone_pos == -1 {
    for i in 0..<n {
      if chars[i] == 'e' {
        tone_pos = i
        break
      }
    }
  }
  if tone_pos == -1 {
    for i in 0..<n {
      if chars[i] == 'o' {
        tone_pos = i
        break
      }
    }
  }
  if tone_pos == -1 {
    for i in 0..<(n - 1) {
      if chars[i] == 'i' && chars[i + 1] == 'u' {
        tone_pos = i + 1
        break
      }
    }
  }
  if tone_pos == -1 {
    for i in 0..<(n - 1) {
      if chars[i] == 'u' && chars[i + 1] == 'i' {
        tone_pos = i + 1
        break
      }
    }
  }
  if tone_pos == -1 {
    let mut i = n - 1
    while i >= 0 {
      if is_vowel_char(chars[i]) {
        tone_pos = i
        break
      }
      i -= 1
    }
  }
  if tone_pos == -1 {
    return pinyin_without_tone
  }
  let vowel = chars[tone_pos]
  let mut vowel_idx = -1
  for i in 0..<all_unmarked_vowel_array.length() {
    if all_unmarked_vowel_array[i] == vowel {
      vowel_idx = i
      break
    }
  }
  if vowel_idx == -1 {
    return pinyin_without_tone
  }
  chars[tone_pos] = all_marked_vowel_array[vowel_idx * 4 + tone - 1]
  for i in 0..<chars.length() {
    if chars[i] == 'v' {
      chars[i] = 'ü'
    }
  }
  String::from_array(chars[:])
}
