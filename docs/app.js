import {
  pinyin_version,
  pinyin_convert,
  pinyin_disambiguate,
  pinyin_input,
  pinyin_shuangpin,
  pinyin_segment,
  pinyin_normalize,
  pinyin_to_simplified,
  pinyin_to_traditional,
  pinyin_convert_sentence,
  pinyin_convert_format,
  pinyin_add_dict_char,
  pinyin_add_dict_phrase,
  pinyin_add_dict_chinese,
  pinyin_multi_readings,
  pinyin_convert_traditional,
  pinyin_tongyong,
} from "./playground.js";

const $ = (sel) => document.querySelector(sel);
const $$ = (sel) => Array.from(document.querySelectorAll(sel));
const setText = (id, text) => {
  const node = $(id);
  if (node) node.textContent = text;
};

/* ---------- 主题切换 ---------- */

const THEME_KEY = "pinyin-theme";
const themeToggle = $("#theme-toggle");

function applyTheme(theme) {
  document.documentElement.dataset.theme = theme;
  if (themeToggle) {
    themeToggle.textContent = theme === "dark" ? "☀" : "◐";
    themeToggle.setAttribute("aria-label", theme === "dark" ? "切换到浅色主题" : "切换到深色主题");
    themeToggle.title = themeToggle.getAttribute("aria-label");
  }
}

if (themeToggle) {
  themeToggle.addEventListener("click", () => {
    const next = document.documentElement.dataset.theme === "dark" ? "light" : "dark";
    applyTheme(next);
    try {
      localStorage.setItem(THEME_KEY, next);
    } catch {
      /* 隐私模式下忽略持久化失败 */
    }
  });
  applyTheme(document.documentElement.dataset.theme === "dark" ? "dark" : "light");
}

/* ---------- 复制按钮 ---------- */

async function copyText(text) {
  if (navigator.clipboard && window.isSecureContext) {
    await navigator.clipboard.writeText(text);
    return;
  }
  const area = document.createElement("textarea");
  area.value = text;
  area.setAttribute("readonly", "");
  area.style.position = "fixed";
  area.style.opacity = "0";
  document.body.appendChild(area);
  area.select();
  document.execCommand("copy");
  document.body.removeChild(area);
}

$$("[data-copy-target]").forEach((button) => {
  button.addEventListener("click", async () => {
    const target = document.getElementById(button.dataset.copyTarget);
    if (!target) return;
    const original = button.textContent;
    try {
      await copyText(target.textContent.trim());
      button.textContent = "已复制";
      button.classList.add("copied");
    } catch {
      button.textContent = "复制失败";
    }
    setTimeout(() => {
      button.textContent = original;
      button.classList.remove("copied");
    }, 1400);
  });
});

/* ---------- Hero 实时转换（先消歧，避免多音字展开干扰） ---------- */

const heroText = $("#hero-text");
const TONE_NUMBER = { "\u0304": 1, "\u0301": 2, "\u030C": 3, "\u0300": 4 };

function decomposeSyllable(syllable) {
  const base = [];
  let tone = 0;
  for (const ch of syllable.normalize("NFD")) {
    const number = TONE_NUMBER[ch];
    if (number) {
      tone = number;
      continue;
    }
    if (ch === "\u0308") {
      base.push("ü");
      continue;
    }
    if (/^\p{M}$/u.test(ch)) continue;
    base.push(ch);
  }
  return { base: base.join(""), tone };
}

function toToneNumber(syllable) {
  const { base, tone } = decomposeSyllable(syllable);
  return tone > 0 ? `${base}${tone}` : base;
}

function firstLetter(syllable) {
  return decomposeSyllable(syllable).base.charAt(0);
}

function renderHero() {
  if (!heroText) return;
  const text = heroText.value;
  const started = performance.now();
  try {
    const syllables = pinyin_disambiguate(text).trim().split(/\s+/).filter(Boolean);
    if (syllables.length === 0) {
      setText("#hero-mark", "—");
      setText("#hero-number", "—");
      setText("#hero-initial", "—");
    } else {
      setText("#hero-mark", syllables.join(" "));
      setText("#hero-number", syllables.map(toToneNumber).join(" "));
      setText("#hero-initial", syllables.map(firstLetter).join(" "));
    }
  } catch (e) {
    setText("#hero-mark", "调用失败：" + e.message);
  }
  setText("#hero-time", (performance.now() - started).toFixed(2) + " ms");
}

if (heroText) {
  heroText.addEventListener("input", renderHero);
  renderHero();
}

/* ---------- 在线演示 ---------- */

function convert() {
  const text = $("#convert-text").value;
  const sep = $("#convert-sep").value;
  const format = $("#convert-format").value;
  try {
    const out = pinyin_convert(text, sep, format);
    setText("#convert-out", out || "（无法转换：请输入汉字）");
  } catch (e) {
    setText("#convert-out", "调用失败：" + e.message);
  }
}

function inputCandidates() {
  const py = $("#input-py").value.trim();
  const box = $("#input-out");
  try {
    const out = pinyin_input(py);
    box.replaceChildren();
    if (!out) {
      box.textContent = "（无候选：检查拼音是否可切分）";
      return;
    }
    out.split("|").forEach((text, index) => {
      const chip = document.createElement("span");
      chip.className = "chip";
      chip.textContent = `${index + 1}. ${text}`;
      box.appendChild(chip);
    });
  } catch (e) {
    box.textContent = "调用失败：" + e.message;
  }
}

function shuangpin() {
  const scheme = $("#sp-scheme").value;
  const input = $("#sp-input").value.trim();
  try {
    const out = pinyin_shuangpin(scheme, input);
    setText("#sp-out", out || "（无法转换）");
  } catch (e) {
    setText("#sp-out", "调用失败：" + e.message);
  }
}

function disambiguate() {
  const text = $("#dis-text").value;
  try {
    const out = pinyin_disambiguate(text);
    setText("#dis-out", out || "（无法消歧：请输入汉字）");
  } catch (e) {
    setText("#dis-out", "调用失败：" + e.message);
  }
}

function segment() {
  const py = $("#seg-py").value.trim();
  try {
    const out = pinyin_segment(py);
    setText("#seg-out", out || "（无法切分）");
  } catch (e) {
    setText("#seg-out", "调用失败：" + e.message);
  }
}

function normalize() {
  const py = $("#norm-py").value.trim();
  try {
    const out = pinyin_normalize(py);
    setText("#norm-out", out || "（空）");
  } catch (e) {
    setText("#norm-out", "调用失败：" + e.message);
  }
}

function valueOf(id) {
  const el = $(id);
  return el ? el.value : "";
}

function toSimplified() {
  setText("#c2s-out", pinyin_to_simplified(valueOf("#c2s-text")) || "（空）");
}

function toTraditional() {
  setText("#s2t-out", pinyin_to_traditional(valueOf("#s2t-text")) || "（空）");
}

function sentencePinyin() {
  setText("#sent-out", pinyin_convert_sentence(valueOf("#sent-text")) || "（无法转换）");
}

function customFormat() {
  const out = pinyin_convert_format(
    valueOf("#fmt-text"),
    valueOf("#fmt-sep"),
    valueOf("#fmt-format"),
  );
  setText("#fmt-out", out || "（无法转换）");
}

function dictChar() {
  const out = pinyin_add_dict_char(
    valueOf("#char-dict-char"),
    valueOf("#char-dict-py"),
    valueOf("#char-dict-text"),
  );
  setText("#char-dict-out", out || "（无结果）");
}

function dictPhrase() {
  const out = pinyin_add_dict_phrase(
    valueOf("#phrase-dict-phrase"),
    valueOf("#phrase-dict-py"),
    valueOf("#phrase-dict-text"),
  );
  setText("#phrase-dict-out", out || "（无结果）");
}

function dictChinese() {
  const out = pinyin_add_dict_chinese(
    valueOf("#cn-dict-trad"),
    valueOf("#cn-dict-simp"),
    valueOf("#cn-dict-text"),
  );
  setText("#cn-dict-out", out || "（无结果）");
}

function multiReadings() {
  setText("#multi-out", pinyin_multi_readings(valueOf("#multi-text")) || "（空）");
}

function tradConvert() {
  const out = pinyin_convert_traditional(
    valueOf("#trad-conv-text"),
    valueOf("#trad-conv-format"),
  );
  setText("#trad-conv-out", out || "（无法转换）");
}

function tongyongPinyin() {
  setText("#tongyong-out", pinyin_tongyong(valueOf("#tongyong-text")) || "（空）");
}

const ACTIONS = {
  convert,
  input: inputCandidates,
  shuangpin,
  disambiguate,
  segment,
  normalize,
  c2s: toSimplified,
  s2t: toTraditional,
  sentence: sentencePinyin,
  format: customFormat,
  charDict: dictChar,
  phraseDict: dictPhrase,
  cnDict: dictChinese,
  multi: multiReadings,
  tradConvert,
  tongyong: tongyongPinyin,
};

$$("button[data-run]").forEach((button) => {
  button.addEventListener("click", () => {
    const action = ACTIONS[button.dataset.run];
    if (action) action();
  });
});

const ENTER_ACTIONS = [
  ["#convert-text", "convert"],
  ["#convert-sep", "convert"],
  ["#convert-format", "convert"],
  ["#input-py", "input"],
  ["#sp-input", "shuangpin"],
  ["#dis-text", "disambiguate"],
  ["#seg-py", "segment"],
  ["#norm-py", "normalize"],
  ["#c2s-text", "c2s"],
  ["#s2t-text", "s2t"],
  ["#sent-text", "sentence"],
  ["#fmt-text", "format"],
  ["#fmt-sep", "format"],
  ["#fmt-format", "format"],
  ["#char-dict-char", "charDict"],
  ["#char-dict-py", "charDict"],
  ["#char-dict-text", "charDict"],
  ["#phrase-dict-phrase", "phraseDict"],
  ["#phrase-dict-py", "phraseDict"],
  ["#phrase-dict-text", "phraseDict"],
  ["#cn-dict-trad", "cnDict"],
  ["#cn-dict-simp", "cnDict"],
  ["#cn-dict-text", "cnDict"],
  ["#multi-text", "multi"],
  ["#trad-conv-text", "tradConvert"],
  ["#trad-conv-format", "tradConvert"],
  ["#tongyong-text", "tongyong"],
];

ENTER_ACTIONS.forEach(([selector, action]) => {
  const field = $(selector);
  if (!field) return;
  field.addEventListener("keydown", (event) => {
    if (event.key !== "Enter") return;
    event.preventDefault();
    ACTIONS[action]();
  });
});

$$("button[data-preset]").forEach((button) => {
  button.addEventListener("click", () => {
    $("#input-py").value = button.dataset.preset;
    inputCandidates();
  });
});

$$("button[data-preset-sp]").forEach((button) => {
  button.addEventListener("click", () => {
    const scheme = button.dataset.presetSp;
    $("#sp-scheme").value = scheme;
    $("#sp-input").value = scheme === "xiaohe" ? "nihc" : "nihk";
    shuangpin();
  });
});

/* ---------- 导航高亮 ---------- */

const navLinks = $$(".nav a");
const sections = navLinks
  .map((link) => document.querySelector(link.getAttribute("href")))
  .filter(Boolean);

if ("IntersectionObserver" in window && sections.length > 0) {
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        navLinks.forEach((link) => {
          link.classList.toggle("active", link.getAttribute("href") === `#${entry.target.id}`);
        });
      });
    },
    { rootMargin: "-45% 0px -50% 0px", threshold: 0 },
  );
  sections.forEach((section) => observer.observe(section));
}

/* ---------- 初始化 ---------- */

try {
  setText("#version", pinyin_version());
} catch {
  /* 版本读取失败不阻断演示 */
}

renderHero();
convert();
inputCandidates();
shuangpin();
disambiguate();
segment();
normalize();