///|
test "example_segment" {
  let segs = @segment.PinyinSegmenter::segment("xian")
  assert_true(segs.length() > 0)
  println("segment 'xian' → \{segs.length()} segmentations")
}

///|
test "example_segment_best" {
  let best = @segment.PinyinSegmenter::segment_best("nihao")
  assert_eq(best.length(), 2)
  println("segment_best 'nihao' → \{best[0]} \{best[1]}")
}
