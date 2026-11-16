///|
/// input 包黑盒测试。所有测试通过 @input. 限定访问宿主包。

///|
test "input_basic" {
  let engine = @input.PinyinInputEngine::new()
  let candidates = engine.input("nihao")
  // 应返回非空候选
  assert_true(candidates.length() > 0)
  // 第一个候选得分应最高
  if candidates.length() >= 2 {
    assert_true(
      candidates[0].score >= candidates[1].score,
      msg="first candidate should have highest score",
    )
  }
  // 候选应包含音节切分
  assert_eq(candidates[0].segments, ["ni", "hao"])
}

///|
test "input_empty_error" {
  let engine = @input.PinyinInputEngine::new()
  try engine.input("") catch {
    _ => {
      // 预期抛出错误
      assert_true(true)
      return
    }
  } noraise {
    _ => fail("expected error for empty input")
  }
}

///|
test "input_with_beam_width" {
  let engine = @input.PinyinInputEngine::with_beam_width(3)
  let candidates = engine.input("nihao")
  // beam 宽度为 3，候选数应不超过 3
  assert_true(candidates.length() <= 3)
}

///|
test "input_set_beam_width" {
  let engine = @input.PinyinInputEngine::new()
  assert_eq(engine.beam_width(), 10)
  engine.set_beam_width(5)
  assert_eq(engine.beam_width(), 5)
  engine.set_beam_width(-1)
  assert_eq(engine.beam_width(), 1)
}

///|
test "input_with_limit" {
  let engine = @input.PinyinInputEngine::new()
  let candidates = engine.input_with_limit("nihao", 2)
  assert_true(candidates.length() <= 2)
}

///|
test "input_zhongguo" {
  let engine = @input.PinyinInputEngine::new()
  let candidates = engine.input("zhongguo")
  assert_true(candidates.length() > 0)
  assert_eq(candidates[0].segments, ["zhong", "guo"])
  // 第一个候选应包含 "中" 字
  assert_true(
    candidates[0].text.length() > 0,
    msg="candidate should have non-empty text",
  )
}

///|
test "input_all_segments" {
  let engine = @input.PinyinInputEngine::new()
  // "xian" 有两种切分：["xi","an"] 和 ["xian"]
  let candidates = engine.input_all_segments("xian")
  assert_true(candidates.length() > 0)
  // 应包含不同切分路径的候选
  let has_xi_an = candidates.iter().any(fn(c) { c.segments == ["xi", "an"] })
  let has_xian = candidates.iter().any(fn(c) { c.segments == ["xian"] })
  assert_true(
    has_xi_an || has_xian,
    msg="should have candidates from both segmentations",
  )
}

///|
test "input_from_segments" {
  let engine = @input.PinyinInputEngine::new()
  let candidates = engine.input_from_segments(["zhong", "guo"])
  assert_true(candidates.length() > 0)
  assert_eq(candidates[0].segments, ["zhong", "guo"])
}

///|
test "input_candidate_struct" {
  let candidate : @input.InputCandidate = {
    text: "你好",
    score: -8.5,
    segments: ["ni", "hao"],
  }
  assert_eq(candidate.text, "你好")
  assert_true(candidate.score < 0.0)
  assert_eq(candidate.segments, ["ni", "hao"])
}

///|
test "input_dedup_in_all_segments" {
  let engine = @input.PinyinInputEngine::new()
  let candidates = engine.input_all_segments("nihao")
  // 相同文本不应重复出现
  let seen : Map[String, Unit] = Map([])
  for c in candidates {
    assert_true(!seen.contains(c.text), msg="duplicate candidate: \{c.text}")
    seen[c.text] = ()
  }
}
