#!/bin/bash

# Pokemon random selector script with multiple tiers
# Used with fastfetch as a custom logo
# Pokémon in different tiers have different chances of appearing
# (weights configurable via config/routefetch.conf and data/rarity.tsv)
# Every Pokémon has a 1-in-SHINY_ODDS chance of being shiny (config/routefetch.conf)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Loads DMG_MODE and TIER_WEIGHT_* from config/routefetch.conf (or the
# shipped .default), and loads the rarity table + pick_pokemon() from
# data/rarity.tsv. See lib/config.sh and lib/rarity.sh for precedence and
# fallback details.
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/rarity.sh"

# Only run the selection/render logic when executed directly, so this
# file can also be sourced (e.g. by test/validate.sh) to reuse the rarity
# arrays without triggering random selection.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

# Renders a sprite, piping it through the palette filter when DMG mode is on.
# Falls back to plain pokeget if lib/dmg.sh is missing, so a broken install
# still leaves fastfetch with a logo.
render() {
  if [ "$DMG_MODE" = "off" ]; then
    pokeget "$@"
  elif [ -r "$SCRIPT_DIR/lib/dmg.sh" ]; then
    pokeget "$@" | bash "$SCRIPT_DIR/lib/dmg.sh" --palette "$DMG_MODE"
  else
    echo "routefetch: DMG mode is on but $SCRIPT_DIR/lib/dmg.sh is missing" >&2
    pokeget "$@"
  fi
}

pick_pokemon

# Generate a random number between 1 and SHINY_ODDS for shiny check
SHINY_ROLL=$((RANDOM % SHINY_ODDS + 1))

# If the random number is 1 (1% chance), show shiny version
# Note: $SELECTED_POKEMON is intentionally unquoted below - entries like
# "rotom --form wash" need to expand into separate pokeget arguments.
if [ $SHINY_ROLL -eq 1 ]; then
  # Debug info - uncomment if needed
  # echo "*** SHINY $SELECTED_POKEMON from $TIER tier! ***" >&2
  render $SELECTED_POKEMON --shiny --hide-name
else
  # Debug info - uncomment if needed
  # echo "Regular $SELECTED_POKEMON from $TIER tier" >&2
  render $SELECTED_POKEMON --hide-name
fi

fi
