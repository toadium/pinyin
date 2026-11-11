///|
/// 多音字转拼音集合
test "example_convert_to_pinyin_array_multi" {
  let result = @convert.PinyinHelper::convert_to_pinyin_array('长')
  println(Repr(result))
}

///|
/// 繁简体转拼音
test "example_convert_to_pinyin_array_traditional" {
  let result = @convert.PinyinHelper::convert_to_pinyin_array('嚴')
  println(Repr(result))
}

///|
/// 多音字检测
test "example_has_multi_pinyin" {
  let result = @convert.PinyinHelper::has_multi_pinyin('中')
  println(result)
}

///|
/// 繁简体转通用拼音
test "example_tongyong_pinyin" {
  let simple = @convert.PinyinHelper::to_tongyong_pinyin_string_array('傳')
  let traditional = @convert.PinyinHelper::to_tongyong_pinyin_string_array(
    '传',
  )
  println(Repr(simple))
  println(Repr(traditional))
}
