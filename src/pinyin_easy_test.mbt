///|
/// PinyinFormat::name 方法对 4 个变体返回正确名称，对齐源库 getName() 行为契约。
test "format_name_returns_correct_strings" {
  inspect(PinyinFormat::WithToneMark.name(), content="WITH_TONE_MARK")
  inspect(PinyinFormat::WithoutTone.name(), content="WITHOUT_TONE")
  inspect(PinyinFormat::WithToneNumber.name(), content="WITH_TONE_NUMBER")
  inspect(PinyinFormat::FirstLetter.name(), content="FIRST_LETTER")
}

///|
/// 4 个变体的 name 返回值互不相同，确保枚举变体可经由 name 方法区分。
test "format_name_returns_distinct_strings" {
  let s1 = PinyinFormat::WithToneMark.name()
  let s2 = PinyinFormat::WithoutTone.name()
  let s3 = PinyinFormat::WithToneNumber.name()
  let s4 = PinyinFormat::FirstLetter.name()
  assert_true(
    s1 != s2 && s1 != s3 && s1 != s4 && s2 != s3 && s2 != s4 && s3 != s4,
  )
}

///|
/// PinyinError 可通过 raise 抛错并被 try...catch 捕获，提取携带的错误消息字符串。
test "error_carries_message" {
  try raise_pinyin_error("test message") catch {
    PinyinError(msg) => inspect(msg, content="test message")
  } noraise {
    _ => fail("expected PinyinError to be raised")
  }
}

///|
/// 边界条件：空字符串作为错误消息，验证 PinyinError 可承载空消息。
test "error_with_empty_message" {
  try raise_pinyin_error("") catch {
    PinyinError(msg) => inspect(msg, content="")
  } noraise {
    _ => fail("expected PinyinError to be raised")
  }
}

///|
/// 不同消息产生可区分的错误值，验证 PinyinError 忠实保留构造时传入的消息载荷。
test "error_preserves_distinct_messages" {
  try raise_pinyin_error("error one") catch {
    PinyinError(msg1) =>
      try raise_pinyin_error("error two") catch {
        PinyinError(msg2) => {
          assert_true(msg1 != msg2)
          inspect(msg1, content="error one")
          inspect(msg2, content="error two")
        }
      } noraise {
        _ => fail("expected second PinyinError to be raised")
      }
  } noraise {
    _ => fail("expected first PinyinError to be raised")
  }
}

///|
/// 辅助函数：抛出携带指定消息的 PinyinError，用于测试错误捕获行为。
fn raise_pinyin_error(msg : String) -> Unit raise PinyinError {
  raise PinyinError(msg)
}

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
    PinyinError(msg) => inspect(msg, content="Please enter a word or sentence")
  } noraise {
    _ => fail("expected PinyinError for empty string")
  }
}

///|
/// has_multi_pinyin 非汉字抛 PinyinError。
test "has_multi_pinyin_non_chinese_raises" {
  try PinyinHelper::has_multi_pinyin('x') catch {
    PinyinError(msg) => inspect(msg, content="Please enter a Chinese character")
  } noraise {
    _ => fail("expected PinyinError for non-Chinese character")
  }
}
