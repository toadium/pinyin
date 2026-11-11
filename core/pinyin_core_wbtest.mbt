///|

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
    _ => ()
  } noraise {
    _ => fail("expected PinyinError to be raised")
  }
}

///|
/// 边界条件：空字符串作为错误消息，验证 PinyinError 可承载空消息。
test "error_with_empty_message" {
  try raise_pinyin_error("") catch {
    _ => ()
  } noraise {
    _ => fail("expected PinyinError to be raised")
  }
}

///|
/// 不同消息产生可区分的错误值，验证 PinyinError 忠实保留构造时传入的消息载荷。
test "error_preserves_distinct_messages" {
  try raise_pinyin_error("error one") catch {
    _ =>
      try raise_pinyin_error("error two") catch {
        _ => ()
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
  raise_invalid_input(msg)
}
