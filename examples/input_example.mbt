///|
test "example_input_basic" {
  let engine = @input.PinyinInputEngine::new()
  let candidates = engine.input("nihao")
  assert_true(candidates.length() > 0)
  println("input 'nihao' → \{candidates.length()} candidates")
  for c in candidates {
    println("  \{c.text} (score=\{c.score})")
  }
}

///|
test "example_input_with_limit" {
  let engine = @input.PinyinInputEngine::new()
  let candidates = engine.input_with_limit("zhongguo", 3)
  assert_true(candidates.length() <= 3)
  println("input_with_limit 'zhongguo' top 3:")
  for c in candidates {
    println("  \{c.text}")
  }
}

///|
test "example_input_user_dict" {
  let engine = @input.PinyinInputEngine::new()
  let dict : Map[String, String] = { "zhang san": "张三" }
  engine.add_user_dict(dict)
  let candidates = engine.input("zhangsan")
  let has_zhangsan = candidates.iter().any(fn(c) { c.text == "张三" })
  assert_true(has_zhangsan, msg="should have '张三' from user dict")
  println("user dict 'zhangsan' → '张三' found: \{has_zhangsan}")
}

///|
test "example_input_all_segments" {
  let engine = @input.PinyinInputEngine::new()
  let candidates = engine.input_all_segments("xian")
  assert_true(candidates.length() > 0)
  println("input_all_segments 'xian' → \{candidates.length()} candidates")
}
