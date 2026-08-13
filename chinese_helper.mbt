///|
/// 繁简中文互转，对齐源库 pinyin4cj 的 `chinese_helper.cj` 公开 API。
///
/// `ChineseHelper` 作为命名空间结构体，承载全部繁简互转公开方法：
/// - `convert_to_simplified_chinese` / `convert_to_traditional_chinese`
/// - `is_traditional_chinese` / `is_chinese` / `contains_chinese`
/// - `add_chinese_dict_resource`
///
/// 内部方法：`convert_char_to_simplified_chinese` / `convert_char_to_traditional_chinese`。

///|
/// `ChineseHelper` 命名空间结构体，对齐源库 `public class ChineseHelper`。无字段，仅承载关联方法。
#warnings("-struct_never_constructed")
pub struct ChineseHelper {}

///|
/// 单字繁→简，对齐源库 `convertCharToSimplifiedChinese`（`chinese_helper.cj:22-30`）。
///
/// 查 `chinese_map` 命中则替换为对应简体码点，未命中原样返回。
fn ChineseHelper::convert_char_to_simplified_chinese(c : Char) -> Char {
  match chinese_map.get(c.to_int()) {
    Some(simplified_code) => Int::to_char(simplified_code).unwrap()
    None => c
  }
}

///|
/// 单字简→繁（O(n) 反查），对齐源库 `convertCharToTraditionalChinese`（`chinese_helper.cj:38-45`）。
///
/// 遍历 `chinese_map` 找值为该字符码点的键，命中返回键对应字符，未命中原样返回。
/// **保留 O(n) 反查语义**（需求 3.8 "不主动优化"）：不构建反向索引。
fn ChineseHelper::convert_char_to_traditional_chinese(c : Char) -> Char {
  let target_code = c.to_int()
  for k, v in chinese_map {
    if v == target_code {
      return Int::to_char(k).unwrap()
    }
  }
  c
}

///|
/// 繁体→简体，对齐源库 `convertToSimplifiedChinese`（`chinese_helper.cj:53-61`）。
///
/// 逐字符查 `chinese_map` 替换，未命中原样。空串返回空串。
pub fn ChineseHelper::convert_to_simplified_chinese(str : String) -> String {
  let buf = StringBuilder::new()
  for c in str {
    buf.write_char(ChineseHelper::convert_char_to_simplified_chinese(c))
  }
  buf.to_string()
}

///|
/// 简体→繁体，对齐源库 `convertToTraditionalChinese`（`chinese_helper.cj:69-80`）。
///
/// 逐字符 O(n) 反查 `chinese_map` 替换，未命中原样。空串返回空串。
/// 用 `for c in str` 安全迭代 Unicode 码点，替代源库 `unsafe { str.rawData() }` + `Rune.fromUtf8`。
pub fn ChineseHelper::convert_to_traditional_chinese(str : String) -> String {
  let buf = StringBuilder::new()
  for c in str {
    buf.write_char(ChineseHelper::convert_char_to_traditional_chinese(c))
  }
  buf.to_string()
}

///|
/// 判断是否繁体字，对齐源库 `isTraditionalChinese`（`chinese_helper.cj:89-96`）。
///
/// 查 `chinese_map` 是否含该字符码点为键。
pub fn ChineseHelper::is_traditional_chinese(c : Char) -> Bool {
  chinese_map.contains(c.to_int())
}

///|
/// 判断是否汉字，对齐源库 `isChinese`（`chinese_helper.cj:105-112`）。
///
/// 查 `pinyin_table` 是否含该字符字符串为键。
pub fn ChineseHelper::is_chinese(c : Char) -> Bool {
  pinyin_table.contains(c.to_string())
}

///|
/// 判断字符串是否含汉字，对齐源库 `containsChinese`（`chinese_helper.cj:121-129`）。
pub fn ChineseHelper::contains_chinese(str : String) -> Bool {
  for c in str {
    if ChineseHelper::is_chinese(c) {
      return true
    }
  }
  false
}

///|
/// 追加自定义繁简字典，对齐源库 `addChineseDictResource`（`chinese_helper.cj:137-139`）。
///
/// 利用 `Map` 可变性原地合并，键冲突时新值覆盖。
pub fn ChineseHelper::add_chinese_dict_resource(dict : Map[Int, Int]) -> Unit {
  for k, v in dict {
    chinese_map[k] = v
  }
}
