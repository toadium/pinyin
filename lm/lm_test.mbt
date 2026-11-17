///|
/// lm 包黑盒测试。所有测试通过 @lm. 限定访问宿主包。

///|
test "unigram_prob basic" {
  let p = @lm.PinyinLM::unigram_prob("zhong")
  assert_true(p > 0.0)
  let p2 = @lm.PinyinLM::unigram_prob("xyz")
  assert_true(p2 > 0.0)
}

///|
test "bigram_prob basic" {
  let p1 = @lm.PinyinLM::bigram_prob("zhong", "guo")
  assert_true(p1 > 0.0)
  let p2 = @lm.PinyinLM::bigram_prob("xyz", "guo")
  assert_true(p2 > 0.0)
  let stats = @lm.PinyinLM::stats()
  assert_true(stats.bigram_types > 0)
}

///|
test "trigram_prob basic" {
  let p1 = @lm.PinyinLM::trigram_prob("zhong", "guo", "ren")
  assert_true(p1 > 0.0)
  let p3 = @lm.PinyinLM::trigram_prob("xyz", "guo", "ren")
  assert_true(p3 > 0.0)
}

///|
test "sentence_log_prob basic" {
  let p1 = @lm.PinyinLM::sentence_log_prob(["zhong", "guo"])
  assert_true(p1 < 0.0)
  let p3 = @lm.PinyinLM::sentence_log_prob([])
  assert_eq(p3, 0.0)
}

///|
test "sentence_log_prob_trigram basic" {
  let p1 = @lm.PinyinLM::sentence_log_prob_trigram(["zhong", "guo", "ren"])
  assert_true(p1 < 0.0)
  let p3 = @lm.PinyinLM::sentence_log_prob_trigram([])
  assert_eq(p3, 0.0)
}

///|
test "perplexity basic" {
  let sentences : Array[Array[String]] = [["zhong", "guo"], ["ni", "hao"]]
  let pp = @lm.PinyinLM::perplexity(sentences)
  assert_true(pp > 0.0)
  assert_true(pp < 10000000000.0)
}

///|
test "stats non-empty" {
  let stats = @lm.PinyinLM::stats()
  assert_true(stats.vocab_size > 0)
  assert_true(stats.unigram_total > 0)
  assert_true(stats.bigram_types > 0)
}

///|
test "interpolation_prob basic" {
  let p = @lm.PinyinLM::interpolation_prob("zhong", "guo", "ren", 0.5, 0.3, 0.2)
  assert_true(p > 0.0)
  assert_true(p < 1.0)
  let p2 = @lm.PinyinLM::interpolation_prob("xyz", "abc", "ren", 0.5, 0.3, 0.2)
  assert_true(p2 > 0.0)
}

///|
test "sentence_log_prob_interpolation basic" {
  let p1 = @lm.PinyinLM::sentence_log_prob_interpolation(
    ["zhong", "guo", "ren"],
    0.5,
    0.3,
    0.2,
  )
  assert_true(p1 < 0.0)
  let p2 = @lm.PinyinLM::sentence_log_prob_interpolation([], 0.5, 0.3, 0.2)
  assert_eq(p2, 0.0)
}

///|
test "interpolation_vs_pure" {
  let interp_uni = @lm.PinyinLM::interpolation_prob(
    "zhong", "guo", "ren", 0.0, 0.0, 1.0,
  )
  let pure_uni = @lm.PinyinLM::unigram_prob("ren")
  assert_true((interp_uni - pure_uni).abs() < 0.000000000001)
  let interp_bi = @lm.PinyinLM::interpolation_prob(
    "zhong", "guo", "ren", 0.0, 1.0, 0.0,
  )
  let pure_bi = @lm.PinyinLM::bigram_prob("guo", "ren")
  assert_true((interp_bi - pure_bi).abs() < 0.000000000001)
}

///|
test "laplace_smoothing_all_positive" {
  let syllables = ["a", "ai", "an", "ang", "ao", "ba", "zhong", "guo"]
  for s in syllables {
    let p = @lm.PinyinLM::unigram_prob(s)
    assert_true(p > 0.0, msg="\{s} unigram prob should be > 0, got \{p}")
  }
}

///|
test "stats precise values" {
  let stats = @lm.PinyinLM::stats()
  assert_true(stats.vocab_size >= 400, msg="vocab_size=\{stats.vocab_size}")
  assert_true(
    stats.unigram_total >= 20000,
    msg="unigram_total=\{stats.unigram_total}",
  )
  assert_true(
    stats.bigram_types >= 500,
    msg="bigram_types=\{stats.bigram_types}",
  )
  assert_true(
    stats.trigram_types >= 100,
    msg="trigram_types=\{stats.trigram_types}",
  )
}

///|
test "perplexity_empty_raises" {
  let caught = try {
    let _ = @lm.PinyinLM::perplexity([])
    false
  } catch {
    _ => true
  }
  assert_true(caught)
}

///|
test "perplexity_trigram_empty_raises" {
  let caught = try {
    let _ = @lm.PinyinLM::perplexity_trigram([])
    false
  } catch {
    _ => true
  }
  assert_true(caught)
}

///|
test "interpolation_prob_negative_lambda_raises" {
  let caught = try {
    let _ = @lm.PinyinLM::interpolation_prob(
      "zhong", "guo", "ren", -0.5, 0.3, 0.2,
    )
    false
  } catch {
    _ => true
  }
  assert_true(caught)
}
