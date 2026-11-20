///|
test "pinyin_helper: 通用拼音与非法字符" {
  let zh = PinyinHelper::to_tongyong_pinyin_string_array('中')
  assert_true(zh.length() > 0)
  assert_true(zh[0].contains("j"))
  assert_eq(PinyinHelper::to_tongyong_pinyin_string_array('A').length(), 0)
}

///|
test "pinyin_helper: 单字读音数组边界" {
  assert_eq(PinyinHelper::convert_to_pinyin_array('A').length(), 0)
  assert_true(PinyinHelper::convert_to_pinyin_array('中').length() > 0)
  assert_true(PinyinHelper::convert_to_pinyin_array('〇').length() > 0)
}

///|
test "pinyin_helper: 多音字判断" {
  assert_true(PinyinHelper::has_multi_pinyin('好'))
  assert_false(PinyinHelper::has_multi_pinyin('一'))
  let caught = try {
    let _ = PinyinHelper::has_multi_pinyin('A')
    false
  } catch {
    _ => true
  }
  assert_true(caught)
}

///|
test "pinyin_helper: 首字母与繁体转换" {
  assert_eq(PinyinHelper::get_short_pinyin("中国"), "z z g")
  assert_eq(
    PinyinHelper::convert_to_pinyin_string_traditional("中國", " "),
    "zhōng zhòng guó",
  )
}

///|
test "pinyin_helper: 分隔符与格式" {
  assert_eq(
    PinyinHelper::convert_to_pinyin_string("中国", "-"),
    "zhōng-zhòng-guó",
  )
  assert_eq(
    PinyinHelper::convert_to_pinyin_string("中国", ""),
    "zhōngzhòngguó",
  )
  assert_eq(
    PinyinHelper::convert_to_pinyin_string("中国", " ", format=FirstLetter),
    "z z g",
  )
}

///|
test "pinyin_helper: 空串与纯标点" {
  let caught = try {
    let _ = PinyinHelper::convert_to_pinyin_string("", " ")
    false
  } catch {
    _ => true
  }
  assert_true(caught)
  assert_eq(PinyinHelper::convert_to_pinyin_string("，", " "), "，")
}

///|
test "pinyin_helper: 中英混合" {
  assert_eq(
    PinyinHelper::convert_to_pinyin_string("中A国", " "),
    "zhōng zhòng A guó",
  )
}

///|
test "pinyin_helper: get_words 词组前缀" {
  match PinyinHelper::get_words("阿訇们") {
    words => {
      assert_eq(words.length(), 1)
      assert_eq(words[0], "阿訇")
    }
  }
  assert_eq(PinyinHelper::get_words("你好").length(), 0)
}

///|
test "pinyin_helper: 自定义词组字典" {
  let key = "测测词组"
  let dict : Map[String, String] = Map([])
  dict[key] = "cè,cè,shì,zǔ"
  PinyinHelper::add_mutil_pinyin_dict_resource(dict)
  assert_eq(
    PinyinHelper::convert_to_pinyin_string(key, " "),
    "cè cè shì zǔ",
  )
  mutil_pinyin_table.remove(key)
  assert_eq(PinyinHelper::convert_to_pinyin_string(key, " "), "cè cè cí zǔ")
}
