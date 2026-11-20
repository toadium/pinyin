///|
test "reverse: 空串错误路径" {
  let caught = try {
    let _ = ReversePinyinHelper::reverse_lookup("")
    false
  } catch {
    _ => true
  }
  assert_true(caught)
  let caught_mark = try {
    let _ = ReversePinyinHelper::reverse_lookup_tone_mark("")
    false
  } catch {
    _ => true
  }
  assert_true(caught_mark)
  let caught_number = try {
    let _ = ReversePinyinHelper::reverse_lookup_tone_number("")
    false
  } catch {
    _ => true
  }
  assert_true(caught_number)
}

///|
test "reverse: 三种调用形式一致" {
  let plain = ReversePinyinHelper::reverse_lookup("zhong")
  assert_true(plain.length() > 0)
  assert_true(plain.contains("中"))
  assert_eq(
    ReversePinyinHelper::reverse_lookup_tone_mark("zhōng").length(),
    plain.length(),
  )
  assert_eq(
    ReversePinyinHelper::reverse_lookup_tone_number("zhong1").length(),
    plain.length(),
  )
}

///|
test "reverse: 未知拼音与合法性判断" {
  assert_eq(ReversePinyinHelper::reverse_lookup("zzz").length(), 0)
  assert_true(ReversePinyinHelper::is_valid_pinyin("zhong"))
  assert_false(ReversePinyinHelper::is_valid_pinyin("zzz"))
  assert_false(ReversePinyinHelper::is_valid_pinyin(""))
}
