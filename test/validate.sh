#!/bin/bash

# Validates that pokeget can render every Pokémon in data/rarity.tsv, both
# normal and shiny, so a bad entry can be spotted before fastfetch hits it
# at random.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../routefetch.sh"

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

for i in "${!RARITY_ENTRY[@]}"; do
  check "${RARITY_TIER[$i]}" "${RARITY_ENTRY[$i]}" "" ""
  check "${RARITY_TIER[$i]}" "${RARITY_ENTRY[$i]}" "--shiny" " (shiny)"
done

echo
if [ ${#FAILURES[@]} -eq 0 ]; then
  echo "All $TOTAL checks passed (normal + shiny for every rarity entry)."
  exit 0
else
  echo "${#FAILURES[@]} / $TOTAL checks failed:"
  printf '  - %s\n' "${FAILURES[@]}"
  exit 1
fi
