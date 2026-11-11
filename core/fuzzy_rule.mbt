///|
/// 模糊匹配规则类型：Prefix 表示声母替换，Suffix 表示韵母后缀替换。
pub(all) enum FuzzyRule {
  Prefix(String, String)
  Suffix(String, String)
}
