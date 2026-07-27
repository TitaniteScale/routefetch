#!/bin/bash

# Pokemon random selector script with multiple tiers
# Used with fastfetch as a custom logo
# Pokémon in different tiers have different chances of appearing
# Each Pokémon has a 1/100 chance of being shiny

# --- DMG mode ---------------------------------------------------------
# Render sprites with a four-shade Game Boy palette instead of full colour.
#   "off"   - normal, full colour sprites
#   "green" - original Game Boy (DMG) LCD green
#   "gray"  - four-level grayscale
# Override at runtime with e.g. ROUTEFETCH_DMG=green
DMG_MODE="${ROUTEFETCH_DMG:-off}"

# Tier 1: Common Pokémon (60% chance)
COMMON=(
  "porygon"
  "voltorb"
  "klink"
  "elekid"
  "shinx"
  "scraggy"
  "magnemite"
  "pichu"
)

# Tier 2: Uncommon Pokémon (30% chance)
UNCOMMON=(
  "toxtricity"
  "electabuzz"
  "raichu"
  "eelektross"
  "magneton"
  "jolteon"
)

# Tier 3: Rare Pokémon (9% chance)
RARE=(
  "rotom"
  "rotom --form wash"
  "rotom --form frost"
  "luxray"
  "electivire"
  "porygon-z"
)

# Tier 4: Ultra Rare Pokémon (1% chance)
ULTRA_RARE=(
  "zygarde --form complete"
  "genesect"
  "zeraora"
  "zapdos"
  "articuno --galar"
)

# Only run the selection/render logic when executed directly, so this
# file can also be sourced (e.g. by validate.sh) to reuse the tier arrays.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Normalise the mode up front. An unusable value falls back to full colour
# rather than letting the pipeline fail and leave fastfetch with no logo.
case "$DMG_MODE" in
  ""|off|no|false) DMG_MODE="off" ;;
  on|yes|true)     DMG_MODE="green" ;;
  green|gray|grey) ;;
  *)
    echo "routefetch: unknown DMG mode '$DMG_MODE', using full colour" >&2
    DMG_MODE="off" ;;
esac

# Renders a sprite, piping it through the palette filter when DMG mode is on.
# Falls back to plain pokeget if dmg.sh is missing, so a broken install still
# leaves fastfetch with a logo.
render() {
  if [ "$DMG_MODE" = "off" ]; then
    pokeget "$@"
  elif [ -r "$SCRIPT_DIR/dmg.sh" ]; then
    pokeget "$@" | bash "$SCRIPT_DIR/dmg.sh" --palette "$DMG_MODE"
  else
    echo "routefetch: DMG mode is on but $SCRIPT_DIR/dmg.sh is missing" >&2
    pokeget "$@"
  fi
}

# Generate a random number between 1 and 100 for tier selection
TIER_ROLL=$((RANDOM % 100 + 1))

# Determine which tier based on the roll
if [ $TIER_ROLL -le 60 ]; then
  # Common tier (60% chance)
  TIER="COMMON"
  SELECTED_ARRAY=("${COMMON[@]}")
elif [ $TIER_ROLL -le 90 ]; then
  # Uncommon tier (30% chance)
  TIER="UNCOMMON"
  SELECTED_ARRAY=("${UNCOMMON[@]}")
elif [ $TIER_ROLL -le 99 ]; then
  # Rare tier (9% chance)
  TIER="RARE"
  SELECTED_ARRAY=("${RARE[@]}")
else
  # Ultra rare tier (1% chance)
  TIER="ULTRA_RARE"
  SELECTED_ARRAY=("${ULTRA_RARE[@]}")
fi

# Get a random Pokémon from the selected tier
ARRAY_SIZE=${#SELECTED_ARRAY[@]}
POKEMON_INDEX=$((RANDOM % ARRAY_SIZE))
SELECTED_POKEMON="${SELECTED_ARRAY[$POKEMON_INDEX]}"

# Generate a random number between 1 and 100 for shiny check
SHINY_ROLL=$((RANDOM % 100 + 1))

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
