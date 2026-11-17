///|
test "example_get_initial" {
  let zh = @core.get_initial("zhong")
  inspect(zh, content="zh")
  let b = @core.get_initial("bei")
  inspect(b, content="b")
  let empty = @core.get_initial("ai")
  inspect(empty, content="")
}

///|
test "example_get_final" {
  let ong = @core.get_final("zhong")
  inspect(ong, content="ong")
  let ei = @core.get_final("bei")
  inspect(ei, content="ei")
  let ai = @core.get_final("ai")
  inspect(ai, content="ai")
}
