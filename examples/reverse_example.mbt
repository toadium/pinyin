///|
test "example_reverse_lookup" {
  let chars = @reverse.ReversePinyinHelper::reverse_lookup("zhong")
  assert_true(chars.contains("中"))
  println("reverse 'zhong' → \{chars.length()} chars")
}

///|
test "example_is_valid_pinyin" {
  assert_true(@reverse.ReversePinyinHelper::is_valid_pinyin("zhong"))
  assert_false(@reverse.ReversePinyinHelper::is_valid_pinyin("xyz"))
}
