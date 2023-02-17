# AwesomeWM rice

(Yet another) Config for [Awesome](https://github.com/awesomeWM/awesome) window manager.


# Dependencies

The following package names are from the Arch repositories or AUR.

## Required

- `awesome-git` - window manager (latest git version, **not** stable v4.3)
- `pulsemixer` - controlling the system volume
- `playerctl` - controlling media player
- `xdg-open` (from `xdg-utils`) - opening files or URLs in the preferred applications
- `xclip` - copying things to the clipboard

## Optional

- `feh` - setting wallpaper
- `maim`, `xdotool` - taking a screenshot
- `slop` - magnifier (required [`boxzoom`](https://github.com/naelstrof/slop/tree/master/shaderexamples) shader), also screen region selection
- [`sct`](https://flak.tedunangst.com/post/sct-set-color-temperature) - setting the color temperature of the screen

## Recommended

- `rofi` - application launcher ([here](https://gist.github.com/kosorin/2e613eb2e09f4f619b3f9f6c3c688c6b) is the config to match the style of this rice)
- `picom` - compositor for a better look

## Fonts

- Nerd Font - use any Nerd Font that you like


# Installation

Backup your current config and download the files from GitHub to the empty `~/.config/awesome` directory:

    $ git clone https://github.com/kosorin/awesome-rice.git ~/.config/awesome


# Setup

Some [dependencies](#dependencies) are not listed and can be changed in `config.lua` file. So go ahead and set up your preferred applications.

In `theme/theme.lua` you can change font or icon theme.


# Gallery

## Screenshots

![img](assets/screenshot_01.png)

![img](assets/screenshot_02.png)

![img](assets/screenshot_03.png)

![img](assets/screenshot_04.png)


# Credits

- Simon Stålenhag (wallpapers)
