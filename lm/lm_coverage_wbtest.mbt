///|
test "lm: stats 字段" {
  let stats = PinyinLM::stats()
  assert_true(stats.vocab_size > 0)
  assert_true(stats.unigram_total > 0)
  assert_true(stats.bigram_total > 0)
  assert_true(stats.trigram_total > 0)
  assert_true(stats.unigram_types > 0)
  assert_true(stats.bigram_types > 0)
  assert_true(stats.trigram_types > 0)
  assert_eq(stats.vocab_size, stats.unigram_types)
}

///|
test "lm: unigram/bigram 概率" {
  assert_true(PinyinLM::unigram_prob("ni") > 0.0)
  assert_true(PinyinLM::unigram_prob("zzz") > 0.0)
  assert_true(PinyinLM::bigram_prob("ni", "hao") > 0.0)
  assert_true(PinyinLM::bigram_prob("zzz", "hao") > 0.0)
}

///|
test "lm: trigram 概率与回退" {
  assert_true(PinyinLM::trigram_prob("zhong", "guo", "ren") > 0.0)
  assert_true(PinyinLM::trigram_prob("zzz", "yyy", "ren") > 0.0)
}

///|
test "lm: 句子对数概率" {
  assert_eq(PinyinLM::sentence_log_prob([]), 0.0)
  assert_true(PinyinLM::sentence_log_prob(["ni"]) < 0.0)
  assert_true(PinyinLM::sentence_log_prob(["ni", "hao"]) < 0.0)
}

///|
test "lm: trigram 句子对数概率" {
  assert_eq(PinyinLM::sentence_log_prob_trigram([]), 0.0)
  assert_true(PinyinLM::sentence_log_prob_trigram(["ni"]) < 0.0)
  assert_true(PinyinLM::sentence_log_prob_trigram(["ni", "hao"]) < 0.0)
  assert_true(
    PinyinLM::sentence_log_prob_trigram(["zhong", "guo", "ren"]) < 0.0,
  )
}

///|
test "lm: interpolation 概率" {
  assert_true(
    PinyinLM::interpolation_prob("zhong", "guo", "ren", 0.5, 0.3, 0.2) > 0.0,
  )
  assert_eq(
    PinyinLM::interpolation_prob("zhong", "guo", "ren", 0.0, 0.0, 0.0),
    0.0,
  )
}

///|
test "lm: interpolation 负 λ 抛错" {
  let caught = try {
    let _ = PinyinLM::interpolation_prob("zhong", "guo", "ren", -1.0, 0.5, 0.5)
    false
  } catch {
    _ => true
  }
  assert_true(caught)
}

///|
test "lm: interpolation 句子对数概率" {
  assert_eq(PinyinLM::sentence_log_prob_interpolation([], 0.5, 0.3, 0.2), 0.0)
  assert_true(
    PinyinLM::sentence_log_prob_interpolation(["ni"], 0.5, 0.3, 0.2) < 0.0,
  )
  assert_true(
    PinyinLM::sentence_log_prob_interpolation(["ni", "hao"], 0.5, 0.3, 0.2) <
    0.0,
  )
  assert_true(
    PinyinLM::sentence_log_prob_interpolation(
      ["zhong", "guo", "ren"],
      0.5,
      0.3,
      0.2,
    ) <
    0.0,
  )
}

///|
test "lm: interpolation 句子负 λ 抛错" {
  let caught = try {
    let _ = PinyinLM::sentence_log_prob_interpolation(
      ["zhong", "guo", "ren"],
      -0.1,
      0.6,
      0.5,
    )
    false
  } catch {
    _ => true
  }
  assert_true(caught)
}

///|
test "lm: perplexity 正常与空输入" {
  assert_true(PinyinLM::perplexity([["ni", "hao"]]) > 0.0)
  assert_true(PinyinLM::perplexity([["ni", "hao"], ["zhong", "guo"]]) > 0.0)
  let caught_empty = try {
    let _ = PinyinLM::perplexity([])
    false
  } catch {
    _ => true
  }
  assert_true(caught_empty)
  let caught_blank = try {
    let _ = PinyinLM::perplexity([[]])
    false
  } catch {
    _ => true
  }
  assert_true(caught_blank)
}

///|
test "lm: perplexity_trigram 正常与空输入" {
  assert_true(PinyinLM::perplexity_trigram([["zhong", "guo", "ren"]]) > 0.0)
  let caught = try {
    let _ = PinyinLM::perplexity_trigram([])
    false
  } catch {
    _ => true
  }
  assert_true(caught)
}

///|
test "lm: perplexity_interpolation 正常与空输入" {
  assert_true(
    PinyinLM::perplexity_interpolation([["zhong", "guo", "ren"]], 0.5, 0.3, 0.2) >
    0.0,
  )
  let caught = try {
    let _ = PinyinLM::perplexity_interpolation([], 0.5, 0.3, 0.2)
    false
  } catch {
    _ => true
  }
  assert_true(caught)
}
