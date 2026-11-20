///|
test "shuangpin: 小鹤全拼转双拼" {
  assert_eq(@shuangpin.ShuangpinScheme::Xiaohe.from_full("ni"), "ni")
  assert_eq(@shuangpin.ShuangpinScheme::Xiaohe.from_full("hao"), "hc")
  assert_eq(@shuangpin.ShuangpinScheme::Xiaohe.from_full("zhong"), "vs")
  assert_eq(@shuangpin.ShuangpinScheme::Xiaohe.from_full("guo"), "go")
  assert_eq(@shuangpin.ShuangpinScheme::Xiaohe.from_full("shu"), "uu")
  assert_eq(@shuangpin.ShuangpinScheme::Xiaohe.from_full("ru"), "ru")
  assert_eq(@shuangpin.ShuangpinScheme::Xiaohe.from_full("fa"), "fa")
}

///|
test "shuangpin: 小鹤韵母覆盖" {
  let scheme = @shuangpin.ShuangpinScheme::Xiaohe
  assert_eq(scheme.from_full("jiong"), "js")
  assert_eq(scheme.from_full("guai"), "gk")
  assert_eq(scheme.from_full("jiang"), "jl")
  assert_eq(scheme.from_full("guang"), "gl")
  assert_eq(scheme.from_full("jia"), "jx")
  assert_eq(scheme.from_full("gua"), "gx")
  assert_eq(scheme.from_full("jiu"), "jq")
  assert_eq(scheme.from_full("dui"), "dv")
  assert_eq(scheme.from_full("lü"), "lv")
  assert_eq(scheme.from_full("xue"), "xt")
  assert_eq(scheme.from_full("lun"), "ly")
  assert_eq(scheme.from_full("liao"), "ln")
  assert_eq(scheme.from_full("zhuang"), "vl")
  assert_eq(scheme.from_full("chuai"), "ik")
  assert_eq(scheme.from_full("shua"), "ux")
  assert_eq(scheme.from_full("ruo"), "ro")
}

///|
test "shuangpin: 小鹤双拼转全拼" {
  assert_eq(@shuangpin.ShuangpinScheme::Xiaohe.to_full("nihc"), "ni hao")
  assert_eq(@shuangpin.ShuangpinScheme::Xiaohe.to_full("vsgo"), "zhong guo")
  assert_eq(@shuangpin.ShuangpinScheme::Xiaohe.to_full("uurufa"), "shu ru fa")
  assert_eq(@shuangpin.ShuangpinScheme::Xiaohe.to_full("ni'hc"), "ni hao")
}

///|
test "shuangpin: 小鹤逆向分支" {
  let scheme = @shuangpin.ShuangpinScheme::Xiaohe
  assert_eq(scheme.to_full("js"), "jiong")
  assert_eq(scheme.to_full("gs"), "gong")
  assert_eq(scheme.to_full("gk"), "guai")
  assert_eq(scheme.to_full("jk"), "jing")
  assert_eq(scheme.to_full("jl"), "jiang")
  assert_eq(scheme.to_full("gl"), "guang")
  assert_eq(scheme.to_full("jx"), "jia")
  assert_eq(scheme.to_full("gx"), "gua")
  assert_eq(scheme.to_full("go"), "guo")
  assert_eq(scheme.to_full("bo"), "bo")
  assert_eq(scheme.to_full("dv"), "dui")
  assert_eq(scheme.to_full("nv"), "nü")
  assert_eq(scheme.to_full("xt"), "xue")
  assert_eq(scheme.to_full("ly"), "lun")
  assert_eq(scheme.to_full("ln"), "liao")
  assert_eq(scheme.to_full("vl"), "zhuang")
  assert_eq(scheme.to_full("ik"), "chuai")
  assert_eq(scheme.to_full("ux"), "shua")
  assert_eq(scheme.to_full("ro"), "ruo")
}

///|
test "shuangpin: 自然码往返" {
  assert_eq(@shuangpin.ShuangpinScheme::Ziranma.from_full("hao"), "hk")
  assert_eq(@shuangpin.ShuangpinScheme::Ziranma.from_full("zhong"), "vs")
  assert_eq(@shuangpin.ShuangpinScheme::Ziranma.from_full("guo"), "go")
  assert_eq(@shuangpin.ShuangpinScheme::Ziranma.to_full("nihk"), "ni hao")
  assert_eq(@shuangpin.ShuangpinScheme::Ziranma.to_full("vsgo"), "zhong guo")
}

///|
test "shuangpin: 自然码韵母覆盖" {
  let scheme = @shuangpin.ShuangpinScheme::Ziranma
  assert_eq(scheme.from_full("xiao"), "xc")
  assert_eq(scheme.from_full("jia"), "jw")
  assert_eq(scheme.from_full("gua"), "gw")
  assert_eq(scheme.from_full("guai"), "gy")
  assert_eq(scheme.from_full("jiang"), "jd")
  assert_eq(scheme.from_full("guang"), "gd")
  assert_eq(scheme.from_full("jun"), "jp")
  assert_eq(scheme.from_full("dui"), "dv")
  assert_eq(scheme.from_full("lü"), "lv")
  assert_eq(scheme.from_full("xue"), "xt")
}

///|
test "shuangpin: 自然码逆向分支" {
  let scheme = @shuangpin.ShuangpinScheme::Ziranma
  assert_eq(scheme.to_full("js"), "jiong")
  assert_eq(scheme.to_full("gs"), "gong")
  assert_eq(scheme.to_full("gw"), "gua")
  assert_eq(scheme.to_full("jw"), "jia")
  assert_eq(scheme.to_full("gy"), "guai")
  assert_eq(scheme.to_full("jy"), "jing")
  assert_eq(scheme.to_full("jd"), "jiang")
  assert_eq(scheme.to_full("gd"), "guang")
  assert_eq(scheme.to_full("gp"), "gun")
  assert_eq(scheme.to_full("jp"), "jun")
  assert_eq(scheme.to_full("do"), "duo")
  assert_eq(scheme.to_full("bo"), "bo")
  assert_eq(scheme.to_full("dv"), "dui")
  assert_eq(scheme.to_full("nv"), "nü")
  assert_eq(scheme.to_full("xt"), "xue")
  assert_eq(scheme.to_full("ri"), "ri")
  assert_eq(scheme.to_full("zi"), "zi")
}

///|
test "shuangpin: ü 归一化" {
  assert_eq(@shuangpin.ShuangpinScheme::Xiaohe.to_full("jv"), "ju")
  assert_eq(@shuangpin.ShuangpinScheme::Xiaohe.to_full("nv"), "nü")
  assert_eq(@shuangpin.ShuangpinScheme::Ziranma.to_full("jv"), "ju")
  assert_eq(@shuangpin.ShuangpinScheme::Ziranma.to_full("jp"), "jun")
}

///|
test "shuangpin: 零声母与非法输入" {
  assert_eq(@shuangpin.ShuangpinScheme::Xiaohe.from_full("ai"), "ai")
  assert_eq(@shuangpin.ShuangpinScheme::Xiaohe.from_full("er"), "er")
  assert_eq(@shuangpin.ShuangpinScheme::Xiaohe.to_full("abc"), "abc")
  assert_eq(@shuangpin.ShuangpinScheme::Xiaohe.to_full(""), "")
}

///|
test "shuangpin: 全声母与韵母覆盖" {
  let scheme = @shuangpin.ShuangpinScheme::Xiaohe
  let initials = [
    "b", "p", "m", "f", "d", "t", "n", "l", "g", "k", "h", "j", "q", "x", "r", "z",
    "c", "s", "y", "w",
  ]
  for ini in initials {
    assert_eq(scheme.from_full(ini + "a").length(), 2)
  }
  let finals = [
    "a", "o", "e", "i", "u", "v", "ai", "ei", "ao", "ou", "an", "en", "ang", "eng",
    "ong", "iong", "uo", "ie", "iu", "ing", "uai", "iang", "uang", "ian", "in", "uan",
    "ue", "ve", "un", "ui", "ia", "ua", "iao", "ü",
  ]
  for f in finals {
    assert_eq(scheme.from_full("g" + f).length(), 2)
  }
}

///|
test "shuangpin: 全键位逆向覆盖" {
  let xiaohe = @shuangpin.ShuangpinScheme::Xiaohe
  let ziranma = @shuangpin.ShuangpinScheme::Ziranma
  let keys = "abcdefghijklmnopqrstuvwxyz"
  for i in 0..<keys.length() {
    let key = keys[i].unsafe_to_char().to_string()
    assert_true(xiaohe.to_full("g" + key).length() > 0)
    assert_true(ziranma.to_full("g" + key).length() > 0)
  }
}

///|
test "shuangpin: 方案名称" {
  assert_eq(@shuangpin.ShuangpinScheme::Xiaohe.name(), "小鹤双拼")
  assert_eq(@shuangpin.ShuangpinScheme::Ziranma.name(), "自然码双拼")
  match @shuangpin.ShuangpinScheme::from_name("xiaohe") {
    Some(scheme) => assert_eq(scheme.name(), "小鹤双拼")
    None => fail("expected xiaohe scheme")
  }
  match @shuangpin.ShuangpinScheme::from_name("unknown") {
    Some(_) => fail("expected None for unknown scheme")
    None => ()
  }
}
