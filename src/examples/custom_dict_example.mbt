///|
/// 添加自定义拼音字典
test "example_add_pinyin_dict_resource" {
  let map : Map[String, String] = { "上": "shǎng" }
  @pinyin.PinyinHelper::add_pinyin_dict_resource(map)
  let result = @pinyin.PinyinHelper::convert_to_pinyin_string("上午", " ")
  println(result)
}

///|
/// 添加自定义拼音组合字典
test "example_add_mutil_pinyin_dict_resource" {
  let map : Map[String, String] = { "阿弥陀佛": "ā,mí,tuó,fó" }
  @pinyin.PinyinHelper::add_mutil_pinyin_dict_resource(map)
  let result = @pinyin.PinyinHelper::convert_to_pinyin_string(
    "阿弥陀佛", " ",
  )
  println(result)
}

///|
/// 添加自定义中文字典
test "example_add_chinese_dict_resource" {
  let map : Map[Int, Int] = { 0x7691: 0x75C7 }
  @pinyin.ChineseHelper::add_chinese_dict_resource(map)
  let result = @pinyin.ChineseHelper::convert_to_simplified_chinese("癥")
  println(result)
}
