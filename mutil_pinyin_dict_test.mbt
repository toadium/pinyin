///|
/// 验证 mutil_pinyin_dict 条目数为 843，对齐设计 §概述/实际条目数核对
/// （源库条目第 13-857 行共 845 条（含 2 组重复 key），去重后 843 条）。
test "mutil_pinyin_dict_has_843_entries" {
  debug_inspect(@data.mutil_pinyin_dict.length(), content="843")
}

///|
/// 验证 mutil_pinyin_dict 中"阿訇"映射为"ā,hōng"（含带调元音），
/// 对齐源库 mutil_pinyin.dict.cj 条目 ("阿訇", "ā,hōng")。
test "mutil_pinyin_dict_maps_a_hong_to_a_hong_pinyin" {
  match @data.mutil_pinyin_dict.get("阿訇") {
    Some(v) => debug_inspect(v, content=(
      #|"ā,hōng"
    ))
    None => fail("expected key \"阿訇\" in mutil_pinyin_dict")
  }
}

///|
/// 验证 mutil_pinyin_dict 中"一丘之貉"映射为"yī,qiū,zhī,hé"（四字词组拼音），
/// 对齐源库 mutil_pinyin.dict.cj 条目 ("一丘之貉", "yī,qiū,zhī,hé")。
test "mutil_pinyin_dict_maps_yi_qiu_zhi_he" {
  match @data.mutil_pinyin_dict.get("一丘之貉") {
    Some(v) => debug_inspect(v, content=(
      #|"yī,qiū,zhī,hé"
    ))
    None => fail("expected key \"一丘之貉\" in mutil_pinyin_dict")
  }
}

///|
/// 边界条件：不存在的 key 返回 None，验证 mutil_pinyin_dict 仅含已知词组。
test "mutil_pinyin_dict_returns_none_for_absent_key" {
  match @data.mutil_pinyin_dict.get("不存在的词组") {
    Some(_) => fail("expected None for absent key")
    None => ()
  }
}
