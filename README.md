# my-odin-libs

A collection of Odin-lang libraries that I'm making for a personal 2d game engine. I want to keep these as simple as possible.

## [audio.odin](audio.odin)
A simple wrapper around miniaudio with error checking and audio asset management.

## [monitors.odin](monitors.odin)
Function to center a raylib window to the center of the screen with system of 1 or 3 monitors. 3 monitors assume that the center monitor is the main monitor. Which is my preference.

The reason for this was that on my system, the left monitor was number 0, the center was 2 and the right was 1. So, why not just get each monitors positions as vectors and figure out which is most center.

With Raylib and Wayland they kept throwing the window on my left monitor even though I set in GNOME my center monitor as the default.

## [vec2.odin](vec2.odin)
2D vector that support float 32 and float 64.

Raylib doesn't support 64 floats, so this is my attempt to do this my self. At least start to.
