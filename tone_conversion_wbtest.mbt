///|
/// `find_array_key_by_value` 正向：首个带调元音 'ā' 索引为 0。
test "find_array_key_by_value_returns_0_for_first_marked_vowel" {
  debug_inspect(find_array_key_by_value('ā'), content="0")
}

///|
/// `find_array_key_by_value` 正向：末个带调元音 'ǜ' 索引为 23。
test "find_array_key_by_value_returns_23_for_last_marked_vowel" {
  debug_inspect(find_array_key_by_value('ǜ'), content="23")
}

///|
/// `find_array_key_by_value` 边界：无调元音 'a' 不在带调数组，返回 -1。
test "find_array_key_by_value_returns_neg1_for_unmarked_vowel" {
  debug_inspect(find_array_key_by_value('a'), content="-1")
}

///|
/// `find_array_key_by_value` 边界：非元音 'x' 返回 -1。
test "find_array_key_by_value_returns_neg1_for_non_vowel" {
  debug_inspect(find_array_key_by_value('x'), content="-1")
}

///|
/// `convert_with_tone_number` 一声：'ā' → "a1"。
test "convert_with_tone_number_tone1" {
  debug_inspect(convert_with_tone_number("ā"), content=(
    #|["a1"]
  ))
}

///|
/// `convert_with_tone_number` 二声：'á' → "a2"。
test "convert_with_tone_number_tone2" {
  debug_inspect(convert_with_tone_number("á"), content=(
    #|["a2"]
  ))
}

///|
/// `convert_with_tone_number` 三声：'ǎ' → "a3"。
test "convert_with_tone_number_tone3" {
  debug_inspect(convert_with_tone_number("ǎ"), content=(
    #|["a3"]
  ))
}

///|
/// `convert_with_tone_number` 四声：'à' → "a4"。
test "convert_with_tone_number_tone4" {
  debug_inspect(convert_with_tone_number("à"), content=(
    #|["a4"]
  ))
}

///|
/// `convert_with_tone_number` 轻声：无带调元音 'a' → "a5"。
test "convert_with_tone_number_light_tone5" {
  debug_inspect(convert_with_tone_number("a"), content=(
    #|["a5"]
  ))
}

///|
/// `convert_with_tone_number` 多音节：'ā,á' → ["a1", "a2"]。
test "convert_with_tone_number_multi_syllable" {
  debug_inspect(convert_with_tone_number("ā,á"), content=(
    #|["a1", "a2"]
  ))
}

///|
/// `convert_with_tone_number` ü 替换为 v + 四声：'lǜ' → "lv4"。
test "convert_with_tone_number_u_umlaut_to_v" {
  debug_inspect(convert_with_tone_number("lǜ"), content=(
    #|["lv4"]
  ))
}

///|
/// `convert_without_tone` 单音节：'ā' → "a"。
test "convert_without_tone_single" {
  debug_inspect(convert_without_tone("ā"), content=(
    #|["a"]
  ))
}

///|
/// `convert_without_tone` 多音节：'ā,á' → ["a", "a"]。
test "convert_without_tone_multi_syllable" {
  debug_inspect(convert_without_tone("ā,á"), content=(
    #|["a", "a"]
  ))
}

///|
/// `convert_without_tone` ü 替换为 v：'lǜ' → "lv"。
test "convert_without_tone_u_umlaut_to_v" {
  debug_inspect(convert_without_tone("lǜ"), content=(
    #|["lv"]
  ))
}

///|
/// `format_pinyin` WithToneMark：原样切分。
test "format_pinyin_with_tone_mark" {
  debug_inspect(format_pinyin("ā", PinyinFormat::WithToneMark), content=(
    #|["ā"]
  ))
}

///|
/// `format_pinyin` WithToneNumber。
test "format_pinyin_with_tone_number" {
  debug_inspect(format_pinyin("ā", PinyinFormat::WithToneNumber), content=(
    #|["a1"]
  ))
}

///|
/// `format_pinyin` WithoutTone。
test "format_pinyin_without_tone" {
  debug_inspect(format_pinyin("ā", PinyinFormat::WithoutTone), content=(
    #|["a"]
  ))
}

///|
/// `format_pinyin` FirstLetter 复用 convert_without_tone。
test "format_pinyin_first_letter" {
  debug_inspect(format_pinyin("ā", PinyinFormat::FirstLetter), content=(
    #|["a"]
  ))
}

///|
/// `convert_to_pinyin_arrays` 命中字典：'一' → ["yī"]（WithToneMark）。
test "convert_to_pinyin_arrays_yi_with_tone_mark" {
  debug_inspect(
    convert_to_pinyin_arrays('一', PinyinFormat::WithToneMark),
    content=(
      #|["yī"]
    ),
  )
}

///|
/// `convert_to_pinyin_arrays` 命中字典：'一' → ["yi1"]（WithToneNumber）。
test "convert_to_pinyin_arrays_yi_with_tone_number" {
  debug_inspect(
    convert_to_pinyin_arrays('一', PinyinFormat::WithToneNumber),
    content=(
      #|["yi1"]
    ),
  )
}

///|
/// `convert_to_pinyin_arrays` 未命中字典：'x' → []。
test "convert_to_pinyin_arrays_non_chinese_returns_empty" {
  debug_inspect(
    convert_to_pinyin_arrays('x', PinyinFormat::WithToneMark),
    content="[]",
  )
}
