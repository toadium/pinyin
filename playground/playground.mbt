///|
/// 浏览器演示导出层（JavaScript 后端）。
/// 所有导出函数均为非 raise 签名：错误折叠为空串，JS 侧无需异常映射。

///|
#export_name("pinyin_version")
pub fn pinyin_version() -> String {
  @pinyin.version
}

///|
/// 汉字 → 拼音。format: "mark"（默认）、"number"、"plain"、"initial"。
#export_name("pinyin_convert")
pub fn pinyin_convert(
  text : String,
  separator : String,
  format_name : String,
) -> String {
  let format : @core.PinyinFormat = match format_name {
    "number" => WithToneNumber
    "plain" => WithoutTone
    "initial" => FirstLetter
    _ => WithToneMark
  }
  @convert.PinyinHelper::convert_to_pinyin_string(text, separator, format~) catch {
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
