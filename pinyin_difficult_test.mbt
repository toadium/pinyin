///|
/// 字典完整性：验证四张字典条目数与设计契约一致。
/// chinese_dict 2533 条（源库 2543 条含 10 组重复 key，去重后 2533）。
/// pinyin_dict 20903 条（源库 41806 行 / 2 = 20903 组）。
/// mutil_pinyin_dict 843 条（源库 845 条含 2 组重复 key，去重后 843）。
/// tongyong_pinyin_dict 82 条。
test "dicts_have_expected_entry_counts" {
  inspect(chinese_map.length(), content="2533")
  inspect(pinyin_table.length(), content="20903")
  inspect(mutil_pinyin_table.length(), content="843")
  inspect(tongyong_pinyin_table.length(), content="82")
  inspect(@data.chinese_dict.length(), content="2533")
  inspect(@data.pinyin_dict.length(), content="20903")
  inspect(@data.mutil_pinyin_dict.length(), content="843")
  inspect(@data.tongyong_pinyin_dict.length(), content="82")
}

///|
/// 字典完整性：chinese_dict 的所有 value 均为有效 Unicode 码点（BMP 区间 <= 0xFFFF）。
/// 抽样验证首条目 0x4E1F→0x4E22 与末条目 0x9F9C→0x9F9F。
test "chinese_dict_values_are_valid_codepoints" {
  match @data.chinese_dict.get(0x4E1F) {
    Some(v) => assert_true(v <= 0xFFFF)
    None => fail("expected key 0x4E1F in chinese_dict")
  }
  match @data.chinese_dict.get(0x9F9C) {
    Some(v) => assert_true(v <= 0xFFFF)
    None => fail("expected key 0x9F9C in chinese_dict")
  }
}

///|
/// 字典完整性：pinyin_dict 中"〇"映射为"líng"（首条目），"丁"映射为"dīng,zhēng"（多音字）。
test "pinyin_dict_key_samples" {
  match @data.pinyin_dict.get("〇") {
    Some(v) => inspect(v, content="líng")
    None => fail("expected key \"〇\" in pinyin_dict")
  }
  match @data.pinyin_dict.get("丁") {
    Some(v) => inspect(v, content="dīng,zhēng")
    None => fail("expected key \"丁\" in pinyin_dict")
  }
}

///|
/// 字典完整性：mutil_pinyin_dict 中"一丘之貉"映射为"yī,qiū,zhī,hé"（四字词组拼音）。
test "mutil_pinyin_dict_key_samples" {
  match @data.mutil_pinyin_dict.get("一丘之貉") {
    Some(v) => inspect(v, content="yī,qiū,zhī,hé")
    None => fail("expected key \"一丘之貉\" in mutil_pinyin_dict")
  }
}

///|
/// 字典完整性：tongyong_pinyin_dict 中"chui"映射为"chuei"。
test "tongyong_pinyin_dict_key_samples" {
  match @data.tongyong_pinyin_dict.get("chui") {
    Some(v) => inspect(v, content="chuei")
    None => fail("expected key \"chui\" in tongyong_pinyin_dict")
  }
}
