///|
test "fuzzy: 空串错误路径" {
  let caught_expand = try {
    let _ = FuzzyPinyinHelper::fuzzy_expand("")
    false
  } catch {
    _ => true
  }
  assert_true(caught_expand)
  let caught_match1 = try {
    let _ = FuzzyPinyinHelper::fuzzy_match("", "ni")
    false
  } catch {
    _ => true
  }
  assert_true(caught_match1)
  let caught_match2 = try {
    let _ = FuzzyPinyinHelper::fuzzy_match("ni", "")
    false
  } catch {
    _ => true
  }
  assert_true(caught_match2)
  let caught_reverse = try {
    let _ = FuzzyPinyinHelper::fuzzy_reverse_lookup("")
    false
  } catch {
    _ => true
  }
  assert_true(caught_reverse)
}

///|
test "fuzzy: 相同/等价/不等价" {
  assert_true(FuzzyPinyinHelper::fuzzy_match("ni", "ni"))
  assert_true(FuzzyPinyinHelper::fuzzy_match("zhong", "zong"))
  assert_false(FuzzyPinyinHelper::fuzzy_match("zhong", "chang"))
}

///|
test "fuzzy: 非法音节只保留自身" {
  assert_eq(FuzzyPinyinHelper::fuzzy_expand("zzz"), ["zzz"])
  assert_true(FuzzyPinyinHelper::fuzzy_expand("zong").contains("zhong"))
}

///|
test "fuzzy: 模糊反向查找" {
  let zh = FuzzyPinyinHelper::fuzzy_reverse_lookup("zhong")
  assert_true(zh.length() > 0)
  assert_true(zh.contains("中"))
  let zong = FuzzyPinyinHelper::fuzzy_reverse_lookup("zong")
  assert_true(zong.length() > 0)
}

///|
test "fuzzy: 自定义规则生效并可回滚" {
  assert_false(FuzzyPinyinHelper::apply_fuzzy_rules("ran").contains("lan"))
  FuzzyPinyinHelper::add_fuzzy_rules([Prefix("r", "l")])
  assert_true(FuzzyPinyinHelper::apply_fuzzy_rules("ran").contains("lan"))
  ignore(fuzzy_rules.pop())
  assert_false(FuzzyPinyinHelper::apply_fuzzy_rules("ran").contains("lan"))
}
