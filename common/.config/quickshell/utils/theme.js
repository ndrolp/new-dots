.pragma library

var THEMES = {
  catppuccin: {
    bg0: "#1e2030",
    bg1: "#24273a",
    bg2: "#363a4f",
    bg3: "#494d64",
    bg4: "#6e738d",
    fg: "#cad3f5",
    fg1: "#b8c0e0",
    fg2: "#6e738d",
    fgdark: "#1e2030",
    accent0: "#c6a0f6",
    accent1: "#eed49f",
    accent2: "#a6da95",
    accent3: "#91d7e3",
    accent4: "#f0c6c6",
    accent5: "#f5a97f",
    accent6: "#ed8796",
    grey0: "#6e738d",
    grey1: "#8087a2",
    grey2: "#939ab7",
    border0: "#6e738d",
  },
}

function theme(name) {
  return THEMES[name] || THEMES.catppuccin
}
