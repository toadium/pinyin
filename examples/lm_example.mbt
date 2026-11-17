///|
test "example_lm_unigram_prob" {
  let p = @lm.PinyinLM::unigram_prob("zhong")
  assert_true(p > 0.0)
  println("P(zhong) = \{p}")
}

///|
test "example_lm_bigram_prob" {
  let p = @lm.PinyinLM::bigram_prob("zhong", "guo")
  assert_true(p > 0.0)
  println("P(guo|zhong) = \{p}")
}

///|
test "example_lm_sentence_log_prob" {
  let log_p = @lm.PinyinLM::sentence_log_prob(["zhong", "guo", "ren"])
  assert_true(log_p < 0.0)
  println("log P(zhong guo ren) = \{log_p}")
}

///|
test "example_lm_interpolation_prob" {
  let p = @lm.PinyinLM::interpolation_prob("zhong", "guo", "ren", 0.5, 0.3, 0.2)
  assert_true(p > 0.0)
  println("P_interp(ren|zhong,guo) = \{p}")
}

///|
test "example_lm_stats" {
  let stats = @lm.PinyinLM::stats()
  assert_true(stats.vocab_size > 0)
  assert_true(stats.bigram_types > 0)
  println("vocab_size=\{stats.vocab_size} bigram_types=\{stats.bigram_types}")
}
