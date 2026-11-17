///|
test "example_tone_sandhi" {
  let result = @tone.ToneSandhiHelper::apply_tone_sandhi(["nǐ", "hǎo"])
  assert_eq(result.length(), 2)
  assert_eq(result[0], "ní")
  assert_eq(result[1], "hǎo")
  println("tone_sandhi ['nǐ','hǎo'] → \{result[0]} \{result[1]}")
}
