import {
  pinyin_version,
  pinyin_convert,
  pinyin_disambiguate,
  pinyin_input,
  pinyin_shuangpin,
  pinyin_segment,
  pinyin_normalize,
} from "./playground.js";

const $ = (sel) => document.querySelector(sel);
const setText = (id, text) => {
  $(id).textContent = text;
};

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
  try {
    const out = pinyin_input(py);
    const box = $("#input-out");
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
    setText("#input-out", "调用失败：" + e.message);
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

const ACTIONS = {
  convert,
  input: inputCandidates,
  shuangpin,
  disambiguate,
  segment,
  normalize,
};

document.querySelectorAll("button[data-run]").forEach((button) => {
  button.addEventListener("click", () => {
    const action = ACTIONS[button.dataset.run];
    if (action) action();
  });
});

document.querySelectorAll("button[data-preset]").forEach((button) => {
  button.addEventListener("click", () => {
    $("#input-py").value = button.dataset.preset;
    inputCandidates();
  });
});

document.querySelectorAll("button[data-preset-sp]").forEach((button) => {
  button.addEventListener("click", () => {
    const scheme = button.dataset.presetSp;
    $("#sp-scheme").value = scheme;
    $("#sp-input").value = scheme === "xiaohe" ? "nihc" : "nihk";
    shuangpin();
  });
});

try {
  $("#version").textContent = pinyin_version();
} catch {
  // 版本读取失败不阻断演示
}

convert();
inputCandidates();
shuangpin();
disambiguate();
segment();
normalize();