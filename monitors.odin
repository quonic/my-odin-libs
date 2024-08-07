package main

/*

Center the window on the center monitor.

Supports 1 or 3 monitors.

If there is only one monitor, the window will be centered on that monitor.
If there are 3 monitors, the window will be centered on the monitor in the middle.

### Usage

```odin
raylib.InitWindow(width, height, "My Window")
SetWindowToCenterMonitor()
```

*/

import "vendor:raylib"

SetWindowToCenterMonitor :: proc() {
	monitors := raylib.GetMonitorCount()

	assert(monitors > 0, "Error: No monitors detected")

	if (monitors == 1) {
		raylib.SetWindowMonitor(0)
		raylib.SetTargetFPS(raylib.GetMonitorRefreshRate(0))
		return
	}
	if (monitors == 3) {
		monitorArrangment: [dynamic]raylib.Vector2
		raylib.TraceLog(.DEBUG, "Number of monitors detected: %i", monitors)
		for i in 0 ..= monitors - 1 {
			raylib.TraceLog(.DEBUG, "Monitor %i: %s", i, raylib.GetMonitorName(i))
			raylib.TraceLog(.DEBUG, "  - Width: %i px", raylib.GetMonitorWidth(i))
			raylib.TraceLog(.DEBUG, "  - Height: %i px", raylib.GetMonitorHeight(i))
			raylib.TraceLog(.DEBUG, "  - Refresh rate: %i Hz", raylib.GetMonitorRefreshRate(i))
			raylib.TraceLog(
				.DEBUG,
				"  - Position: %i,%i",
				raylib.GetMonitorPosition(i)[0],
				raylib.GetMonitorPosition(i)[1],
			)
			raylib.SetWindowMonitor(i)
			append(&monitorArrangment, raylib.GetMonitorPosition(i))
		}
		// Sort monitors positions array
		for i in 0 ..= monitors - 1 {
			for j in 0 ..= monitors - 1 {
				if monitorArrangment[i].x < monitorArrangment[j].x {
					monitorArrangment[i], monitorArrangment[j] =
						monitorArrangment[j], monitorArrangment[i]
				}
			}
		}
		when ODIN_OS == .Windows {
			for i: int = 0; i < len(monitorArrangment); i = i + 1 {
				if monitorArrangment[i].x == 0 && monitorArrangment[i].y == 0 {
					raylib.SetWindowMonitor(i32(i))
					raylib.SetTargetFPS(raylib.GetMonitorRefreshRate(i32(i)))
					return
				}
			}
		}
		when ODIN_OS == .Linux {
			// From the monitors detected, select one in the middle based on the array of Vector2 positions in the variable monitorArrangment
			selectedMonitor: i32 = 0 // Set the first monitor as the default one
			for i in 0 ..= monitors - 1 {
				// Check if monitor position is in the middle of the monitors arrangement
				if monitorArrangment[i].x >= monitorArrangment[0].x &&
				   monitorArrangment[i].y >= monitorArrangment[0].y &&
				   monitorArrangment[i].x <= monitorArrangment[monitors - 1].x &&
				   monitorArrangment[i].y <= monitorArrangment[monitors - 1].y {
					selectedMonitor = i
					break
				}
			}
			raylib.SetWindowMonitor(selectedMonitor)
			raylib.SetTargetFPS(raylib.GetMonitorRefreshRate(selectedMonitor))
		}
		when ODIN_OS == .Darwin {
			// From the monitors detected, select the one with the highest resolution
			selectedMonitor: i32 = 0 // Set the first monitor as the default one
			maxWidth: i32 = 0
			for i in 0 ..= monitors - 1 {
				if raylib.GetMonitorWidth(i) > maxWidth {
					maxWidth = raylib.GetMonitorWidth(i)
					selectedMonitor = i
				}
			}
			raylib.SetWindowMonitor(selectedMonitor)
			raylib.SetTargetFPS(raylib.GetMonitorRefreshRate(selectedMonitor))
		}
	}
}
