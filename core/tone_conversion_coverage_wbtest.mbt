///|
test "strip_tone: 带调元音与 ü" {
  assert_eq(strip_tone("nǐ"), "ni")
  assert_eq(strip_tone("lǚ"), "lv")
  assert_eq(strip_tone("zhōng"), "zhong")
  assert_eq(strip_tone("shuì"), "shui")
  assert_eq(strip_tone("zhong"), "zhong")
  assert_eq(strip_tone(""), "")
}

///|
test "strip_tone_number: 0-5 后缀" {
  assert_eq(strip_tone_number("zhong1"), "zhong")
  assert_eq(strip_tone_number("zhong5"), "zhong")
  assert_eq(strip_tone_number("zhong0"), "zhong")
  assert_eq(strip_tone_number("zhong"), "zhong")
  assert_eq(strip_tone_number("5"), "")
}

///|
test "convert_with_tone_number: 带调/轻声/ü/多音节" {
  assert_eq(convert_with_tone_number("zhōng,guó"), ["zhong1", "guo2"])
  assert_eq(convert_with_tone_number("lǚ"), ["lv3"])
  assert_eq(convert_with_tone_number("ma"), ["ma5"])
  assert_eq(convert_with_tone_number("nǐ,hǎo"), ["ni3", "hao3"])
}

///|
test "convert_without_tone: 多音节与 ü" {
  assert_eq(convert_without_tone("zhōng,guó"), ["zhong", "guo"])
  assert_eq(convert_without_tone("lǚ"), ["lv"])
  assert_eq(convert_without_tone(""), [""])
}

///|
test "format_pinyin: 四格式" {
  assert_eq(format_pinyin("nǐ,hǎo", WithToneMark), ["nǐ", "hǎo"])
  assert_eq(format_pinyin("nǐ,hǎo", WithToneNumber), ["ni3", "hao3"])
  assert_eq(format_pinyin("nǐ,hǎo", WithoutTone), ["ni", "hao"])
  assert_eq(format_pinyin("nǐ,hǎo", FirstLetter), ["ni", "hao"])
}

///|
test "get_tone_number: 标记/数字/无调" {
  assert_eq(get_tone_number("nǐ"), 3)
  assert_eq(get_tone_number("zhōng"), 1)
  assert_eq(get_tone_number("zhong2"), 2)
  assert_eq(get_tone_number("zhong5"), 0)
  assert_eq(get_tone_number("zhong"), 0)
  assert_eq(get_tone_number(""), 0)
}

///|
test "is_vowel_char" {
  assert_true(is_vowel_char('a'))
  assert_true(is_vowel_char('e'))
  assert_true(is_vowel_char('i'))
  assert_true(is_vowel_char('o'))
  assert_true(is_vowel_char('u'))
  assert_true(is_vowel_char('v'))
  assert_false(is_vowel_char('b'))
  assert_false(is_vowel_char('ü'))
}

///|
test "set_tone: 标调位置规则" {
  assert_eq(set_tone("zhong", 1), "zhōng")
  assert_eq(set_tone("hao", 4), "hào")
  assert_eq(set_tone("xue", 2), "xué")
  assert_eq(set_tone("wo", 3), "wǒ")
  assert_eq(set_tone("liu", 2), "liú")
  assert_eq(set_tone("gui", 3), "guǐ")
  assert_eq(set_tone("shui", 4), "shuì")
  assert_eq(set_tone("nv", 3), "nǚ")
  assert_eq(set_tone("zhuang", 4), "zhuàng")
}

///|
test "set_tone: 非法输入" {
  assert_eq(set_tone("zhong", 0), "zhong")
  assert_eq(set_tone("zhong", 5), "zhong")
  assert_eq(set_tone("xyz", 1), "xyz")
  assert_eq(set_tone("", 1), "")
}

///|
test "find_array_key_by_value" {
  assert_eq(find_array_key_by_value('ā'), 0)
  assert_eq(find_array_key_by_value('ǜ'), 23)
  assert_eq(find_array_key_by_value('a'), -1)
}
