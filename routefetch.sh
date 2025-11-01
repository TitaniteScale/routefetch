#!/bin/bash

# Pokemon random selector script with multiple tiers
# Used with fastfetch as a custom logo
# Pokémon in different tiers have different chances of appearing
# Each Pokémon has a 1/100 chance of being shiny

# Tier 1: Common Pokémon (60% chance)
COMMON=(
  "bulbasaur"
  "caterpie"
  "shroomish"
  "oddish"
  "lotad"
  "chikorita"
  "paras"
  "shooky"
  "bonsly"
)

# Tier 2: Uncommon Pokémon (30% chance)
UNCOMMON=(
  "roselia"
  "grovyle"
  "breloom"
  "leafeon"
  "sudowoodo"
)

# Tier 3: Rare Pokémon (9% chance)
RARE=(
  "snorlax"
  "venusaur"
  "torterra"
  "meowscarada"
  "decidueye"
)

# Tier 4: Ultra Rare Pokémon (1% chance)
ULTRA_RARE=(
  "celebi"
  "jirachi"
)

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
if [ $SHINY_ROLL -eq 1 ]; then
  # Debug info - uncomment if needed
  # echo "*** SHINY $SELECTED_POKEMON from $TIER tier! ***" >&2
  pokeget "$SELECTED_POKEMON" --shiny --hide-name
else
  # Debug info - uncomment if needed
  # echo "Regular $SELECTED_POKEMON from $TIER tier" >&2
  pokeget "$SELECTED_POKEMON" --hide-name
fi
