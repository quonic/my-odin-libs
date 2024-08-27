# my-odin-libs

A collection of Odin-lang libraries that I'm making for a personal 2d game engine. I want to keep these as simple as possible.

## [audio.odin](audio.odin)
A simple wrapper around miniaudio with error checking and audio asset management.

## [monitors.odin](monitors.odin)
Functions to move our game window to the primary monitor and get the primary monitor.

## [vec2.odin](vec2.odin)
2D vector that support float 32 and float 64.

Raylib doesn't support 64 floats, so this is my attempt to do this my self. At least start to.

## [execute_command.odin](execute_command.odin)
Lets you run a command and get stdout.

Example Usage:
```odin
root_buf: [1024]byte
data := root_buf[:]
code, ok, out := run_executable("ls -lah", &data)
fmt.println(string(out))
```

## [aseprite.odin](aseprite/aseprite.odin)
Parses an exported Aseprite json sprite sheet.

Example Usage:
```odin
mySprite := ReadAsespriteJsonFile("assets/mySprite.json")
```
