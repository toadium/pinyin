"""生成常用字排序表。

排序依据分两层：
1. 人工整理的高频字序（约 500 字，按常见度排列），作为主排序键；
2. GB2312-80 一级汉字区（0xB0A1-0xD7F9，共 3755 个常用字）作为兜底，
   未进入高频表的常用字排在主表之后，生僻字不收录。

高频表为输入法候选排序服务，不宣称是权威语料字频；GB2312 一级字区
用于保证"常用字优先、生僻字靠后"的下界。

输出：data/common_chars.mbt（字符串常量 + 查找函数，避免大 Map 字面量
触发 wasm local count 上限）。
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "data" / "common_chars.mbt"

HIGH_FREQ = (
    "的一是在不了有和人这中大为上个国我以要他时来用们生到作地于出就分"
    "对成会可主发年动同工也能下过子说产种面而方后多定行学法所民得经十三"
    "之进着等部度家电力里如水化高自二理起小物现实加量都两体制机当使点从"
    "业本去把性好应开它合还因由其些然前外天政四日那社义事平形相全表间样"
    "与关各重新线内数正心反你明看原又么利比或但质气第向道命此变条只没结"
    "解问意建月公无系军很情者最立代想已通并提直题党程展五果料象员革位入"
    "常文总次品式活设及管特件长求老头基资边流路级少图山统接知较将组见计"
    "别她手角期根论运农指几九区强放决西被干做必战先回则任取据处队南给色"
    "光门即保治北造百规热领七海口东导器压志世金增争济阶油思术极交受联什"
    "认六共权收证改清美再采转更单风切打白教速花带安场身车例真务具万每目"
    "至达走积示议声报斗完类八离华名确才科张信马节话米整空元况今集温传土"
    "许步群广石记需段研界拉林律叫且究观越织装影算低持音众书布复容儿须际"
    "商非验连断深难近矿千周委素技备半办青省列习响约支般史感劳便团往酸历"
    "市克何除消构府称太准精值号率族维划选标写存候毛亲快效斯院查江型眼王"
    "按格养易置派层片始却专状育厂京识适属圆包火住调满县局照参红细引听该"
    "铁价严龙飞"
)

LINE_SIZE = 100


def gb2312_level1() -> str:
    chars = []
    for high in range(0xB0, 0xD8):
        for low in range(0xA1, 0xFF):
            if high == 0xD7 and low > 0xF9:
                continue
            chars.append(bytes([high, low]).decode("gb2312"))
    return "".join(chars)


def build_chars() -> list[str]:
    seen: dict[str, None] = {}
    for ch in HIGH_FREQ:
        seen.setdefault(ch, None)
    for ch in gb2312_level1():
        seen.setdefault(ch, None)
    return list(seen.keys())


def emit() -> None:
    chars = build_chars()
    chunks = [
        "".join(chars[i : i + LINE_SIZE])
        for i in range(0, len(chars), LINE_SIZE)
    ]

    lines = [
        "///|",
        "/// 常用字序列：人工整理的高频字序（约 500 字）在前，GB2312-80 一级汉字区",
        "/// （3755 个常用字）在后。序号越小越常用，未收录字由调用方排在最后。",
        "/// 输入法候选排序用：同音候选优先常用字，截断候选上限时保留常用字。",
        "/// 由 scripts/gen_common_chars.py 生成，请勿手工编辑。",
        "let common_chars : String = " +
        " +\n  ".join(f'"{chunk}"' for chunk in chunks),
        "",
        "///|",
        "/// 返回汉字在常用字序列中的字节偏移（越小越常用），未收录返回 100000。",
        "pub fn common_char_rank(ch : String) -> Int32 {",
        "  match common_chars.find(ch) {",
        "    Some(offset) => offset",
        "    None => 100000",
        "  }",
        "}",
        "",
    ]

    OUT.write_text("\n".join(lines), encoding="utf-8")

    rank = {ch: i for i, ch in enumerate(chars)}
    print(f"generated {OUT} ({len(chars)} chars, {len(chunks)} lines)")
    for ch in "你好中国是的一不了在人有我":
        print(ch, rank.get(ch, "missing"))


if __name__ == "__main__":
    emit()