///|
/// lm 包黑盒测试。所有测试通过 @lm. 限定访问宿主包。

///|
test "unigram_prob basic" {
  // "zhong" 是高频音节，概率应大于 0
  let p = @lm.PinyinLM::unigram_prob("zhong")
  assert_true(p > 0.0)
  // 未见音节概率应大于 0（Laplace 平滑）
  let p2 = @lm.PinyinLM::unigram_prob("xyz")
  assert_true(p2 > 0.0)
}

///|
test "bigram_prob basic" {
  // bigram 概率应大于 0（Laplace 平滑保证）
  let p1 = @lm.PinyinLM::bigram_prob("zhong", "guo")
  assert_true(p1 > 0.0)
  // 未见上下文应回退到 unigram，概率也应 > 0
  let p2 = @lm.PinyinLM::bigram_prob("xyz", "guo")
  assert_true(p2 > 0.0)
  // 确认 bigram 数据不为空
  let stats = @lm.PinyinLM::stats()
  assert_true(stats.bigram_types > 0)
}

///|
test "trigram_prob basic" {
  // trigram 概率应大于 0
  let p1 = @lm.PinyinLM::trigram_prob("zhong", "guo", "ren")
  assert_true(p1 > 0.0)
  // 回退：未见 pair 应回退到 bigram
  let p3 = @lm.PinyinLM::trigram_prob("xyz", "guo", "ren")
  assert_true(p3 > 0.0)
}

///|
test "sentence_log_prob basic" {
  let p1 = @lm.PinyinLM::sentence_log_prob(["zhong", "guo"])
  // 合法句子对数概率应为负值（概率 < 1）
  assert_true(p1 < 0.0)
  // 空串返回 0.0
  let p3 = @lm.PinyinLM::sentence_log_prob([])
  assert_eq(p3, 0.0)
}

///|
test "sentence_log_prob_trigram basic" {
  let p1 = @lm.PinyinLM::sentence_log_prob_trigram(["zhong", "guo", "ren"])
  assert_true(p1 < 0.0)
  // 空串返回 0.0
  let p3 = @lm.PinyinLM::sentence_log_prob_trigram([])
  assert_eq(p3, 0.0)
}

///|
test "perplexity basic" {
  let sentences : Array[Array[String]] = [["zhong", "guo"], ["ni", "hao"]]
  let pp = @lm.PinyinLM::perplexity(sentences)
  // 困惑度应为正有限值
  assert_true(pp > 0.0)
  assert_true(pp < 10000000000.0)
}

///|
test "stats non-empty" {
  let stats = @lm.PinyinLM::stats()
  // 词汇量应大于 0
  assert_true(stats.vocab_size > 0)
  // 总频次应大于 0
  assert_true(stats.unigram_total > 0)
  // 应有 bigram 数据（来自 843 词组字典）
  assert_true(stats.bigram_types > 0)
}

///|
test "laplace_smoothing_all_positive" {
  // 所有概率都应大于 0（Laplace 平滑保证）
  let syllables = ["a", "ai", "an", "ang", "ao", "ba", "zhong", "guo"]
  for s in syllables {
    let p = @lm.PinyinLM::unigram_prob(s)
    assert_true(p > 0.0, msg="\{s} unigram prob should be > 0, got \{p}")
  }
}
