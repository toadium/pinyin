///|
/// 繁体转简体
test "example_convert_to_simplified_chinese" {
  let result = @pinyin.ChineseHelper::convert_to_simplified_chinese(
    "臺，喪，麗",
  )
  println(result)
}

///|
/// 简体转繁体
test "example_convert_to_traditional_chinese" {
  let result = @pinyin.ChineseHelper::convert_to_traditional_chinese(
    "我是中国人",
  )
  println(result)
}
