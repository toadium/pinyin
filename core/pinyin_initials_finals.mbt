///|
/// 声母列表（按长度降序排列，确保双字母声母优先匹配）
pub let initials_list : Array[String] = [
  "zh", "ch", "sh", "b", "p", "m", "f", "d", "t", "n", "l", "g", "k", "h", "j", "q",
  "x", "r", "z", "c", "s", "y", "w",
]

///|
/// 提取拼音音节的声母。无调或带调拼音均可。
/// 返回声母字符串，无声母（零声母）返回空字符串。
/// 例如："zhong" → "zh", "ai" → "", "shuang" → "sh"
/// 空串抛 PinyinError。
pub fn get_initial(pinyin : String) -> String raise PinyinError {
  if pinyin.length() == 0 {
    raise_invalid_input("Pinyin syllable must not be empty")
  }
  let plain = strip_tone(pinyin)
  for initial in initials_list {
    if plain.has_prefix(initial) {
      return initial
    }
  }
  ""
}

///|
/// 提取拼音音节的韵母。无调或带调拼音均可。
/// 先去除声调标记，再去除声母，剩余部分即为韵母。
/// 例如："zhong" → "ong", "ai" → "ai", "shuang" → "uang"
/// 空串抛 PinyinError。
pub fn get_final(pinyin : String) -> String raise PinyinError {
  if pinyin.length() == 0 {
    raise_invalid_input("Pinyin syllable must not be empty")
  }
  let plain = strip_tone(pinyin)
  let initial = get_initial(pinyin)
  plain[initial.length():].to_owned()
}
