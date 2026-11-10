///|
test "disambiguate: 银行 → yín háng" {
  let result = @pinyin.PinyinDisambiguator::disambiguate("银行")
  assert_eq(result.length(), 2)
  assert_eq(result[0], "yín")
  assert_eq(result[1], "háng")
}

///|
test "disambiguate: 重要 → zhòng yào" {
  let result = @pinyin.PinyinDisambiguator::disambiguate("重要")
  assert_eq(result.length(), 2)
  assert_eq(result[0], "zhòng")
  assert_eq(result[1], "yào")
}

///|
test "disambiguate: 长城 → cháng chéng" {
  let result = @pinyin.PinyinDisambiguator::disambiguate("长城")
  assert_eq(result.length(), 2)
  assert_eq(result[0], "cháng")
  assert_eq(result[1], "chéng")
}

///|
test "disambiguate: 单字 → 返回第一个读音" {
  let result = @pinyin.PinyinDisambiguator::disambiguate("中")
  assert_eq(result.length(), 1)
  assert_eq(result[0], "zhōng")
}

///|
test "disambiguate: 空串 → raise PinyinError" {
  let raised = try {
    ignore(@pinyin.PinyinDisambiguator::disambiguate(""))
    false
  } catch {
    PinyinError(_) => true
  }
  assert_true(raised)
}

///|
test "disambiguate: 中国 → zhōng guó" {
  let result = @pinyin.PinyinDisambiguator::disambiguate("中国")
  assert_eq(result.length(), 2)
  assert_eq(result[0], "zhōng")
  assert_eq(result[1], "guó")
}

///|
test "disambiguate: 你好 → nǐ hǎo" {
  let result = @pinyin.PinyinDisambiguator::disambiguate("你好")
  assert_eq(result.length(), 2)
  assert_eq(result[0], "nǐ")
  assert_eq(result[1], "hǎo")
}
