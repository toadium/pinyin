///|
/// ToneSandhiHelper 命名空间类型，提供声调变调规则引擎。
/// 自动应用汉语变调规则：三声变调、一变调、不变调、七变调、八变调。
#warnings("-struct_never_constructed")
pub struct ToneSandhiHelper {}

///|
/// 应用声调变调规则：三声变调、一变调、不变调、七变调、八变调。
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
    let tone_i = @core.get_tone_number(result[i])
    let tone_next = @core.get_tone_number(result[i + 1])
    if tone_i == 3 && tone_next == 3 {
      let without_tone = @core.strip_tone(result[i])
      result[i] = @core.set_tone(without_tone, 2)
    }
  }
  for i in 0..<n {
    let without_tone_i = @core.strip_tone(result[i])
    if without_tone_i == "yi" {
      if i + 1 < n {
        let tone_next = @core.get_tone_number(result[i + 1])
        if tone_next == 4 {
          result[i] = @core.set_tone("yi", 2)
        } else if tone_next == 1 || tone_next == 2 || tone_next == 3 {
          result[i] = @core.set_tone("yi", 4)
        } else {
          result[i] = @core.set_tone("yi", 1)
        }
      } else {
        result[i] = @core.set_tone("yi", 1)
      }
    }
  }
  for i in 0..<n {
    let without_tone_i = @core.strip_tone(result[i])
    if without_tone_i == "bu" {
      if i + 1 < n {
        let tone_next = @core.get_tone_number(result[i + 1])
        if tone_next == 4 {
          result[i] = @core.set_tone("bu", 2)
        } else {
          result[i] = @core.set_tone("bu", 4)
        }
      } else {
        result[i] = @core.set_tone("bu", 4)
      }
    }
  }
  for i in 0..<n {
    let without_tone_i = @core.strip_tone(result[i])
    if without_tone_i == "qi" {
      if i + 1 < n {
        let tone_next = @core.get_tone_number(result[i + 1])
        if tone_next == 4 {
          result[i] = @core.set_tone("qi", 2)
        } else if tone_next == 1 || tone_next == 2 || tone_next == 3 {
          result[i] = @core.set_tone("qi", 4)
        } else {
          result[i] = @core.set_tone("qi", 1)
        }
      } else {
        result[i] = @core.set_tone("qi", 1)
      }
    }
  }
  for i in 0..<n {
    let without_tone_i = @core.strip_tone(result[i])
    if without_tone_i == "ba" {
      if i + 1 < n {
        let tone_next = @core.get_tone_number(result[i + 1])
        if tone_next == 4 {
          result[i] = @core.set_tone("ba", 2)
        } else if tone_next == 1 || tone_next == 2 || tone_next == 3 {
          result[i] = @core.set_tone("ba", 4)
        } else {
          result[i] = @core.set_tone("ba", 1)
        }
      } else {
        result[i] = @core.set_tone("ba", 1)
      }
    }
  }
  result
}
