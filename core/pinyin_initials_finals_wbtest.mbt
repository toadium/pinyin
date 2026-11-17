///|

///|
/// 双字母声母提取：zh/ch/sh 应完整匹配，不误取首字母。
test "initial_double_letter" {
  assert_eq(get_initial("zhong"), "zh")
  assert_eq(get_initial("chang"), "ch")
  assert_eq(get_initial("sheng"), "sh")
}

///|
/// 单字母声母提取：b/p/m/f/d/t/n/l/g/k/h/j/q/x/r/z/c/s 各取首字母。
test "initial_single_letter" {
  assert_eq(get_initial("bei"), "b")
  assert_eq(get_initial("dong"), "d")
  assert_eq(get_initial("guo"), "g")
  assert_eq(get_initial("jian"), "j")
}

///|
/// 零声母：纯韵母音节无声母，返回空字符串。
test "initial_zero" {
  assert_eq(get_initial("ai"), "")
  assert_eq(get_initial("er"), "")
  assert_eq(get_initial("ou"), "")
}

///|
/// 韵母提取：去掉声母后剩余部分即为韵母。
test "final_basic" {
  assert_eq(get_final("zhong"), "ong")
  assert_eq(get_final("chang"), "ang")
  assert_eq(get_final("bei"), "ei")
  assert_eq(get_final("guo"), "uo")
  assert_eq(get_final("jian"), "ian")
}

///|
/// 零声母韵母：无声母时韵母等于整个音节。
test "final_zero_initial" {
  assert_eq(get_final("ai"), "ai")
  assert_eq(get_final("er"), "er")
  assert_eq(get_final("ou"), "ou")
}

///|
/// 带调拼音：声调标记不影响声母/韵母提取。
test "initials_finals_with_tone" {
  assert_eq(get_initial("zhōng"), "zh")
  assert_eq(get_final("zhōng"), "ong")
  assert_eq(get_initial("cháng"), "ch")
  assert_eq(get_final("cháng"), "ang")
}

///|
/// 特殊音节：ri 有声母 r，y/w 作半元音声母。
test "special_syllables" {
  assert_eq(get_initial("ri"), "r")
  assert_eq(get_final("ri"), "i")
  assert_eq(get_initial("yong"), "y")
  assert_eq(get_final("yong"), "ong")
  assert_eq(get_initial("wu"), "w")
  assert_eq(get_final("wu"), "u")
}
