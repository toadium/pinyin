///|
test "tone_sandhi: 一+二/三/轻声" {
  assert_eq(ToneSandhiHelper::apply_tone_sandhi(["yī", "míng"]), [
    "yì", "míng",
  ])
  assert_eq(ToneSandhiHelper::apply_tone_sandhi(["yī", "qǐ"]), ["yì", "qǐ"])
  assert_eq(ToneSandhiHelper::apply_tone_sandhi(["yī", "ma"]), ["yī", "ma"])
}

///|
test "tone_sandhi: 一单独" {
  assert_eq(ToneSandhiHelper::apply_tone_sandhi(["yī"]), ["yī"])
}

///|
test "tone_sandhi: 七各分支" {
  assert_eq(ToneSandhiHelper::apply_tone_sandhi(["qī", "míng"]), [
    "qì", "míng",
  ])
  assert_eq(ToneSandhiHelper::apply_tone_sandhi(["qī", "qǐ"]), ["qì", "qǐ"])
  assert_eq(ToneSandhiHelper::apply_tone_sandhi(["qī", "ma"]), ["qī", "ma"])
  assert_eq(ToneSandhiHelper::apply_tone_sandhi(["qī"]), ["qī"])
}

///|
test "tone_sandhi: 八各分支" {
  assert_eq(ToneSandhiHelper::apply_tone_sandhi(["bā", "míng"]), [
    "bà", "míng",
  ])
  assert_eq(ToneSandhiHelper::apply_tone_sandhi(["bā", "qǐ"]), ["bà", "qǐ"])
  assert_eq(ToneSandhiHelper::apply_tone_sandhi(["bā", "ma"]), ["bā", "ma"])
  assert_eq(ToneSandhiHelper::apply_tone_sandhi(["bā"]), ["bā"])
}

///|
test "tone_sandhi: 不各分支" {
  assert_eq(ToneSandhiHelper::apply_tone_sandhi(["bù", "tiān"]), [
    "bù", "tiān",
  ])
  assert_eq(ToneSandhiHelper::apply_tone_sandhi(["bù", "ma"]), ["bù", "ma"])
  assert_eq(ToneSandhiHelper::apply_tone_sandhi(["bù"]), ["bù"])
}

///|
test "tone_sandhi: 三声链与无调" {
  assert_eq(ToneSandhiHelper::apply_tone_sandhi(["nǐ", "hǎo", "ma"]), [
    "ní", "hǎo", "ma",
  ])
  assert_eq(ToneSandhiHelper::apply_tone_sandhi(["ni", "hao"]), ["ni", "hao"])
}
