///|
test "edit_distance: 相同拼音距离为0" {
  let d = @normalize.PinyinEditDistance::distance("nihao", "nihao")
  assert_eq(d, 0)
}

///|
test "edit_distance: 一个音节差异" {
  let d = @normalize.PinyinEditDistance::distance("nihao", "lihao")
  assert_eq(d, 1)
}

///|
test "edit_distance: 插入一个音节" {
  let d = @normalize.PinyinEditDistance::distance("nihao", "ni")
  assert_eq(d, 1)
}

///|
test "edit_distance: 模糊距离 zhong vs zong" {
  let d = @normalize.PinyinEditDistance::fuzzy_distance("zhongguo", "zongguo")
  assert_eq(d, 0)
}

///|
test "edit_distance: 模糊距离 vs 精确距离" {
  let exact = @normalize.PinyinEditDistance::distance("zhongguo", "zongguo")
  let fuzzy = @normalize.PinyinEditDistance::fuzzy_distance(
    "zhongguo", "zongguo",
  )
  assert_true(exact > fuzzy)
}

///|
test "edit_distance: 完全不同" {
  let d = @normalize.PinyinEditDistance::distance("a", "b")
  assert_eq(d, 1)
}

///|
test "edit_distance: 空串" {
  let d = @normalize.PinyinEditDistance::distance("", "nihao")
  assert_eq(d, 2)
}
