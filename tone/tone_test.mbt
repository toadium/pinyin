///|
test "tone_sandhi: 三声变调 你好 → ní hǎo" {
  let result = @tone.ToneSandhiHelper::apply_tone_sandhi(["nǐ", "hǎo"])
  assert_eq(result.length(), 2)
  assert_eq(result[0], "ní")
  assert_eq(result[1], "hǎo")
}

///|
test "tone_sandhi: 三声不变调 你 → nǐ" {
  let result = @tone.ToneSandhiHelper::apply_tone_sandhi(["nǐ"])
  assert_eq(result.length(), 1)
  assert_eq(result[0], "nǐ")
}

///|
test "tone_sandhi: 一+四声 → 二声 一个" {
  let result = @tone.ToneSandhiHelper::apply_tone_sandhi(["yī", "gè"])
  assert_eq(result.length(), 2)
  assert_eq(result[0], "yí")
  assert_eq(result[1], "gè")
}

///|
test "tone_sandhi: 一+一声 → 四声 一天" {
  let result = @tone.ToneSandhiHelper::apply_tone_sandhi(["yī", "tiān"])
  assert_eq(result.length(), 2)
  assert_eq(result[0], "yì")
  assert_eq(result[1], "tiān")
}

///|
test "tone_sandhi: 不+四声 → 二声 不对" {
  let result = @tone.ToneSandhiHelper::apply_tone_sandhi(["bù", "duì"])
  assert_eq(result.length(), 2)
  assert_eq(result[0], "bú")
  assert_eq(result[1], "duì")
}

///|
test "tone_sandhi: 不+非四声 → 保持四声 不好" {
  let result = @tone.ToneSandhiHelper::apply_tone_sandhi(["bù", "hǎo"])
  assert_eq(result.length(), 2)
  assert_eq(result[0], "bù")
  assert_eq(result[1], "hǎo")
}

///|
test "tone_sandhi: 空数组" {
  let result = @tone.ToneSandhiHelper::apply_tone_sandhi([])
  assert_eq(result.length(), 0)
}

///|
test "tone_sandhi: 三声变调链 很好 → hén hǎo" {
  let result = @tone.ToneSandhiHelper::apply_tone_sandhi(["hěn", "hǎo"])
  assert_eq(result.length(), 2)
  assert_eq(result[0], "hén")
  assert_eq(result[1], "hǎo")
}
