///|
/// 词、句转换成拼音（默认带声调）
test "example_convert_to_pinyin_string" {
  let result = @pinyin.PinyinHelper::convert_to_pinyin_string(
    "我是中国人", " ",
  )
  println(result)
}

///|
/// 自定义输出格式：带声调数字
test "example_with_tone_number" {
  let result = @pinyin.PinyinHelper::convert_to_pinyin_string(
    "中国",
    " ",
    format=@pinyin.PinyinFormat::WithToneNumber,
  )
  println(result)
}

///|
/// 自定义输出格式：无声调
test "example_without_tone" {
  let result = @pinyin.PinyinHelper::convert_to_pinyin_string(
    "中国",
    " ",
    format=@pinyin.PinyinFormat::WithoutTone,
  )
  println(result)
}

///|
/// 自定义输出格式：首字母
test "example_first_letter" {
  let result = @pinyin.PinyinHelper::convert_to_pinyin_string(
    "中国",
    " ",
    format=@pinyin.PinyinFormat::FirstLetter,
  )
  println(result)
}

///|
/// 首字母格式拼音
test "example_get_short_pinyin" {
  let result = @pinyin.PinyinHelper::get_short_pinyin("中国")
  println(result)
}
