// shuangpin 包：双拼（小鹤 / 自然码）与全拼互转，零依赖

///|
/// 双拼方案。键位映射参考 Rime double_pinyin_flypy / double_pinyin schema。
pub(all) enum ShuangpinScheme {
  Xiaohe
  Ziranma
}

///|
/// 小鹤双拼韵母键位。
let xiaohe_finals : Map[String, String] = {
  "a": "a",
  "o": "o",
  "e": "e",
  "i": "i",
  "u": "u",
  "v": "v",
  "ü": "v",
  "ai": "d",
  "ei": "w",
  "ao": "c",
  "ou": "z",
  "an": "j",
  "en": "f",
  "ang": "h",
  "eng": "g",
  "ong": "s",
  "iong": "s",
  "uo": "o",
  "ie": "p",
  "iu": "q",
  "ing": "k",
  "uai": "k",
  "iang": "l",
  "uang": "l",
  "ian": "m",
  "in": "b",
  "uan": "r",
  "ue": "t",
  "ve": "t",
  "un": "y",
  "ui": "v",
  "ia": "x",
  "ua": "x",
  "iao": "n",
}

///|
/// 自然码双拼韵母键位。
let ziranma_finals : Map[String, String] = {
  "a": "a",
  "o": "o",
  "e": "e",
  "i": "i",
  "u": "u",
  "v": "v",
  "ü": "v",
  "ai": "l",
  "ei": "z",
  "ao": "k",
  "ou": "b",
  "an": "j",
  "en": "f",
  "ang": "h",
  "eng": "g",
  "ong": "s",
  "iong": "s",
  "uo": "o",
  "ie": "x",
  "iu": "q",
  "ing": "y",
  "uai": "y",
  "iang": "d",
  "uang": "d",
  "ian": "m",
  "in": "n",
  "uan": "r",
  "ue": "t",
  "ve": "t",
  "un": "p",
  "vn": "p",
  "ui": "v",
  "ia": "w",
  "ua": "w",
  "iao": "c",
}

///|
fn final_table(scheme : ShuangpinScheme) -> Map[String, String] {
  match scheme {
    Xiaohe => xiaohe_finals
    Ziranma => ziranma_finals
  }
}

///|
/// 声母 → 双拼键。zh/ch/sh 使用单键 v/i/u，其余保持。
fn initial_key(initial : String) -> String {
  if initial == "zh" {
    "v"
  } else if initial == "ch" {
    "i"
  } else if initial == "sh" {
    "u"
  } else {
    initial
  }
}

///|
/// 双拼声母键 → 全拼声母。
fn initial_from_key(key : String) -> String {
  if key == "v" {
    "zh"
  } else if key == "i" {
    "ch"
  } else if key == "u" {
    "sh"
  } else {
    key
  }
}

///|
/// 从全拼音节中切出声母；无辅音声母返回空串。
fn initial_of(syllable : String) -> String {
  if syllable.has_prefix("zh"[:]) ||
    syllable.has_prefix("ch"[:]) ||
    syllable.has_prefix("sh"[:]) {
    return syllable[:2].to_owned()
  }
  if syllable.length() > 0 {
    let c = syllable[0].unsafe_to_char()
    if "bpmfdtnlgkhjqxrzcsyw".contains(c.to_string()[:]) {
      return c.to_string()
    }
  }
  ""
}

///|
/// 韵母 → 双拼键；未知韵母返回空串。
fn final_key(scheme : ShuangpinScheme, final_part : String) -> String {
  match final_table(scheme).get(final_part) {
    Some(key) => key
    None => ""
  }
}

///|
fn is_key_set(initials : String, initial : String) -> Bool {
  initials.contains(initial[:])
}

///|
/// 小鹤双拼：声母键 + 韵母键 → 全拼韵母。
fn xiaohe_final_from_key(initial : String, key : String) -> String {
  match key {
    "s" => if is_key_set("jqx", initial) { "iong" } else { "ong" }
    "k" =>
      if is_key_set("gkhvui rzcs".replace_all(old=" ", new=""), initial) {
        "uai"
      } else {
        "ing"
      }
    "l" => if is_key_set("jqxnl", initial) { "iang" } else { "uang" }
    "x" =>
      if is_key_set("gkhvui rzcs".replace_all(old=" ", new=""), initial) {
        "ua"
      } else {
        "ia"
      }
    "o" =>
      if is_key_set("dtnlgkhvui rzcs".replace_all(old=" ", new=""), initial) {
        "uo"
      } else {
        "o"
      }
    "v" =>
      if is_key_set("dtgkhvui rzcs".replace_all(old=" ", new=""), initial) {
        "ui"
      } else {
        "ü"
      }
    "d" => "ai"
    "w" => "ei"
    "c" => "ao"
    "z" => "ou"
    "j" => "an"
    "f" => "en"
    "h" => "ang"
    "g" => "eng"
    "p" => "ie"
    "q" => "iu"
    "m" => "ian"
    "b" => "in"
    "r" => "uan"
    "t" => "ue"
    "y" => "un"
    "n" => "iao"
    "a" => "a"
    "e" => "e"
    "i" => "i"
    "u" => "u"
    _ => ""
  }
}

///|
/// 自然码双拼：声母键 + 韵母键 → 全拼韵母。
fn ziranma_final_from_key(initial : String, key : String) -> String {
  match key {
    "s" => if is_key_set("jqx", initial) { "iong" } else { "ong" }
    "w" =>
      if is_key_set("gkhvui rzcs".replace_all(old=" ", new=""), initial) {
        "ua"
      } else {
        "ia"
      }
    "y" =>
      if is_key_set("gkhvui rzcs".replace_all(old=" ", new=""), initial) {
        "uai"
      } else {
        "ing"
      }
    "d" => if is_key_set("jqxnl", initial) { "iang" } else { "uang" }
    "p" =>
      if is_key_set("dtnlgkhvui rzcs".replace_all(old=" ", new=""), initial) {
        "un"
      } else {
        "ün"
      }
    "o" =>
      if is_key_set("dtnlgkhvui rzcs".replace_all(old=" ", new=""), initial) {
        "uo"
      } else {
        "o"
      }
    "v" =>
      if is_key_set("dtgkhvui rzcs".replace_all(old=" ", new=""), initial) {
        "ui"
      } else {
        "ü"
      }
    "q" => "iu"
    "r" => "uan"
    "t" => "ue"
    "c" => "iao"
    "k" => "ao"
    "l" => "ai"
    "z" => "ei"
    "x" => "ie"
    "b" => "ou"
    "n" => "in"
    "f" => "en"
    "g" => "eng"
    "h" => "ang"
    "j" => "an"
    "m" => "ian"
    "a" => "a"
    "e" => "e"
    "i" => "i"
    "u" => "u"
    _ => ""
  }
}

///|
/// j/q/x 后的 ü/ün 按汉语拼音书写习惯还原为 u/un（ju/qu/xu、jun/qun/xun）。
fn normalize_umlaut(initial : String, final_part : String) -> String {
  if (final_part == "ü" || final_part == "ün") &&
    (initial == "j" || initial == "q" || initial == "x") {
    return final_part.replace_all(old="ü", new="u")
  }
  final_part
}

///|
fn final_from_key(
  scheme : ShuangpinScheme,
  initial : String,
  key : String,
) -> String {
  match scheme {
    Xiaohe => xiaohe_final_from_key(initial, key)
    Ziranma => ziranma_final_from_key(initial, key)
  }
}

///|
/// 全拼音节 → 双拼音节（声母键 + 韵母键）。
/// 仅支持有声母的普通音节；零声母或未知韵母原样返回。
pub fn ShuangpinScheme::from_full(
  self : ShuangpinScheme,
  syllable : String,
) -> String {
  let initial = initial_of(syllable)
  if initial.length() == 0 {
    return syllable
  }
  let final_part = syllable[initial.length():].to_owned()
  let key = final_key(self, final_part)
  if key.length() == 0 {
    return syllable
  }
  initial_key(initial) + key
}

///|
/// 双拼串（每音节 2 键，可含空格/单引号分隔）→ 空格分隔全拼。
/// 奇数长度或无法识别的键位原样返回。
pub fn ShuangpinScheme::to_full(
  self : ShuangpinScheme,
  input : String,
) -> String {
  let cleaned = input.replace_all(old=" ", new="").replace_all(old="'", new="")
  if cleaned.length() == 0 || cleaned.length() % 2 != 0 {
    return input
  }
  let result = StringBuilder()
  let mut has_output = false
  let mut i = 0
  while i < cleaned.length() {
    let first = cleaned[i].unsafe_to_char().to_string()
    let second = cleaned[i + 1].unsafe_to_char().to_string()
    let initial = initial_from_key(first)
    let final_part = normalize_umlaut(
      initial,
      final_from_key(self, first, second),
    )
    if final_part.length() == 0 {
      return input
    }
    if has_output {
      result.write_char(' ')
    }
    result.write_string(initial)
    result.write_string(final_part)
    has_output = true
    i += 2
  }
  result.to_string()
}

///|
/// 从配置名解析双拼方案（"xiaohe"/"小鹤"、"ziranma"/"自然码"）。
pub fn ShuangpinScheme::from_name(name : String) -> ShuangpinScheme? {
  if name == "xiaohe" || name == "小鹤" {
    Some(Xiaohe)
  } else if name == "ziranma" || name == "自然码" {
    Some(Ziranma)
  } else {
    None
  }
}

///|
/// 方案名称：便于配置与展示。
pub fn ShuangpinScheme::name(self : ShuangpinScheme) -> String {
  match self {
    Xiaohe => "小鹤双拼"
    Ziranma => "自然码双拼"
  }
}
