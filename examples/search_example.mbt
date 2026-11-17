///|
test "example_search_initial" {
  let index = @search.PinyinSearchIndex::new()
  ignore(index.add_document("中国人"))
  let results = index.search_initial("zgr")
  assert_true(results.length() > 0)
  println("search_initial 'zgr' → \{results.length()} results")
}

///|
test "example_search_fuzzy" {
  let index = @search.PinyinSearchIndex::new()
  ignore(index.add_document("中国人"))
  let results = index.search_fuzzy("zongguoren")
  assert_true(results.length() > 0)
  println("search_fuzzy 'zongguoren' → \{results.length()} results")
}
