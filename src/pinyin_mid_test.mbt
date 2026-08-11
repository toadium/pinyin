///|
/// chinese_map 与 @data.chinese_dict 共享同一 Map[Int, Int] 对象引用。
/// 通过一侧 set 后另一侧可观察到变更来验证共享引用，测试结束前 remove 清理副作用。
test "chinese_map_shares_reference_with_data" {
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
/// pinyin_table 与 @data.pinyin_dict 共享同一 Map[String, String] 对象引用。
test "pinyin_table_shares_reference_with_data" {
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
/// mutil_pinyin_table 与 @data.mutil_pinyin_dict 共享同一 Map[String, String] 对象引用。
test "mutil_pinyin_table_shares_reference_with_data" {
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
/// tongyong_pinyin_table 与 @data.tongyong_pinyin_dict 共享同一 Map[String, String] 对象引用。
test "tongyong_pinyin_table_shares_reference_with_data" {
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
/// 正向用例：chinese_map 中繁体"臺"(0x81FA) 映射到简体"台"(0x53F0=21488)。
test "chinese_map_maps_0x81FA_to_0x53F0" {
  match chinese_map.get(0x81FA) {
    Some(v) => inspect(v, content="21488")
    None => fail("expected key 0x81FA in chinese_map")
  }
}

///|
/// 正向用例：pinyin_table 中"一"映射为"yī"（单音）。
test "pinyin_table_maps_yi_to_yi" {
  match pinyin_table.get("一") {
    Some(v) => inspect(v, content="yī")
    None => fail("expected key \"一\" in pinyin_table")
  }
}

///|
/// 正向用例：mutil_pinyin_table 中"阿訇"映射为"ā,hōng"。
test "mutil_pinyin_table_maps_a_hong" {
  match mutil_pinyin_table.get("阿訇") {
    Some(v) => inspect(v, content="ā,hōng")
    None => fail("expected key \"阿訇\" in mutil_pinyin_table")
  }
}

///|
/// 正向用例：tongyong_pinyin_table 中"chi"映射为"chih"。
test "tongyong_pinyin_table_maps_chi_to_chih" {
  match tongyong_pinyin_table.get("chi") {
    Some(v) => inspect(v, content="chih")
    None => fail("expected key \"chi\" in tongyong_pinyin_table")
  }
}

///|
/// 边界条件：各字典不存在的 key 返回 None。
test "dicts_return_none_for_absent_keys" {
  match chinese_map.get(0x00) {
    Some(_) => fail("expected None for absent key 0x00")
    None => ()
  }
  match pinyin_table.get("𠀀") {
    Some(_) => fail("expected None for absent key")
    None => ()
  }
  match mutil_pinyin_table.get("不存在的词组") {
    Some(_) => fail("expected None for absent key")
    None => ()
  }
  match tongyong_pinyin_table.get("nonexistent") {
    Some(_) => fail("expected None for absent key")
    None => ()
  }
}

///|
/// 词句转拼音：基本用例，默认 WithToneMark 格式。
test "convert_to_pinyin_string_basic" {
  inspect(
    PinyinHelper::convert_to_pinyin_string("我是中国人", " "),
    content=(
      #|wǒ shì zhōng zhòng guó rén
    ),
  )
}

///|
/// 词句转拼音：WithToneNumber 格式。
test "convert_to_pinyin_string_with_tone_number" {
  inspect(
    PinyinHelper::convert_to_pinyin_string("中国", " ", format=WithToneNumber),
    content=(
      #|zhong1 zhong4 guo2
    ),
  )
}

///|
/// 词句转拼音：WithoutTone 格式。
test "convert_to_pinyin_string_without_tone" {
  inspect(
    PinyinHelper::convert_to_pinyin_string("中国", " ", format=WithoutTone),
    content=(
      #|zhong zhong guo
    ),
  )
}

///|
/// 词句转拼音：FirstLetter 格式。
test "convert_to_pinyin_string_first_letter" {
  inspect(
    PinyinHelper::convert_to_pinyin_string("中国", " ", format=FirstLetter),
    content=(
      #|z z g
    ),
  )
}

///|
/// 多音字判断：丁是多音字（dīng,zhēng），一不是多音字（yī）。
test "has_multi_pinyin_basic" {
  assert_true(PinyinHelper::has_multi_pinyin('丁'))
  assert_false(PinyinHelper::has_multi_pinyin('一'))
}

///|
/// 首字母格式拼音。
test "get_short_pinyin_basic" {
  inspect(
    PinyinHelper::get_short_pinyin("中国"),
    content=(
      #|z z g
    ),
  )
}

///|
/// 繁体转拼音：先繁→简再转拼音。
test "convert_to_pinyin_string_traditional" {
  inspect(
    PinyinHelper::convert_to_pinyin_string_traditional("臺灣", " "),
    content=(
      #|tái tāi wān
    ),
  )
}

///|
/// 通用拼音数组。
test "to_tongyong_pinyin_string_array_basic" {
  debug_inspect(
    PinyinHelper::to_tongyong_pinyin_string_array('痴'),
    content=(
      #|["chih1"]
    ),
  )
}

///|
/// 自定义字典追加：add_pinyin_dict_resource 原地合并。
test "add_pinyin_dict_resource" {
  let custom_dict : Map[String, String] = { "测试字": "cè,shì" }
  PinyinHelper::add_pinyin_dict_resource(custom_dict)
  match pinyin_table.get("测试字") {
    Some(v) => inspect(v, content="cè,shì")
    None => fail("expected custom key in pinyin_table")
  }
  pinyin_table.remove("测试字")
}

///|
/// 自定义繁简字典追加：add_chinese_dict_resource 原地合并。
test "add_chinese_dict_resource" {
  let custom_dict : Map[Int, Int] = { 0x41: 0x42 }
  ChineseHelper::add_chinese_dict_resource(custom_dict)
  match chinese_map.get(0x41) {
    Some(v) => inspect(v, content="66")
    None => fail("expected custom key in chinese_map")
  }
  chinese_map.remove(0x41)
}
