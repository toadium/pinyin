///|
/// PinyinNormalizer 命名空间类型，提供拼音规范化能力。
/// 统一各种拼音表示：大小写、ü/v 转换、声调格式统一、声调位置纠正。
#warnings("-struct_never_constructed")
pub struct PinyinNormalizer {}

///|
/// 将字符串中的大写字母转换为小写。
fn to_lower(pinyin : String) -> String {
  let buf = StringBuilder()
  for c in pinyin {
    let lower = match c {
      'A' => 'a'
      'B' => 'b'
      'C' => 'c'
      'D' => 'd'
      'E' => 'e'
      'F' => 'f'
      'G' => 'g'
      'H' => 'h'
      'I' => 'i'
      'J' => 'j'
      'K' => 'k'
      'L' => 'l'
      'M' => 'm'
      'N' => 'n'
      'O' => 'o'
      'P' => 'p'
      'Q' => 'q'
      'R' => 'r'
      'S' => 's'
      'T' => 't'
      'U' => 'u'
      'V' => 'v'
      'W' => 'w'
      'X' => 'x'
      'Y' => 'y'
      'Z' => 'z'
      _ => c
    }
    buf.write_char(lower)
  }
  buf.to_string()
}

///|
/// 规范化拼音字符串为标准带调标记格式。
/// 处理：大小写统一为小写、数字调→带调标记、v→ü、声调位置纠正。
/// 例如 "ZHONG1" → "zhōng"，"nv3" → "nǚ"。
pub fn PinyinNormalizer::normalize(pinyin : String) -> String {
  let lower = to_lower(pinyin)
  let chars = lower.to_array()
  let mut tone = 0
  let mut pinyin_part = lower
  if chars.length() > 0 {
    let last = chars[chars.length() - 1]
    if last >= '1' && last <= '4' {
      tone = last.to_int() - '0'.to_int()
      pinyin_part = lower[:lower.length() - 1].to_owned()
    }
  }
  if tone == 0 {
    for ch in pinyin_part.to_array() {
      let idx = @core.find_array_key_by_value(ch)
      if idx >= 0 {
        tone = idx % 4 + 1
        break
      }
    }
  }
  let without_tone = @core.strip_tone(pinyin_part)
  if tone >= 1 && tone <= 4 {
    @core.set_tone(without_tone, tone)
  } else {
    without_tone.replace_all(old="v", new="ü")
  }
}

///|
/// 规范化拼音字符串为数字调格式。
/// 例如 "zhōng" → "zhong1"，"nǚ" → "nv3"。
pub fn PinyinNormalizer::normalize_to_tone_number(pinyin : String) -> String {
  let normalized = PinyinNormalizer::normalize(pinyin)
  let pinyin_array = @core.convert_with_tone_number(normalized)
  if pinyin_array.length() > 0 {
    pinyin_array[0]
  } else {
    normalized
  }
}

///|
/// 规范化拼音字符串为无调格式。
/// 例如 "zhōng" → "zhong"，"nǚ" → "nv"。
pub fn PinyinNormalizer::normalize_to_without_tone(pinyin : String) -> String {
  let normalized = PinyinNormalizer::normalize(pinyin)
  let pinyin_array = @core.convert_without_tone(normalized)
  if pinyin_array.length() > 0 {
    pinyin_array[0]
  } else {
    normalized
  }
}
