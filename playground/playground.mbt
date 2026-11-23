///|
/// 浏览器演示导出层（JavaScript 后端）。
/// 所有导出函数均为非 raise 签名：错误折叠为空串，JS 侧无需异常映射。

///|
#export_name("pinyin_version")
pub fn pinyin_version() -> String {
  @pinyin.version
}

///|
/// 格式名 → PinyinFormat（未知回退带调）。
fn format_of(name : String) -> @core.PinyinFormat {
  match name {
    "number" => WithToneNumber
    "plain" => WithoutTone
    "initial" => FirstLetter
    _ => WithToneMark
  }
}

///|
/// 汉字 → 拼音。format: "mark"（默认）、"number"、"plain"、"initial"。
#export_name("pinyin_convert")
pub fn pinyin_convert(
  text : String,
  separator : String,
  format_name : String,
) -> String {
  @convert.PinyinHelper::convert_to_pinyin_string(
    text,
    separator,
    format=format_of(format_name),
  ) catch {
    _ => ""
  }
}

///|
/// 多音字上下文消歧：返回空格分隔的带调读音。
#export_name("pinyin_disambiguate")
pub fn pinyin_disambiguate(text : String) -> String {
  @disambiguate.PinyinDisambiguator::disambiguate(text).join(" ") catch {
    _ => ""
  }
}

///|
/// 拼音 → 输入法候选（最多 10 个，`|` 分隔）。
#export_name("pinyin_input")
pub fn pinyin_input(pinyin : String) -> String {
  try {
    let engine = @input.PinyinInputEngine::new()
    let candidates = engine.input(pinyin)
    let result = StringBuilder()
    let mut first = true
    for i, candidate in candidates {
      if i < 10 {
        if !first {
          result.write_char('|')
        }
        result.write_string(candidate.text)
        first = false
      }
    }
    result.to_string()
  } catch {
    _ => ""
  }
}

///|
/// 双拼 → 空格分隔全拼。scheme: "xiaohe"（默认）、"ziranma"。
#export_name("pinyin_shuangpin")
pub fn pinyin_shuangpin(scheme_name : String, input : String) -> String {
  let scheme = match @shuangpin.ShuangpinScheme::from_name(scheme_name) {
    Some(value) => value
    None => Xiaohe
  }
  scheme.to_full(input)
}

///|
/// 连续拼音串 → 最优切分。
#export_name("pinyin_segment")
pub fn pinyin_segment(pinyin : String) -> String {
  @segment.PinyinSegmenter::segment_best(pinyin).join(" ") catch {
    _ => ""
  }
}

///|
/// 拼音规范化（大小写 / 数字调 / v→ü）。
#export_name("pinyin_normalize")
pub fn pinyin_normalize(pinyin : String) -> String {
  @normalize.PinyinNormalizer::normalize(pinyin)
}

///|
/// 繁 → 简。
#export_name("pinyin_to_simplified")
pub fn pinyin_to_simplified(text : String) -> String {
  @convert.ChineseHelper::convert_to_simplified_chinese(text)
}

///|
/// 简 → 繁。
#export_name("pinyin_to_traditional")
pub fn pinyin_to_traditional(text : String) -> String {
  @convert.ChineseHelper::convert_to_traditional_chinese(text)
}

///|
/// 词句 → 拼音（带调、空格分隔）。
#export_name("pinyin_convert_sentence")
pub fn pinyin_convert_sentence(text : String) -> String {
  @convert.PinyinHelper::convert_to_pinyin_string(text, " ") catch { _ => "" }
}

///|
/// 自定义输出格式：format_name（mark/number/plain/initial）+ separator。
#export_name("pinyin_convert_format")
pub fn pinyin_convert_format(
  text : String,
  separator : String,
  format_name : String,
) -> String {
  @convert.PinyinHelper::convert_to_pinyin_string(
    text,
    separator,
    format=format_of(format_name),
  ) catch {
    _ => ""
  }
}

///|
/// 注入自定义单字读音字典后转换。
#export_name("pinyin_add_dict_char")
pub fn pinyin_add_dict_char(
  ch : String,
  readings : String,
  text : String,
) -> String {
  let dict : Map[String, String] = Map([])
  dict[ch] = readings
  @convert.PinyinHelper::add_pinyin_dict_resource(dict)
  @convert.PinyinHelper::convert_to_pinyin_string(text, " ") catch { _ => "" }
}

///|
/// 注入自定义词组读音字典后转换（readings 用逗号分隔）。
#export_name("pinyin_add_dict_phrase")
pub fn pinyin_add_dict_phrase(
  phrase : String,
  readings : String,
  text : String,
) -> String {
  let dict : Map[String, String] = Map([])
  dict[phrase] = readings
  @convert.PinyinHelper::add_mutil_pinyin_dict_resource(dict)
  @convert.PinyinHelper::convert_to_pinyin_string(text, " ") catch { _ => "" }
}

///|
/// 注入自定义繁简映射后转换（tr/simp 各取首字符码点）。
#export_name("pinyin_add_dict_chinese")
pub fn pinyin_add_dict_chinese(
  trad : String,
  simp : String,
  text : String,
) -> String {
  let t = trad.to_array()
  let s = simp.to_array()
  if t.length() == 1 && s.length() == 1 {
    let dict : Map[Int32, Int32] = Map([])
    dict[t[0].to_int()] = s[0].to_int()
    @convert.ChineseHelper::add_chinese_dict_resource(dict)
  }
  @convert.ChineseHelper::convert_to_simplified_chinese(text)
}

///|
/// 多音字读音集合：逐字一行 `字: 读音/读音`。
#export_name("pinyin_multi_readings")
pub fn pinyin_multi_readings(text : String) -> String {
  let lines : Array[String] = []
  for c in text {
    let readings = @convert.PinyinHelper::convert_to_pinyin_array(
      c,
      format=WithToneMark,
    )
    if readings.length() > 0 {
      lines.push(c.to_string() + ": " + readings.join("/"))
    } else {
      lines.push(c.to_string())
    }
  }
  lines.join("\n")
}

///|
/// 繁体文本 → 拼音（先繁转简）。
#export_name("pinyin_convert_traditional")
pub fn pinyin_convert_traditional(
  text : String,
  format_name : String,
) -> String {
  @convert.PinyinHelper::convert_to_pinyin_string_traditional(
    text,
    " ",
    format=format_of(format_name),
  ) catch {
    _ => ""
  }
}

///|
/// 通用拼音：逐字一行 `字: 读音/读音`。
#export_name("pinyin_tongyong")
pub fn pinyin_tongyong(text : String) -> String {
  let lines : Array[String] = []
  for c in text {
    let readings = @convert.PinyinHelper::to_tongyong_pinyin_string_array(c)
    if readings.length() > 0 {
      lines.push(c.to_string() + ": " + readings.join("/"))
    }
  }
  lines.join("\n")
}
