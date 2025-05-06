package main

import "core:math"
import "core:math/linalg"
import "core:math/linalg/glsl"
import "vendor:raylib"
/*

	Particle Emitter
	=================

	This is a simple Particle Emitter that can be used as a jumping off point for
	a more complex Particle Emitter.

	It isn't perfect and there is room for improvement, but it works well enough for
	a simple Particle Emitter.

	This is all done on the CPU. On my machine, it can create 11200 Particles at ~30 FPS from 200 emitters.

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

ParticleCollision :: enum {
	// The Particle is not affected by collisions
	None,
	// The Particle bounces off the bounds
	Bounce,
	// The Particle is destroyed on collision
	Destroy,
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
	// Whether the Particle Emitter is affected by wind
	is_wind:               bool,
	// Wind of the Particle Emitter
	wind:                  raylib.Vector2,
	// Whether the Particle Emitter is affected by drag
	is_drag:               bool,
	// Drag of the Particle Emitter
	drag:                  f32,
	// Collision type of the Particle Emitter
	collision:             ParticleCollision,
}

Circle :: struct {
	// The center of the Circle
	center: raylib.Vector2,
	// The radius of the Circle
	radius: f32,
}

CollissionShape :: union {
	// Rectangle
	raylib.Rectangle,
	// Circle
	Circle,
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

UpdateEmitter :: proc(
	emitter: ^Emitter,
	deltaTime: f32,
	circleBounds: []Circle = nil,
	rectBounds: []raylib.Rectangle = nil,
) {
	// Update the time since the last Particle
	emitter.timeSinceLastParticle += deltaTime

	// Check if the Particle Emitter is empty
	if len(emitter.Particles) == 0 {
		// Reset the Particle Emitter
		emitter.timeSinceLastParticle = emitter.timeBetweenParticles
	}

	// Check if it's time to create a new Particle
	shouldSpawn := emitter.timeSinceLastParticle >= emitter.timeBetweenParticles
	if shouldSpawn {
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
			if emitter.is_gravity {
				// Update the Particle position with gravity
				particle.velocity += emitter.gravity * deltaTime
			}
			if emitter.is_wind {
				// Update the Particle position with wind
				particle.velocity += emitter.wind * deltaTime
			}
			if emitter.is_drag {
				// Update the Particle position with drag
				particle.velocity -= particle.velocity * emitter.drag * deltaTime
			}

			// Check if the Particle collides with the bounds
			if len(circleBounds) > 0 {
				for bound in circleBounds {
					if raylib.CheckCollisionCircles(
						particle.position,
						particle.size,
						bound.center,
						bound.radius,
					) {
						switch emitter.collision {
						case ParticleCollision.Destroy:
							// Remove the Particle
							ordered_remove(&emitter.Particles, i)
							i = i - 1
						case ParticleCollision.Bounce:
							// Where on the Circle is the Particle
							collision_normal: raylib.Vector2
							collision_normal.x = particle.position.x - bound.center.x
							collision_normal.y = particle.position.y - bound.center.y
							// Adjust for the particle's size
							if glsl.length(collision_normal) < particle.size + bound.radius {
								// Normalize the collision normal
								collision_normal = glsl.normalize(collision_normal)
								// Reflect the Particle
								particle.velocity = glsl.reflect(
									particle.velocity,
									collision_normal,
								)
							}
						case ParticleCollision.None:
						}
					}
				}
			}
			if len(rectBounds) > 0 {
				for bound in rectBounds {
					if raylib.CheckCollisionCircleRec(particle.position, particle.size, bound) {
						switch emitter.collision {
						case ParticleCollision.Destroy:
							// Remove the Particle
							ordered_remove(&emitter.Particles, i)
							i = i - 1
						case ParticleCollision.Bounce:
							// Where on the Rectangle is the Particle
							collision_normal: raylib.Vector2
							if particle.position.x < bound.x {
								collision_normal.x = -1.0
							} else if particle.position.x > bound.x + bound.width {
								collision_normal.x = 1.0
							}
							if particle.position.y < bound.y {
								collision_normal.y = -1.0
							} else if particle.position.y > bound.y + bound.height {
								collision_normal.y = 1.0
							}
							// Reflect the Particle
							particle.velocity = glsl.reflect(particle.velocity, collision_normal)
							// Adjust for the particle's size
							if glsl.length(collision_normal) < particle.size {
								// Normalize the collision normal
								collision_normal = glsl.normalize(collision_normal)
								// Reflect the Particle
								particle.velocity = glsl.reflect(
									particle.velocity,
									collision_normal,
								)
							}
						case ParticleCollision.None:
						}
					}
				}
			}
			// Update the Particle position
			particle.position += particle.velocity * deltaTime
		}
	}
}


GetRandomVector2Direction :: proc() -> raylib.Vector2 {
	// Get a random direction
	angle := f32(raylib.GetRandomValue(0, 360)) * math.PI / 180.0
	return glsl.normalize(raylib.Vector2{glsl.cos(angle), glsl.sin(angle)})
}

reflect :: proc(dir, normal: raylib.Vector2) -> raylib.Vector2 {
	new_direction := glsl.reflect(dir, glsl.normalize(normal))
	return glsl.normalize(new_direction)
}
