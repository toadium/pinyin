///|
test "disambiguate: 空串抛错" {
  let caught = try {
    let _ = PinyinDisambiguator::disambiguate("")
    false
  } catch {
    _ => true
  }
  assert_true(caught)
}

///|
test "disambiguate: 单字与单字符" {
  let zhōng = PinyinDisambiguator::disambiguate("中")
  assert_eq(zhōng.length(), 1)
  assert_eq(zhōng[0], "zhōng")
  let latin = PinyinDisambiguator::disambiguate("A")
  assert_eq(latin.length(), 1)
  assert_eq(latin[0], "A")
}

///|
test "disambiguate: 多音单字返回首读音" {
  let result = PinyinDisambiguator::disambiguate("重")
  assert_eq(result.length(), 1)
  assert_true(result[0].length() > 0)
}

///|
test "disambiguate: 中英混合" {
  assert_eq(PinyinDisambiguator::disambiguate("中A国"), [
    "zhōng", "A", "guó",
  ])
}

///|
test "disambiguate: 三字词" {
  let result = PinyinDisambiguator::disambiguate("中国人")
  assert_eq(result.length(), 3)
  assert_eq(result[0], "zhōng")
  assert_eq(result[1], "guó")
  assert_eq(result[2], "rén")
}
