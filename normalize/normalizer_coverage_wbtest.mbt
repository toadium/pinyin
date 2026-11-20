///|
test "to_lower: 全字母与混合" {
  assert_eq(
    to_lower("ABCDEFGHIJKLMNOPQRSTUVWXYZ"),
    "abcdefghijklmnopqrstuvwxyz",
  )
  assert_eq(to_lower("A1-ü"), "a1-ü")
  assert_eq(to_lower(""), "")
}

///|
test "normalize: 各声调数字" {
  assert_eq(PinyinNormalizer::normalize("zhong1"), "zhōng")
  assert_eq(PinyinNormalizer::normalize("zhong2"), "zhóng")
  assert_eq(PinyinNormalizer::normalize("zhong3"), "zhǒng")
  assert_eq(PinyinNormalizer::normalize("zhong4"), "zhòng")
}

///|
test "normalize: 轻声数字 5" {
  assert_eq(PinyinNormalizer::normalize("ma5"), "ma")
  assert_eq(PinyinNormalizer::normalize("zhong5"), "zhong")
}

///|
test "normalize: 声调位置纠正" {
  assert_eq(PinyinNormalizer::normalize("zhōng"), "zhōng")
  assert_eq(PinyinNormalizer::normalize("zhòng"), "zhòng")
  assert_eq(PinyinNormalizer::normalize("nǚ"), "nǚ")
}

///|
test "normalize: 大写混数字" {
  assert_eq(PinyinNormalizer::normalize("ZHONG4"), "zhòng")
  assert_eq(PinyinNormalizer::normalize("LV4"), "lǜ")
}

///|
test "normalize_to_tone_number: 空与轻声" {
  assert_eq(PinyinNormalizer::normalize_to_tone_number(""), "")
  assert_eq(PinyinNormalizer::normalize_to_tone_number("ma"), "ma5")
  assert_eq(PinyinNormalizer::normalize_to_tone_number("ma5"), "ma5")
}

///|
test "normalize_to_without_tone: 空与轻声" {
  assert_eq(PinyinNormalizer::normalize_to_without_tone(""), "")
  assert_eq(PinyinNormalizer::normalize_to_without_tone("ma5"), "ma")
  assert_eq(PinyinNormalizer::normalize_to_without_tone("nǚ"), "nv")
}
