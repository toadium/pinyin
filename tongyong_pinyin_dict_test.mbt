///|
/// 验证 tongyong_pinyin_dict 条目数为 82，对齐设计 §概述/实际条目数核对
/// （源库 tongyong_pinyin_dict.cj 92 行，去 9 行头 + 1 行收尾共 82 条）。
test "tongyong_pinyin_dict_has_82_entries" {
  inspect(@data.tongyong_pinyin_dict.length(), content="82")
}

///|
/// 验证 tongyong_pinyin_dict 中"chi"映射为"chih"（纯 ASCII），
/// 对齐源库 tongyong_pinyin_dict.cj 条目 ("chi", "chih")。
test "tongyong_pinyin_dict_maps_chi_to_chih" {
  match @data.tongyong_pinyin_dict.get("chi") {
    Some(v) => inspect(v, content="chih")
    None => fail("expected key \"chi\" in tongyong_pinyin_dict")
  }
}

///|
/// 验证 tongyong_pinyin_dict 中"chui"映射为"chuei"（纯 ASCII），
/// 对齐源库 tongyong_pinyin_dict.cj 条目 ("chui", "chuei")。
test "tongyong_pinyin_dict_maps_chui_to_chuei" {
  match @data.tongyong_pinyin_dict.get("chui") {
    Some(v) => inspect(v, content="chuei")
    None => fail("expected key \"chui\" in tongyong_pinyin_dict")
  }
}

///|
/// 边界条件：不存在的 key 返回 None，验证 tongyong_pinyin_dict 仅含已知通用拼音键。
test "tongyong_pinyin_dict_returns_none_for_absent_key" {
  match @data.tongyong_pinyin_dict.get("nonexistent") {
    Some(_) => fail("expected None for absent key")
    None => ()
  }
}