///|
test "search: 首字母搜索" {
  let index = @search.PinyinSearchIndex::new()
  ignore(index.add_document("中国人"))
  let result = index.search_initial("zgr")
  assert_eq(result.length(), 1)
  assert_eq(result[0], "中国人")
}

///|
test "search: 连续拼音搜索" {
  let index = @search.PinyinSearchIndex::new()
  ignore(index.add_document("中国人"))
  let result = index.search_pinyin("zhongguoren")
  assert_eq(result.length(), 1)
  assert_eq(result[0], "中国人")
}

///|
test "search: 模糊拼音搜索" {
  let index = @search.PinyinSearchIndex::new()
  ignore(index.add_document("中国人"))
  let result = index.search_fuzzy("zongguoren")
  assert_eq(result.length(), 1)
  assert_eq(result[0], "中国人")
}

///|
test "search: 精确匹配优先于模糊匹配" {
  let index = @search.PinyinSearchIndex::new()
  ignore(index.add_document("中国人"))
  let result = index.search_fuzzy("zhongguoren")
  assert_eq(result.length(), 1)
  assert_eq(result[0], "中国人")
}

///|
test "search: 无匹配返回空数组" {
  let index = @search.PinyinSearchIndex::new()
  ignore(index.add_document("中国人"))
  let result = index.search_initial("abc")
  assert_eq(result.length(), 0)
}

///|
test "search: 多文档索引" {
  let index = @search.PinyinSearchIndex::new()
  ignore(index.add_document("中国"))
  ignore(index.add_document("中国人"))
  let result = index.search_initial("zg")
  assert_eq(result.length(), 1)
  assert_eq(result[0], "中国")
}

///|
test "search: 模糊搜索去重" {
  let index = @search.PinyinSearchIndex::new()
  ignore(index.add_document("中总"))
  let result = index.search_fuzzy("zhongzong")
  assert_eq(result.length(), 1)
}
