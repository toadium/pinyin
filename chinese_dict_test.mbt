///|
/// 验证 chinese_dict 条目数为 2543，对齐设计 §概述/实际条目数核对
/// （源库 chinese.dict.cj 2556 行，条目第 13-2555 行共 2543 条）。
test "chinese_dict_has_2543_entries" {
  inspect(@data.chinese_dict.length(), content="2543")
}

///|
/// 验证 chinese_dict 中繁体"臺"(0x81FA) 映射到简体"台"(0x53F0)，
/// 对齐源库 chinese.dict.cj 条目 (r'臺', r'台')。
test "chinese_dict_maps_0x81FA_to_0x53F0" {
  match @data.chinese_dict.get(0x81FA) {
    Some(v) => inspect(v, content="21488")
    None => fail("expected key 0x81FA in chinese_dict")
  }
}

///|
/// 验证 chinese_dict 中繁体"萬"(0x842C) 映射到简体"万"(0x4E07)，
/// 对齐源库 chinese.dict.cj 条目 (r'萬', r'万')。
test "chinese_dict_maps_0x842C_to_0x4E07" {
  match @data.chinese_dict.get(0x842C) {
    Some(v) => inspect(v, content="19975")
    None => fail("expected key 0x842C in chinese_dict")
  }
}

///|
/// 边界条件：不存在的 key 返回 None，验证 chinese_dict 仅含已知繁体码点。
test "chinese_dict_returns_none_for_absent_key" {
  match @data.chinese_dict.get(0x00) {
    Some(_) => fail("expected None for absent key 0x00")
    None => ()
  }
}

///|
/// 状态交互：chinese_dict 的所有 value 均为有效 Unicode 码点，
/// 抽样验证首条目 0x4E1F→0x4E22 与末条目 0x9F9C→0x9F9F 均落在 BMP 区间（<= 0xFFFF）。
/// 繁简体汉字同属 CJK 统一表意文字 BMP 区间（U+4E00–U+9FFF），value 不应超出 BMP。
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