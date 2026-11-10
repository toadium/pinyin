///|
test "normalize: 数字调→带调标记 zhong1 → zhōng" {
  let result = @pinyin.PinyinNormalizer::normalize("zhong1")
  assert_eq(result, "zhōng")
}

///|
test "normalize: 大写→小写 ZHONG → zhong" {
  let result = @pinyin.PinyinNormalizer::normalize("ZHONG")
  assert_eq(result, "zhong")
}

///|
test "normalize: 大写+数字调 ZHONG1 → zhōng" {
  let result = @pinyin.PinyinNormalizer::normalize("ZHONG1")
  assert_eq(result, "zhōng")
}

///|
test "normalize: 带调标记保持不变 zhōng → zhōng" {
  let result = @pinyin.PinyinNormalizer::normalize("zhōng")
  assert_eq(result, "zhōng")
}

///|
test "normalize: v→ü 无调 nv → nü" {
  let result = @pinyin.PinyinNormalizer::normalize("nv")
  assert_eq(result, "nü")
}

///|
test "normalize: v→ü 数字调 nv3 → nǚ" {
  let result = @pinyin.PinyinNormalizer::normalize("nv3")
  assert_eq(result, "nǚ")
}

///|
test "normalize: 规范化到数字调 zhōng → zhong1" {
  let result = @pinyin.PinyinNormalizer::normalize_to_tone_number("zhōng")
  assert_eq(result, "zhong1")
}

///|
test "normalize: 规范化到无调 zhōng → zhong" {
  let result = @pinyin.PinyinNormalizer::normalize_to_without_tone("zhōng")
  assert_eq(result, "zhong")
}

///|
test "normalize: 无调拼音保持不变 zhong → zhong" {
  let result = @pinyin.PinyinNormalizer::normalize("zhong")
  assert_eq(result, "zhong")
}

///|
test "normalize: nü3 → nǚ" {
  let result = @pinyin.PinyinNormalizer::normalize("nü3")
  assert_eq(result, "nǚ")
}
