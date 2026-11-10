///|
/// ToneSandhiHelper 命名空间类型，提供声调变调规则引擎。
/// 自动应用汉语变调规则：三声变调、一变调、不变调。
#warnings("-struct_never_constructed")
pub struct ToneSandhiHelper {}

///|
/// 从带调拼音中提取声调数字 (1-4)，无调或轻声返回 0。
fn get_tone_number(pinyin : String) -> Int32 {
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
fn is_vowel_char(ch : Char) -> Bool {
  ch == 'a' || ch == 'e' || ch == 'i' || ch == 'o' || ch == 'u' || ch == 'v'
}

///|
/// 将无调拼音 + 声调数字 → 带调拼音。
/// 声调标记位置遵循汉语拼音规则：a > e > o > iu(ui标在后) > 最后元音。
fn set_tone(pinyin_without_tone : String, tone : Int32) -> String {
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

///|
/// 应用声调变调规则：三声变调、一变调、不变调。
/// 输入带调拼音数组，输出应用变调规则后的带调拼音数组。
/// 例如 ["nǐ", "hǎo"] → ["ní", "hǎo"]（三声变调）。
pub fn ToneSandhiHelper::apply_tone_sandhi(
  pinyin_array : Array[String],
) -> Array[String] {
  if pinyin_array.length() == 0 {
    return []
  }
  let result = pinyin_array.copy()
  let n = result.length()
  for i in 0..<(n - 1) {
    let tone_i = get_tone_number(result[i])
    let tone_next = get_tone_number(result[i + 1])
    if tone_i == 3 && tone_next == 3 {
      let without_tone = strip_tone(result[i])
      result[i] = set_tone(without_tone, 2)
    }
  }
  for i in 0..<n {
    let without_tone_i = strip_tone(result[i])
    if without_tone_i == "yi" {
      if i + 1 < n {
        let tone_next = get_tone_number(result[i + 1])
        if tone_next == 4 {
          result[i] = set_tone("yi", 2)
        } else if tone_next == 1 || tone_next == 2 || tone_next == 3 {
          result[i] = set_tone("yi", 4)
        } else {
          result[i] = set_tone("yi", 1)
        }
      } else {
        result[i] = set_tone("yi", 1)
      }
    }
  }
  for i in 0..<n {
    let without_tone_i = strip_tone(result[i])
    if without_tone_i == "bu" {
      if i + 1 < n {
        let tone_next = get_tone_number(result[i + 1])
        if tone_next == 4 {
          result[i] = set_tone("bu", 2)
        } else {
          result[i] = set_tone("bu", 4)
        }
      } else {
        result[i] = set_tone("bu", 4)
      }
    }
  }
  result
}
