///|
/// 拼音输出格式枚举，对齐源库 pinyin4cj 的 PinyinFormat。
/// 4 个变体分别对应：带声调标记 / 不带声调 / 带声调数字 / 首字母。
pub(all) enum PinyinFormat {
  WithToneMark
  WithoutTone
  WithToneNumber
  FirstLetter
}

///|
/// 返回格式名称字符串（大写下划线形式），逐字符对齐源库 getName()。
pub fn PinyinFormat::name(self : PinyinFormat) -> String {
  match self {
    WithToneMark => "WITH_TONE_MARK"
    WithoutTone => "WITHOUT_TONE"
    WithToneNumber => "WITH_TONE_NUMBER"
    FirstLetter => "FIRST_LETTER"
  }
}
