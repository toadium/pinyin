///|
/// PinyinHelper 命名空间类型，对齐源库 PinyinHelper。所有方法为类型关联方法。
#warnings("-struct_never_constructed")
pub struct PinyinHelper {}

///|
/// 词句转拼音（默认 WithToneMark 格式）。对齐源库 convertToPinyinString(str, sep)。
pub fn PinyinHelper::convert_to_pinyin_string(
  str : String,
  separator : String,
  format? : PinyinFormat = WithToneMark,
) -> String raise PinyinError {
  PinyinHelper::convert_to_pinyin_string_result(str, separator, format)
}

///|
/// 先繁→简再转拼音。对齐源库 convertToPinyinStringTraditional。
pub fn PinyinHelper::convert_to_pinyin_string_traditional(
  str : String,
  separator : String,
  format? : PinyinFormat = WithToneMark,
) -> String raise PinyinError {
  let simplified = ChineseHelper::convert_to_simplified_chinese(str)
  PinyinHelper::convert_to_pinyin_string(simplified, separator, format~)
}

///|
/// 单字所有读音数组。对齐源库 convertToPinyinArray。非汉字返回 []。
pub fn PinyinHelper::convert_to_pinyin_array(
  c : Char,
  format? : PinyinFormat = WithToneMark,
) -> Array[String] {
  convert_to_pinyin_arrays(c, format)
}

///|
/// 首字母格式拼音。对齐源库 getShortPinyin。空串抛 PinyinError。
pub fn PinyinHelper::get_short_pinyin(str : String) -> String raise PinyinError {
  PinyinHelper::convert_to_pinyin_string(str, " ", format=FirstLetter)
}

///|
/// 判断是否多音字。对齐源库 hasMultiPinyin。非汉字抛 PinyinError。
pub fn PinyinHelper::has_multi_pinyin(c : Char) -> Bool raise PinyinError {
  if !ChineseHelper::is_chinese(c) {
    raise PinyinError("Please enter a Chinese character")
  }
  match pinyin_table.get(c.to_string()) {
    Some(v) => v.contains(pinyin_separator[:])
    None => false
  }
}

///|
/// 追加自定义单字拼音字典到 pinyin_table（原地合并）。
/// 对齐源库 addPinyinDictResource。
pub fn PinyinHelper::add_pinyin_dict_resource(
  dict : Map[String, String],
) -> Unit {
  for k, v in dict {
    pinyin_table[k] = v
  }
}

///|
/// 追加自定义词组拼音字典到 mutil_pinyin_table（原地合并）。
/// 对齐源库 addMutilPinyinDictResource。
pub fn PinyinHelper::add_mutil_pinyin_dict_resource(
  dict : Map[String, String],
) -> Unit {
  for k, v in dict {
    mutil_pinyin_table[k] = v
  }
}

///|
/// 通用拼音数组。对齐源库 toTongyongPinyinStringArray。非汉字返回 []。
pub fn PinyinHelper::to_tongyong_pinyin_string_array(
  char : Char,
) -> Array[String] {
  if !ChineseHelper::is_chinese(char) {
    return []
  }
  let pinyin_array = PinyinHelper::convert_to_pinyin_array(
    char,
    format=WithToneNumber,
  )
  let result : Array[String] = []
  for pinyin in pinyin_array {
    if pinyin.length() > 0 {
      let num = pinyin[pinyin.length() - 1:].to_owned()
      let pinyin_part = pinyin[:pinyin.length() - 1].to_owned()
      match tongyong_pinyin_table.get(pinyin_part) {
        Some(t) => result.push(t + num)
        None => result.push(pinyin)
      }
    } else {
      result.push(pinyin)
    }
  }
  result
}

///|
/// 内部方法：词组匹配（最短前缀优先）。从 1 字到 5 字逐长度扫描，首个命中即返回。
/// 对齐源库 getWords。
fn PinyinHelper::get_words(str : String) -> Array[String] {
  let char_array = str.to_array()
  let max_len = if char_array.length() < 5 { char_array.length() } else { 5 }
  for i in 1..<=max_len {
    let prefix = String::from_array(char_array[:i])
    if mutil_pinyin_table.contains(prefix) {
      return [prefix]
    }
  }
  []
}

///|
/// 内部方法：词句转拼音主流程。对齐源库 convertToPinyinStringResult。
fn PinyinHelper::convert_to_pinyin_string_result(
  str : String,
  separator : String,
  format : PinyinFormat,
) -> String raise PinyinError {
  let char_array = str.to_array()
  if char_array.length() == 0 {
    raise PinyinError("Please enter a word or sentence")
  }
  let result = StringBuilder()
  let str_len = char_array.length()
  let mut i = 0
  while i < str_len {
    let remaining = String::from_array(char_array[i:])
    let words = PinyinHelper::get_words(remaining)
    if words.length() > 0 {
      let word = words[0]
      match mutil_pinyin_table.get(word) {
        Some(v) => {
          let pinyin_array = format_pinyin(v, format)
          for p in pinyin_array {
            if format is FirstLetter && p.length() > 0 {
              result.write_char(p[0].unsafe_to_char())
            } else {
              result.write_string(p)
            }
            result.write_string(separator)
          }
        }
        None => ()
      }
      i += word.length()
    } else {
      let c = char_array[i]
      if ChineseHelper::is_chinese(c) || c == chinese_ling {
        match pinyin_table.get(c.to_string()) {
          Some(v) => {
            let pinyin_array = format_pinyin(v, format)
            for p in pinyin_array {
              if format is FirstLetter && p.length() > 0 {
                result.write_char(p[0].unsafe_to_char())
              } else {
                result.write_string(p)
              }
              result.write_string(separator)
            }
          }
          None => {
            result.write_char(c)
            result.write_string(separator)
          }
        }
      } else {
        result.write_char(c)
        if i + 1 < str_len && ChineseHelper::is_chinese(char_array[i + 1]) {
          result.write_string(separator)
        }
      }
      i += 1
    }
  }
  let result_str = result.to_string()
  if separator.length() > 0 &&
    result_str.length() >= separator.length() &&
    result_str[result_str.length() - separator.length():] == separator[:] {
    result_str[:result_str.length() - separator.length()].to_owned()
  } else {
    result_str
  }
}
