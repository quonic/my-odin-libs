package main

/*

A simple 2D vector library for the ODIN language.

Supports `f32` and `f64` vectors.

### Usage Example

```odin
// f32 vectors
v := vec2_f32{1, 2}
v2 := vec2_f32{3, 4}

// f32 vectors converted to f64
// v := vec2_to_f64(vec2_f32{1, 2})
// v2 := vec2_to_f64(vec2_f32{3, 4})

// f64 vectors
//v := vec2_f64{1, 2}
//v2 := vec2_f64{3, 4}


// Add two vectors
v3 := vec2_add(v, v2)

// Subtract two vectors
v4 := vec2_sub(v, v2)

// Multiply two vectors
v5 := vec2_mul(v, v2)

// Divide two vectors
v6 := vec2_div(v, v2)

// Dot product of two vectors
dot := vec2_dot(v, v2)

// Magnitude of a vector
mag := vec2_mag(v)

// Magnitude squared of a vector
mag_sqr := vec2_mag_sqr(v)

// Normalize a vector
norm := vec2_normalize(v)

// Linear interpolation between two vectors
lerp := vec2_lerp(v, v2, 0.5)

// Minimum of two vectors
min := vec2_min(v, v2)

// Maximum of two vectors
max := vec2_max(v, v2)
```

*/

import "base:intrinsics"
import "core:fmt"
import "core:math"
import "core:testing"

vec2 :: union {
	vec2_f32,
	vec2_f64,
}

vec2_f32 :: struct {
	x: f32,
	y: f32,
}

vec2_f64 :: struct {
	x: f64,
	y: f64,
}

// Conversions
vec2_convert :: proc {
	vec2_convert_to_f64,
	vec2_convert_to_f32,
}

vec2_convert_to_f64 :: proc(v: vec2_f32) -> vec2_f64 {
	return vec2_f64{f64(v.x), f64(v.y)}
}

vec2_convert_to_f32 :: proc(v: vec2_f64) -> vec2_f32 {
	return vec2_f32{f32(v.x), f32(v.y)}
}

vec2_cross_product :: proc {
	vec2_cross_product_f32,
	vec2_cross_product_f64,
}

vec2_cross_product_f32 :: proc(v: vec2_f32, w: vec2_f32) -> f32 {
	return v.x * w.y - v.y * w.x
}

vec2_cross_product_f64 :: proc(v: vec2_f64, w: vec2_f64) -> f64 {
	return v.x * w.y - v.y * w.x
}

vec2_add :: proc {
	vec2_f32_add,
	vec2_f64_add,
}

vec2_sub :: proc {
	vec2_f32_sub,
	vec2_f64_sub,
}

vec2_mul :: proc {
	vec2_f32_mul,
	vec2_f64_mul,
}

vec2_div :: proc {
	vec2_f32_div,
	vec2_f64_div,
}

vec2_mag :: proc {
	vec2_f32_mag,
	vec2_f64_mag,
}

vec2_dot :: proc {
	vec2_f32_dot,
	vec2_f64_dot,
}

vec2_min :: proc {
	vec2_f32_min,
	vec2_f64_min,
}

vec2_max :: proc {
	vec2_f32_max,
	vec2_f64_max,
}

vec2_lerp :: proc {
	vec2_f32_lerp,
	vec2_f64_lerp,
}

vec2_normalize :: proc {
	vec2_f32_normalize,
	vec2_f64_normalize,
}

vec2_mag_sqr :: proc {
	vec2_f32_mag_sqr,
	vec2_f64_mag_sqr,
}

// vec2_f32

vec2_f32_add :: proc(a: vec2_f32, b: vec2_f32) -> vec2_f32 {
	return vec2_f32{a.x + b.x, a.y + b.y}
}

vec2_f32_sub :: proc(a: vec2_f32, b: vec2_f32) -> vec2_f32 {
	return vec2_f32{a.x - b.x, a.y - b.y}
}

vec2_f32_mul :: proc(a: vec2_f32, b: vec2_f32) -> vec2_f32 {
	return vec2_f32{a.x * b.x, a.y * b.y}
}

vec2_f32_div :: proc(a: vec2_f32, b: vec2_f32) -> vec2_f32 {
	return vec2_f32{a.x / b.x, a.y / b.y}
}

vec2_f32_dot :: proc(a: vec2_f32, b: vec2_f32) -> f32 {
	return a.x * b.x + a.y * b.y
}

vec2_f32_mag :: proc(v: vec2_f32) -> f32 {
	return math.sqrt(v.x * v.x + v.y * v.y)
}

vec2_f32_mag_sqr :: proc(v: vec2_f32) -> f32 {
	return v.x * v.x + v.y * v.y
}

vec2_f32_normalize :: proc(v: vec2_f32) -> vec2_f32 {
	mag := vec2_f32_mag(v)
	if mag == 0.0 {
		return vec2_f32{0, 0}
	}
	return vec2_f32_div(v, vec2_f32{mag, mag})
}


vec2_f32_lerp :: proc(a: vec2_f32, b: vec2_f32, t: f32) -> vec2_f32 {
	return vec2_f32_add(
		vec2_f32_mul(a, vec2_f32{1.0 - t, 1.0 - t}),
		vec2_f32_mul(b, vec2_f32{t, t}),
	)
}


vec2_f32_min :: proc(a: vec2_f32, b: vec2_f32) -> vec2_f32 {
	return vec2_f32{math.min(a.x, b.x), math.min(a.y, b.y)}
}


vec2_f32_max :: proc(a: vec2_f32, b: vec2_f32) -> vec2_f32 {
	return vec2_f32{math.max(a.x, b.x), math.max(a.y, b.y)}
}


// vec2_f64

vec2_f64_add :: proc(a: vec2_f64, b: vec2_f64) -> vec2_f64 {
	return vec2_f64{a.x + b.x, a.y + b.y}
}


vec2_f64_sub :: proc(a: vec2_f64, b: vec2_f64) -> vec2_f64 {
	return vec2_f64{a.x - b.x, a.y - b.y}
}


vec2_f64_mul :: proc(a: vec2_f64, b: vec2_f64) -> vec2_f64 {
	return vec2_f64{a.x * b.x, a.y * b.y}
}


vec2_f64_div :: proc(a: vec2_f64, b: vec2_f64) -> vec2_f64 {
	return vec2_f64{a.x / b.x, a.y / b.y}
}


vec2_f64_dot :: proc(a: vec2_f64, b: vec2_f64) -> f64 {
	return a.x * b.x + a.y * b.y
}


vec2_f64_mag :: proc(v: vec2_f64) -> f64 {
	return math.sqrt(v.x * v.x + v.y * v.y)
}


vec2_f64_mag_sqr :: proc(v: vec2_f64) -> f64 {
	return v.x * v.x + v.y * v.y
}

vec2_f64_normalize :: proc(v: vec2_f64) -> vec2_f64 {
	mag := vec2_f64_mag(v)
	if mag == 0 {
		return vec2_f64{0, 0}
	}
	return vec2_f64{v.x / mag, v.y / mag}
}

vec2_f64_lerp :: proc(a: vec2_f64, b: vec2_f64, t: f64) -> vec2_f64 {
	return vec2_f64_add(
		vec2_f64_mul(a, vec2_f64{1.0 - t, 1.0 - t}),
		vec2_f64_mul(b, vec2_f64{t, t}),
	)
}

vec2_f64_min :: proc(a: vec2_f64, b: vec2_f64) -> vec2_f64 {
	return vec2_f64{math.min(a.x, b.x), math.min(a.y, b.y)}
}

vec2_f64_max :: proc(a: vec2_f64, b: vec2_f64) -> vec2_f64 {
	return vec2_f64{math.max(a.x, b.x), math.max(a.y, b.y)}
}

@(test)
test_vec2_f32_add :: proc(t: ^testing.T) {
	v := vec2_f32{1, 2}
	v2 := vec2_f32{3, 4}
	v3 := vec2_add(v, v2)
	assert(v3.x == 4)
	assert(v3.y == 6)
}

@(test)
test_vec2_f32_sub :: proc(t: ^testing.T) {
	v := vec2_f32{1, 2}
	v2 := vec2_f32{3, 4}
	v3 := vec2_sub(v, v2)
	assert(v3.x == -2)
	assert(v3.y == -2)
}

@(test)
test_vec2_f32_mul :: proc(t: ^testing.T) {
	v := vec2_f32{1, 2}
	v2 := vec2_f32{3, 4}
	v3 := vec2_mul(v, v2)
	assert(v3.x == 3)
	assert(v3.y == 8)
}

@(test)
test_vec2_f32_div :: proc(t: ^testing.T) {
	v := vec2_f32{1, 2}
	v2 := vec2_f32{3, 4}
	v3 := vec2_div(v, v2)
	assert(v3.x == 0.33333334)
	assert(v3.y == 0.5)
}

@(test)
test_vec2_convert_to_f64 :: proc(t: ^testing.T) {
	v := vec2_f32{1, 2}
	v2 := vec2_convert(v)
	assert(v2.x == 1.0)
	assert(v2.y == 2.0)
}

@(test)
test_vec2_convert_to_f32 :: proc(t: ^testing.T) {
	v := vec2_f64{1, 2}
	v2 := vec2_convert(v)
	assert(v2.x == 1.0)
	assert(v2.y == 2.0)
}

@(test)
test_vec2_f32_dot :: proc(t: ^testing.T) {
	v := vec2_f32{1, 2}
	v2 := vec2_f32{3, 4}
	dot := vec2_dot(v, v2)
	assert(dot == 11)
}

@(test)
test_vec2_f32_mag_sqr :: proc(t: ^testing.T) {
	v := vec2_f32{1, 2}
	mag_sqr := vec2_mag_sqr(v)
	assert(mag_sqr == 5)
}

@(test)
test_vec2_f32_mag :: proc(t: ^testing.T) {
	v := vec2_f32{1, 2}
	mag := vec2_mag(v)
	assert(mag <= 2.24 && mag >= 2.23, fmt.tprintf("Magnitude: %f not 2.236", mag))
}

@(test)
test_vec2_f32_normalize :: proc(t: ^testing.T) {
	v := vec2_f32{1, 2}
	v2 := vec2_normalize(v)
	assert(v2.x <= 0.45 && v2.x >= 0.44, fmt.tprintf("x: %f", v2.x))
	assert(v2.y >= 0.87 && v2.y >= 0.89, fmt.tprintf("y: %f", v2.y))
}

@(test)
test_vec2_f32_lerp :: proc(t: ^testing.T) {
	v := vec2_f32{1, 2}
	v2 := vec2_f32{3, 4}
	lerp := vec2_lerp(v, v2, 0.5)
	assert(lerp.x == 2)
	assert(lerp.y == 3)
}

@(test)
test_vec2_f32_min :: proc(t: ^testing.T) {
	v := vec2_f32{1, 2}
	v2 := vec2_f32{3, 4}
	min := vec2_min(v, v2)
	assert(min.x == 1)
	assert(min.y == 2)
}

@(test)
test_vec2_f32_max :: proc(t: ^testing.T) {
	v := vec2_f32{1, 2}
	v2 := vec2_f32{3, 4}
	max := vec2_max(v, v2)
	assert(max.x == 3)
	assert(max.y == 4)
}

@(test)
test_vec2_f64_add :: proc(t: ^testing.T) {
	v := vec2_f64{1, 2}
	v2 := vec2_f64{3, 4}
	v3 := vec2_add(v, v2)
	assert(v3.x == 4)
	assert(v3.y == 6)
}

@(test)
test_vec2_f64_sub :: proc(t: ^testing.T) {
	v := vec2_f64{1, 2}
	v2 := vec2_f64{3, 4}
	v3 := vec2_sub(v, v2)
	assert(v3.x == -2)
	assert(v3.y == -2)
}

@(test)
test_vec2_f64_mul :: proc(t: ^testing.T) {
	v := vec2_f64{1, 2}
	v2 := vec2_f64{3, 4}
	v3 := vec2_mul(v, v2)
	assert(v3.x == 3)
	assert(v3.y == 8)
}

@(test)
test_vec2_f64_div :: proc(t: ^testing.T) {
	v := vec2_f64{1, 2}
	v2 := vec2_f64{3, 4}
	v3 := vec2_div(v, v2)
	assert(v3.x <= 0.334 && v3.x >= 0.332, fmt.tprintf("x: %f", v3.x))
	assert(v3.y == 0.5, fmt.tprintf("y: %f", v3.y))
}

@(test)
test_vec2_f64_dot :: proc(t: ^testing.T) {
	v := vec2_f64{1, 2}
	v2 := vec2_f64{3, 4}
	dot := vec2_dot(v, v2)
	assert(dot == 11)
}

@(test)
test_vec2_f64_mag :: proc(t: ^testing.T) {
	v := vec2_f64{1, 2}
	mag := vec2_mag(v)
	assert(mag <= 2.24 && mag >= 2.23, fmt.tprintf("Magnitude: %f not 2.236", mag))
}

@(test)
test_vec2_f64_mag_sqr :: proc(t: ^testing.T) {
	v := vec2_f64{1, 2}
	mag_sqr := vec2_mag_sqr(v)
	assert(mag_sqr == 5)
}

@(test)
test_vec2_f64_normalize :: proc(t: ^testing.T) {
	v := vec2_f64{1, 2}
	v2 := vec2_normalize(v)
	assert(v2.x <= 0.45 && v2.x >= 0.44, fmt.tprintf("x: %f", v2.x))
	assert(v2.y >= 0.87 && v2.y >= 0.89, fmt.tprintf("y: %f", v2.y))
}

@(test)
test_vec2_f64_lerp :: proc(t: ^testing.T) {
	v := vec2_f64{1, 2}
	v2 := vec2_f64{3, 4}
	lerp := vec2_lerp(v, v2, 0.5)
	assert(lerp.x == 2)
	assert(lerp.y == 3)
}

@(test)
test_vec2_f64_min :: proc(t: ^testing.T) {
	v := vec2_f64{1, 2}
	v2 := vec2_f64{3, 4}
	min := vec2_min(v, v2)
	assert(min.x == 1)
	assert(min.y == 2)
}

@(test)
test_vec2_f64_max :: proc(t: ^testing.T) {
	v := vec2_f64{1, 2}
	v2 := vec2_f64{3, 4}
	max := vec2_max(v, v2)
	assert(max.x == 3)
	assert(max.y == 4)
}

@(test)
test_vec2_convert :: proc(t: ^testing.T) {
	v := vec2_f32{1, 2}
	v2 := vec2_convert(v)
	assert(v2.x == 1.0)
	assert(v2.y == 2.0)

	v3 := vec2_convert(v2)
	assert(v3.x == 1.0)
	assert(v3.y == 2.0)
}

@(test)
test_vec2_cross_product :: proc(t: ^testing.T) {
	assert(vec2_cross_product(vec2_f32{1.0, 2.0}, vec2_f32{3.0, 4.0}) == -2.0)
	assert(vec2_cross_product_f64(vec2_f64{1.0, 2.0}, vec2_f64{3.0, 4.0}) == -2.0)
}
