# Routefetch

### A Pokeget Script Designed with Fastfetch in Mind

Routefetch brings life to your terminal rice by displaying random Pokémon with varying rarity levels. It seamlessly integrates with Fastfetch to show different tiers of Pokémon in your system information display, with each Pokémon having a chance to appear as its shiny variant. This adds an element of surprise and discovery to your daily terminal usage.

## Pre-Requisites
- Pokeget (or pokeget-rs)

Routefetch uses Pokeget to render Pokémon images in the terminal. More information regarding Pokeget can be found at the [repo](https://github.com/talwat/pokeget-rs)

## Installation
If you want to use this for fastfetch, navigate to your fastfetch config.

```bash
cd ~/.config/fastfetch
```

Once in your fastfetch folder, clone this repo into a scripts folder.

```bash
git clone git@github.com:TitaniteScale/routefetch.git scripts
```

Then, in your fastfetch config, change the type and source of the logo to the following:

```json
  "logo": {
    "type": "command-raw",
    "source": "~/.config/fastfetch/scripts/routefetch.sh",
```

## Example
![Example of Routefetch in action](images/example1.png)

## How It Works

Routefetch randomly selects Pokémon from four different rarity tiers:
- Common (60% chance) - Pokémon like Bulbasaur, Caterpie, and Oddish
- Uncommon (30% chance) - Pokémon like Roselia, Grovyle, and Leafeon
- Rare (9% chance) - Pokémon like Snorlax, Venusaur, and Torterra
- Ultra Rare (1% chance) - Legendary Pokémon like Celebi and Jirachi

Additionally, every Pokémon has a 1% chance of appearing in its shiny form.
Changing the rates is very easy as the shell script is very simple.

## DMG Mode

Sprites can be re-rendered with a four-shade Game Boy palette. Set `DMG_MODE`
near the top of `routefetch.sh`:

```bash
DMG_MODE="${ROUTEFETCH_DMG:-green}"
```

| Value | Result |
| --- | --- |
| `off` | Full colour sprites (default) |
| `green` | Original Game Boy (DMG) LCD green |
| `gray` | Four-level grayscale |

You can also flip it per-run without editing anything:

```bash
ROUTEFETCH_DMG=green ./routefetch.sh
```

The palette logic lives in `dmg.sh`, which is a plain stdin/stdout filter, so
it works with any truecolor sprite and can be used on its own:

```bash
pokeget pikachu --hide-name | ./dmg.sh
pokeget pikachu --hide-name | ./dmg.sh --palette gray
pokeget pikachu --hide-name | ./dmg.sh --colors '#0F380F,#306230,#8BAC0F,#9BBC0F'
```

Each colour in the sprite is ranked by luminance and reduced to four levels of
grey, and those levels then choose the shade to draw with. The luminance range
is stretched per sprite, so dark Pokémon still use the whole palette instead of
flattening into one shade. Transparent pixels stay transparent.

### Upcoming

- **`--fill`** — real DMG hardware has no transparency, so the area around the
  sprite would be lightest green rather than showing through to the terminal,
  making it look like an actual Game Boy screen. This needs pokeget's rows
  padded to a uniform width first, since it trims them and they currently vary
  by a few cells.
- **More palettes** — Game Boy Pocket and Game Boy Light shades, on top of the
  existing `--colors` escape hatch.


Enjoy!
