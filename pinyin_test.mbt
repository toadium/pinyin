///|
/// README 示例 1：繁体转简体。`ChineseHelper.convertToSimplifiedChinese("臺，喪，麗")` → `"台，丧，丽"`。
test "readme_example_1_traditional_to_simplified" {
  debug_inspect(
    ChineseHelper::convert_to_simplified_chinese("臺，喪，麗"),
    content=(
      #|"台，丧，丽"
    ),
  )
}

///|
/// README 示例 2：简体转繁体。`ChineseHelper.convertToTraditionalChinese("我是中国人")` → `"我是中國人"`。
test "readme_example_2_simplified_to_traditional" {
  debug_inspect(
    ChineseHelper::convert_to_traditional_chinese("我是中国人"),
    content=(
      #|"我是中國人"
    ),
  )
}

///|
/// README 示例 3：词句转拼音（带声调标记）。
test "readme_example_3_convert_to_pinyin_string" {
  debug_inspect(
    PinyinHelper::convert_to_pinyin_string(
      "我是中国共产主义接班人。", " ",
    ),
    content=(
      #|"wǒ shì zhōng guó gòng chǎn zhǔ yì jiē bān rén 。"
    ),
  )
}

///|
/// README 示例 4：自定义输出格式（带声调数字）。
test "readme_example_4_convert_to_pinyin_string_tone_number" {
  debug_inspect(
    PinyinHelper::convert_to_pinyin_string(
      "我是中国共产主义接班人。",
      " ",
      format=PinyinFormat::WithToneNumber,
    ),
    content=(
      #|"wo3 shi4 zhong1 guo2 gong4 chan3 zhu3 yi4 jie1 ban1 ren2 。"
    ),
  )
}

///|
/// README 示例 8：多音字转拼音集合。`convertToPinyinArray('长', WithToneMark)` → `["cháng", "zhǎng"]`。
test "readme_example_8_multi_pinyin_array" {
  debug_inspect(
    PinyinHelper::convert_to_pinyin_array(
      '长',
      format=PinyinFormat::WithToneMark,
    ),
    content=(
      #|["cháng", "zhǎng"]
    ),
  )
}

///|
/// README 示例 9：繁简体转拼音。`convertToPinyinArray('嚴', WithToneMark)` → `["yán"]`。
test "readme_example_9_traditional_pinyin_array" {
  debug_inspect(
    PinyinHelper::convert_to_pinyin_array(
      '嚴',
      format=PinyinFormat::WithToneMark,
    ),
    content=(
      #|["yán"]
    ),
  )
}

///|
/// README 示例 10：繁简体转通用拼音。`toTongyongPinyinStringArray('傳')` → `["chuan2", "jhuan4"]`。
test "readme_example_10a_tongyong_pinyin_traditional" {
  debug_inspect(
    PinyinHelper::to_tongyong_pinyin_string_array('傳'),
    content=(
      #|["chuan2", "jhuan4"]
    ),
  )
}

///|
/// README 示例 10：`toTongyongPinyinStringArray('传')` → `["chuan2", "jhuan4"]`。
test "readme_example_10b_tongyong_pinyin_simplified" {
  debug_inspect(
    PinyinHelper::to_tongyong_pinyin_string_array('传'),
    content=(
      #|["chuan2", "jhuan4"]
    ),
  )
}

///|
/// 空串抛 `PinyinError("Please enter a word or sentence")`。
test "convert_to_pinyin_string_empty_raises" {
  try PinyinHelper::convert_to_pinyin_string("", " ") catch {
    PinyinError::PinyinError(msg) =>
      debug_inspect(msg, content=(
        #|"Please enter a word or sentence"
      ))
  } noraise {
    _ => fail("expected PinyinError for empty string")
  }
}

///|
/// 非汉字抛 `PinyinError("Please enter a Chinese character")`。
test "has_multi_pinyin_non_chinese_raises" {
  try PinyinHelper::has_multi_pinyin('x') catch {
    PinyinError::PinyinError(msg) =>
      debug_inspect(msg, content=(
        #|"Please enter a Chinese character"
      ))
  } noraise {
    _ => fail("expected PinyinError for non-Chinese character")
  }
}

///|
/// `is_chinese` 正向：汉字返回 true。
test "is_chinese_true_for_chinese" {
  assert_true(ChineseHelper::is_chinese('我'))
}

///|
/// `is_chinese` 边界：非汉字返回 false。
test "is_chinese_false_for_non_chinese" {
  assert_false(ChineseHelper::is_chinese('x'))
}

///|
/// `is_traditional_chinese` 正向：繁体字返回 true。
test "is_traditional_chinese_true" {
  assert_true(ChineseHelper::is_traditional_chinese('臺'))
}

///|
/// `is_traditional_chinese` 边界：简体字返回 false。
test "is_traditional_chinese_false_for_simplified" {
  assert_false(ChineseHelper::is_traditional_chinese('台'))
}

///|
/// `contains_chinese` 正向：含汉字返回 true。
test "contains_chinese_true" {
  assert_true(ChineseHelper::contains_chinese("abc我是中国人"))
}

///|
/// `contains_chinese` 边界：不含汉字返回 false。
test "contains_chinese_false" {
  assert_false(ChineseHelper::contains_chinese("abc123"))
}

///|
/// `has_multi_pinyin` 正向：多音字"长"返回 true。
test "has_multi_pinyin_true" {
  assert_true(PinyinHelper::has_multi_pinyin('长'))
}

///|
/// `has_multi_pinyin` 边界：单音字"我"返回 false。
test "has_multi_pinyin_false" {
  assert_false(PinyinHelper::has_multi_pinyin('我'))
}

///|
/// `get_short_pinyin` 首字母格式。
test "get_short_pinyin" {
  debug_inspect(PinyinHelper::get_short_pinyin("我是中国人"), content=(
    #|"wszgr"
  ))
}

///|
/// `convert_to_pinyin_string_traditional` 繁体词句转拼音。
test "convert_to_pinyin_string_traditional" {
  debug_inspect(
    PinyinHelper::convert_to_pinyin_string_traditional("我是中國人", " "),
    content=(
      #|"wǒ shì zhōng guó rén"
    ),
  )
}

///|
/// `convert_to_pinyin_array` 非汉字返回空数组。
test "convert_to_pinyin_array_non_chinese_returns_empty" {
  debug_inspect(
    PinyinHelper::convert_to_pinyin_array(
      'x',
      format=PinyinFormat::WithToneMark,
    ),
    content="[]",
  )
}

///|
/// `convert_to_pinyin_array` WithToneNumber 格式。
test "convert_to_pinyin_array_with_tone_number" {
  debug_inspect(
    PinyinHelper::convert_to_pinyin_array(
      '我',
      format=PinyinFormat::WithToneNumber,
    ),
    content=(
      #|["wo3"]
    ),
  )
}

///|
/// `convert_to_pinyin_array` WithoutTone 格式。
test "convert_to_pinyin_array_without_tone" {
  debug_inspect(
    PinyinHelper::convert_to_pinyin_array(
      '我',
      format=PinyinFormat::WithoutTone,
    ),
    content=(
      #|["wo"]
    ),
  )
}

///|
/// `convert_to_pinyin_array` FirstLetter 格式。
test "convert_to_pinyin_array_first_letter" {
  debug_inspect(
    PinyinHelper::convert_to_pinyin_array(
      '我',
      format=PinyinFormat::FirstLetter,
    ),
    content=(
      #|["w"]
    ),
  )
}

///|
/// 汉字零 '〇' (U+3007) 特殊处理。
test "chinese_ling_pinyin" {
  debug_inspect(PinyinHelper::convert_to_pinyin_string("〇", " "), content=(
    #|"líng"
  ))
}

///|
/// `PinyinFormat::name` 方法验证（通过 @pinyin 黑盒调用）。
test "pinyin_format_name_via_helper" {
  debug_inspect(PinyinFormat::WithToneMark.name(), content=(
    #|"WITH_TONE_MARK"
  ))
}
