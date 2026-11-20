///|
test "search: 空索引" {
  let index = PinyinSearchIndex::new()
  assert_eq(index.search_initial("z").length(), 0)
  assert_eq(index.search_pinyin("zhong").length(), 0)
}

///|
test "search: 非汉字文档" {
  let index = PinyinSearchIndex::new()
  ignore(index.add_document("A中B"))
  let by_initial = index.search_initial("AzB")
  assert_eq(by_initial.length(), 1)
  assert_eq(by_initial[0], "A中B")
  let by_pinyin = index.search_pinyin("AzhongB")
  assert_eq(by_pinyin.length(), 1)
  assert_eq(by_pinyin[0], "A中B")
}

///|
test "search: 重复文档不去重" {
  let index = PinyinSearchIndex::new()
  ignore(index.add_document("中国"))
  ignore(index.add_document("中国"))
  assert_eq(index.search_initial("zg").length(), 2)
}

///|
test "search: 空查询模糊搜索抛错" {
  let index = PinyinSearchIndex::new()
  ignore(index.add_document("中国"))
  let caught = try {
    let _ = index.search_fuzzy("")
    false
  } catch {
    _ => true
  }
  assert_true(caught)
}

///|
test "search: 无法分词的模糊查询" {
  let index = PinyinSearchIndex::new()
  ignore(index.add_document("中国"))
  assert_eq(index.search_fuzzy("xyz").length(), 0)
}

///|
test "search: 可分但无匹配的模糊查询" {
  let index = PinyinSearchIndex::new()
  ignore(index.add_document("中国"))
  assert_eq(index.search_fuzzy("nihao").length(), 0)
}

///|
test "search: 单字文档" {
  let index = PinyinSearchIndex::new()
  ignore(index.add_document("中"))
  assert_eq(index.search_initial("z").length(), 1)
  assert_eq(index.search_pinyin("zhong").length(), 1)
}

///|
test "search: 空首字母查询" {
  let index = PinyinSearchIndex::new()
  ignore(index.add_document("中国"))
  assert_eq(index.search_initial("").length(), 0)
}
