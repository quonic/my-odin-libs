package aseprite

import "core:encoding/json"
import "core:fmt"
import "core:io"
import "core:os"
import "core:strconv"
import "core:strings"

Aseprite :: struct {
	frames: map[string]Frame,
	meta:   Meta,
}

Meta :: struct {
	app:     string,
	version: string,
	image:   string,
	format:  string,
	size:    Size,
	scale:   f32,
	slices:  [dynamic]Slice,
}

Frame :: struct {
	frame:            Bounds,
	rotated:          bool,
	trimmed:          bool,
	spriteSourceSize: Bounds,
	sourceSize:       Size,
	duration:         int,
}

Slice :: struct {
	name:  string,
	color: string,
	keys:  [dynamic]Key,
}

Key :: struct {
	frame:  int,
	bounds: Bounds,
}

Bounds :: struct {
	x: f32,
	y: f32,
	w: f32,
	h: f32,
}

Size :: struct {
	w: int,
	h: int,
}

ReadAsespriteJsonFile :: proc(path: string) -> (aseprite: Aseprite) {
	assert(os.is_file(path), "File not found")

	// Get parent directory of the file
	parent_dir: string
	split_path := strings.split(path, "/")
	assert(len(split_path) != 0, "Invalid path")

	if len(split_path) == 1 {
		parent_dir = ""
	} else {
		parent_dir = split_path[len(split_path) - 2]
	}

	// Get the file contents
	data, ok := os.read_entire_file_from_filename(path)
	defer delete(data)
	assert(ok, "Read file failed!")

	json_data, err := json.parse(data, json.Specification.JSON5, true)
	defer json.destroy_value(json_data)
	assert(err == .None, "Failed to parse JSON")

	// Get the frames
	for key, value in json_data.(json.Object)["frames"].(json.Object) {
		aseprite.frames[key] = Frame {
			frame = Bounds {
				x = cast(f32)value.(json.Object)["frame"].(json.Object)["x"].(json.Integer),
				y = cast(f32)value.(json.Object)["frame"].(json.Object)["y"].(json.Integer),
				w = cast(f32)value.(json.Object)["frame"].(json.Object)["w"].(json.Integer),
				h = cast(f32)value.(json.Object)["frame"].(json.Object)["h"].(json.Integer),
			},
			rotated = value.(json.Object)["rotated"].(json.Boolean),
			trimmed = value.(json.Object)["trimmed"].(json.Boolean),
			spriteSourceSize = Bounds {
				x = cast(f32)value.(json.Object)["spriteSourceSize"].(json.Object)["x"].(json.Integer),
				y = cast(f32)value.(json.Object)["spriteSourceSize"].(json.Object)["y"].(json.Integer),
				w = cast(f32)value.(json.Object)["spriteSourceSize"].(json.Object)["w"].(json.Integer),
				h = cast(f32)value.(json.Object)["spriteSourceSize"].(json.Object)["h"].(json.Integer),
			},
			sourceSize = Size {
				w = cast(int)value.(json.Object)["sourceSize"].(json.Object)["w"].(json.Integer),
				h = cast(int)value.(json.Object)["sourceSize"].(json.Object)["h"].(json.Integer),
			},
			duration = cast(int)value.(json.Object)["duration"].(json.Integer),
		}
	}

	// meta.app
	aseprite.meta.app = json_data.(json.Object)["meta"].(json.Object)["app"].(json.String)
	// meta.version
	aseprite.meta.version = json_data.(json.Object)["meta"].(json.Object)["version"].(json.String)
	// meta.image
	aseprite.meta.image = json_data.(json.Object)["meta"].(json.Object)["image"].(json.String)
	// meta.format
	aseprite.meta.format = json_data.(json.Object)["meta"].(json.Object)["format"].(json.String)
	// meta.size
	aseprite.meta.size.w =
	cast(int)json_data.(json.Object)["meta"].(json.Object)["size"].(json.Object)["w"].(json.Integer)
	aseprite.meta.size.h =
	cast(int)json_data.(json.Object)["meta"].(json.Object)["size"].(json.Object)["h"].(json.Integer)
	// meta.scale
	aseprite.meta.scale, ok = strconv.parse_f32(
		json_data.(json.Object)["meta"].(json.Object)["scale"].(json.String),
	)
	assert(ok, "Failed to parse meta.scale")

	// meta.slices[]
	for slice in json_data.(json.Object)["meta"].(json.Object)["slices"].(json.Array) {
		currentSlice := Slice {
			name  = slice.(json.Object)["name"].(json.String),
			color = slice.(json.Object)["color"].(json.String),
			keys  = [dynamic]Key{},
		}
		for key in slice.(json.Object)["keys"].(json.Array) {
			append(
				&currentSlice.keys,
				Key {
					frame = cast(int)key.(json.Object)["frame"].(json.Integer),
					bounds = Bounds {
						x = cast(f32)key.(json.Object)["bounds"].(json.Object)["x"].(json.Integer),
						y = cast(f32)key.(json.Object)["bounds"].(json.Object)["y"].(json.Integer),
						w = cast(f32)key.(json.Object)["bounds"].(json.Object)["w"].(json.Integer),
						h = cast(f32)key.(json.Object)["bounds"].(json.Object)["h"].(json.Integer),
					},
				},
			)
		}
		append(&aseprite.meta.slices, currentSlice)
	}
	return
}


import "core:testing"

@(test)
test_read_aseprite_json_file :: proc(_: ^testing.T) {
	// Note: Replace with your own test data or remove this test
	// I've created this test for validating the parser in my own project
	test_file := "assets/window.json"
	aseprite := ReadAsespriteJsonFile(test_file)
	assert(aseprite.frames["window.aseprite"].frame.x == 0)
	assert(aseprite.frames["window.aseprite"].frame.y == 0)
	assert(aseprite.frames["window.aseprite"].frame.w == 600)
	assert(aseprite.frames["window.aseprite"].frame.h == 200)
	assert(aseprite.frames["window.aseprite"].rotated == false)
	assert(aseprite.frames["window.aseprite"].trimmed == false)
	assert(aseprite.frames["window.aseprite"].spriteSourceSize.x == 0)
	assert(aseprite.frames["window.aseprite"].spriteSourceSize.y == 0)
	assert(aseprite.frames["window.aseprite"].spriteSourceSize.w == 600)
	assert(aseprite.frames["window.aseprite"].spriteSourceSize.h == 200)
	assert(aseprite.frames["window.aseprite"].sourceSize.w == 600)
	assert(aseprite.frames["window.aseprite"].sourceSize.h == 200)
	assert(aseprite.frames["window.aseprite"].duration == 100)

	assert(aseprite.meta.app == "http://www.aseprite.org/")
	// assert(aseprite.meta.version == "1.3.8.1-x64") // Version will change, was tested with Aseprite 1.3.8.1-x64
	assert(aseprite.meta.image == "window.png")
	assert(aseprite.meta.format == "RGBA8888")
	assert(aseprite.meta.size.w == 600)
	assert(aseprite.meta.size.h == 200)
	assert(aseprite.meta.scale == 1)
	assert(aseprite.meta.slices[0].name == "previous")
	assert(aseprite.meta.slices[0].color == "#0000ffff")
	assert(aseprite.meta.slices[0].keys[0].frame == 0)
	assert(aseprite.meta.slices[0].keys[0].bounds.x == 6)
	assert(aseprite.meta.slices[0].keys[0].bounds.y == 145)
	assert(aseprite.meta.slices[0].keys[0].bounds.w == 50)
	assert(aseprite.meta.slices[0].keys[0].bounds.h == 50)
}
