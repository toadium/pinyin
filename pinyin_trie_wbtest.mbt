///|
/// Trie 基本操作：insert + contains。
test "trie_insert_and_contains" {
  let trie = PinyinTrie::new()
  trie.insert("hello")
  assert_true(trie.contains("hello"))
  assert_false(trie.contains("hell"))
  assert_false(trie.contains("helloo"))
}

///|
/// Trie 插入空串后 contains 空串为 true。
test "trie_empty_string" {
  let trie = PinyinTrie::new()
  assert_false(trie.contains(""))
  trie.insert("")
  assert_true(trie.contains(""))
}

///|
/// Trie 前缀查找：从给定位置返回所有有效音节前缀长度。
test "trie_prefix_lengths" {
  let trie = PinyinTrie::new()
  trie.insert("ni")
  trie.insert("nihao")
  trie.insert("hao")
  let lengths = trie.prefix_lengths("nihao", 0)
  // "ni" 是完整音节（长度 2），"nihao" 不是（未 insert 为完整词除非单独 insert）
  assert_true(lengths.contains(2))
}

///|
/// pinyin_trie 全局实例：包含所有合法拼音音节。
test "pinyin_trie_contains_common_syllables" {
  assert_true(pinyin_trie.contains("a"))
  assert_true(pinyin_trie.contains("zhong"))
  assert_true(pinyin_trie.contains("guo"))
  assert_true(pinyin_trie.contains("ni"))
  assert_true(pinyin_trie.contains("hao"))
  assert_true(pinyin_trie.contains("xian"))
  assert_true(pinyin_trie.contains("xi"))
  assert_true(pinyin_trie.contains("an"))
}

///|
/// pinyin_trie 全局实例：非法拼音不在 Trie 中。
test "pinyin_trie_rejects_invalid_syllables" {
  assert_false(pinyin_trie.contains("xyz"))
  assert_false(pinyin_trie.contains("niha"))
  assert_false(pinyin_trie.contains("zhongg"))
}

///|
/// pinyin_trie prefix_lengths：从 "nihao" 位置 0 开始，应找到 "ni"（长度 2）。
test "pinyin_trie_prefix_lengths_nihao" {
  let lengths = pinyin_trie.prefix_lengths("nihao", 0)
  assert_true(lengths.contains(2))
}

///|
/// pinyin_trie prefix_lengths：从 "xian" 位置 0 开始，应找到 "xi"（长度 2）和 "xian"（长度 4）。
test "pinyin_trie_prefix_lengths_xian" {
  let lengths = pinyin_trie.prefix_lengths("xian", 0)
  assert_true(lengths.contains(2))
  assert_true(lengths.contains(4))
}

///|
/// strip_tone：带调拼音 → 无调拼音。
test "strip_tone_basic" {
  inspect(strip_tone("zhōng"), content="zhong")
  inspect(strip_tone("lǚ"), content="lv")
  inspect(strip_tone("ā,mí,tuó,fó"), content="a,mi,tuo,fo")
}

///|
/// strip_tone_number：数字调拼音 → 无调拼音。
test "strip_tone_number_basic" {
  inspect(strip_tone_number("zhong1"), content="zhong")
  inspect(strip_tone_number("lv3"), content="lv")
  inspect(strip_tone_number("zhong"), content="zhong")
}
