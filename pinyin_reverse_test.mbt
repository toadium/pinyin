///|
/// 拼音→汉字反向查找：无调拼音 "zhong" 返回包含 "中" 的汉字列表。
test "reverse_lookup_zhong" {
  let chars = @pinyin.ReversePinyinHelper::reverse_lookup("zhong")
  assert_true(chars.contains("中"))
  assert_true(chars.length() > 0)
}

///|
/// 拼音→汉字反向查找：无调拼音 "guo" 返回包含 "国" 的汉字列表。
test "reverse_lookup_guo" {
  let chars = @pinyin.ReversePinyinHelper::reverse_lookup("guo")
  assert_true(chars.contains("国"))
}

///|
/// 拼音→汉字反向查找：无调拼音 "ni" 返回包含 "你" 或 "尼" 的汉字列表。
test "reverse_lookup_ni" {
  let chars = @pinyin.ReversePinyinHelper::reverse_lookup("ni")
  assert_true(chars.length() > 0)
}

///|
/// 带调拼音→汉字反向查找："zhōng" 返回包含 "中" 的汉字列表。
test "reverse_lookup_tone_mark_zhong" {
  let chars = @pinyin.ReversePinyinHelper::reverse_lookup_tone_mark("zhōng")
  assert_true(chars.contains("中"))
}

///|
/// 带调拼音→汉字反向查找："lǚ" 返回包含 "吕" 或 "旅" 的汉字列表。
test "reverse_lookup_tone_mark_lv" {
  let chars = @pinyin.ReversePinyinHelper::reverse_lookup_tone_mark("lǚ")
  assert_true(chars.length() > 0)
}

///|
/// 数字调拼音→汉字反向查找："zhong1" 返回包含 "中" 的汉字列表。
test "reverse_lookup_tone_number_zhong" {
  let chars = @pinyin.ReversePinyinHelper::reverse_lookup_tone_number("zhong1")
  assert_true(chars.contains("中"))
}

///|
/// 数字调拼音→汉字反向查找："guo2" 返回包含 "国" 的汉字列表。
test "reverse_lookup_tone_number_guo2" {
  let chars = @pinyin.ReversePinyinHelper::reverse_lookup_tone_number("guo2")
  assert_true(chars.contains("国"))
}

///|
/// 空串反向查找抛 PinyinError。
test "reverse_lookup_empty_raises" {
  try @pinyin.ReversePinyinHelper::reverse_lookup("") catch {
    PinyinError(msg) => inspect(msg, content="Please enter a pinyin syllable")
  } noraise {
    _ => fail("expected PinyinError for empty string")
  }
}

///|
/// 不存在的拼音返回空数组。
test "reverse_lookup_nonexistent_returns_empty" {
  let chars = @pinyin.ReversePinyinHelper::reverse_lookup("xyz")
  assert_true(chars.length() == 0)
}

///|
/// is_valid_pinyin：合法拼音返回 true，非法拼音返回 false。
test "is_valid_pinyin" {
  assert_true(@pinyin.ReversePinyinHelper::is_valid_pinyin("zhong"))
  assert_true(@pinyin.ReversePinyinHelper::is_valid_pinyin("a"))
  assert_true(@pinyin.ReversePinyinHelper::is_valid_pinyin("xian"))
  assert_false(@pinyin.ReversePinyinHelper::is_valid_pinyin("xyz"))
  assert_false(@pinyin.ReversePinyinHelper::is_valid_pinyin("niha"))
}
