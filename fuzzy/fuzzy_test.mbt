///|
/// 模糊扩展：zh↔z 规则，"zhong" → ["zhong", "zong"]。
test "fuzzy_expand_zhong" {
  let variants = @fuzzy.FuzzyPinyinHelper::fuzzy_expand("zhong")
  assert_true(variants.contains("zhong"))
  assert_true(variants.contains("zong"))
}

///|
/// 模糊扩展：ch↔c 规则，"chang" → ["chang", "cang"]。
test "fuzzy_expand_chang" {
  let variants = @fuzzy.FuzzyPinyinHelper::fuzzy_expand("chang")
  assert_true(variants.contains("chang"))
  assert_true(variants.contains("cang"))
}

///|
/// 模糊扩展：sh↔s 规则，"shang" → ["shang", "sang"]。
test "fuzzy_expand_shang" {
  let variants = @fuzzy.FuzzyPinyinHelper::fuzzy_expand("shang")
  assert_true(variants.contains("shang"))
  assert_true(variants.contains("sang"))
}

///|
/// 模糊扩展：n↔l 规则，"nan" → ["nan", "lan"]。
test "fuzzy_expand_nan" {
  let variants = @fuzzy.FuzzyPinyinHelper::fuzzy_expand("nan")
  assert_true(variants.contains("nan"))
  assert_true(variants.contains("lan"))
}

///|
/// 模糊扩展：in↔ing 规则，"lin" → ["lin", "ling"]。
test "fuzzy_expand_lin" {
  let variants = @fuzzy.FuzzyPinyinHelper::fuzzy_expand("lin")
  assert_true(variants.contains("lin"))
  assert_true(variants.contains("ling"))
}

///|
/// 模糊扩展：en↔eng 规则，"hen" → ["hen", "heng"]。
test "fuzzy_expand_hen" {
  let variants = @fuzzy.FuzzyPinyinHelper::fuzzy_expand("hen")
  assert_true(variants.contains("hen"))
  assert_true(variants.contains("heng"))
}

///|
/// 模糊扩展：组合规则，"zhen" → ["zhen", "zheng", "zen", "zeng"]。
test "fuzzy_expand_zhen" {
  let variants = @fuzzy.FuzzyPinyinHelper::fuzzy_expand("zhen")
  assert_true(variants.contains("zhen"))
  assert_true(variants.contains("zheng"))
  assert_true(variants.contains("zen"))
  assert_true(variants.contains("zeng"))
}

///|
/// 模糊扩展：无模糊规则的拼音只返回自身。
test "fuzzy_expand_no_variants" {
  let variants = @fuzzy.FuzzyPinyinHelper::fuzzy_expand("ba")
  assert_true(variants.length() == 1)
  assert_eq(variants[0], "ba")
}

///|
/// 模糊匹配：zh↔z，"zhong" 和 "zong" 模糊等价。
test "fuzzy_match_zhong_zong" {
  assert_true(@fuzzy.FuzzyPinyinHelper::fuzzy_match("zhong", "zong"))
}

///|
/// 模糊匹配：相同拼音模糊等价。
test "fuzzy_match_same" {
  assert_true(@fuzzy.FuzzyPinyinHelper::fuzzy_match("zhong", "zhong"))
}

///|
/// 模糊匹配：不模糊等价的拼音返回 false。
test "fuzzy_match_not_match" {
  assert_false(@fuzzy.FuzzyPinyinHelper::fuzzy_match("zhong", "ba"))
}

///|
/// 模糊匹配：n↔l，"nan" 和 "lan" 模糊等价。
test "fuzzy_match_nan_lan" {
  assert_true(@fuzzy.FuzzyPinyinHelper::fuzzy_match("nan", "lan"))
}

///|
/// 模糊反向查找："zhong" 返回 "zhong" 和 "zong" 对应的汉字。
test "fuzzy_reverse_lookup_zhong" {
  let chars = @fuzzy.FuzzyPinyinHelper::fuzzy_reverse_lookup("zhong")
  assert_true(chars.contains("中"))
  assert_true(chars.length() > 1)
}

///|
/// 模糊反向查找：空串抛 PinyinError。
test "fuzzy_reverse_lookup_empty_raises" {
  try @fuzzy.FuzzyPinyinHelper::fuzzy_reverse_lookup("") catch {
    _ => ()
  } noraise {
    _ => fail("expected PinyinError for empty string")
  }
}

///|
/// 模糊扩展：f↔h 规则，"fan" → ["fan", "han"]。
test "fuzzy_expand_fan" {
  let variants = @fuzzy.FuzzyPinyinHelper::fuzzy_expand("fan")
  assert_true(variants.contains("fan"))
  assert_true(variants.contains("han"))
}

///|
/// 模糊扩展：an↔ang 规则，"ban" → ["ban", "bang"]。
test "fuzzy_expand_ban" {
  let variants = @fuzzy.FuzzyPinyinHelper::fuzzy_expand("ban")
  assert_true(variants.contains("ban"))
  assert_true(variants.contains("bang"))
}

///|
/// 模糊扩展：ong↔eng 规则，"hong" → ["hong", "heng"]。
test "fuzzy_expand_hong" {
  let variants = @fuzzy.FuzzyPinyinHelper::fuzzy_expand("hong")
  assert_true(variants.contains("hong"))
  assert_true(variants.contains("heng"))
}

///|
/// 模糊匹配：f↔h，"fan" 和 "han" 模糊等价。
test "fuzzy_match_fan_han" {
  assert_true(@fuzzy.FuzzyPinyinHelper::fuzzy_match("fan", "han"))
}

///|
/// 模糊匹配：an↔ang，"ban" 和 "bang" 模糊等价。
test "fuzzy_match_ban_bang" {
  assert_true(@fuzzy.FuzzyPinyinHelper::fuzzy_match("ban", "bang"))
}
