///|
/// 汉字零（U+3007），对齐源库 CHINESE_LING。is_chinese 将其视为汉字。
let chinese_ling : Char = '〇'

///|
/// ChineseHelper 命名空间类型，对齐源库 ChineseHelper。所有方法为类型关联方法。
#warnings("-struct_never_constructed")
pub struct ChineseHelper {}

///|
/// 判断字符是否为汉字（CJK 统一表意文字 U+4E00-U+9FFF 或汉字零 U+3007）。
/// 对齐源库 ChineseHelper.isChinese。
pub fn ChineseHelper::is_chinese(c : Char) -> Bool {
  (c >= '\u{4e00}' && c <= '\u{9fff}') || c == chinese_ling
}

///|
/// 判断字符是否为繁体汉字（在 chinese_map 中存在映射）。
/// 对齐源库 ChineseHelper.isTraditionalChinese。
pub fn ChineseHelper::is_traditional_chinese(c : Char) -> Bool {
  chinese_map.contains(c.to_int())
}

///|
/// 判断字符串是否包含汉字。对齐源库 ChineseHelper.containsChinese。
pub fn ChineseHelper::contains_chinese(str : String) -> Bool {
  for c in str {
    if ChineseHelper::is_chinese(c) {
      return true
    }
  }
  false
}

///|
/// 繁→简转换：逐字符查 chinese_map，命中替换为简体码点，未命中原样。空串返回空串。
/// 对齐源库 ChineseHelper.convertToSimplifiedChinese。
pub fn ChineseHelper::convert_to_simplified_chinese(str : String) -> String {
  let buf = StringBuilder()
  for c in str {
    buf.write_char(ChineseHelper::convert_char_to_simplified_chinese(c))
  }
  buf.to_string()
}

///|
/// 简→繁转换：逐字符遍历 chinese_map 反查值为该字符的键，命中替换为键，未命中原样。
/// 保留 O(n) 反查语义（需求 3.8 不主动优化，避免改变多映射语义）。
/// 对齐源库 ChineseHelper.convertToTraditionalChinese。
pub fn ChineseHelper::convert_to_traditional_chinese(str : String) -> String {
  let buf = StringBuilder()
  for c in str {
    buf.write_char(ChineseHelper::convert_char_to_traditional_chinese(c))
  }
  buf.to_string()
}

///|
/// 追加自定义繁简映射到 chinese_map（原地合并，键冲突新值覆盖）。
/// 对齐源库 ChineseHelper.addChineseDictResource。
pub fn ChineseHelper::add_chinese_dict_resource(dict : Map[Int, Int]) -> Unit {
  for k, v in dict {
    chinese_map[k] = v
  }
}

///|
/// 内部方法：单字符繁→简。查 chinese_map，命中返回简体 Char，未命中返回原字符。
/// 对齐源库 convertCharToSimplifiedChinese。
fn ChineseHelper::convert_char_to_simplified_chinese(c : Char) -> Char {
  match chinese_map.get(c.to_int()) {
    Some(v) => v.unsafe_to_char()
    None => c
  }
}

///|
/// 内部方法：单字符简→繁。遍历 chinese_map 反查值为该字符的键，命中返回繁体 Char，未命中返回原字符。
/// 保留 O(n) 反查语义。对齐源库 convertCharToTraditionalChinese。
fn ChineseHelper::convert_char_to_traditional_chinese(c : Char) -> Char {
  let target = c.to_int()
  for k, v in chinese_map {
    if v == target {
      return k.unsafe_to_char()
    }
  }
  c
}
