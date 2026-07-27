#!/bin/bash

# Validates that pokeget can render every Pokémon in routefetch.sh's tier
# arrays, both normal and shiny, so a bad entry can be spotted before
# fastfetch hits it at random.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/routefetch.sh"

FAILURES=()
TOTAL=0

check() {
  local tier="$1" entry="$2" shiny_flag="$3" label="$4"
  local err
  TOTAL=$((TOTAL + 1))
  if err=$(pokeget $entry $shiny_flag --hide-name 2>&1 >/dev/null); then
    echo "OK   [$tier]$label $entry"
  else
    echo "FAIL [$tier]$label $entry -- $err"
    FAILURES+=("[$tier]$label $entry -- $err")
  fi
}

for entry in "${COMMON[@]}"; do
  check "COMMON" "$entry" "" ""
  check "COMMON" "$entry" "--shiny" " (shiny)"
done

for entry in "${UNCOMMON[@]}"; do
  check "UNCOMMON" "$entry" "" ""
  check "UNCOMMON" "$entry" "--shiny" " (shiny)"
done

for entry in "${RARE[@]}"; do
  check "RARE" "$entry" "" ""
  check "RARE" "$entry" "--shiny" " (shiny)"
done

for entry in "${ULTRA_RARE[@]}"; do
  check "ULTRA_RARE" "$entry" "" ""
  check "ULTRA_RARE" "$entry" "--shiny" " (shiny)"
done

echo
if [ ${#FAILURES[@]} -eq 0 ]; then
  echo "All $TOTAL checks passed (normal + shiny for every tier entry)."
  exit 0
else
  echo "${#FAILURES[@]} / $TOTAL checks failed:"
  printf '  - %s\n' "${FAILURES[@]}"
  exit 1
fi
