///|
test "example_fuzzy_expand" {
  let variants = @fuzzy.FuzzyPinyinHelper::fuzzy_expand("zhong")
  assert_true(variants.length() > 1)
  println("fuzzy_expand 'zhong' → \{variants.length()} variants")
}

///|
test "example_fuzzy_match" {
  let match_result = @fuzzy.FuzzyPinyinHelper::fuzzy_match("zhong", "zong")
  assert_true(match_result)
  println("fuzzy_match 'zhong' ↔ 'zong' = \{match_result}")
}
