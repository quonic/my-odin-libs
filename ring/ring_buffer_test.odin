package ring

import "core:testing"

@(test)
ring_buffer_partial_fill_preserves_order :: proc(t: ^testing.T) {
	_ = t
	rb := MakeRingBuffer(int, 4)
	defer FreeRingBuffer(&rb)

	_ = RingBufferAppend(&rb, 10)
	_ = RingBufferAppend(&rb, 20)
	_ = RingBufferAppend(&rb, 30)

	assert(RingBufferLen(&rb) == 3, "expected len 3 after three appends")
	assert(!RingBufferIsFull(&rb), "buffer should not be full yet")

	first, first_ok := RingBufferFirst(&rb)
	last, last_ok := RingBufferLast(&rb)
	assert(first_ok, "expected first element to exist")
	assert(last_ok, "expected last element to exist")
	assert(first^ == 10, "expected oldest element to be 10")
	assert(last^ == 30, "expected newest element to be 30")

	expected_values := [?]int{10, 20, 30}
	for expected, i in expected_values {
		value, ok := RingBufferAt(&rb, i)
		assert(ok, "expected logical index to resolve")
		assert(value^ == expected, "expected logical ordering to match append order")
	}
}

@(test)
ring_buffer_overwrite_keeps_latest_values :: proc(t: ^testing.T) {
	_ = t
	rb := MakeRingBuffer(int, 3)
	defer FreeRingBuffer(&rb)

	assert(!RingBufferAppend(&rb, 1), "first append should not overwrite")
	assert(!RingBufferAppend(&rb, 2), "second append should not overwrite")
	assert(!RingBufferAppend(&rb, 3), "third append should not overwrite")
	assert(RingBufferIsFull(&rb), "buffer should report full at capacity")
	assert(RingBufferAppend(&rb, 4), "append past capacity should overwrite oldest value")

	expected_values := [?]int{2, 3, 4}
	for expected, i in expected_values {
		value, ok := RingBufferAt(&rb, i)
		assert(ok, "expected wrapped logical index to resolve")
		assert(value^ == expected, "expected overwrite to discard only the oldest value")
	}
}

@(test)
ring_buffer_wraparound_updates_first_and_last :: proc(t: ^testing.T) {
	_ = t
	rb := MakeRingBuffer(int, 2)
	defer FreeRingBuffer(&rb)

	_ = RingBufferAppend(&rb, 7)
	_ = RingBufferAppend(&rb, 8)
	_ = RingBufferAppend(&rb, 9)
	_ = RingBufferAppend(&rb, 10)

	first, first_ok := RingBufferFirst(&rb)
	last, last_ok := RingBufferLast(&rb)
	assert(first_ok, "expected first element after wraparound")
	assert(last_ok, "expected last element after wraparound")
	assert(first^ == 9, "expected first visible element to be 9 after wraparound")
	assert(last^ == 10, "expected last visible element to be 10 after wraparound")

	missing, ok := RingBufferAt(&rb, -1)
	assert(!ok, "negative logical indices must fail")
	assert(missing == nil, "failed lookups should return nil pointer")
}

@(test)
ring_buffer_clear_resets_logical_contents :: proc(t: ^testing.T) {
	_ = t
	rb := MakeRingBuffer(int, 5)
	defer FreeRingBuffer(&rb)

	_ = RingBufferAppend(&rb, 42)
	_ = RingBufferAppend(&rb, 99)
	ClearRingBuffer(&rb)

	assert(RingBufferLen(&rb) == 0, "clear should reset length to zero")
	assert(!RingBufferIsFull(&rb), "cleared buffer should not be full")
	first, ok := RingBufferFirst(&rb)
	assert(!ok, "cleared buffer should not have a first element")
	assert(first == nil, "cleared buffer should return nil for first element")
}
