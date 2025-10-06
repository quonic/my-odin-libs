#+feature dynamic-literals
package main

import lua "vendor:lua/5.4"

lua_app_lib: []lua.L_Reg = {
	// Add your application-specific Lua functions here
	// {name = "log", func = logMessage},
	{name = nil, func = nil}, // Sentinel
}

lua_raylib_lib: []lua.L_Reg = {
	{name = "LoadTexture", func = rlLoadTexture},
	{name = "UnloadTexture", func = rlUnloadTexture},
	{name = "DrawTexture", func = rlDrawTexture},
	{name = "DrawLineEx", func = rlDrawLineEx},
	{name = "DrawText", func = rlDrawText},
	{name = "DrawTextPro", func = rlDrawTextPro},
	{name = "DrawCircle", func = rlDrawCircle},
	{name = "DrawTriangle", func = rlDrawTriangle},
	{name = "DrawRectangle", func = rlDrawRectangle},
	{name = "DrawArchedLine", func = rlDrawArchedLine},
	{name = "DrawCircleSector", func = rlDrawCircleSector},
	{name = "GetScreenWidth", func = rlGetScreenWidth},
	{name = "GetScreenHeight", func = rlGetScreenHeight},
	{name = "GetMousePosition", func = rlGetMousePosition},
	{name = "IsMouseButtonDown", func = rlIsMouseButtonDown},
	{name = "IsMouseButtonPressed", func = rlIsMouseButtonPressed},
	{name = "IsMouseButtonReleased", func = rlIsMouseButtonReleased},
	{name = "GetMouseWheelMove", func = rlGetMouseWheelMove},
	{name = "CheckCollisionRecs", func = rlCheckCollisionRecs},
	{name = "CheckCollisionCircles", func = rlCheckCollisionCircles},
	{name = "CheckCollisionPointRec", func = rlCheckCollisionPointRec},
	{name = "CheckCollisionPointCircle", func = rlCheckCollisionPointCircle},
	{name = "CheckCollisionPointTriangle", func = rlCheckCollisionPointTriangle},
	{name = "CheckCollisionCircleRec", func = rlCheckCollisionCircleRec},
	{name = "FileExists", func = rlFileExists},
	{name = "ColorFromHSV", func = rlColorFromHSV},
	{name = "MeasureTextEx", func = rlMeasureTextEx},
	{name = nil, func = nil}, // Sentinel
}
