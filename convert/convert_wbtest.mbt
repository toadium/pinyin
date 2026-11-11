///|

///|
/// is_chinese 判断汉字：CJK 范围内为 true，非汉字为 false。
test "is_chinese_basic" {
  assert_true(ChineseHelper::is_chinese('我'))
  assert_true(ChineseHelper::is_chinese('中'))
  assert_true(ChineseHelper::is_chinese('〇'))
  assert_false(ChineseHelper::is_chinese('a'))
  assert_false(ChineseHelper::is_chinese('1'))
  assert_false(ChineseHelper::is_chinese(' '))
}

///|
/// contains_chinese 判断字符串是否含汉字。
test "contains_chinese_basic" {
  assert_true(ChineseHelper::contains_chinese("hello世界"))
  assert_true(ChineseHelper::contains_chinese("中国"))
  assert_false(ChineseHelper::contains_chinese("hello"))
  assert_false(ChineseHelper::contains_chinese("123"))
}

///|
/// 繁→简转换：逐字符查 chinese_map 替换。
test "convert_to_simplified_chinese" {
  inspect(
    ChineseHelper::convert_to_simplified_chinese("臺灣"),
    content="台湾",
  )
  inspect(ChineseHelper::convert_to_simplified_chinese("萬"), content="万")
  inspect(
    ChineseHelper::convert_to_simplified_chinese("简体"),
    content="简体",
  )
  inspect(ChineseHelper::convert_to_simplified_chinese(""), content="")
}

///|
/// 简→繁转换：逐字符反查 chinese_map。
test "convert_to_traditional_chinese" {
  inspect(
    ChineseHelper::convert_to_traditional_chinese("台湾"),
    content="臺灣",
  )
  inspect(ChineseHelper::convert_to_traditional_chinese("万"), content="萬")
  inspect(
    ChineseHelper::convert_to_traditional_chinese("繁体"),
    content="繁體",
  )
}

///|
/// is_traditional_chinese 判断繁体汉字。
test "is_traditional_chinese_basic" {
  assert_true(ChineseHelper::is_traditional_chinese('臺'))
  assert_true(ChineseHelper::is_traditional_chinese('萬'))
  assert_false(ChineseHelper::is_traditional_chinese('台'))
  assert_false(ChineseHelper::is_traditional_chinese('a'))
}

///|
/// 单字转拼音数组：查 pinyin_table 返回所有读音。
test "convert_to_pinyin_array_basic" {
  debug_inspect(
    PinyinHelper::convert_to_pinyin_array('一'),
    content="[\"yī\"]",
  )
  debug_inspect(
    PinyinHelper::convert_to_pinyin_array('丁'),
    content="[\"dīng\", \"zhēng\"]",
  )
  debug_inspect(PinyinHelper::convert_to_pinyin_array('x'), content="[]")
}

///|
/// 空串转拼音抛 PinyinError。
test "convert_to_pinyin_string_empty_raises" {
  try PinyinHelper::convert_to_pinyin_string("", " ") catch {
    _ => ()
  } noraise {
    _ => fail("expected PinyinError for empty string")
  }
}

///|
/// has_multi_pinyin 非汉字抛 PinyinError。
test "has_multi_pinyin_non_chinese_raises" {
  try PinyinHelper::has_multi_pinyin('x') catch {
    _ => ()
  } noraise {
    _ => fail("expected PinyinError for non-Chinese character")
  }
}
