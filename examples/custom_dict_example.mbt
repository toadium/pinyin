///|
/// 添加自定义拼音字典
test "example_add_pinyin_dict_resource" {
  let map : Map[String, String] = { "上": "shǎng" }
  @convert.PinyinHelper::add_pinyin_dict_resource(map)
  let result = @convert.PinyinHelper::convert_to_pinyin_string("上午", " ")
  println(result)
}

///|
/// 添加自定义拼音组合字典
test "example_add_mutil_pinyin_dict_resource" {
  let map : Map[String, String] = { "阿弥陀佛": "ā,mí,tuó,fó" }
  @convert.PinyinHelper::add_mutil_pinyin_dict_resource(map)
  let result = @convert.PinyinHelper::convert_to_pinyin_string(
    "阿弥陀佛", " ",
  )
  println(result)
}

///|
/// 添加自定义中文字典
test "example_add_chinese_dict_resource" {
  let map : Map[Int32, Int32] = { 0x7691: 0x75C7 }
  @convert.ChineseHelper::add_chinese_dict_resource(map)
  let result = @convert.ChineseHelper::convert_to_simplified_chinese("癥")
  println(result)
}
