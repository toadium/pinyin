///|
/// ReversePinyinHelper 命名空间类型，提供拼音→汉字反向查找能力。
#warnings("-struct_never_constructed")
pub struct ReversePinyinHelper {}

///|
/// 反向拼音字典：无调拼音 → 汉字列表。
/// 从 pinyin_table 运行时构建，支持多音字（一个拼音对应多个汉字）。
pub let reverse_pinyin_table : Map[String, Array[String]] = {
  let result : Map[String, Array[String]] = Map([])
  for k, v in pinyin_table {
    let pinyin_array = v
      .split(pinyin_separator[:])
      .map(fn(x) { x.to_owned() })
      .to_array()
    for pinyin in pinyin_array {
      let without_tone = strip_tone(pinyin)
      match result.get(without_tone) {
        Some(arr) => arr.push(k)
        None => result[without_tone] = [k]
      }
    }
  }
  result
}

///|
/// 拼音→汉字反向查找。输入无调拼音（如 "zhong"），返回所有读该音的汉字。
/// 非拼音抛 PinyinError。
pub fn ReversePinyinHelper::reverse_lookup(
  pinyin : String,
) -> Array[String] raise PinyinError {
  if pinyin.length() == 0 {
    raise PinyinError("Please enter a pinyin syllable")
  }
  match reverse_pinyin_table.get(pinyin) {
    Some(arr) => arr.copy()
    None => []
  }
}

///|
/// 带调拼音→汉字反向查找。输入带调拼音（如 "zhōng"），返回所有读该音的汉字。
/// 自动去除声调标记后查找。非拼音抛 PinyinError。
pub fn ReversePinyinHelper::reverse_lookup_tone_mark(
  pinyin : String,
) -> Array[String] raise PinyinError {
  if pinyin.length() == 0 {
    raise PinyinError("Please enter a pinyin syllable")
  }
  let without_tone = strip_tone(pinyin)
  match reverse_pinyin_table.get(without_tone) {
    Some(arr) => arr.copy()
    None => []
  }
}

///|
/// 数字调拼音→汉字反向查找。输入数字调拼音（如 "zhong1"），返回所有读该音的汉字。
/// 自动去除数字后缀后查找。非拼音抛 PinyinError。
pub fn ReversePinyinHelper::reverse_lookup_tone_number(
  pinyin : String,
) -> Array[String] raise PinyinError {
  if pinyin.length() == 0 {
    raise PinyinError("Please enter a pinyin syllable")
  }
  let without_tone = strip_tone_number(pinyin)
  match reverse_pinyin_table.get(without_tone) {
    Some(arr) => arr.copy()
    None => []
  }
}

///|
/// 判断给定字符串是否为合法无调拼音音节。
pub fn ReversePinyinHelper::is_valid_pinyin(pinyin : String) -> Bool {
  pinyin_trie.contains(pinyin)
}
