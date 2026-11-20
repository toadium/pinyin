///|
test "segment: 空串与无法切分" {
  let caught_empty = try {
    let _ = PinyinSegmenter::segment("")
    false
  } catch {
    _ => true
  }
  assert_true(caught_empty)
  assert_eq(PinyinSegmenter::segment("xyz").length(), 0)
  let caught_best = try {
    let _ = PinyinSegmenter::segment_best("")
    false
  } catch {
    _ => true
  }
  assert_true(caught_best)
  assert_eq(PinyinSegmenter::segment_best("xyz").length(), 0)
}

///|
test "segment: 多切分与最优切分" {
  let all = PinyinSegmenter::segment("xian")
  assert_true(all.length() >= 2)
  assert_eq(PinyinSegmenter::segment_best("xian"), ["xian"])
  assert_eq(PinyinSegmenter::segment_best("nihao"), ["ni", "hao"])
}

///|
test "segment: can_segment 边界" {
  assert_false(PinyinSegmenter::can_segment(""))
  assert_true(PinyinSegmenter::can_segment("nihao"))
  assert_false(PinyinSegmenter::can_segment("xyz"))
}
