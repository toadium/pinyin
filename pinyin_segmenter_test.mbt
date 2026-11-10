///|
/// 拼音分词：无歧义串 "nihao" → [["ni","hao"]]。
test "segment_nihao" {
  let segments = @pinyin.PinyinSegmenter::segment("nihao")
  assert_true(segments.length() > 0)
  let first = segments[0]
  assert_true(first.length() == 2)
  assert_eq(first[0], "ni")
  assert_eq(first[1], "hao")
}

///|
/// 拼音分词：歧义串 "xian" → [["xi","an"],["xian"]]。
test "segment_xian" {
  let segments = @pinyin.PinyinSegmenter::segment("xian")
  assert_true(segments.length() >= 2)
  // 检查 ["xian"] 方案存在
  let has_xian = segments
    .iter()
    .any(fn(seg) { seg.length() == 1 && seg[0] == "xian" })
  assert_true(has_xian)
  // 检查 ["xi","an"] 方案存在
  let has_xi_an = segments
    .iter()
    .any(fn(seg) { seg.length() == 2 && seg[0] == "xi" && seg[1] == "an" })
  assert_true(has_xi_an)
}

///|
/// 拼音分词：空串返回 []。
test "segment_empty" {
  let segments = @pinyin.PinyinSegmenter::segment("")
  assert_true(segments.length() == 0)
}

///|
/// 拼音分词：无法切分的串返回 []。
test "segment_invalid" {
  let segments = @pinyin.PinyinSegmenter::segment("xyz")
  assert_true(segments.length() == 0)
}

///|
/// 最优分词：无歧义串 "nihao" → ["ni","hao"]。
test "segment_best_nihao" {
  let result = @pinyin.PinyinSegmenter::segment_best("nihao")
  assert_true(result.length() == 2)
  assert_eq(result[0], "ni")
  assert_eq(result[1], "hao")
}

///|
/// 最优分词：歧义串 "xian" → ["xian"]（最少音节数优先）。
test "segment_best_xian" {
  let result = @pinyin.PinyinSegmenter::segment_best("xian")
  assert_true(result.length() == 1)
  assert_eq(result[0], "xian")
}

///|
/// 最优分词：多音节串 "zhongguo" → ["zhong","guo"]。
test "segment_best_zhongguo" {
  let result = @pinyin.PinyinSegmenter::segment_best("zhongguo")
  assert_true(result.length() == 2)
  assert_eq(result[0], "zhong")
  assert_eq(result[1], "guo")
}

///|
/// 最优分词：空串返回 []。
test "segment_best_empty" {
  let result = @pinyin.PinyinSegmenter::segment_best("")
  assert_true(result.length() == 0)
}

///|
/// 最优分词：无法切分的串返回 []。
test "segment_best_invalid" {
  let result = @pinyin.PinyinSegmenter::segment_best("xyz")
  assert_true(result.length() == 0)
}

///|
/// can_segment：合法拼音串返回 true。
test "can_segment_valid" {
  assert_true(@pinyin.PinyinSegmenter::can_segment("nihao"))
  assert_true(@pinyin.PinyinSegmenter::can_segment("xian"))
  assert_true(@pinyin.PinyinSegmenter::can_segment("zhongguo"))
}

///|
/// can_segment：非法拼音串返回 false。
test "can_segment_invalid" {
  assert_false(@pinyin.PinyinSegmenter::can_segment("xyz"))
  assert_false(@pinyin.PinyinSegmenter::can_segment(""))
}

///|
/// 拼音分词：长串 "nihaozhongguo" 多种切分。
test "segment_long_string" {
  let segments = @pinyin.PinyinSegmenter::segment("nihaozhongguo")
  assert_true(segments.length() > 0)
  let best = @pinyin.PinyinSegmenter::segment_best("nihaozhongguo")
  assert_true(best.length() == 4)
  assert_eq(best[0], "ni")
  assert_eq(best[1], "hao")
  assert_eq(best[2], "zhong")
  assert_eq(best[3], "guo")
}
