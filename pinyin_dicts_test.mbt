///|
/// 验证 chinese_map 视图常量条目数为 2533，对齐设计 §C 共享语义契约
/// （chinese_map 与 @data.chinese_dict 共享同一 Map[Int, Int] 对象引用）。
test "chinese_map_has_2533_entries" {
  debug_inspect(chinese_map.length(), content="2533")
}

///|
/// 验证 pinyin_table 视图常量条目数为 20903，对齐设计 §C 共享语义契约
/// （pinyin_table 与 @data.pinyin_dict 共享同一 Map[String, String] 对象引用）。
test "pinyin_table_has_20903_entries" {
  debug_inspect(pinyin_table.length(), content="20903")
}

///|
/// 验证 mutil_pinyin_table 视图常量条目数为 843，对齐设计 §C 共享语义契约
/// （mutil_pinyin_table 与 @data.mutil_pinyin_dict 共享同一 Map[String, String] 对象引用）。
test "mutil_pinyin_table_has_843_entries" {
  debug_inspect(mutil_pinyin_table.length(), content="843")
}

///|
/// 验证 tongyong_pinyin_table 视图常量条目数为 82，对齐设计 §C 共享语义契约
/// （tongyong_pinyin_table 与 @data.tongyong_pinyin_dict 共享同一 Map[String, String] 对象引用）。
test "tongyong_pinyin_table_has_82_entries" {
  debug_inspect(tongyong_pinyin_table.length(), content="82")
}

///|
/// 状态交互：chinese_map 与 @data.chinese_dict 共享同一 Map[Int, Int] 对象引用。
/// 通过一侧 set 后另一侧可观察到变更来验证共享引用（设计 §C），
/// 测试结束前 remove 清理副作用，保证用例独立性。
test "chinese_map_shares_reference_with_data_chinese_dict" {
  let test_key = 0x00
  let test_val = 0x00
  chinese_map.set(test_key, test_val)
  match @data.chinese_dict.get(test_key) {
    Some(v) => assert_true(v == test_val)
    None =>
      fail(
        "expected shared reference: set on chinese_map observed on @data.chinese_dict",
      )
  }
  chinese_map.remove(test_key)
}

///|
/// 状态交互：pinyin_table 与 @data.pinyin_dict 共享同一 Map[String, String] 对象引用。
/// 通过一侧 set 后另一侧可观察到变更来验证共享引用（设计 §C），
/// 测试结束前 remove 清理副作用，保证用例独立性。
test "pinyin_table_shares_reference_with_data_pinyin_dict" {
  let test_key = "__test_shared_ref__"
  let test_val = "__test_val__"
  pinyin_table.set(test_key, test_val)
  match @data.pinyin_dict.get(test_key) {
    Some(v) => assert_true(v == test_val)
    None =>
      fail(
        "expected shared reference: set on pinyin_table observed on @data.pinyin_dict",
      )
  }
  pinyin_table.remove(test_key)
}

///|
/// 状态交互：mutil_pinyin_table 与 @data.mutil_pinyin_dict 共享同一 Map[String, String] 对象引用。
/// 通过一侧 set 后另一侧可观察到变更来验证共享引用（设计 §C），
/// 测试结束前 remove 清理副作用，保证用例独立性。
test "mutil_pinyin_table_shares_reference_with_data_mutil_pinyin_dict" {
  let test_key = "__test_shared_ref__"
  let test_val = "__test_val__"
  mutil_pinyin_table.set(test_key, test_val)
  match @data.mutil_pinyin_dict.get(test_key) {
    Some(v) => assert_true(v == test_val)
    None =>
      fail(
        "expected shared reference: set on mutil_pinyin_table observed on @data.mutil_pinyin_dict",
      )
  }
  mutil_pinyin_table.remove(test_key)
}

///|
/// 状态交互：tongyong_pinyin_table 与 @data.tongyong_pinyin_dict 共享同一 Map[String, String] 对象引用。
/// 通过一侧 set 后另一侧可观察到变更来验证共享引用（设计 §C），
/// 测试结束前 remove 清理副作用，保证用例独立性。
test "tongyong_pinyin_table_shares_reference_with_data_tongyong_pinyin_dict" {
  let test_key = "__test_shared_ref__"
  let test_val = "__test_val__"
  tongyong_pinyin_table.set(test_key, test_val)
  match @data.tongyong_pinyin_dict.get(test_key) {
    Some(v) => assert_true(v == test_val)
    None =>
      fail(
        "expected shared reference: set on tongyong_pinyin_table observed on @data.tongyong_pinyin_dict",
      )
  }
  tongyong_pinyin_table.remove(test_key)
}

///|
/// 正向用例：chinese_map 中繁体"臺"(0x81FA) 映射到简体"台"(0x53F0=21488)，
/// 对齐源库 CHINESE_MAP 条目 (r'臺', r'台')，验证视图常量映射正确。
test "chinese_map_maps_0x81FA_to_0x53F0" {
  match chinese_map.get(0x81FA) {
    Some(v) => debug_inspect(v, content="21488")
    None => fail("expected key 0x81FA in chinese_map")
  }
}

///|
/// 正向用例：pinyin_table 中"一"映射为"yī"（单音），
/// 对齐源库 PINYIN_TABLE 条目（一 / yī），验证视图常量映射正确。
test "pinyin_table_maps_yi_to_yi" {
  match pinyin_table.get("一") {
    Some(v) => debug_inspect(v, content=(
      #|"yī"
    ))
    None => fail("expected key \"一\" in pinyin_table")
  }
}

///|
/// 正向用例：mutil_pinyin_table 中"阿訇"映射为"ā,hōng"（含带调元音），
/// 对齐源库 MUTIL_PINYIN_TABLE 条目 ("阿訇", "ā,hōng")，验证视图常量映射正确。
test "mutil_pinyin_table_maps_a_hong_to_a_hong_pinyin" {
  match mutil_pinyin_table.get("阿訇") {
    Some(v) => debug_inspect(v, content=(
      #|"ā,hōng"
    ))
    None => fail("expected key \"阿訇\" in mutil_pinyin_table")
  }
}

///|
/// 正向用例：tongyong_pinyin_table 中"chi"映射为"chih"（纯 ASCII），
/// 对齐源库 TONGYONG_PINYIN_TABLE 条目 ("chi", "chih")，验证视图常量映射正确。
test "tongyong_pinyin_table_maps_chi_to_chih" {
  match tongyong_pinyin_table.get("chi") {
    Some(v) => debug_inspect(v, content=(
      #|"chih"
    ))
    None => fail("expected key \"chi\" in tongyong_pinyin_table")
  }
}

///|
/// 边界条件：chinese_map 不存在的 key 返回 None，
/// 验证视图常量仅含已知繁体码点，与 @data.chinese_dict 行为一致。
test "chinese_map_returns_none_for_absent_key" {
  match chinese_map.get(0x00) {
    Some(_) => fail("expected None for absent key 0x00")
    None => ()
  }
}

///|
/// 边界条件：pinyin_table 不存在的 key 返回 None，
/// 验证视图常量仅含已知单字，与 @data.pinyin_dict 行为一致。
test "pinyin_table_returns_none_for_absent_key" {
  match pinyin_table.get("𠀀") {
    Some(_) => fail("expected None for absent key")
    None => ()
  }
}

///|
/// 边界条件：mutil_pinyin_table 不存在的 key 返回 None，
/// 验证视图常量仅含已知词组，与 @data.mutil_pinyin_dict 行为一致。
test "mutil_pinyin_table_returns_none_for_absent_key" {
  match mutil_pinyin_table.get("不存在的词组") {
    Some(_) => fail("expected None for absent key")
    None => ()
  }
}

///|
/// 边界条件：tongyong_pinyin_table 不存在的 key 返回 None，
/// 验证视图常量仅含已知通用拼音键，与 @data.tongyong_pinyin_dict 行为一致。
test "tongyong_pinyin_table_returns_none_for_absent_key" {
  match tongyong_pinyin_table.get("nonexistent") {
    Some(_) => fail("expected None for absent key")
    None => ()
  }
}
