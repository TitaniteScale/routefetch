#!/bin/bash

# lib/config.sh - Load routefetch's settings (DMG palette mode, tier
# weights, shiny odds) from a config file, with ROUTEFETCH_DMG kept as a
# top-priority env var override for backward compatibility.
#
# Meant to be sourced, not executed. Expects SCRIPT_DIR (repo root) to
# already be set by the caller.
#
# Precedence, highest first:
#   1. ROUTEFETCH_DMG env var          (legacy override, DMG_MODE only)
#   2. ROUTEFETCH_CONFIG=/path env var (use this file instead of below)
#   3. config/routefetch.conf          (user's own copy, untracked)
#   4. config/routefetch.conf.default  (shipped defaults, tracked)
#
# Every step is guarded so a missing or partial install still renders a
# logo instead of erroring out.

CONFIG_FILE=""
if [ -n "${ROUTEFETCH_CONFIG:-}" ] && [ -r "$ROUTEFETCH_CONFIG" ]; then
  CONFIG_FILE="$ROUTEFETCH_CONFIG"
elif [ -r "$SCRIPT_DIR/config/routefetch.conf" ]; then
  CONFIG_FILE="$SCRIPT_DIR/config/routefetch.conf"
elif [ -r "$SCRIPT_DIR/config/routefetch.conf.default" ]; then
  CONFIG_FILE="$SCRIPT_DIR/config/routefetch.conf.default"
fi

if [ -n "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
fi

# ROUTEFETCH_DMG wins outright over whatever the config file set, matching
# the original ROUTEFETCH_DMG behaviour from before config files existed.
DMG_MODE="${ROUTEFETCH_DMG:-${DMG_MODE:-off}}"

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

# Tier weights and shiny odds, falling back to their historical values
# (60/30/9/1 and 1-in-100) if unset or non-numeric, e.g. the config file is
# missing these keys entirely.
_default_positive_int() {
  local value="$1" fallback="$2"
  [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -gt 0 ] && { echo "$value"; return; }
  echo "$fallback"
}
TIER_WEIGHT_COMMON="$(_default_positive_int "${TIER_WEIGHT_COMMON:-}" 60)"
TIER_WEIGHT_UNCOMMON="$(_default_positive_int "${TIER_WEIGHT_UNCOMMON:-}" 30)"
TIER_WEIGHT_RARE="$(_default_positive_int "${TIER_WEIGHT_RARE:-}" 9)"
TIER_WEIGHT_ULTRA_RARE="$(_default_positive_int "${TIER_WEIGHT_ULTRA_RARE:-}" 1)"
SHINY_ODDS="$(_default_positive_int "${SHINY_ODDS:-}" 100)"
unset -f _default_positive_int
