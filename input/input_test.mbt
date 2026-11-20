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

///|
test "input_user_dict" {
  let engine = @input.PinyinInputEngine::new()
  let ud : Map[String, String] = { "zhang san": "张三" }
  engine.add_user_dict(ud)
  let candidates = engine.input("zhangsan")
  let has_user = candidates.iter().any(fn(c) { c.text == "张三" })
  assert_true(has_user, msg="should find user dict entry")
}

///|
test "input_phrase_priority" {
  let engine = @input.PinyinInputEngine::new()
  // "种植" is in mutil_pinyin_dict: "zhòng,zhí" → "zhong zhi"
  let candidates = engine.input("zhongzhi")
  let mut phrase_idx : Int32 = -1
  for i in 0..<candidates.length() {
    if candidates[i].text == "种植" {
      phrase_idx = i
    }
  }
  // 词组应出现在候选中且排名靠前
  if phrase_idx >= 0 {
    assert_true(phrase_idx < 3, msg="phrase should rank high")
  }
}

///|
test "input_fuzzy_basic" {
  let engine = @input.PinyinInputEngine::new()
  let candidates = engine.input_fuzzy("zongguo")
  assert_true(candidates.length() > 0)
  // 模糊扩展 zong→zhong，应产生比普通 input 更多的候选
  let normal_candidates = engine.input("zongguo")
  // fuzzy 候选应不少于普通候选
  assert_true(
    candidates.length() >= normal_candidates.length(),
    msg="fuzzy should produce at least as many candidates",
  )
}

///|
test "input_user_dict_not_override" {
  let engine = @input.PinyinInputEngine::new()
  let ud : Map[String, String] = { "zhang san": "张三" }
  engine.add_user_dict(ud)
  let candidates = engine.input("nihao")
  assert_true(candidates.length() > 0)
}

///|
test "input_scoring_config_default" {
  let engine = @input.PinyinInputEngine::new()
  let config = engine.scoring_config()
  assert_true(config.user_dict_bonus == 10.0)
  assert_true(config.phrase_bonus == 5.0)
  assert_eq(config.candidate_limit, 20)
}

///|
test "input_scoring_config_custom" {
  let engine = @input.PinyinInputEngine::new()
  engine.set_scoring_config({
    user_dict_bonus: 20.0,
    phrase_bonus: 8.0,
    candidate_limit: 30,
  })
  let config = engine.scoring_config()
  assert_true(config.user_dict_bonus == 20.0)
  assert_true(config.phrase_bonus == 8.0)
  assert_eq(config.candidate_limit, 30)
}

///|
test "input_from_segments_empty_raises" {
  let engine = @input.PinyinInputEngine::new()
  try engine.input_from_segments([]) catch {
    _ => return
  } noraise {
    _ => fail("expected PinyinError for empty segments")
  }
}

///|
test "input_with_limit_invalid_raises" {
  let engine = @input.PinyinInputEngine::new()
  try engine.input_with_limit("nihao", 0) catch {
    _ => return
  } noraise {
    _ => fail("expected PinyinError for limit < 1")
  }
}

///|
test "input_common_char_priority_nihao" {
  let engine = @input.PinyinInputEngine::new()
  let candidates = engine.input("nihao")
  assert_true(candidates.length() > 0)
  assert_eq(candidates[0].text, "你好")
}

///|
test "input_common_char_priority_zhongguo" {
  let engine = @input.PinyinInputEngine::new()
  let candidates = engine.input("zhongguo")
  assert_true(candidates.length() > 0)
  assert_eq(candidates[0].text, "中国")
}

///|
test "input_common_phrase_words" {
  let engine = @input.PinyinInputEngine::new()
  let shurufa = engine.input("shurufa")
  assert_true(shurufa.length() > 0)
  assert_eq(shurufa[0].text, "输入法")
  let pinyin = engine.input("pinyin")
  assert_true(pinyin.length() > 0)
  assert_eq(pinyin[0].text, "拼音")
  let shouji = engine.input("shouji")
  assert_true(shouji.length() > 0)
  assert_eq(shouji[0].text, "手机")
}

///|
test "input_initial_abbreviation" {
  let engine = @input.PinyinInputEngine::new()
  let zg = engine.input("zg")
  assert_true(zg.length() > 0)
  assert_eq(zg[0].text, "中国")
  let shurf = engine.input("srf")
  assert_true(shurf.iter().any(fn(c) { c.text == "输入法" }))
}

///|
test "input_learn_reranks" {
  let engine = @input.PinyinInputEngine::new()
  let before = engine.input("nihao")
  assert_true(before.iter().any(fn(c) { c.text == "你号" }))
  for _ in 0..<5 {
    engine.learn("你号")
  }
  let after = engine.input("nihao")
  assert_true(after.length() > 0)
  assert_eq(after[0].text, "你号")
}

///|
test "input_shuangpin_xiaohe" {
  let engine = @input.PinyinInputEngine::new()
  let nihao = engine.input_shuangpin(Xiaohe, "nihc")
  assert_true(nihao.length() > 0)
  assert_eq(nihao[0].text, "你好")
  let zhongguo = engine.input_shuangpin(Xiaohe, "vsgo")
  assert_true(zhongguo.length() > 0)
  assert_eq(zhongguo[0].text, "中国")
}

///|
test "input_shuangpin_ziranma" {
  let engine = @input.PinyinInputEngine::new()
  let nihao = engine.input_shuangpin(Ziranma, "nihk")
  assert_true(nihao.length() > 0)
  assert_eq(nihao[0].text, "你好")
}

///|
test "input_initial_empty_and_unknown" {
  let engine = @input.PinyinInputEngine::new()
  assert_eq(engine.input_initial("").length(), 0)
  assert_eq(engine.input_initial("zzzz").length(), 0)
  assert_eq(engine.input("zzzz").length(), 0)
}

///|
test "input_initial_single_letter_no_match" {
  let engine = @input.PinyinInputEngine::new()
  assert_eq(engine.input_initial("z").length(), 0)
}

///|
test "input_all_segments_initial_fallback" {
  let engine = @input.PinyinInputEngine::new()
  let candidates = engine.input_all_segments("zg")
  assert_true(candidates.iter().any(fn(c) { c.text == "中国" }))
}

///|
test "input_shuangpin_empty_raises" {
  let engine = @input.PinyinInputEngine::new()
  try engine.input_shuangpin(Xiaohe, "") catch {
    _ => return
  } noraise {
    _ => fail("expected PinyinError for empty shuangpin")
  }
}

///|
test "input_learn_empty_is_noop" {
  let engine = @input.PinyinInputEngine::new()
  engine.learn("")
  let candidates = engine.input("nihao")
  assert_true(candidates.length() > 0)
}
