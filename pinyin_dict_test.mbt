///|
/// 验证 pinyin_dict 条目数为 20903，对齐设计 §概述/实际条目数核对
/// （源库 pinyin.dict.txt 41806 行 / 2 = 20903 组，精确匹配）。
test "pinyin_dict_has_20903_entries" {
  debug_inspect(@data.pinyin_dict.length(), content="20903")
}

///|
/// 验证 pinyin_dict 中"〇"映射为"líng"（带调元音），
/// 对齐源库 pinyin.dict.txt 首组（第 1-2 行：〇 / líng）。
test "pinyin_dict_maps_ling_to_ling" {
  match @data.pinyin_dict.get("〇") {
    Some(v) => debug_inspect(v, content=(
      #|"líng"
    ))
    None => fail("expected key \"〇\" in pinyin_dict")
  }
}

///|
/// 验证 pinyin_dict 中"一"映射为"yī"（单音），
/// 对齐源库 pinyin.dict.txt 条目（一 / yī）。
test "pinyin_dict_maps_yi_to_yi" {
  match @data.pinyin_dict.get("一") {
    Some(v) => debug_inspect(v, content=(
      #|"yī"
    ))
    None => fail("expected key \"一\" in pinyin_dict")
  }
}

///|
/// 验证 pinyin_dict 中"丁"映射为"dīng,zhēng"（多音，逗号分隔），
/// 对齐源库 pinyin.dict.txt 条目（丁 / dīng,zhēng）。
test "pinyin_dict_maps_ding_to_ding_zheng" {
  match @data.pinyin_dict.get("丁") {
    Some(v) => debug_inspect(v, content=(
      #|"dīng,zhēng"
    ))
    None => fail("expected key \"丁\" in pinyin_dict")
  }
}

///|
/// 边界条件：不存在的 key 返回 None，验证 pinyin_dict 仅含已知单字。
test "pinyin_dict_returns_none_for_absent_key" {
  match @data.pinyin_dict.get("𠀀") {
    Some(_) => fail("expected None for absent key")
    None => ()
  }
}
