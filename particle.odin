package main

import "core:math"
import "vendor:raylib"

/*

	Particle Emitter
	=================

	This is a simple Particle Emitter that can be used as a jumping off point for
	a more complex Particle Emitter.

	It isn't perfect and there is room for improvement, but it works well enough for
	a simple Particle Emitter.

	This is all done on the CPU. On my machine, it can create 11200 Particles at ~30 FPS.

	This is just single-threaded, so I'm sure it can be improved by using multiple threads.

	Usage
	=====
	1. Create a Particle Emitter
	2. Set the Particle Emitter properties
	3. Update the Particle Emitter
	4. Draw the Particle Emitter
	5. Repeat

	Example
	=======
	```odin
	import "core:math"
	import "vendor:raylib"

	Width: i32 = 800
	Height: i32 = 600

	main :: proc() {
		// Initialize the window
		raylib.InitWindow(Width, Height, "Particle Effect")
		defer raylib.CloseWindow()
		// Create a Particle Emitter
		emitter := Emitter {
			maxParticles         = 1000,
			timeBetweenParticles = 1,
			position             = {100, 100},
			size                 = 0.6,
			color                = raylib.ORANGE,
			lifetime             = 2,
			magnitude            = 5.0,
			is_gravity           = true,
			gravity              = raylib.Vector2{0, -25},
		}
		for !raylib.WindowShouldClose() {
			raylib.BeginDrawing()
			raylib.ClearBackground(raylib.BLACK)

			// Update the Particle Emitter
			deltaTime := raylib.GetFrameTime()
			// Update the Particle Emitter position
			emitter.position = raylib.GetMousePosition()
			// Update the Particle Emitter
			UpdateEmitter(&emitter, deltaTime)
			// Draw the Particle Emitter
			DrawEmitter(emitter)

			raylib.EndDrawing()
		}
	}
	```

*/

// A single particle
Particle :: struct {
	// The position of the Particle
	position: raylib.Vector2,
	// The velocity of the Particle
	velocity: raylib.Vector2,
	// The size of the Particle
	size:     f32,
	// The color of the Particle
	color:    raylib.Color,
	// The lifetime of the Particle
	lifetime: f32,
	// The age of the Particle
	age:      f32,
}

// The particle emitter
Emitter :: struct {
	// The list of Particles
	Particles:             [dynamic]Particle,
	// The maximum number of Particles
	maxParticles:          i32,
	// The time between each Particle
	timeBetweenParticles:  f32,
	// The time since the last Particle
	timeSinceLastParticle: f32,
	// The position of the Particle Emitter
	position:              raylib.Vector2,
	// The size of the Particle Emitter
	size:                  f32,
	// The color of the Particle Emitter
	color:                 raylib.Color,
	// The Emitter magnitude
	magnitude:             f32,
	// Lifetime of the Particle Emitter
	lifetime:              f32,
	// Whether the Particle Emitter is affected by gravity
	is_gravity:            bool,
	// Gravity of the Particle Emitter
	gravity:               raylib.Vector2,
}

DrawEmitter :: proc(emitter: Emitter) {
	for particle in emitter.Particles {
		// Draw the Particle
		raylib.DrawCircleV(
			particle.position,
			particle.size,
			raylib.ColorAlpha(particle.color, 1.0 - particle.age / particle.lifetime),
		)
	}
}

NewRandomParticle :: proc(emitter: ^Emitter) -> Particle {
	return Particle {
		position = emitter.position,
		velocity = GetRandomVector2Direction() * emitter.magnitude,
		size = emitter.size,
		color = emitter.color,
		lifetime = emitter.lifetime,
		age = 0.0,
	}
}

UpdateEmitter :: proc(emitter: ^Emitter, deltaTime: f32) {
	// Update the time since the last Particle
	emitter.timeSinceLastParticle += deltaTime

	// Check if the Particle Emitter is empty
	if len(emitter.Particles) == 0 {
		// Reset the Particle Emitter
		emitter.timeSinceLastParticle = 0.0
	}

	// Check if it's time to create a new Particle
	if emitter.timeSinceLastParticle >= emitter.timeBetweenParticles ||
	   len(emitter.Particles) < int(emitter.maxParticles) {
		// Create a new Particle
		Particle := NewRandomParticle(emitter)
		Particle.velocity += GetRandomVector2Direction() * emitter.magnitude
		append(&emitter.Particles, Particle)
		emitter.timeSinceLastParticle = 0.0
	}

	// Remove Particles if there are too many
	for len(emitter.Particles) > int(emitter.maxParticles) {
		// Remove the oldest Particle
		ordered_remove(&emitter.Particles, 0)
	}

	// Update the Particles
	for i := 0; i < len(emitter.Particles); i = i + 1 {
		particle := &emitter.Particles[i]
		particle.age += deltaTime

		// Check if the Particle is dead
		if particle.age >= particle.lifetime {
			// Remove the Particle
			ordered_remove(&emitter.Particles, i)
			i = i - 1
		} else {
			// Update the Particle position
			if emitter.is_gravity {
				// Update the Particle position with gravity
				particle.position += particle.velocity * deltaTime
				particle.velocity += emitter.gravity * deltaTime
			} else {
				// Update the Particle position without gravity
				particle.position += particle.velocity * deltaTime
			}
		}
	}
}


GetRandomVector2Direction :: proc() -> raylib.Vector2 {
	// Get a random direction
	angle := f32(raylib.GetRandomValue(0, 360)) * math.PI / 180.0
	return raylib.Vector2Normalize(raylib.Vector2{math.cos(angle), math.sin(angle)})
}
