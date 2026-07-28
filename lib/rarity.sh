#!/bin/bash

# lib/rarity.sh - Load data/rarity.tsv into parallel arrays and provide
# pick_pokemon(), a weighted random selector.
#
# Meant to be sourced, not executed. Expects SCRIPT_DIR (repo root) and the
# TIER_WEIGHT_* variables (set by lib/config.sh) to already be available.
#
# rarity.tsv format: tier:weight:pokeget-args
#   - tier is one of common, uncommon, rare, ultra_rare
#   - weight is a positive integer, relative *within its tier only*
#   - pokeget-args may contain spaces to pass extra flags (e.g.
#     "rotom --form wash"); see the word-splitting note near the
#     render() call in routefetch.sh - the same caveat applies here.
#
# Malformed lines are skipped with a warning rather than aborting, and a
# missing file falls back to a small built-in table, so a broken/partial
# install still renders a logo.

RARITY_TIER=()
RARITY_WEIGHT=()
RARITY_ENTRY=()

_rarity_load_builtin_fallback() {
  echo "routefetch: rarity data file not found, using built-in fallback table" >&2
  RARITY_TIER=(common common uncommon rare ultra_rare)
  RARITY_WEIGHT=(1 1 1 1 1)
  RARITY_ENTRY=(pichu magnemite raichu luxray zapdos)
}

_rarity_load_file() {
  local file="$1" lineno=0 line tier weight args
  while IFS= read -r line || [ -n "$line" ]; do
    lineno=$((lineno + 1))
    [ -z "$line" ] && continue
    case "$line" in
      \#*) continue ;;
    esac

    IFS=':' read -r tier weight args <<<"$line"

    case "$tier" in
      common|uncommon|rare|ultra_rare) ;;
      *)
        echo "routefetch: $file:$lineno: unknown tier '$tier', skipping" >&2
        continue ;;
    esac

    if ! [[ "$weight" =~ ^[0-9]+$ ]] || [ "$weight" -le 0 ]; then
      echo "routefetch: $file:$lineno: invalid weight '$weight', skipping" >&2
      continue
    fi

    if [ -z "$args" ]; then
      echo "routefetch: $file:$lineno: missing pokeget args, skipping" >&2
      continue
    fi

    RARITY_TIER+=("$tier")
    RARITY_WEIGHT+=("$weight")
    RARITY_ENTRY+=("$args")
  done <"$file"
}

RARITY_FILE="${ROUTEFETCH_RARITY_FILE:-$SCRIPT_DIR/data/rarity.tsv}"
if [ -r "$RARITY_FILE" ]; then
  _rarity_load_file "$RARITY_FILE"
  if [ "${#RARITY_ENTRY[@]}" -eq 0 ]; then
    echo "routefetch: $RARITY_FILE had no usable entries, using built-in fallback table" >&2
    _rarity_load_builtin_fallback
  fi
else
  _rarity_load_builtin_fallback
fi

# Rolls a weighted random pick. Takes the roll target (0-based, already
# reduced mod the total weight) and, for each index, its weight; echoes the
# chosen index.
_rarity_weighted_index() {
  local roll="$1"; shift
  local -a weights=("$@")
  local i cumulative=0
  for i in "${!weights[@]}"; do
    cumulative=$((cumulative + weights[i]))
    if [ "$roll" -lt "$cumulative" ]; then
      echo "$i"
      return
    fi
  done
  echo "$(( ${#weights[@]} - 1 ))"
}

# Picks a Pokémon using the tier weights from config and each entry's
# in-tier weight from the rarity data. Sets SELECTED_POKEMON and TIER.
pick_pokemon() {
  local tier_total tier_roll
  tier_total=$((TIER_WEIGHT_COMMON + TIER_WEIGHT_UNCOMMON + TIER_WEIGHT_RARE + TIER_WEIGHT_ULTRA_RARE))
  tier_roll=$((RANDOM % tier_total))

  local tier_names=(common uncommon rare ultra_rare)
  local tier_weights=("$TIER_WEIGHT_COMMON" "$TIER_WEIGHT_UNCOMMON" "$TIER_WEIGHT_RARE" "$TIER_WEIGHT_ULTRA_RARE")
  local tier_idx
  tier_idx=$(_rarity_weighted_index "$tier_roll" "${tier_weights[@]}")
  TIER="${tier_names[$tier_idx]}"

  local -a candidate_entries=() candidate_weights=()
  local i
  for i in "${!RARITY_TIER[@]}"; do
    if [ "${RARITY_TIER[$i]}" = "$TIER" ]; then
      candidate_entries+=("${RARITY_ENTRY[$i]}")
      candidate_weights+=("${RARITY_WEIGHT[$i]}")
    fi
  done

  local entry_total entry_roll entry_idx
  entry_total=0
  for i in "${!candidate_weights[@]}"; do
    entry_total=$((entry_total + candidate_weights[i]))
  done
  entry_roll=$((RANDOM % entry_total))
  entry_idx=$(_rarity_weighted_index "$entry_roll" "${candidate_weights[@]}")

  SELECTED_POKEMON="${candidate_entries[$entry_idx]}"
}
