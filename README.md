## Routefetch
### A Pokeget Script Designed with Fastfetch in Mind

## Pre-Requisites
- Pokeget

## Installation
If you want to use this for fastfetch, navigate to your fastfetch config.

```bash
cd ~/.config/fastfetch
```

Once in your fastfetch folder, clone this repo into a scripts folder.

```bash
git clone git@github.com:TitaniteScale/routefetch.git scripts"
```

Then, in your fastfetch config, change the type and source of the logo to the following:

```json
  "logo": {
    "type": "command-raw",
    "source": "~/.config/fastfetch/scripts/routefetch.sh",
```
