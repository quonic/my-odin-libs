package main

/*

Center the window on the center monitor.

Supports any amount of monitors.

### Usage

```odin
raylib.InitWindow(width, height, "My Window")
SetWindowToPrimaryMonitor(true,false)
```

*/

import "vendor:glfw"
import "vendor:raylib"

// Sets a raylib window to the primary monitor
SetWindowToPrimaryMonitor :: proc(setFps: bool = false, fullscreen: bool = false) {
	assert(raylib.GetMonitorCount() > 0, "Error: No monitors detected")

	monitorIndex := GetPrimaryMonitor()
	assert(monitorIndex >= 0, "Error: No primary monitor detected")

	if setFps {raylib.SetTargetFPS(raylib.GetMonitorRefreshRate(monitorIndex))}
	if fullscreen {
		p := GetPrimaryMonitor()
		monitor_position := raylib.GetMonitorPosition(p)
		raylib.SetWindowPosition(i32(monitor_position.x), i32(monitor_position.y))
		raylib.SetWindowState({.WINDOW_MAXIMIZED, .WINDOW_RESIZABLE})
		raylib.SetWindowState({.WINDOW_MAXIMIZED})
		raylib.ToggleFullscreen()
	}
	raylib.SetWindowMonitor(monitorIndex)
}
// Returns the index of the primary monitor
GetPrimaryMonitor :: proc() -> i32 {
	primary := glfw.GetPrimaryMonitor()
	name := glfw.GetMonitorName(primary)

	for i in 0 ..< raylib.GetMonitorCount() {
		if string(raylib.GetMonitorName(i)) == name {
			return i
		}
	}
	return -1
}

// SetWindowToCenterMonitor is a deprecated function
SetWindowToCenterMonitor :: proc() {
	SetWindowToPrimaryMonitor()
}

VideoMode :: struct {
	width:       int,
	height:      int,
	refreshRate: int,
}

Monitor :: struct {
	index:    int,
	modes:    [dynamic]VideoMode,
	name:     string,
	position: [2]i32,
	primary:  bool,
}

GetMonitorProperties :: proc() -> []Monitor {
	monitorHandle := glfw.GetMonitors()
	defer delete(monitorHandle)

	primaryMonitorHandle := glfw.GetPrimaryMonitor()
	primaryMonitorName := glfw.GetMonitorName(primaryMonitorHandle)


	monitors: [dynamic]Monitor
	defer delete(monitors)

	for i in 0 ..< len(monitorHandle) {
		monitor := Monitor{}
		monitor.modes = [dynamic]VideoMode{}
		mh := glfw.GetVideoModes(monitorHandle[i])
		defer delete(mh)

		monitor.name = glfw.GetMonitorName(monitorHandle[i])
		monitor.primary = monitor.name == primaryMonitorName
		monitor.index = i

		x, y := glfw.GetMonitorPos(monitorHandle[i])
		monitor.position = [2]i32{x, y}

		for j in 0 ..< len(mh) {
			append(
				&monitor.modes,
				VideoMode {
					width = int(mh[j].width),
					height = int(mh[j].height),
					refreshRate = int(mh[j].refresh_rate),
				},
			)
		}
		append(&monitors, monitor)
	}


	return monitors[:]
}
