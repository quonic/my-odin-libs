package main

/*

Move the window to the primary monitor.

### Usage

```odin
raylib.InitWindow(width, height, "My Window")
SetWindowToPrimaryMonitor()
```

*/

import "vendor:glfw"
import "vendor:raylib"

// Sets a raylib window to the primary monitor
SetWindowToPrimaryMonitor :: proc(setFps: bool = false) {
	monitors := raylib.GetMonitorCount()
	assert(monitors > 0, "Error: No monitors detected")

	monitorIndex := GetPrimaryMonitor()
	assert(monitorIndex >= 0, "Error: No primary monitor detected")

	raylib.SetWindowMonitor(monitorIndex)
	if setFps {
		raylib.SetTargetFPS(raylib.GetMonitorRefreshRate(monitorIndex))
	}
	return
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
