///|
/// 验证 PinyinFormat::name 方法对 WithToneMark 变体返回 "WITH_TONE_MARK"，
/// 对齐源库 pinyin4cj 的 getName() 行为契约。
test "with_tone_mark_name_returns_WITH_TONE_MARK" {
  debug_inspect(@pinyin.PinyinFormat::WithToneMark.name(), content=(
    #|"WITH_TONE_MARK"
  ))
}

///|
/// 验证 PinyinFormat::name 方法对 WithoutTone 变体返回 "WITHOUT_TONE"。
test "without_tone_name_returns_WITHOUT_TONE" {
  debug_inspect(@pinyin.PinyinFormat::WithoutTone.name(), content=(
    #|"WITHOUT_TONE"
  ))
}

///|
/// 验证 PinyinFormat::name 方法对 WithToneNumber 变体返回 "WITH_TONE_NUMBER"。
test "with_tone_number_name_returns_WITH_TONE_NUMBER" {
  debug_inspect(
    @pinyin.PinyinFormat::WithToneNumber.name(),
    content=(
      #|"WITH_TONE_NUMBER"
    ),
  )
}

///|
/// 验证 PinyinFormat::name 方法对 FirstLetter 变体返回 "FIRST_LETTER"。
test "first_letter_name_returns_FIRST_LETTER" {
  debug_inspect(@pinyin.PinyinFormat::FirstLetter.name(), content=(
    #|"FIRST_LETTER"
  ))
}

///|
/// 状态交互：验证 4 个变体的 name 返回值互不相同，
/// 确保枚举变体可经由 name 方法区分，覆盖所有变体（边界/穷尽）。
test "name_returns_distinct_strings_for_all_variants" {
  let s1 = @pinyin.PinyinFormat::WithToneMark.name()
  let s2 = @pinyin.PinyinFormat::WithoutTone.name()
  let s3 = @pinyin.PinyinFormat::WithToneNumber.name()
  let s4 = @pinyin.PinyinFormat::FirstLetter.name()
  assert_true(
    s1 != s2 && s1 != s3 && s1 != s4 && s2 != s3 && s2 != s4 && s3 != s4,
  )
}
