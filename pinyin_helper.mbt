///|
/// 拼音转换主流程，对齐源库 pinyin4cj 的 `pinyin_helper.cj` 公开 API。
///
/// `PinyinHelper` 作为命名空间结构体，承载全部拼音转换公开方法：
/// - `convert_to_pinyin_array` / `convert_to_pinyin_string` / `convert_to_pinyin_string_traditional`
/// - `get_short_pinyin` / `has_multi_pinyin` / `to_tongyong_pinyin_string_array`
/// - `add_pinyin_dict_resource` / `add_mutil_pinyin_dict_resource`
///
/// 内部方法：`get_words`（词组最短前缀匹配）、`convert_to_pinyin_string_result`（末尾分隔符裁剪）。

///|
/// `PinyinHelper` 命名空间结构体，对齐源库 `public class PinyinHelper`。无字段，仅承载关联方法。
#warnings("-struct_never_constructed")
pub struct PinyinHelper {}

///|
/// 汉字零（U+3007），对齐源库 `CHINESE_LING`。`pinyin_helper.mbt` 内部使用。
let chinese_ling : Char = '〇'

///|
/// 词组最短前缀匹配，对齐源库 `getWords`（`pinyin_helper.cj:131-140`）。
///
/// 从 1 字到 5 字逐长度扫描剩余字符数组前缀，首个命中 `mutil_pinyin_table` 即返回 `[str]`。
/// **最短前缀优先**（落实审查建议 N1）。
fn PinyinHelper::get_words(char_array : ArrayView[Char]) -> Array[String] {
  let max_len = if char_array.length() < 5 { char_array.length() } else { 5 }
  for i in 1..<=max_len {
    let str = String::from_array(char_array[:i])
    if mutil_pinyin_table.contains(str) {
      return [str]
    }
  }
  []
}

///|
/// 末尾分隔符裁剪，对齐源库 `convertToPinyinStringResult`（`pinyin_helper.cj:214-222`）。
///
/// 若 separator 非空且 res 末尾字符等于 separator 的首个字符，则裁剪末尾该字符。
fn PinyinHelper::convert_to_pinyin_string_result(
  buf : StringBuilder,
  separator : String,
) -> String {
  let res = buf.to_string()
  let sep_chars = separator.to_array()
  if sep_chars.length() == 1 {
    let res_chars = res.to_array()
    if res_chars.length() > 0 &&
      res_chars[res_chars.length() - 1] == sep_chars[0] {
      return String::from_array(res_chars[:res_chars.length() - 1])
    }
  }
  res
}

///|
/// 单字转拼音数组（所有读音），对齐源库 `convertToPinyinArray`（`pinyin_helper.cj:102-115`）。
///
/// 查 `pinyin_table` 命中则 `format_pinyin` 格式化；`FirstLetter` 格式取每个音节首字符。
/// 未命中字典（非汉字）返回空数组。
pub fn PinyinHelper::convert_to_pinyin_array(
  c : Char,
  format? : PinyinFormat = PinyinFormat::WithToneMark,
) -> Array[String] {
  match pinyin_table.get(c.to_string()) {
    Some(v) => {
      let formatted = format_pinyin(v, format)
      if format is FirstLetter {
        for i in 0..<formatted.length() {
          formatted[i] = formatted[i].to_array()[0].to_string()
        }
      }
      formatted
    }
    None => []
  }
}

///|
/// 词句转拼音，对齐源库 `convertToPinyinString`（`pinyin_helper.cj:150-207`）。
///
/// 空串抛 `PinyinError("Please enter a word or sentence")`。从左到右扫描：
/// 命中词组（最短前缀优先）则按词组输出；未命中则取单字，汉字查字典取首音，非汉字原样输出。
/// 末尾多余分隔符裁剪。
pub fn PinyinHelper::convert_to_pinyin_string(
  str : String,
  separator : String,
  format? : PinyinFormat = PinyinFormat::WithToneMark,
) -> String raise PinyinError {
  let char_array = str.to_array()
  if char_array.length() == 0 {
    raise PinyinError::PinyinError("Please enter a word or sentence")
  }
  let buf = StringBuilder::new()
  let str_len = char_array.length()
  let mut i = 0
  while i < str_len {
    let common_prefix_list = PinyinHelper::get_words(char_array[i:])
    if common_prefix_list.length() == 0 {
      let c = char_array[i]
      if ChineseHelper::is_chinese(c) || c == chinese_ling {
        let pinyin_array = convert_to_pinyin_arrays(c, format)
        if pinyin_array.length() > 0 {
          if format is FirstLetter {
            buf.write_string(pinyin_array[0].to_array()[0].to_string())
            buf.write_string(separator)
          } else {
            buf.write_string(pinyin_array[0])
            buf.write_string(separator)
          }
        } else {
          buf.write_char(c)
        }
      } else if i + 1 < str_len {
        if ChineseHelper::is_chinese(char_array[i + 1]) {
          buf.write_string(c.to_string())
          buf.write_string(separator)
        } else {
          buf.write_char(c)
        }
      } else {
        buf.write_char(c)
      }
      i += 1
    } else {
      let words = common_prefix_list[common_prefix_list.length() - 1]
      let pinyin_array = format_pinyin(mutil_pinyin_table[words], format)
      for j in 0..<pinyin_array.length() {
        if format is FirstLetter {
          buf.write_string(pinyin_array[j].to_array()[0].to_string())
          buf.write_string(separator)
        } else {
          buf.write_string(pinyin_array[j])
          buf.write_string(separator)
        }
      }
      i += words.to_array().length()
    }
  }
  PinyinHelper::convert_to_pinyin_string_result(buf, separator)
}

///|
/// 繁体词句转拼音，对齐源库 `convertToPinyinStringTraditional`（`pinyin_helper.cj:209-212`）。
///
/// 先繁→简再转拼音。
pub fn PinyinHelper::convert_to_pinyin_string_traditional(
  str : String,
  separator : String,
  format? : PinyinFormat = PinyinFormat::WithToneMark,
) -> String raise PinyinError {
  let simplified = ChineseHelper::convert_to_simplified_chinese(str)
  PinyinHelper::convert_to_pinyin_string(simplified, separator, format~)
}

///|
/// 获取首字母拼音，对齐源库 `getShortPinyin`（`pinyin_helper.cj:241-243`）。
pub fn PinyinHelper::get_short_pinyin(str : String) -> String raise PinyinError {
  PinyinHelper::convert_to_pinyin_string(
    str,
    "",
    format=PinyinFormat::FirstLetter,
  )
}

///|
/// 判断是否多音字，对齐源库 `hasMultiPinyin`（`pinyin_helper.cj:251-257`）。
///
/// 非汉字抛 `PinyinError("Please enter a Chinese character")`。
pub fn PinyinHelper::has_multi_pinyin(c : Char) -> Bool raise PinyinError {
  if !ChineseHelper::is_chinese(c) {
    raise PinyinError::PinyinError("Please enter a Chinese character")
  }
  match pinyin_table.get(c.to_string()) {
    Some(pinyin) => pinyin.split(pinyin_separator[:]).to_array().length() > 1
    None => false
  }
}

///|
/// 追加单字拼音字典，对齐源库 `addPinyinDictResource`（`pinyin_helper.cj:265-267`）。
///
/// 利用 `Map` 可变性原地合并，键冲突时新值覆盖。
pub fn PinyinHelper::add_pinyin_dict_resource(
  dict : Map[String, String],
) -> Unit {
  for k, v in dict {
    pinyin_table[k] = v
  }
}

///|
/// 追加词组拼音字典，对齐源库 `addMutilPinyinDictResource`（`pinyin_helper.cj:275-277`）。
pub fn PinyinHelper::add_mutil_pinyin_dict_resource(
  dict : Map[String, String],
) -> Unit {
  for k, v in dict {
    mutil_pinyin_table[k] = v
  }
}

///|
/// 单字转通用拼音数组，对齐源库 `toTongyongPinyinStringArray`（`pinyin_helper.cj:295-309`）。
///
/// 先得数字调拼音数组，对每个音节拆为"拼音部分 + 末尾数字"，
/// 查 `tongyong_pinyin_table` 替换拼音部分：命中则 `t + num`，未命中原样。非汉字返回 `[]`。
pub fn PinyinHelper::to_tongyong_pinyin_string_array(
  char : Char,
) -> Array[String] {
  let pinyin_array = PinyinHelper::convert_to_pinyin_array(
    char,
    format=PinyinFormat::WithToneNumber,
  )
  let res : Array[String] = []
  for i in 0..<pinyin_array.length() {
    let pinyin_i = pinyin_array[i]
    let chars = pinyin_i.to_array()
    if chars.length() == 0 {
      res.push("")
      continue
    }
    let num = chars[chars.length() - 1].to_string()
    let pinyin = String::from_array(chars[:chars.length() - 1])
    match tongyong_pinyin_table.get(pinyin) {
      Some(t) => res.push(t + num)
      None => res.push(pinyin_i)
    }
  }
  res
}
