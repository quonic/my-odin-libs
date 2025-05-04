package main

/*

A simple audio engine for the ODIN language that uses `vendor:miniaudio`.
Allows you to play sounds as well as manage loops and music.

Miniaudio is a cross-platform audio library that uses a callback-based API.
It runs on a separate thread from the main program, so it doesn't block the main thread.
This reduces the risk of audio glitches and makes it easier to manage audio resources.

### Usage

```odin
// To use this audio engine, you must first initialize the audio engine with the `initAudio` function.
initAudio()
defer shutdownAudio()
// After initializing the audio engine, you can add audio assets with the `addAudioAsset` function.
addAudioAsset("mySound", "path/to/my/sound.wav")
// You can then play sounds with the `playSound` function.
playSound("mySound")
```

*/

import "core:fmt"
import "core:os"
import "core:strings"
import "core:testing"
import "vendor:miniaudio"

// Audio Asset Struct
AudioAsset :: struct {
	name:    string,
	path:    string,
	sound:   miniaudio.sound,
	isLoop:  bool,
	isMusic: bool,
	volume:  f32,
}

// Set to true to panic instead of printing error messages
AUDIO_SHOULD_PANIC :: false

audioAssets: [dynamic]AudioAsset
audioengineConfig: miniaudio.engine_config
audioEngine: miniaudio.engine


// Get Audio Asset by Name
getAudioAsset :: proc(name: string) -> ^AudioAsset {
	for i := 0; i < len(audioAssets); i += 1 {
		if strings.to_lower(audioAssets[i].name) == strings.to_lower(name) {
			return &audioAssets[i]
		}
	}
	return nil
}

// Initializes the audio engine
initAudio :: proc(volume: f32 = 1, gain: f32 = 0, sampleRate: u32 = 44100) {

	// Initialize audio engine
	audioengineConfig = miniaudio.engine_config_init()
	audioengineConfig.sampleRate = sampleRate
	result: miniaudio.result = miniaudio.engine_init(&audioengineConfig, &audioEngine)
	assert(checkAudioResult(result), "initAudio: Failed to initialize audio engine")

	// Start audio engine (required for all sounds)
	result = miniaudio.engine_start(&audioEngine)
	assert(checkAudioResult(result), "initAudio: Failed to start audio engine")
	result = miniaudio.engine_set_volume(&audioEngine, volume)
	assert(checkAudioResult(result), "initAudio: Failed to set audio engine volume")
	result = miniaudio.engine_set_gain_db(&audioEngine, gain)
	assert(checkAudioResult(result), "initAudio: Failed to set audio engine gain")
}

/*
Adds an audio asset to the audio engine

### Parameters

#### Required: `Name`, `Path`
* Name: Name of the audio asset
* Path: Path to the audio asset
#### Optional: `Loop`, `Music`, `Volume`
* isLoop: Whether the audio asset is a loop
* isMusic: Whether the audio asset is music
* volume: Volume of the audio asset
*/
addAudioAsset :: proc(
	name: string,
	path: string,
	isLoop: bool = false,
	isMusic: bool = false,
	volume: f32 = 1,
) -> bool {
	if name == "" {
		fmt.eprintfln("addAudioAsset: Audio asset name is empty")
		return false
	}
	if path == "" {
		fmt.eprintln("addAudioAsset: Audio asset path is empty")
		return false
	}
	if !os.exists(path) {
		fmt.eprintln("addAudioAsset: Audio asset does not exist: %s", path)
		return false
	}
	asset: AudioAsset = {
		name    = name,
		path    = path,
		sound   = miniaudio.sound{},
		isLoop  = isLoop,
		isMusic = isMusic,
		volume  = volume,
	}
	result: miniaudio.result
	append(&audioAssets, asset)
	if isMusic {
		result = miniaudio.sound_init_from_file(
			&audioEngine,
			fmt.caprint(asset.path),
			miniaudio.sound_flags{miniaudio.sound_flag.DECODE},
			nil,
			nil,
			&asset.sound,
		)
	} else {
		result = miniaudio.sound_init_from_file(
			&audioEngine,
			fmt.caprint(asset.path),
			miniaudio.sound_flags{miniaudio.sound_flag.DECODE, miniaudio.sound_flag.STREAM},
			nil,
			nil,
			&asset.sound,
		)
	}
	assert(checkAudioResult(result), "initAudio: Failed to load audio asset")

	// Set looping and volume for audio asset
	miniaudio.sound_set_looping(&asset.sound, cast(b32)asset.isLoop)
	miniaudio.sound_set_volume(&asset.sound, asset.volume)

	return true
}

// Shutdown Audio Engine
shutdownAudio :: proc() {
	// Stop audio engine
	result: miniaudio.result = miniaudio.engine_stop(&audioEngine)
	assert(checkAudioResult(result), "shutdownAudio: Failed to stop audio engine")

	// Unload sounds
	for i := 0; i < len(audioAssets); i += 1 {
		miniaudio.sound_uninit(&audioAssets[i].sound)
	}

	// Uninitialize audio engine
	miniaudio.engine_uninit(&audioEngine)
	audioAssets = nil
}

// Start Loop by Name
startLoop :: proc(name: string) {
	result: miniaudio.result
	for i := 0; i < len(audioAssets); i += 1 {
		if audioAssets[i].name == name &&
		   audioAssets[i].isLoop &&
		   !audioAssets[i].isMusic &&
		   !miniaudio.sound_is_playing(&audioAssets[i].sound) {
			result = miniaudio.sound_start(&audioAssets[i].sound)
			assert(checkAudioResult(result), "startLoop: Failed to start loop")
		}
	}
}

// Restarts Loop by Name
restartLoop :: proc(name: string) {
	result: miniaudio.result
	for i := 0; i < len(audioAssets); i += 1 {
		if audioAssets[i].name == name &&
		   audioAssets[i].isLoop &&
		   !audioAssets[i].isMusic &&
		   miniaudio.sound_is_playing(&audioAssets[i].sound) {
			result = miniaudio.sound_stop(&audioAssets[i].sound)
			assert(checkAudioResult(result), "restartLoop: Failed to stop loop")
			result = miniaudio.sound_seek_to_pcm_frame(&audioAssets[i].sound, 0)
			assert(checkAudioResult(result), "restartLoop: Failed to reset loop")
			result = miniaudio.sound_start(&audioAssets[i].sound)
			assert(checkAudioResult(result), "restartLoop: Failed to start loop")
		}
	}
}

// Pauses all Loops
pauseLoops :: proc() {
	result: miniaudio.result
	for i := 0; i < len(audioAssets); i += 1 {
		if audioAssets[i].isLoop &&
		   !audioAssets[i].isMusic &&
		   miniaudio.sound_is_playing(&audioAssets[i].sound) {
			result = miniaudio.sound_stop(&audioAssets[i].sound)
			assert(checkAudioResult(result), "pauseLoops: Failed to pause music")
		}
	}
}
// Stops Loop by Name
stopLoop :: proc(name: string) {
	result: miniaudio.result
	for i := 0; i < len(audioAssets); i += 1 {
		if audioAssets[i].name == name &&
		   audioAssets[i].isLoop &&
		   !audioAssets[i].isMusic &&
		   miniaudio.sound_is_playing(&audioAssets[i].sound) {
			result = miniaudio.sound_stop(&audioAssets[i].sound)
			assert(checkAudioResult(result), "stopLoop: Failed to stop loop")
			result = miniaudio.sound_seek_to_pcm_frame(&audioAssets[i].sound, 0)
			assert(checkAudioResult(result), "stopLoop: Failed to reset loop")
		}
	}
}

// Starts Music by Name
startMusic :: proc(name: string) {
	result: miniaudio.result
	for i := 0; i < len(audioAssets); i += 1 {
		if audioAssets[i].name == name &&
		   audioAssets[i].isMusic &&
		   !miniaudio.sound_is_playing(&audioAssets[i].sound) {
			result = miniaudio.sound_start(&audioAssets[i].sound)
			assert(checkAudioResult(result), "startMusic: Failed to start music")
		}
	}
}

// Restarts Music by Name
restartMusic :: proc(name: string) {
	result: miniaudio.result
	for i := 0; i < len(audioAssets); i += 1 {
		if audioAssets[i].name == name &&
		   audioAssets[i].isMusic &&
		   miniaudio.sound_is_playing(&audioAssets[i].sound) {
			result = miniaudio.sound_stop(&audioAssets[i].sound)
			assert(checkAudioResult(result), "restartMusic: Failed to stop music")
			result = miniaudio.sound_seek_to_pcm_frame(&audioAssets[i].sound, 0)
			assert(checkAudioResult(result), "restartMusic: Failed to reset loop")
			result = miniaudio.sound_start(&audioAssets[i].sound)
			assert(checkAudioResult(result), "restartMusic: Failed to start music")
		}
	}
}

// Pauses Music by Name
pauseMusic :: proc(name: string) {
	result: miniaudio.result
	for i := 0; i < len(audioAssets); i += 1 {
		if audioAssets[i].isMusic && miniaudio.sound_is_playing(&audioAssets[i].sound) {
			result = miniaudio.sound_stop(&audioAssets[i].sound)
			assert(checkAudioResult(result), "pauseMusic: Failed to stop music")
		}
	}
}

// Stops all Music
stopMusic :: proc() {
	result: miniaudio.result
	for i := 0; i < len(audioAssets); i += 1 {
		if audioAssets[i].isMusic && miniaudio.sound_is_playing(&audioAssets[i].sound) {
			result = miniaudio.sound_stop(&audioAssets[i].sound)
			assert(checkAudioResult(result), "stopMusic: Failed to stop music")
			result = miniaudio.sound_seek_to_pcm_frame(&audioAssets[i].sound, 0)
			audioAssets[i].sound.seekTarget = 0
			assert(checkAudioResult(result), "stopMusic: Failed to reset loop")
		}
	}
}

// Plays Sound by Name with Volume, Pan, and Pitch options
playSound :: proc(name: string, volume: f32 = 1, pan: f32 = 0, pitch: f32 = 1) {
	result: miniaudio.result
	for i := 0; i < len(audioAssets); i += 1 {
		if audioAssets[i].name == name {
			// Check if sound is playing
			if !miniaudio.sound_is_playing(&audioAssets[i].sound) {
				// Start sound
				miniaudio.sound_set_volume(&audioAssets[i].sound, volume)
				miniaudio.sound_set_pan(&audioAssets[i].sound, pan)
				miniaudio.sound_set_pitch(&audioAssets[i].sound, pitch)
				result = miniaudio.sound_start(&audioAssets[i].sound)
				assert(checkAudioResult(result), "playSound: Failed to start sound")
			} else {
				// Restart sound
				// sound_seek_to_pcm_frame resets the sound to the beginning
				miniaudio.sound_seek_to_pcm_frame(&audioAssets[i].sound, 0)
				miniaudio.sound_set_volume(&audioAssets[i].sound, volume)
				miniaudio.sound_set_pan(&audioAssets[i].sound, pan)
				miniaudio.sound_set_pitch(&audioAssets[i].sound, pitch)
				result = miniaudio.sound_start(&audioAssets[i].sound)
				assert(checkAudioResult(result), "playSound: Failed to restart sound")
			}
		}
	}
}

// Stops All Sounds
stopAllSounds :: proc() {
	result: miniaudio.result
	for i := 0; i < len(audioAssets); i += 1 {
		if miniaudio.sound_is_playing(&audioAssets[i].sound) {
			result = miniaudio.sound_stop(&audioAssets[i].sound)
			assert(checkAudioResult(result), "stopAllSounds: Failed to stop loop")
			result = miniaudio.sound_seek_to_pcm_frame(&audioAssets[i].sound, 0)
			assert(checkAudioResult(result), "stopAllSounds: Failed to reset loop")
		}
	}
}

// Check results from miniaudio
//
// Returns true if the result is SUCCESS.
// Otherwise, prints the error message to stderr and returns false
//
// Setting AUDIO_SHOULD_PANIC to true will cause the program to panic instead of printing the error message.
//
// Exmaple:
// ```
//  result := miniaudio.sound_start(&sound)
//  assert(checkAudioResult(result), "Failed to start sound")
// ```
checkAudioResult :: proc(result: miniaudio.result) -> bool {
	// Returns true if the result is SUCCESS
	// Otherwise, prints the error message to stderr and returns false
	// Change as needed

	// Error messages
	errorMessage: string

	// Switch on the result
	switch result {
	case .SUCCESS:
		return true
	case .ADDRESS_FAMILY_NOT_SUPPORTED:
		errorMessage = "MINIAUDIO: Address family not supported"
	case .ALREADY_CONNECTED:
		errorMessage = "MINIAUDIO: Already connected"
	case .ALREADY_EXISTS:
		errorMessage = "MINIAUDIO: Already exists"
	case .API_NOT_FOUND:
		errorMessage = "MINIAUDIO: API not found"
	case .AT_END:
		errorMessage = "MINIAUDIO: At end"
	case .BAD_ADDRESS:
		errorMessage = "MINIAUDIO: Bad address"
	case .ACCESS_DENIED:
		errorMessage = "MINIAUDIO: Access denied"
	case .ALREADY_IN_USE:
		errorMessage = "MINIAUDIO: Already in use"
	case .BACKEND_NOT_ENABLED:
		errorMessage = "MINIAUDIO: Backend not enabled"
	case .BAD_MESSAGE:
		errorMessage = "MINIAUDIO: Bad message"
	case .BAD_PROTOCOL:
		errorMessage = "MINIAUDIO: Bad protocol"
	case .BAD_PIPE:
		errorMessage = "MINIAUDIO: Bad pipe"
	case .BAD_SEEK:
		errorMessage = "MINIAUDIO: Bad seek"
	case .BUSY:
		errorMessage = "MINIAUDIO: Busy"
	case .CANCELLED:
		errorMessage = "MINIAUDIO: Cancelled"
	case .CONNECTION_REFUSED:
		errorMessage = "MINIAUDIO: Connection refused"
	case .CONNECTION_RESET:
		errorMessage = "MINIAUDIO: Connection reset"
	case .CRC_MISMATCH:
		errorMessage = "MINIAUDIO: CRC mismatch"
	case .DEADLOCK:
		errorMessage = "MINIAUDIO: Deadlock"
	case .DEVICE_ALREADY_INITIALIZED:
		errorMessage = "MINIAUDIO: Device already initialized"
	case .DEVICE_NOT_INITIALIZED:
		errorMessage = "MINIAUDIO: Device not initialized"
	case .DEVICE_NOT_STARTED:
		errorMessage = "MINIAUDIO: Device not started"
	case .DEVICE_NOT_STOPPED:
		errorMessage = "MINIAUDIO: Device not stopped"
	case .DEVICE_TYPE_NOT_SUPPORTED:
		errorMessage = "MINIAUDIO: Device type not supported"
	case .DIRECTORY_NOT_EMPTY:
		errorMessage = "MINIAUDIO: Directory not empty"
	case .DOES_NOT_EXIST:
		errorMessage = "MINIAUDIO: Does not exist"
	case .ERROR:
		errorMessage = "MINIAUDIO: Error"
	case .FAILED_TO_INIT_BACKEND:
		errorMessage = "MINIAUDIO: Failed to init backend"
	case .FAILED_TO_OPEN_BACKEND_DEVICE:
		errorMessage = "MINIAUDIO: Failed to open backend device"
	case .FAILED_TO_START_BACKEND_DEVICE:
		errorMessage = "MINIAUDIO: Failed to start backend device"
	case .FAILED_TO_STOP_BACKEND_DEVICE:
		errorMessage = "MINIAUDIO: Failed to stop backend device"
	case .FORMAT_NOT_SUPPORTED:
		errorMessage = "MINIAUDIO: Format not supported"
	case .IN_PROGRESS:
		errorMessage = "MINIAUDIO: In progress"
	case .INVALID_ARGS:
		errorMessage = "MINIAUDIO: Invalid args"
	case .INVALID_OPERATION:
		errorMessage = "MINIAUDIO: Invalid operation"
	case .INTERRUPT:
		errorMessage = "MINIAUDIO: Interrupt"
	case .INVALID_DATA:
		errorMessage = "MINIAUDIO: Invalid data"
	case .INVALID_FILE:
		errorMessage = "MINIAUDIO: Invalid file"
	case .INVALID_DEVICE_CONFIG:
		errorMessage = "MINIAUDIO: Invalid device config"
	case .IO_ERROR:
		errorMessage = "MINIAUDIO: IO error"
	case .IS_DIRECTORY:
		errorMessage = "MINIAUDIO: Is directory"
	case .LOOP:
		errorMessage = "MINIAUDIO: Loop"
	case .MEMORY_ALREADY_MAPPED:
		errorMessage = "MINIAUDIO: Memory already mapped"
	case .NAME_TOO_LONG:
		errorMessage = "MINIAUDIO: Name too long"
	case .NO_DEVICE:
		errorMessage = "MINIAUDIO: No device"
	case .NO_ADDRESS:
		errorMessage = "MINIAUDIO: No address"
	case .NO_DATA_AVAILABLE:
		errorMessage = "MINIAUDIO: No data available"
	case .NO_BACKEND:
		errorMessage = "MINIAUDIO: No backend"
	case .NO_HOST:
		errorMessage = "MINIAUDIO: No host"
	case .NO_MESSAGE:
		errorMessage = "MINIAUDIO: No message"
	case .NO_NETWORK:
		errorMessage = "MINIAUDIO: No network"
	case .NO_SPACE:
		errorMessage = "MINIAUDIO: No space"
	case .NOT_CONNECTED:
		errorMessage = "MINIAUDIO: Not connected"
	case .NOT_IMPLEMENTED:
		errorMessage = "MINIAUDIO: Not implemented"
	case .NOT_DIRECTORY:
		errorMessage = "MINIAUDIO: Not directory"
	case .NOT_SOCKET:
		errorMessage = "MINIAUDIO: Not socket"
	case .NOT_UNIQUE:
		errorMessage = "MINIAUDIO: Not unique"
	case .OUT_OF_MEMORY:
		errorMessage = "MINIAUDIO: Out of memory"
	case .OUT_OF_RANGE:
		errorMessage = "MINIAUDIO: Out of range"
	case .PATH_TOO_LONG:
		errorMessage = "MINIAUDIO: Path too long"
	case .PROTOCOL_FAMILY_NOT_SUPPORTED:
		errorMessage = "MINIAUDIO: Protocol family not supported"
	case .PROTOCOL_NOT_SUPPORTED:
		errorMessage = "MINIAUDIO: Protocol not supported"
	case .PROTOCOL_UNAVAILABLE:
		errorMessage = "MINIAUDIO: Protocol unavailable"
	case .SHARE_MODE_NOT_SUPPORTED:
		errorMessage = "MINIAUDIO: Share mode not supported"
	case .SOCKET_NOT_SUPPORTED:
		errorMessage = "MINIAUDIO: Socket not supported"
	case .TIMEOUT:
		errorMessage = "MINIAUDIO: Timeout"
	case .TOO_BIG:
		errorMessage = "MINIAUDIO: Too big"
	case .TOO_MANY_LINKS:
		errorMessage = "MINIAUDIO: Too many links"
	case .TOO_MANY_OPEN_FILES:
		errorMessage = "MINIAUDIO: Too many open files"
	case .UNAVAILABLE:
		errorMessage = "MINIAUDIO: Unavailable"
	}

	when AUDIO_SHOULD_PANIC {
		panic(errorMessage)
	} else {
		fmt.eprintln(errorMessage)
	}

	return false
}

test_wav_path := fmt.tprintf("%s/test.wav", os.get_current_directory())

@(test)
test_music :: proc(t: ^testing.T) {
	initAudio()
	assert(
		addAudioAsset("test", test_wav_path, true, true, 0),
		"addAudioAsset: Failed to add test asset",
	)
	startMusic("test")
	restartMusic("test")
	pauseMusic("test")
	shutdownAudio()
}
