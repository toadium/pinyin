///|
test "example_normalize" {
  let result = @normalize.PinyinNormalizer::normalize("ZHONG1")
  inspect(result, content="zhōng")
}

///|
test "example_edit_distance" {
  let dist = @normalize.PinyinEditDistance::distance("nihao", "lihao")
  assert_eq(dist, 1)
  let fuzzy_dist = @normalize.PinyinEditDistance::fuzzy_distance(
    "zhongguo", "zongguo",
  )
  assert_eq(fuzzy_dist, 0)
  println(
    "distance 'nihao'↔'lihao'=\{dist}, fuzzy 'zhongguo'↔'zongguo'=\{fuzzy_dist}",
  )
}
