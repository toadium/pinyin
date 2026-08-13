///|
/// `add_pinyin_dict_resource` 正向：追加自定义单字拼音后可查询到。
/// 用私用区字符 U+E000 避免与现有字典冲突，测试后 remove 清理。
test "add_pinyin_dict_resource_adds_entry" {
  let test_char = Int::to_char(0xE000).unwrap()
  let test_key = test_char.to_string()
  let dict : Map[String, String] = Map([])
  dict[test_key] = "cē"
  PinyinHelper::add_pinyin_dict_resource(dict)
  match pinyin_table.get(test_key) {
    Some(v) => debug_inspect(v, content=(
      #|"cē"
    ))
    None => fail("expected entry after add_pinyin_dict_resource")
  }
  pinyin_table.remove(test_key)
}

///|
/// `add_mutil_pinyin_dict_resource` 正向：追加自定义词组拼音后可查询到。
/// 用不冲突的词组键，测试后 remove 清理。
test "add_mutil_pinyin_dict_resource_adds_entry" {
  let test_key = "测试词组键"
  let dict : Map[String, String] = Map([])
  dict[test_key] = "cè,shì,cí,zǔ,jiàn"
  PinyinHelper::add_mutil_pinyin_dict_resource(dict)
  match mutil_pinyin_table.get(test_key) {
    Some(v) => debug_inspect(v, content=(
      #|"cè,shì,cí,zǔ,jiàn"
    ))
    None => fail("expected entry after add_mutil_pinyin_dict_resource")
  }
  mutil_pinyin_table.remove(test_key)
}

///|
/// `add_chinese_dict_resource` 正向：追加自定义繁简映射后可查询到。
/// 用不冲突的码点，测试后 remove 清理。
test "add_chinese_dict_resource_adds_entry" {
  let test_key = 0xE001
  let dict : Map[Int, Int] = Map([])
  dict[test_key] = 0xE002
  ChineseHelper::add_chinese_dict_resource(dict)
  match chinese_map.get(test_key) {
    Some(v) => debug_inspect(v, content="57346")
    None => fail("expected entry after add_chinese_dict_resource")
  }
  chinese_map.remove(test_key)
}

///|
/// `add_pinyin_dict_resource` 覆盖语义：同键追加新值覆盖旧值。
test "add_pinyin_dict_resource_overrides_existing" {
  let test_char = Int::to_char(0xE003).unwrap()
  let test_key = test_char.to_string()
  let dict1 : Map[String, String] = Map([])
  dict1[test_key] = "first"
  PinyinHelper::add_pinyin_dict_resource(dict1)
  let dict2 : Map[String, String] = Map([])
  dict2[test_key] = "second"
  PinyinHelper::add_pinyin_dict_resource(dict2)
  match pinyin_table.get(test_key) {
    Some(v) => debug_inspect(v, content=(
      #|"second"
    ))
    None => fail("expected overridden entry")
  }
  pinyin_table.remove(test_key)
}
