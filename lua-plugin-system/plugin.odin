package main

import "base:runtime"
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import lua "vendor:lua/5.4"
import "vendor:raylib"

Plugin :: struct {
	name:                 string,
	version:              string,
	author:               string,
	description:          string,
	script:               string,
	workshop_id:          string,
	is_workshop_item:     bool,
	enabled:              bool,
	state:                ^lua.State,
	optional_functions:   [dynamic]string,
	can_My_Optional_Func: bool,
}

Lua_Types :: union {
	int,
	f32,
	string,
	bool,
}

plugin_folder: string = "plugins"

plugin_app_name_string: string = "my_game"
plugin_app_name_cstring: cstring = "my_game"

// Might change this to a pointer list
plugins: [dynamic]Plugin

plugin_required_functions: []string = {"On_Load", "On_Unload", "On_Update", "On_Render"}

plugin_optional_functions: []string = {"My_Optional_Func"}

load_plugin_libs :: proc(state: ^lua.State) {
	// Register app functions
	// lua.L_newlib(state, lua_app_lib)
	// lua.setglobal(state, plugin_app_name_cstring)

	// Register raylib functions
	lua.L_newlib(state, lua_raylib_lib)
	lua.setglobal(state, "raylib")
}

plugin_conflict_check :: proc(name: string) -> (list: [dynamic]string, conflict: bool) {
	// Check if more than one plugin uses My_Optional_Func
	this_contains_My_Optional_Func := false
	My_Optional_Func_conflict := false

	conflicting_plugins: [dynamic]string

	for plugin in plugins {
		if plugin.name == name {
			for func_name in plugin.optional_functions {
				if func_name == "My_Optional_Func" {
					this_contains_My_Optional_Func = true
					fmt.println(
						strings.concatenate(
							{"Plugin \"", plugin.name, "\" uses My_Optional_Func"},
						),
					)
					break
				}
			}
			break
		}
	}

	for plugin in plugins {
		if plugin.name == name {
			continue
		}
		contains_My_Optional_Func := false
		for func_name in plugin.optional_functions {
			if func_name == "My_Optional_Func" {
				contains_My_Optional_Func = true
				fmt.println(
					strings.concatenate({"Plugin \"", plugin.name, "\" uses My_Optional_Func"}),
				)
			}
		}
		if this_contains_My_Optional_Func && contains_My_Optional_Func {
			fmt.println(
				strings.concatenate(
					{
						"Plugin conflict detected: \"",
						plugin.name,
						"\" already uses My_Optional_Func, but \"",
						name,
						"\" also uses it. Only one plugin can use My_Optional_Func at a time.",
					},
				),
			)
			append(&conflicting_plugins, plugin.name)
			My_Optional_Func_conflict = true
		}
	}
	if My_Optional_Func_conflict {
		append(&conflicting_plugins, name)
	}
	return conflicting_plugins, My_Optional_Func_conflict
}

init_lua_environment :: proc() -> ^lua.State {
	state: ^lua.State = lua.L_newstate()
	lua.open_base(state)
	lua.L_openlibs(state)

	// Limit the Lua standard libraries for security
	// (we don't want plugins to have full access to the filesystem, etc.)
	lua.pushnil(state)
	lua.setglobal(state, "io") // Disable io library
	lua.pushnil(state)
	lua.setglobal(state, "os") // Disable os library
	// lua.pushnil(state)
	// lua.setglobal(state, "debug") // Disable debug library

	// Load App and Raylib bindings
	load_plugin_libs(state)
	return state
}

load_plugins :: proc() {
	context = runtime.default_context()
	// Load plugins from the plugin folder
	fmt.println("Loading plugins from folder: %s", plugin_folder)
	if !os.exists(plugin_folder) {
		fmt.println("Plugin folder does not exist, creating: %s", plugin_folder)
		if os.make_directory(plugin_folder) != nil {
			fmt.eprintln("Failed to create plugin folder: %s", plugin_folder)
			return
		}
	}

	// Open the plugin folder
	folder_handle, open_err := os.open(plugin_folder)
	defer os.close(folder_handle)
	if open_err != nil {
		fmt.eprintln("Failed to open plugin folder: %s", open_err)
		return
	}

	// Read the directory entries
	dir_entries, read_err := os.read_dir(folder_handle, 0)
	if read_err != nil {
		fmt.eprintln("Failed to read plugin folder: %s", read_err)
		return
	}

	// Load each plugin from their respective directory entry
	for entry in dir_entries {
		if entry.is_dir {
			// Open the subdirectory
			subdir_handle, subdir_err := os.open(entry.fullpath)
			if subdir_err != nil {
				fmt.eprintln("Failed to open plugin subdirectory: %s", subdir_err)
				continue
			}
			subdir_entries, subdir_read_err := os.read_dir(subdir_handle, 0)
			defer os.close(subdir_handle)
			if subdir_read_err != nil {
				fmt.eprintln("Failed to read plugin subdirectory: %s", subdir_read_err)
				continue
			}
			// Look for a .lua file in the subdirectory
			for sub_entry in subdir_entries {
				if strings.ends_with(sub_entry.name, ".lua") {
					plugin := load_plugin(sub_entry.fullpath)
					if plugin.name != "" {
						// Check for conflicts with existing plugins
						if conflict_list, conflict := plugin_conflict_check(plugin.name);
						   conflict {
							fmt.eprintln(
								"Plugin \"%s\" has conflicts with existing plugins: %s. Skipping load.",
								plugin.name,
								strings.join(conflict_list[:], ", "),
							)
							plugin.enabled = false
						} else {
							append(&plugins, plugin)
						}
					}
				}
			}
		}
	}

	fmt.println("Finished loading plugins. Total loaded: %d", len(plugins))
}

load_plugin :: proc(path: string) -> Plugin {
	context = runtime.default_context()
	fmt.println("Loading plugin from path: %s", path)
	state := init_lua_environment()
	if os.exists(path) {
		script, success := os.read_entire_file_from_filename(path)
		if success {
			if lua.L_loadstring(state, strings.clone_to_cstring(string(script))) == .OK {
				// Set the error function
				// lua.pushcfunction(state, error_handler)
				// lua.insert(state, -2)
				// Run the loaded script
				if lua.Status(lua.pcall(state, 0, lua.MULTRET, 0)) == .OK {
					// Retrieve plugin metadata

					// Name
					lua.getglobal(state, "plugin_name")
					name := strings.clone_from_cstring(lua.tostring(state, -1))
					lua.pop(state, 1)

					// Version
					lua.getglobal(state, "plugin_version")
					version := strings.clone_from_cstring(lua.tostring(state, -1))
					lua.pop(state, 1)

					// Author
					lua.getglobal(state, "plugin_author")
					author := strings.clone_from_cstring(lua.tostring(state, -1))
					lua.pop(state, 1)

					// Description
					lua.getglobal(state, "plugin_description")
					description := strings.clone_from_cstring(lua.tostring(state, -1))
					lua.pop(state, 1)

					// Check that the required functions are defined

					for func_name in plugin_required_functions {
						lua.getglobal(state, strings.clone_to_cstring(func_name))
						if lua.isnil(state, -1) {
							fmt.eprintln(
								"Plugin %s is missing required function: %s",
								name,
								func_name,
							)
							return {}
						}
						lua.pop(state, 1)
					}

					optional_functions: [dynamic]string
					can_My_Optional_Func: bool = false
					defer delete(optional_functions)

					for func_name in plugin_optional_functions {
						lua.getglobal(state, strings.clone_to_cstring(func_name))
						if !lua.isnil(state, -1) {
							// Function is defined, add to optional functions list
							if func_name == "My_Optional_Func" {
								fmt.println("Plugin %s can draw wheels", name)
								can_My_Optional_Func = true
							}
							append(&optional_functions, func_name)
						}
						lua.pop(state, 1)
					}

					// Try to load the plugin config if it exists
					if loadPluginConfig(state, name) {
						fmt.println("Loaded config for plugin: %s", name)
					} else {
						fmt.println("No existing config found for plugin: %s", name)
					}

					// Call the On_Load function
					if !plugin_On_Load(state, name) {
						fmt.eprintln("Plugin %s failed to load properly.", name)
						return {}
					}

					fmt.println("Successfully loaded plugin: %s v%s by %s", name, version, author)

					// If there are optional functions, include them in the Plugin struct
					if len(optional_functions) > 0 {
						return Plugin {
							name = name,
							version = version,
							author = author,
							description = description,
							script = path,
							state = state,
							optional_functions = optional_functions,
							can_My_Optional_Func = can_My_Optional_Func,
						}
					}
					// If there are no optional functions, return the Plugin struct without them
					return Plugin {
						name = name,
						version = version,
						author = author,
						description = description,
						script = path,
						state = state,
						can_My_Optional_Func = can_My_Optional_Func,
					}
				} else {
					error_msg := strings.clone_from_cstring(lua.tostring(state, -1))
					fmt.eprintln("Error running plugin script: %s", error_msg)
					lua.pop(state, 1)
					return {}
				}
			} else {
				error_msg := strings.clone_from_cstring(lua.tostring(state, -1))
				fmt.eprintln("Error loading plugin script: %s", error_msg)
				lua.pop(state, 1)
				return {}
			}
		} else {
			fmt.eprintln("Failed to read plugin file: %s", path)
			return {}
		}
	}
	fmt.eprintln("Plugin file does not exist: %s", path)
	return {}
}

plugin_On_Load :: proc {
	plugin_On_Load_plugin,
	plugin_On_Load_state,
}

plugin_On_Load_plugin :: proc(plugin: ^Plugin) -> (ok: bool) {
	return plugin_On_Load(plugin.state, plugin.name)
}

plugin_On_Load_state :: proc(state: ^lua.State, name: string) -> (ok: bool) {
	// Call the On_Load function
	On_Load_status := lua.L_dostring(state, "return On_Load()")
	if lua.Status(On_Load_status) != .OK {
		error_msg := strings.clone_from_cstring(lua.tostring(state, -1))
		fmt.eprintln("Error calling On_Load for plugin %s: %s", name, error_msg)
		return false
	}
	fmt.println("Plugin %s On_Load executed successfully", name)
	return true
}

plugin_On_Unload :: proc(plugin: ^Plugin) -> (ok: bool) {
	// Call the On_Unload function
	On_Unload_status := lua.L_dostring(plugin.state, "return On_Unload()")
	if lua.Status(On_Unload_status) != .OK {
		error_msg := strings.clone_from_cstring(lua.tostring(plugin.state, -1))
		fmt.eprintln("Error calling On_Unload for plugin %s: %s", plugin.name, error_msg)
		return false
	}
	fmt.println("Plugin %s On_Unload executed successfully", plugin.name)
	return true
}

plugin_On_Update :: proc(plugin: ^Plugin, delta_time: f32) -> (ok: bool) {
	// Call the On_Update function
	lua.pushnumber(plugin.state, lua.Number(delta_time))
	On_Update_status := lua.L_dostring(plugin.state, "return On_Update()")
	if lua.Status(On_Update_status) != .OK {
		error_msg := strings.clone_from_cstring(lua.tostring(plugin.state, -1))
		fmt.eprintln("Error calling On_Update for plugin %s: %s", plugin.name, error_msg)
		return false
	}
	return true
}

plugin_On_Render :: proc(plugin: ^Plugin) -> (ok: bool) {
	// Call the On_Render function
	On_Render_status := lua.L_dostring(plugin.state, "return On_Render()")
	if lua.Status(On_Render_status) != .OK {
		error_msg := strings.clone_from_cstring(lua.tostring(plugin.state, -1))
		fmt.eprintln("Error calling On_Render for plugin %s: %s", plugin.name, error_msg)
		return false
	}
	return true
}

plugin_My_Optional_Func :: proc(plugin: ^Plugin) -> (ok: bool) {
	context = runtime.default_context()
	if !plugin.can_My_Optional_Func {
		fmt.eprintln("Plugin %s cannot draw wheels", plugin.name)
		return false
	}
	// Call the My_Optional_Func function
	My_Optional_Func_status := lua.L_dostring(
		plugin.state,
		fmt.caprintf("return My_Optional_Func()"),
	)
	if lua.Status(My_Optional_Func_status) != .OK {
		error_msg := strings.clone_from_cstring(lua.tostring(plugin.state, -1))
		fmt.eprintln("Error calling My_Optional_Func for plugin %s: %s", plugin.name, error_msg)
		return false
	}
	return true
}

get_field :: proc(state: ^lua.State, key: string) -> (result: Lua_Types) {
	lua.pushstring(state, strings.clone_to_cstring(key))
	if lua.Status(lua.gettable(state, -2)) != .OK {
		fmt.eprintln("Error getting field %s from table", key)
		return nil
	}
	if !lua.isstring(state, -1) {
		if lua.isnumber(state, -1) {
			result = f32(lua.tonumber(state, -1))
		} else if lua.isboolean(state, -1) {
			result = bool(lua.toboolean(state, -1))
		} else {
			result = nil
		}
	} else {
		result = strings.clone_from_cstring((lua.tostring(state, -1)))
	}
	lua.pop(state, 1)
	return result
}

get_table_global :: proc(
	state: ^lua.State,
	key: string,
) -> (
	table: map[string]Lua_Types,
	ok: bool,
) {
	lua.getglobal(state, strings.clone_to_cstring(key))
	if !lua.istable(state, -1) {
		lua.pop(state, 1) // remove non-table from stack
		return {}, false
	}

	// table_idx := lua.gettop(state)
	lua.pushnil(state) // first key
	for lua.Status(lua.next(state, -2)) != .OK {
		k := strings.clone_from_cstring(lua.tostring(state, -2))
		value: Lua_Types
		if lua.isstring(state, -1) {
			value = strings.clone_from_cstring(lua.tostring(state, -1))
		} else if lua.isnumber(state, -1) {
			value = f32(lua.tonumber(state, -1))
		} else if lua.isboolean(state, -1) {
			value = bool(lua.toboolean(state, -1))
		} else {
			fmt.eprintln("Found nil or unsupported value for key %s", k)
			value = nil
		}
		table[k] = value
		lua.pop(state, 1) // remove value, keep key for next iteration
	}
	lua.pop(state, 1) // remove table from stack
	return table, true
}

set_table :: proc(state: ^lua.State, key: string, table: map[string]Lua_Types) {
	lua.newtable(state)
	for k, v in table {
		// Push the value based on its type
		switch typeid_of(type_of(v)) {
		case typeid_of(int):
			lua.pushinteger(state, lua.Integer(v.(int)))
		case typeid_of(f32):
			lua.pushnumber(state, lua.Number(v.(f32)))
		case typeid_of(string):
			lua.pushstring(state, strings.clone_to_cstring(v.(string)))
		case typeid_of(bool):
			lua.pushboolean(state, b32(v.(bool)))
		case:
			lua.pushnil(state)
		}
		lua.setfield(state, -2, strings.clone_to_cstring(k))
	}
	lua.setglobal(state, strings.clone_to_cstring(key))
}

loadPluginConfig :: proc(state: ^lua.State, name: string) -> (ok: bool) {
	context = runtime.default_context()
	// Load the plugin config from a file and set the config table in Lua
	config_filename := "config.json"
	config_file: string

	when ODIN_OS == .Windows {
		home_env := os.get_env("APPDATA")
		if config_path, ok := strings.join(
			{home_env, plugin_app_name_string, "plugins", name},
			"\\",
		); ok == nil {
			config_file, ok = strings.join({config_path, config_filename}, "\\")
			delete(config_path)
		} else {
			fmt.eprintln("Failed to create config path.")
			return false
		}
	} else when ODIN_OS == .Linux {
		home_env := os.get_env("HOME")
		if config_path, ok := strings.join(
			{home_env, ".config", plugin_app_name_string, "plugins", name},
			"/",
		); ok == nil {
			config_file, ok = strings.join({config_path, config_filename}, "/")
			delete(config_path)
		} else {
			fmt.eprintln("Failed to create config path.")
			return false
		}
	}

	if !os.exists(config_file) {
		fmt.eprintln("No config file found for plugin (%s), skipping load.", name)
		return true
	}
	json_bytes, read_ok := os.read_entire_file(config_file)
	if !read_ok {
		fmt.eprintln("Error reading config file for plugin (%s)", name)
		return false
	}

	config_map: map[string]Lua_Types

	// Unmarshal the json into a map
	err := json.unmarshal(json_bytes, &config_map)
	if err != nil {
		fmt.eprintln("Error unmarshalling config json for plugin (%s): %s", name, err)
		return false
	}

	// Set the config table in Lua
	set_table(state, "config", config_map)

	fmt.println("Loaded plugin (%s) config from %s", name, config_file)
	return true
}

savePluginConfig :: proc(state: ^lua.State, name: string) -> (ok: bool) {
	context = runtime.default_context()
	// Get the config table from Lua and return it as a map[string]any
	config_map, table_ok := get_table_global(state, "config")
	if !table_ok {
		fmt.eprintln("No config table found in plugin (%s), skipping save.", name)
		return false
	}

	// Convert the map to json
	json_bytes, err := json.marshal(config_map)
	if err != nil {
		fmt.eprintln("Error marshalling config map to json")
		return false
	}

	// Save the json to a file
	config_filename := "config.json"
	config_file: string

	when ODIN_OS == .Windows {
		home_env := os.get_env("APPDATA")
		if config_path, ok := strings.join(
			{home_env, plugin_app_name_string, "plugins", name},
			"\\",
		); ok == nil {
			if !os.exists(config_path) {
				config_path_err := os.make_directory(config_path)
				if config_path_err != nil {
					fmt.eprintln("Failed to create config path: %s", config_path_err)
					panic("Failed to create config path.")
				}
			}
			config_file, ok = strings.join({config_path, config_filename}, "\\")
			delete(config_path)
		} else {
			fmt.eprintln("Failed to create config path.")
			return false
		}
	} else when ODIN_OS == .Linux {
		home_env := os.get_env("HOME")
		if config_path, ok := strings.join(
			{home_env, ".config", plugin_app_name_string, "plugins", name},
			"/",
		); ok == nil {
			if !os.exists(config_path) {
				// check if the parent directories exist, if not create them
				parent_path, _ := strings.join(
					{home_env, ".config", plugin_app_name_string, "plugins"},
					"/",
				)
				if !os.exists(parent_path) {
					parent_path_err := os.make_directory(parent_path)
					if parent_path_err != nil {
						fmt.eprintln(
							"Failed to create parent config path(%s): %s",
							parent_path,
							parent_path_err,
						)
						return false
					}
				}
				delete(parent_path)
				// Now create the full config path
				config_path_err := os.make_directory(config_path)
				if config_path_err != nil {
					fmt.eprintln(
						"Failed to create config path(%s): %s",
						config_path,
						config_path_err,
					)
					return false
				}
			}
			config_file, ok = strings.join({config_path, config_filename}, "/")
			delete(config_path)
		} else {
			fmt.eprintln("Failed to create config path.")
			return false
		}
	}

	if success := os.write_entire_file(config_file, json_bytes); !success {
		fmt.eprintln("Error writing config to file")
		return false
	}
	fmt.println("Saved plugin (%s) config to %s", name, config_file)
	return true
}

GetNumberParam :: proc(state: ^lua.State, index: i32) -> f32 {
	num := f32(lua.L_checknumber(state, index))
	return num
}

GetIntegerParam :: proc(state: ^lua.State, index: i32) -> i32 {
	num := i32(lua.L_checkinteger(state, index))
	return num
}

GetCStringParam :: proc(state: ^lua.State, index: i32) -> cstring {
	cstr := lua.L_checkstring(state, index)
	return cstr
}

GetStringParam :: proc(state: ^lua.State, index: i32) -> string {
	str := strings.clone_from_cstring(lua.L_checkstring(state, index))
	return str
}

GetVector2 :: proc "c" (state: ^lua.State, index: i32) -> raylib.Vector2 {
	context = runtime.default_context()

	lua.getfield(state, index, "x")
	x: f32 = f32(lua.L_checknumber(state, -1))
	lua.pop(state, 1) // remove x from the stack

	lua.getfield(state, index, "y")
	y: f32 = f32(lua.L_checknumber(state, -1))
	lua.pop(state, 1) // remove y from the stack

	return {x, y}
}

GetVector3 :: proc "c" (state: ^lua.State, index: i32) -> raylib.Vector3 {
	context = runtime.default_context()

	lua.getfield(state, index, "x")
	x: f32 = f32(lua.L_checknumber(state, -1))
	lua.pop(state, 1) // remove x from the stack

	lua.getfield(state, index, "y")
	y: f32 = f32(lua.L_checknumber(state, -1))
	lua.pop(state, 1) // remove y from the stack

	lua.getfield(state, index, "z")
	z: f32 = f32(lua.L_checknumber(state, -1))
	lua.pop(state, 1) // remove z from the stack

	return {x, y, z}
}

GetRectangle :: proc "c" (state: ^lua.State, index: i32) -> raylib.Rectangle {
	context = runtime.default_context()

	lua.getfield(state, index, "x")
	x: f32 = f32(lua.L_checknumber(state, -1))
	lua.pop(state, 1) // remove x from the stack

	lua.getfield(state, index, "y")
	y: f32 = f32(lua.L_checknumber(state, -1))
	lua.pop(state, 1) // remove y from the stack

	lua.getfield(state, index, "width")
	width: f32 = f32(lua.L_checknumber(state, -1))
	lua.pop(state, 1) // remove width from the stack

	lua.getfield(state, index, "height")
	height: f32 = f32(lua.L_checknumber(state, -1))
	lua.pop(state, 1) // remove height from the stack

	return {x, y, width, height}
}
