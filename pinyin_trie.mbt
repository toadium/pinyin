///|
/// Trie 节点：children 存储子节点，is_end 标记是否为完整音节终点。
struct PinyinTrieNode {
  children : Map[Char, PinyinTrieNode]
  mut is_end : Bool
}

///|
fn PinyinTrieNode::new() -> PinyinTrieNode {
  { children: {}, is_end: false, }
}

///|
/// 拼音 Trie 数据结构，用于高效前缀查找和拼音音节验证。
/// 自研实现，MoonBit 生态尚无通用 Trie 库。
pub struct PinyinTrie {
  root : PinyinTrieNode
}

///|
pub fn PinyinTrie::new() -> PinyinTrie {
  { root: PinyinTrieNode::new(), }
}

///|
/// 插入一个词到 Trie 中。
pub fn PinyinTrie::insert(self : PinyinTrie, word : String) -> Unit {
  let chars = word.to_array()
  PinyinTrieNode::insert_recursive(self.root, chars, 0)
}

///|
fn PinyinTrieNode::insert_recursive(
  node : PinyinTrieNode,
  chars : Array[Char],
  index : Int32,
) -> Unit {
  if index >= chars.length() {
    node.is_end = true
    return
  }
  let ch = chars[index]
  match node.children.get(ch) {
    Some(child) => PinyinTrieNode::insert_recursive(child, chars, index + 1)
    None => {
      let new_node = PinyinTrieNode::new()
      node.children[ch] = new_node
      PinyinTrieNode::insert_recursive(new_node, chars, index + 1)
    }
  }
}

///|
/// 判断完整词是否在 Trie 中。
pub fn PinyinTrie::contains(self : PinyinTrie, word : String) -> Bool {
  let chars = word.to_array()
  PinyinTrieNode::contains_recursive(self.root, chars, 0)
}

///|
fn PinyinTrieNode::contains_recursive(
  node : PinyinTrieNode,
  chars : Array[Char],
  index : Int32,
) -> Bool {
  if index >= chars.length() {
    return node.is_end
  }
  match node.children.get(chars[index]) {
    Some(child) => PinyinTrieNode::contains_recursive(child, chars, index + 1)
    None => false
  }
}

///|
/// 从字符串 start 位置开始，返回所有有效音节前缀的长度列表。
/// 例如对 "nihao" 从位置 0 开始，返回 [2]（"ni" 是有效音节，长度 2）。
pub fn PinyinTrie::prefix_lengths(
  self : PinyinTrie,
  s : String,
  start : Int32,
) -> Array[Int32] {
  let result : Array[Int32] = []
  let chars = s.to_array()
  PinyinTrieNode::collect_prefix_lengths(self.root, chars, start, start, result)
  result
}

///|
fn PinyinTrieNode::collect_prefix_lengths(
  node : PinyinTrieNode,
  chars : Array[Char],
  start : Int32,
  current : Int32,
  result : Array[Int32],
) -> Unit {
  if current >= chars.length() {
    return
  }
  match node.children.get(chars[current]) {
    Some(child) => {
      let next = current + 1
      if child.is_end {
        result.push(next - start)
      }
      PinyinTrieNode::collect_prefix_lengths(child, chars, start, next, result)
    }
    None => ()
  }
}

///|
/// 全部合法无调拼音音节列表（约 420 个），覆盖汉语拼音全部声母韵母组合。
/// 使用 'v' 替代 'ü'，与 strip_tone 输出一致。
let pinyin_syllables : Array[String] = [
  // 零声母
  "a", "ai", "an", "ang", "ao", "e", "ei", "en", "eng", "er", "o", "ou",
  // b
   "ba", "bai", "ban", "bang", "bao", "bei", "ben", "beng", "bi", "bian", "biao",
  "bie", "bin", "bing", "bo", "bu",
  // p
   "pa", "pai", "pan", "pang", "pao", "pei", "pen", "peng", "pi", "pian", "piao",
  "pie", "pin", "ping", "po", "pou", "pu",
  // m
   "ma", "mai", "man", "mang", "mao", "me", "mei", "men", "meng", "mi", "mian", "miao",
  "mie", "min", "ming", "miu", "mo", "mou", "mu",
  // f
   "fa", "fan", "fang", "fei", "fen", "feng", "fo", "fou", "fu",
  // d
   "da", "dai", "dan", "dang", "dao", "de", "dei", "den", "deng", "di", "dia", "dian",
  "diao", "die", "ding", "diu", "dong", "dou", "du", "duan", "dui", "dun", "duo",
  // t
   "ta", "tai", "tan", "tang", "tao", "te", "teng", "ti", "tian", "tiao", "tie",
  "ting", "tong", "tou", "tu", "tuan", "tui", "tun", "tuo",
  // n
   "na", "nai", "nan", "nang", "nao", "ne", "nei", "nen", "neng", "ni", "nian", "niang",
  "niao", "nie", "nin", "ning", "niu", "nong", "nou", "nu", "nuan", "nun", "nuo",
  "nv", "nve",
  // l
   "la", "lai", "lan", "lang", "lao", "le", "lei", "leng", "li", "lia", "lian", "liang",
  "liao", "lie", "lin", "ling", "liu", "long", "lou", "lu", "luan", "lun", "luo",
  "lv", "lve",
  // g
   "ga", "gai", "gan", "gang", "gao", "ge", "gei", "gen", "geng", "gong", "gou",
  "gu", "gua", "guai", "guan", "guang", "gui", "gun", "guo",
  // k
   "ka", "kai", "kan", "kang", "kao", "ke", "kei", "ken", "keng", "kong", "kou",
  "ku", "kua", "kuai", "kuan", "kuang", "kui", "kun", "kuo",
  // h
   "ha", "hai", "han", "hang", "hao", "he", "hei", "hen", "heng", "hong", "hou",
  "hu", "hua", "huai", "huan", "huang", "hui", "hun", "huo",
  // j
   "ji", "jia", "jian", "jiang", "jiao", "jie", "jin", "jing", "jiong", "jiu", "ju",
  "juan", "jue", "jun",
  // q
   "qi", "qia", "qian", "qiang", "qiao", "qie", "qin", "qing", "qiong", "qiu", "qu",
  "quan", "que", "qun",
  // x
   "xi", "xia", "xian", "xiang", "xiao", "xie", "xin", "xing", "xiong", "xiu", "xu",
  "xuan", "xue", "xun",
  // zh
   "zha", "zhai", "zhan", "zhang", "zhao", "zhe", "zhei", "zhen", "zheng", "zhi",
  "zhong", "zhou", "zhu", "zhua", "zhuai", "zhuan", "zhuang", "zhui", "zhun", "zhuo",
  // ch
   "cha", "chai", "chan", "chang", "chao", "che", "chen", "cheng", "chi", "chong",
  "chou", "chu", "chua", "chuai", "chuan", "chuang", "chui", "chun", "chuo",
  // sh
   "sha", "shai", "shan", "shang", "shao", "she", "shei", "shen", "sheng", "shi",
  "shou", "shu", "shua", "shuai", "shuan", "shuang", "shui", "shun", "shuo",
  // r
   "ran", "rang", "rao", "re", "ren", "reng", "ri", "rong", "rou", "ru", "rua", "ruan",
  "rui", "run", "ruo",
  // z
   "za", "zai", "zan", "zang", "zao", "ze", "zei", "zen", "zeng", "zi", "zong", "zou",
  "zu", "zuan", "zui", "zun", "zuo",
  // c
   "ca", "cai", "can", "cang", "cao", "ce", "cen", "ceng", "ci", "cong", "cou", "cu",
  "cuan", "cui", "cun", "cuo",
  // s
   "sa", "sai", "san", "sang", "sao", "se", "sen", "seng", "si", "song", "sou", "su",
  "suan", "sui", "sun", "suo",
  // y
   "ya", "yan", "yang", "yao", "ye", "yi", "yin", "ying", "yo", "yong", "you", "yu",
  "yuan", "yue", "yun",
  // w
   "wa", "wai", "wan", "wang", "wei", "wen", "weng", "wo", "wu",
]

///|
/// 从 pinyin_syllables 构建的拼音 Trie 全局实例。
/// 用于拼音分词（PinyinSegmenter）和音节验证。
pub let pinyin_trie : PinyinTrie = {
  let trie = PinyinTrie::new()
  for syllable in pinyin_syllables {
    trie.insert(syllable)
  }
  trie
}

///|
/// 去除单个拼音音节的声调标记，返回无调拼音。
/// 带调元音 → 无调元音，ü → v。
fn strip_tone(pinyin : String) -> String {
  let mut s = pinyin
  for i in 0..<all_marked_vowel_array.length() {
    let original_char = all_marked_vowel_array[i]
    let replace_char = all_unmarked_vowel_array[(i - i % 4) / 4]
    s = s.replace_all(
      old=original_char.to_string(),
      new=replace_char.to_string(),
    )
  }
  s.replace_all(old="ü", new="v")
}

///|
/// 去除数字声调后缀（如 "zhong1" → "zhong"），返回无调无数字拼音。
fn strip_tone_number(pinyin : String) -> String {
  let chars = pinyin.to_array()
  if chars.length() > 0 {
    let last = chars[chars.length() - 1]
    if last >= '0' && last <= '5' {
      return pinyin[:pinyin.length() - 1].to_owned()
    }
  }
  pinyin
}
