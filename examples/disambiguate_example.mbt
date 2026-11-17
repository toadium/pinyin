///|
test "example_disambiguate" {
  let result = @disambiguate.PinyinDisambiguator::disambiguate("中国")
  assert_eq(result.length(), 2)
  assert_eq(result[0], "zhōng")
  assert_eq(result[1], "guó")
  println("disambiguate '中国' → \{result[0]} \{result[1]}")
}
