#!/bin/bash

# dmg.sh - Re-render a truecolor sprite using a four-shade Game Boy palette.
#
# Reads pokeget's output on stdin and writes it back out with every colour
# replaced by one of four shades. Colours are ranked by luminance, so the
# sprite is first reduced to four levels of grey and those levels then pick
# the shade to draw with. Transparent pixels stay transparent.
#
# Usage:
#   pokeget pichu --hide-name | ./dmg.sh
#   pokeget pichu --hide-name | ./dmg.sh --palette gray
#   pokeget pichu --hide-name | ./dmg.sh --colors '#0F380F,#306230,#8BAC0F,#9BBC0F'
#
# Palettes are always listed darkest -> lightest.

set -u

# Original Game Boy (DMG-01) LCD green.
PALETTE_GREEN='#0F380F,#306230,#8BAC0F,#9BBC0F'
# Plain four-level grayscale, i.e. the intermediate step on its own.
PALETTE_GRAY='#000000,#555555,#AAAAAA,#FFFFFF'

usage() {
  cat <<'EOF'
Usage: dmg.sh [--palette green|gray] [--colors C1,C2,C3,C4]

Reads a truecolor sprite (e.g. from pokeget) on stdin and re-renders it
with a four-shade palette on stdout.

  -p, --palette NAME   Built-in palette. "green" (default) is the DMG LCD
                       green, "gray" is four-level grayscale.
  -c, --colors LIST    Four comma separated #RRGGBB colours, darkest first.
                       Overrides --palette.
  -h, --help           Show this help.
EOF
}

mode="green"
colors=""

while [ $# -gt 0 ]; do
  case "$1" in
    -p|--palette)
      [ $# -ge 2 ] || { echo "dmg.sh: --palette needs a value" >&2; exit 2; }
      mode="$2"; shift 2 ;;
    -c|--colors)
      [ $# -ge 2 ] || { echo "dmg.sh: --colors needs a value" >&2; exit 2; }
      colors="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "dmg.sh: unknown option: $1" >&2
      usage >&2
      exit 2 ;;
  esac
done

if [ -z "$colors" ]; then
  case "$mode" in
    green|dmg)        colors="$PALETTE_GREEN" ;;
    gray|grey|mono)   colors="$PALETTE_GRAY" ;;
    *)
      echo "dmg.sh: unknown palette: $mode (expected 'green' or 'gray')" >&2
      exit 2 ;;
  esac
fi

# Turn "#RRGGBB,..." into the "R;G;B R;G;B ..." form the awk pass wants.
IFS=',' read -r -a hex_colors <<<"$colors"
if [ "${#hex_colors[@]}" -ne 4 ]; then
  echo "dmg.sh: expected 4 colours, got ${#hex_colors[@]}" >&2
  exit 2
fi

shades=""
for hex in "${hex_colors[@]}"; do
  hex="${hex#\#}"
  if [[ ! "$hex" =~ ^[0-9a-fA-F]{6}$ ]]; then
    echo "dmg.sh: invalid colour '$hex' (expected #RRGGBB)" >&2
    exit 2
  fi
  shades+="${shades:+ }$((16#${hex:0:2}));$((16#${hex:2:2}));$((16#${hex:4:2}))"
done

# Two passes over the sprite: the first collects every distinct colour and its
# luminance, the second rewrites the stream. Buffering is fine, sprites are a
# few dozen lines at most.
exec awk -v PALETTE="$shades" '
BEGIN {
  ESC = sprintf("%c", 27)
  # Matches a truecolor SGR sequence: foreground (38) or background (48).
  RE = ESC "\\[[34]8;2;[0-9]+;[0-9]+;[0-9]+m"
  levels = split(PALETTE, SHADE, " ")
  first = 1
}

{
  raw[NR] = $0
  rest = $0
  while (match(rest, RE)) {
    seq = substr(rest, RSTART, RLENGTH)
    rest = substr(rest, RSTART + RLENGTH)
    if (seq in luma) continue

    # Strip the leading ESC "[" and the trailing "m" to get "38;2;R;G;B".
    split(substr(seq, 3, length(seq) - 3), part, ";")
    # Rec. 601 luma, the usual weighting for this kind of colour -> grey pass.
    value = 0.299 * part[3] + 0.587 * part[4] + 0.114 * part[5]

    luma[seq] = value
    if (first) { lo = value; hi = value; first = 0 }
    else if (value < lo) lo = value
    else if (value > hi) hi = value
  }
}

END {
  # Stretch the luminance range of this sprite across the four shades rather
  # than using fixed cut-offs, so dark or washed out sprites still use the
  # whole palette.
  span = hi - lo

  for (seq in luma) {
    if (span > 0) {
      band = int((luma[seq] - lo) * levels / span)
      if (band >= levels) band = levels - 1
    } else {
      band = levels - 1
    }
    # Keep the layer (38 = foreground, 48 = background) the pixel came from.
    shade[seq] = ESC "[" substr(seq, 3, 2) ";2;" SHADE[band + 1] "m"
  }

  for (i = 1; i <= NR; i++) {
    rest = raw[i]
    out = ""
    while (match(rest, RE)) {
      out = out substr(rest, 1, RSTART - 1) shade[substr(rest, RSTART, RLENGTH)]
      rest = substr(rest, RSTART + RLENGTH)
    }
    print out rest
  }
}
'
