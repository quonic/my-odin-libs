package main

import "base:runtime"
import "core:path/filepath"
import "core:strings"
import lua "vendor:lua/5.4"
import "vendor:raylib"

// Raylib functions for lua plugins

plugin_texture_map: map[u32]raylib.Texture

rlLoadTexture :: proc "c" (state: ^lua.State) -> i32 {
	context = runtime.default_context()
	texture: raylib.Texture2D

	// Name: LoadTexture
	// Description: Loads a texture from a file. `file_name` is relative to the plugin's directory.
	// Example: spinster.log(raylib.LoadTexture("my_texture.png"))
	// Output: [PLUGIN] [%DateTime%] [INFO] 1
	// Expects: file_name (string)
	// Returns: texture_id (int) or -1 on failure

	lua.L_checktype(state, 1, i32(lua.TSTRING))

	// Get "file_name" from the stack
	file_name := GetStringParam(state, 1)

	// Get "plugin_name" from global state
	lua.getglobal(state, "plugin_name")
	plugin_name := lua.tostring(state, -1)
	lua.pop(state, 1) // remove plugin_name from stack

	// Prevent directory traversal attacks
	if strings.contains(string(file_name), "..") {
		lua.pushinteger(state, -1)
		return 1
	}

	// Check if file_name is a simple file name or a path
	if strings.contains(string(file_name), "/") || strings.contains(string(file_name), "\\") {
		when ODIN_OS == .Windows {
			path: string
			if strings.contains(string(file_name), "/") {
				p, _ := strings.replace(string(file_name), "/", "\\", -1)
				path = strings.split(p, "\\")
			} else {
				path = strings.split(string(file_name), "\\")
			}
			pathd: [dynamic]string

			defer delete(path)
			defer delete(pathd)

			append(&pathd, ".")
			append(&pathd, "plugin")
			append(&pathd, string(plugin_name))

			for part in path {
				append(&pathd, part)
			}

			texture = raylib.LoadTexture(strings.clone_to_cstring(strings.join(pathd[:], "\\")))
		}
		when ODIN_OS == .Linux {
			path: []string
			if strings.contains(string(file_name), "\\") {
				p, _ := strings.replace(string(file_name), "\\", "/", -1)
				path = strings.split(p, "/")
			} else {
				path = strings.split(string(file_name), "/")
			}
			pathd: [dynamic]string

			defer delete(path)
			defer delete(pathd)

			append(&pathd, ".")
			append(&pathd, "plugin")
			append(&pathd, string(plugin_name))

			for part in path {
				append(&pathd, part)
			}

			texture = raylib.LoadTexture(strings.clone_to_cstring(strings.join(pathd[:], "/")))
		}
	} else {
		// Just a file name, load from plugin directory
		when ODIN_OS == .Windows {
			plugin_path := strings.join(
				{".", "plugin", string(plugin_name), string(file_name)},
				"\\",
			)
			texture = raylib.LoadTexture(strings.clone_to_cstring(plugin_path))
		}
		when ODIN_OS == .Linux {
			plugin_path := strings.join(
				{".", "plugin", string(plugin_name), string(file_name)},
				"/",
			)
			texture = raylib.LoadTexture(strings.clone_to_cstring(plugin_path))
		}
	}

	if texture.id == 0 {
		lua.pushinteger(state, -1)
	} else {
		plugin_texture_map[texture.id] = texture
		lua.pushinteger(state, lua.Integer(texture.id))
	}
	// Tell VM that we are returning 1 value
	return 1
}

rlUnloadTexture :: proc "c" (state: ^lua.State) -> i32 {
	context = runtime.default_context()
	// Name: UnloadTexture
	// Description: Unloads a texture from memory
	// Example: raylib.UnloadTexture(texture_id)
	// Output: (none)
	// Expects: texture_id (int)
	// Returns: nothing
	lua.L_checktype(state, 1, i32(lua.TNUMBER))

	texture_id := GetIntegerParam(state, 1)
	raylib.UnloadTexture(plugin_texture_map[u32(texture_id)])
	delete_key(&plugin_texture_map, u32(texture_id))
	// Tell VM that we are not returning any values
	return 0
}

rlDrawTexture :: proc "c" (state: ^lua.State) -> i32 {
	// Name: DrawTexture
	// Description: Draws a texture at the specified position with the specified color
	// Example: raylib.DrawTexture(texture_id, x, y, tointeger("0x11BB2CFF"))
	// Output: (none)
	// Expects: texture_id (int), x (int), y (int), hex_color (int RGBA)
	// Returns: nothing
	context = runtime.default_context()
	lua.L_checktype(state, 1, i32(lua.TNUMBER))
	lua.L_checktype(state, 2, i32(lua.TNUMBER))
	lua.L_checktype(state, 3, i32(lua.TNUMBER))
	lua.L_checktype(state, 4, i32(lua.TNUMBER))

	// Draw the texture using raylib
	raylib.DrawTexture(
		plugin_texture_map[u32(GetIntegerParam(state, 1))],
		GetIntegerParam(state, 2),
		GetIntegerParam(state, 3),
		raylib.GetColor(u32(GetIntegerParam(state, 4))),
	)
	// Tell VM that we are not returning any values
	return 0
}

rlDrawLineEx :: proc "c" (state: ^lua.State) -> i32 {
	context = runtime.default_context()
	// Name: DrawLine
	// Description: Draws a line from (start_x, start_y) to (end_x, end_y) with the specified color
	// Example: raylib.DrawLine(10, 10, 100, 100, tointeger("0xFF0000FF"))
	// Output: (none)
	// Expects: start (table with x, y), end (table with x, y), thickness (float), hex_color (int RGBA)
	// Returns: nothing

	lua.L_checktype(state, 1, i32(lua.TTABLE))
	lua.L_checktype(state, 2, i32(lua.TTABLE))
	lua.L_checktype(state, 3, i32(lua.TNUMBER))
	lua.L_checktype(state, 4, i32(lua.TNUMBER))

	// Draw the line using raylib
	raylib.DrawLineEx(
		GetVector2(state, 1),
		GetVector2(state, 2),
		GetNumberParam(state, 3),
		raylib.GetColor(u32(GetIntegerParam(state, 4))),
	)
	// Tell VM that we are not returning any values
	return 0
}

rlDrawText :: proc "c" (state: ^lua.State) -> i32 {
	context = runtime.default_context()
	// Name: DrawText
	// Description: Draws text at the specified position with the specified color
	// Example: raylib.DrawText("Hello, World!", 10, 10, 20, tointeger("0xFFFFFFFF"))
	// Output: (none)
	// Expects: text (string), x (int), y (int), font_size (int), hex_color (int RGBA)
	// Returns: nothing

	lua.L_checktype(state, 1, i32(lua.TSTRING))
	lua.L_checktype(state, 2, i32(lua.TNUMBER))
	lua.L_checktype(state, 3, i32(lua.TNUMBER))
	lua.L_checktype(state, 4, i32(lua.TNUMBER))
	lua.L_checktype(state, 5, i32(lua.TNUMBER))

	// Draw the text using raylib
	raylib.DrawText(
		GetCStringParam(state, 1),
		i32(GetIntegerParam(state, 2)),
		i32(GetIntegerParam(state, 3)),
		i32(GetIntegerParam(state, 4)),
		raylib.GetColor(u32(GetIntegerParam(state, 5))),
	)
	// Tell VM that we are not returning any values
	return 0
}

rlDrawTextPro :: proc "c" (state: ^lua.State) -> i32 {
	context = runtime.default_context()
	// Name: DrawTextPro
	// Description: Draws text using a font at the specified position with the specified color and other parameters
	// Example: raylib.DrawTextPro("Hello, World!", {x=10, y=10}, {x=0, y=0}, 0, 20, 2, tointeger("0xFFFFFFFF"))
	// Output: (none)
	// Expects: text (string), position (table with x, y), origin (table with x, y), rotation (float), font_size (float), spacing (float), hex_color (int RGBA)
	// Returns: nothing

	lua.L_checktype(state, 1, i32(lua.TSTRING))
	lua.L_checktype(state, 2, i32(lua.TTABLE))
	lua.L_checktype(state, 3, i32(lua.TTABLE))
	lua.L_checktype(state, 4, i32(lua.TNUMBER))
	lua.L_checktype(state, 5, i32(lua.TNUMBER))
	lua.L_checktype(state, 6, i32(lua.TNUMBER))
	lua.L_checktype(state, 7, i32(lua.TNUMBER))

	// Draw the text using raylib
	raylib.DrawTextPro(
		raylib.GetFontDefault(),
		lua.tostring(state, 1),
		GetVector2(state, 2),
		GetVector2(state, 3),
		GetNumberParam(state, 4),
		GetNumberParam(state, 5),
		GetNumberParam(state, 6),
		raylib.GetColor(u32(GetIntegerParam(state, 7))),
	)
	// Tell VM that we are not returning any values
	return 0
}

rlDrawCircle :: proc "c" (state: ^lua.State) -> i32 {
	context = runtime.default_context()
	// Name: DrawCircle
	// Description: Draws a circle at the specified position with the specified color
	// Example: raylib.DrawCircle({x=100, y=100}, 50, tointeger("0xFFAA00FF"))
	// Output: (none)
	// Expects: center (table with x, y), radius (float), hex_color (int RGBA)
	// Returns: nothing

	lua.L_checktype(state, 1, i32(lua.TTABLE))
	lua.L_checktype(state, 2, i32(lua.TNUMBER))
	lua.L_checktype(state, 3, i32(lua.TNUMBER))

	// Draw the circle using raylib
	raylib.DrawCircleV(
		GetVector2(state, 1),
		GetNumberParam(state, 2),
		raylib.GetColor(u32(GetIntegerParam(state, 3))),
	)
	// Tell VM that we are not returning any values
	return 0
}

rlDrawTriangle :: proc "c" (state: ^lua.State) -> i32 {
	context = runtime.default_context()
	// Name: DrawTriangle
	// Description: Draws a triangle with the specified vertices and color
	// Example: raylib.DrawTriangle({x=100, y=100}, {x=150, y=50}, {x=200, y=100}, tointeger("0xFF00FFFF"))
	// Output: (none)
	// Expects: p1 (table with x, y), p2 (table with x, y), p3 (table with x, y), hex_color (int RGBA)
	// Returns: nothing

	lua.L_checktype(state, 1, i32(lua.TTABLE))
	lua.L_checktype(state, 2, i32(lua.TTABLE))
	lua.L_checktype(state, 3, i32(lua.TTABLE))
	lua.L_checktype(state, 4, i32(lua.TNUMBER))

	// Draw the triangle using raylib
	raylib.DrawTriangle(
		GetVector2(state, 1),
		GetVector2(state, 2),
		GetVector2(state, 3),
		raylib.GetColor(u32(GetIntegerParam(state, 4))),
	)
	// Tell VM that we are not returning any values
	return 0
}

rlDrawTriangleLines :: proc "c" (state: ^lua.State) -> i32 {
	context = runtime.default_context()
	// Name: DrawTriangleLines
	// Description: Draws the outline of a triangle with the specified vertices and color
	// Example: raylib.DrawTriangleLines({x=100, y=100}, {x=150, y=50}, {x=200, y=100}, tointeger("0xFF00FFFF"))
	// Output: (none)
	// Expects: p1 (table with x, y), p2 (table with x, y), p3 (table with x, y), hex_color (int RGBA)
	// Returns: nothing

	lua.L_checktype(state, 1, i32(lua.TTABLE))
	lua.L_checktype(state, 2, i32(lua.TTABLE))
	lua.L_checktype(state, 3, i32(lua.TTABLE))
	lua.L_checktype(state, 4, i32(lua.TNUMBER))

	// Draw the triangle lines using raylib
	raylib.DrawTriangleLines(
		GetVector2(state, 1),
		GetVector2(state, 2),
		GetVector2(state, 3),
		raylib.GetColor(u32(GetIntegerParam(state, 4))),
	)
	// Tell VM that we are not returning any values
	return 0
}

rlDrawRectangle :: proc "c" (state: ^lua.State) -> i32 {
	context = runtime.default_context()
	// Name: DrawRectangle
	// Description: Draws a rectangle at the specified position with the specified color
	// Example: raylib.DrawRectangle({x=50, y=50, width=200, height=100}, {x=0, y=0}, 45, tointeger("0x00FF00FF"))
	// Output: (none)
	// Expects: rect (table with x, y, width, height), origin (table with x, y), rotation (float), hex_color (int RGBA)
	// Returns: nothing

	lua.L_checktype(state, 1, i32(lua.TTABLE))
	lua.L_checktype(state, 2, i32(lua.TTABLE))
	lua.L_checktype(state, 3, i32(lua.TNUMBER))
	lua.L_checktype(state, 4, i32(lua.TNUMBER))

	// Draw the rectangle using raylib
	raylib.DrawRectanglePro(
		GetRectangle(state, 1),
		GetVector2(state, 2),
		GetNumberParam(state, 3),
		raylib.GetColor(u32(GetIntegerParam(state, 4))),
	)
	// Tell VM that we are not returning any values
	return 0
}

rlDrawArchedLine :: proc "c" (state: ^lua.State) -> i32 {
	context = runtime.default_context()
	// Name: DrawArchedLine
	// Description: Draws an arched line (arc) at the specified position with the specified color
	// Example: raylib.DrawArchedLine({x=200, y=200}, 50, 0, 180, 10, tointeger("0x0000FFFF"))
	// Output: (none)
	// Expects: center (table with x, y), radius (int), start_angle (float), end_angle (float), thickness (int), segments (int), hex_color (int RGBA)
	// Returns: nothing

	lua.L_checktype(state, 1, i32(lua.TTABLE))
	lua.L_checktype(state, 2, i32(lua.TNUMBER))
	lua.L_checktype(state, 3, i32(lua.TNUMBER))
	lua.L_checktype(state, 4, i32(lua.TNUMBER))
	lua.L_checktype(state, 5, i32(lua.TNUMBER))
	lua.L_checktype(state, 6, i32(lua.TNUMBER))
	lua.L_checktype(state, 7, i32(lua.TNUMBER))

	// Draw the arc using raylib
	raylib.DrawRing(
		GetVector2(state, 1),
		GetNumberParam(state, 2),
		GetNumberParam(state, 3),
		GetNumberParam(state, 4),
		GetNumberParam(state, 5),
		GetIntegerParam(state, 6),
		raylib.GetColor(u32(GetIntegerParam(state, 7))),
	)
	// Tell VM that we are not returning any values
	return 0
}

rlDrawCircleSector :: proc "c" (state: ^lua.State) -> i32 {
	context = runtime.default_context()
	// Name: DrawCircleSector
	// Description: Draws a circle sector at the specified position with the specified color
	// Example: raylib.DrawCircleSector({x=300, y=300}, 75, 0, 90, 10, tointeger("0xFF00FFFF"))
	// Output: (none)
	// Expects: center (table with x, y), radius (float), start_angle (float), end_angle (float), segments (int), hex_color (int RGBA)
	// Returns: nothing

	lua.L_checktype(state, 1, i32(lua.TTABLE))
	lua.L_checktype(state, 2, i32(lua.TNUMBER))
	lua.L_checktype(state, 3, i32(lua.TNUMBER))
	lua.L_checktype(state, 4, i32(lua.TNUMBER))
	lua.L_checktype(state, 5, i32(lua.TNUMBER))
	lua.L_checktype(state, 6, i32(lua.TNUMBER))

	// Draw the circle sector using raylib
	raylib.DrawCircleSector(
		GetVector2(state, 1),
		GetNumberParam(state, 2),
		GetNumberParam(state, 3),
		GetNumberParam(state, 4),
		GetIntegerParam(state, 5),
		raylib.GetColor(u32(GetIntegerParam(state, 6))),
	)
	// Tell VM that we are not returning any values
	return 0
}

rlGetScreenWidth :: proc "c" (state: ^lua.State) -> i32 {
	// Name: GetScreenWidth
	// Description: Returns the current screen width
	// Example: spinster.log(raylib.GetScreenWidth())
	// Output: [PLUGIN] [%DateTime%] [INFO] 800
	// Expects: nothing
	// Returns: screen_width (int)
	lua.pushinteger(state, lua.Integer(raylib.GetScreenWidth()))
	// Tell VM that we are returning 1 value
	return 1
}

rlGetScreenHeight :: proc "c" (state: ^lua.State) -> i32 {
	// Name: GetScreenHeight
	// Description: Returns the current screen height
	// Example: spinster.log(raylib.GetScreenHeight())
	// Output: [PLUGIN] [%DateTime%] [INFO] 600
	// Expects: nothing
	// Returns: screen_height (int)
	lua.pushinteger(state, lua.Integer(raylib.GetScreenHeight()))
	// Tell VM that we are returning 1 value
	return 1
}

rlGetMousePosition :: proc "c" (state: ^lua.State) -> i32 {
	// Name: GetMousePosition
	// Description: Returns the current mouse position
	// Example: spinster.log(raylib.GetMousePosition())
	// Output: [PLUGIN] [%DateTime%] [INFO] {x=400, y=300}
	// Expects: nothing
	// Returns: mouse_x (int), mouse_y (int)
	mouse_pos := raylib.GetMousePosition()
	lua.newtable(state)
	lua.pushinteger(state, lua.Integer(mouse_pos.x))
	lua.setfield(state, -2, "x")
	lua.pushinteger(state, lua.Integer(mouse_pos.y))
	lua.setfield(state, -2, "y")
	return 1
}

rlIsMouseButtonDown :: proc "c" (state: ^lua.State) -> i32 {
	context = runtime.default_context()
	// Name: IsMouseButtonDown
	// Description: Returns whether a mouse button is currently being pressed. 0 = left, 1 = right, 2 = middle, 3 = side, 4 = extra, 5 = forward, 6 = back
	// Example: spinster.log(raylib.IsMouseButtonDown(0))
	// Output: [PLUGIN] [%DateTime%] [INFO] true
	// Expects: button (int)
	// Returns: is_down (bool)
	button := GetIntegerParam(state, 1)
	if raylib.IsMouseButtonDown(raylib.MouseButton(button)) {
		lua.pushboolean(state, true)
	} else {
		lua.pushboolean(state, false)
	}
	// Tell VM that we are returning 1 value
	return 1
}

rlIsMouseButtonPressed :: proc "c" (state: ^lua.State) -> i32 {
	context = runtime.default_context()
	// Name: IsMouseButtonPressed
	// Description: Returns whether a mouse button was pressed once. 0 = left, 1 = right, 2 = middle, 3 = side, 4 = extra, 5 = forward, 6 = back
	// Example: spinster.log(raylib.IsMouseButtonPressed(0))
	// Output: [PLUGIN] [%DateTime%] [INFO] true
	// Expects: button (int)
	// Returns: is_pressed (bool)
	button := GetIntegerParam(state, 1)
	if raylib.IsMouseButtonPressed(raylib.MouseButton(button)) {
		lua.pushboolean(state, true)
	} else {
		lua.pushboolean(state, false)
	}
	// Tell VM that we are returning 1 value
	return 1
}

rlIsMouseButtonReleased :: proc "c" (state: ^lua.State) -> i32 {
	context = runtime.default_context()
	// Name: IsMouseButtonReleased
	// Description: Returns whether a mouse button was released once. 0 = left, 1 = right, 2 = middle, 3 = side, 4 = extra, 5 = forward, 6 = back
	// Example: spinster.log(raylib.IsMouseButtonReleased(0))
	// Output: [PLUGIN] [%DateTime%] [INFO] true
	// Expects: button (int)
	// Returns: is_released (bool)
	button := GetIntegerParam(state, 1)
	if raylib.IsMouseButtonReleased(raylib.MouseButton(button)) {
		lua.pushboolean(state, true)
	} else {
		lua.pushboolean(state, false)
	}
	// Tell VM that we are returning 1 value
	return 1
}

rlGetMouseWheelMove :: proc "c" (state: ^lua.State) -> i32 {
	// Name: GetMouseWheelMove
	// Description: Returns the mouse wheel movement for the last frame
	// Example: spinster.log(raylib.GetMouseWheelMove())
	// Output: [PLUGIN] [%DateTime%] [INFO] -1.0
	// Expects: nothing
	// Returns: wheel_move (float)
	lua.pushnumber(state, lua.Number(raylib.GetMouseWheelMove()))
	// Tell VM that we are returning 1 value
	return 1
}

rlCheckCollisionRecs :: proc "c" (state: ^lua.State) -> i32 {
	// Name: CheckCollisionRecs
	// Description: Checks if two rectangles are colliding
	// Example: spinster.log(raylib.CheckCollisionRecs({x=100, y=100, width=50, height=50}, {x=120, y=120, width=50, height=50}))
	// Output: [PLUGIN] [%DateTime%] [INFO] true
	// Expects: rec1 (table with x, y, width, height), rec2 (table with x, y, width, height)
	// Returns: is_colliding (bool)

	lua.L_checktype(state, 1, i32(lua.TTABLE))
	lua.L_checktype(state, 2, i32(lua.TTABLE))

	if raylib.CheckCollisionRecs(GetRectangle(state, 1), GetRectangle(state, 2)) {
		lua.pushboolean(state, true)
	} else {
		lua.pushboolean(state, false)
	}
	// Tell VM that we are returning 1 value
	return 1
}

rlCheckCollisionCircles :: proc "c" (state: ^lua.State) -> i32 {
	context = runtime.default_context()
	// Name: CheckCollisionCircles
	// Description: Checks if two circles are colliding
	// Example: spinster.log(raylib.CheckCollisionCircles({x=200, y=200}, 50, {x=220, y=220}, 50))
	// Output: [PLUGIN] [%DateTime%] [INFO] true
	// Expects: center1 (table with x, y), radius1 (int), center2 (table with x, y), radius2 (int)
	// Returns: is_colliding (bool)

	lua.L_checktype(state, 1, i32(lua.TTABLE))
	lua.L_checktype(state, 2, i32(lua.TNUMBER))
	lua.L_checktype(state, 3, i32(lua.TTABLE))
	lua.L_checktype(state, 4, i32(lua.TNUMBER))

	if raylib.CheckCollisionCircles(
		GetVector2(state, 1),
		GetNumberParam(state, 2),
		GetVector2(state, 3),
		GetNumberParam(state, 4),
	) {
		lua.pushboolean(state, true)
	} else {
		lua.pushboolean(state, false)
	}
	// Tell VM that we are returning 1 value
	return 1
}

rlCheckCollisionPointRec :: proc "c" (state: ^lua.State) -> i32 {
	// Name: CheckCollisionPointRec
	// Description: Checks if a point is inside a rectangle
	// Example: spinster.log(raylib.CheckCollisionPointRec({x=100, y=100}, {x=50, y=50, width=100, height=100}))
	// Output: [PLUGIN] [%DateTime%] [INFO] true
	// Expects: point (table with x, y), rec (table with x, y, width, height)
	// Returns: is_colliding (bool)

	lua.L_checktype(state, 1, i32(lua.TTABLE))
	lua.L_checktype(state, 2, i32(lua.TTABLE))

	if raylib.CheckCollisionPointRec(GetVector2(state, 1), GetRectangle(state, 2)) {
		lua.pushboolean(state, true)
	} else {
		lua.pushboolean(state, false)
	}
	// Tell VM that we are returning 1 value
	return 1
}

rlCheckCollisionPointCircle :: proc "c" (state: ^lua.State) -> i32 {
	context = runtime.default_context()
	// Name: CheckCollisionPointCircle
	// Description: Checks if a point is inside a circle
	// Example: spinster.log(raylib.CheckCollisionPointCircle({x=150, y=150}, {x=200, y=200}, 75))
	// Output: [PLUGIN] [%DateTime%] [INFO] false
	// Expects: point (table with x, y), center (table with x, y), radius (int)
	// Returns: is_colliding (bool)

	lua.L_checktype(state, 1, i32(lua.TTABLE))
	lua.L_checktype(state, 2, i32(lua.TTABLE))
	lua.L_checktype(state, 3, i32(lua.TNUMBER))

	if raylib.CheckCollisionPointCircle(
		GetVector2(state, 1),
		GetVector2(state, 2),
		GetNumberParam(state, 3),
	) {
		lua.pushboolean(state, true)
	} else {
		lua.pushboolean(state, false)
	}
	// Tell VM that we are returning 1 value
	return 1
}

rlCheckCollisionPointTriangle :: proc "c" (state: ^lua.State) -> i32 {
	// Name: CheckCollisionPointTriangle
	// Description: Checks if a point is inside a triangle
	// Example: spinster.log(raylib.CheckCollisionPointTriangle({x=250, y=250}, {x=200, y=200}, {x=300, y=200}, {x=250, y=300}))
	// Output: [PLUGIN] [%DateTime%] [INFO] true
	// Expects: point (table with x, y), p1 (table with x, y), p2 (table with x, y), p3 (table with x, y)
	// Returns: is_colliding (bool)

	lua.L_checktype(state, 1, i32(lua.TTABLE))
	lua.L_checktype(state, 2, i32(lua.TTABLE))
	lua.L_checktype(state, 3, i32(lua.TTABLE))
	lua.L_checktype(state, 4, i32(lua.TTABLE))

	// First get point
	point := GetVector2(state, 1)

	// Now get p1
	p1 := GetVector2(state, 2)

	// Now get p2
	p2 := GetVector2(state, 3)

	// Now get p3
	p3 := GetVector2(state, 4)

	if raylib.CheckCollisionPointTriangle(point, p1, p2, p3) {
		lua.pushboolean(state, true)
	} else {
		lua.pushboolean(state, false)
	}
	// Tell VM that we are returning 1 value
	return 1
}

rlCheckCollisionCircleRec :: proc "c" (state: ^lua.State) -> i32 {
	context = runtime.default_context()
	// Name: CheckCollisionCircleRec
	// Description: Checks if a circle and a rectangle are colliding
	// Example: spinster.log(raylib.CheckCollisionCircleRec({x=150, y=150}, {x=100, y=100, width=100, height=100}, 50))
	// Output: [PLUGIN] [%DateTime%] [INFO] true
	// Expects: rec (table with x, y, width, height), center (table with x, y), radius (int)
	// Returns: is_colliding (bool)

	lua.L_checktype(state, 1, i32(lua.TTABLE))
	lua.L_checktype(state, 2, i32(lua.TTABLE))
	lua.L_checktype(state, 3, i32(lua.TNUMBER))

	rec := GetRectangle(state, 1)
	center := GetVector2(state, 2)
	radius := GetNumberParam(state, 3)

	if raylib.CheckCollisionCircleRec(center, f32(radius), rec) {
		lua.pushboolean(state, true)
	} else {
		lua.pushboolean(state, false)
	}
	// Tell VM that we are returning 1 value
	return 1
}

rlFileExists :: proc "c" (state: ^lua.State) -> i32 {
	context = runtime.default_context()
	// Name: FileExists
	// Description: Checks if a file exists. `file_name` is relative to the plugin's directory.
	// Example: spinster.log(raylib.FileExists("my_texture.png"))
	// Output: [PLUGIN] [%DateTime%] [INFO] true
	// Expects: file_name (string)
	// Returns: exists (bool)

	lua.L_checktype(state, 1, i32(lua.TSTRING))

	// Get "file_name" from the stack
	file_name := GetStringParam(state, 1)

	// Get "plugin_name" from global state
	lua.getglobal(state, "plugin_name")
	plugin_name := GetStringParam(state, -1)
	lua.pop(state, 1) // remove plugin_name from stack

	// Prevent directory traversal attacks
	if strings.contains(string(file_name), "..") {
		lua.pushboolean(state, false)
		return 1
	}

	full_path: string

	// Check if file_name is a simple file name or a path
	if strings.contains(file_name, "/") || strings.contains(file_name, "\\") {
		when ODIN_OS == .Windows {
			full_path = strings.join({plugin_name, file_name}, "\\")
		}
		when ODIN_OS == .Linux {
			full_path = strings.join({plugin_name, file_name}, "/")
		}
	} else {
		// Just a file name, load from plugin directory
		when ODIN_OS == .Windows {
			full_path = strings.join({".", "plugins", plugin_name, file_name}, "\\")
		}
		when ODIN_OS == .Linux {
			full_path = strings.join({".", "plugins", plugin_name, file_name}, "/")
		}
	}
	full_path = filepath.clean(full_path)
	if raylib.FileExists(strings.clone_to_cstring(full_path)) {
		lua.pushboolean(state, true)
	} else {
		lua.pushboolean(state, false)
	}
	// Tell VM that we are returning 1 value
	return 1
}

rlColorFromHSV :: proc "c" (state: ^lua.State) -> i32 {
	context = runtime.default_context()
	// Name: ColorFromHSV
	// Description: Converts HSV values to a Color. Hue is in degrees [0..360], Saturation and Value are in range [0..1]
	// Example: local color = raylib.ColorFromHSV(210, 0.75, 0.9); spinster.log(string.format("0x%X", color))
	// Output: [PLUGIN] [%DateTime%] [INFO] 0x3F7FBFFF
	// Expects: hue (float), saturation (float), value (float)
	// Returns: hex_color (int RGBA)

	lua.L_checktype(state, 1, i32(lua.TNUMBER))
	lua.L_checktype(state, 2, i32(lua.TNUMBER))
	lua.L_checktype(state, 3, i32(lua.TNUMBER))

	hue := GetNumberParam(state, 1)
	saturation := GetNumberParam(state, 2)
	value := GetNumberParam(state, 3)

	color := raylib.ColorFromHSV(f32(hue), f32(saturation), f32(value))
	lua.pushinteger(state, lua.Integer(raylib.ColorToInt(color)))
	// Tell VM that we are returning 1 value
	return 1
}

rlMeasureTextEx :: proc "c" (state: ^lua.State) -> i32 {
	context = runtime.default_context()
	// Name: MeasureTextEx
	// Description: Measures the size of a text string when rendered with the current font and parameters
	// Example: local size = raylib.MeasureTextEx("Hello, World!", 20, 2); spinster.log(string.format("Width: %d, Height: %d", size.x, size.y))
	// Output: [PLUGIN] [%DateTime%] [INFO] Width: 190, Height: 20
	// Expects: text (string), font_size (float), spacing (float)
	// Returns: size (table with x, y)

	lua.L_checktype(state, 1, i32(lua.TSTRING))
	lua.L_checktype(state, 2, i32(lua.TNUMBER))
	lua.L_checktype(state, 3, i32(lua.TNUMBER))

	size := raylib.MeasureTextEx(
		raylib.GetFontDefault(),
		GetCStringParam(state, 1),
		GetNumberParam(state, 2),
		GetNumberParam(state, 3),
	)

	lua.newtable(state)
	lua.pushnumber(state, lua.Number(size.x))
	lua.setfield(state, -2, "x")
	lua.pushnumber(state, lua.Number(size.y))
	lua.setfield(state, -2, "y")

	// Tell VM that we are returning 1 value
	return 1
}
