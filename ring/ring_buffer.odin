package ring

RingBuffer :: struct($T: typeid) {
	data:  []T,
	head:  int,
	count: int,
}

MakeRingBuffer :: proc($T: typeid, capacity: int) -> RingBuffer(T) {
	rb := RingBuffer(T){}
	if capacity <= 0 {
		return rb
	}

	rb.data = make([]T, capacity)
	return rb
}

FreeRingBuffer :: proc(rb: ^RingBuffer($T)) {
	if rb == nil {
		return
	}

	delete(rb.data)
	rb.data = nil
	rb.head = 0
	rb.count = 0
}

ClearRingBuffer :: proc(rb: ^RingBuffer($T)) {
	if rb == nil {
		return
	}

	rb.head = 0
	rb.count = 0
}

RingBufferLen :: proc(rb: ^RingBuffer($T)) -> int {
	if rb == nil {
		return 0
	}

	return rb.count
}

RingBufferCap :: proc(rb: ^RingBuffer($T)) -> int {
	if rb == nil {
		return 0
	}

	return len(rb.data)
}

RingBufferIsFull :: proc(rb: ^RingBuffer($T)) -> bool {
	capacity := RingBufferCap(rb)
	return capacity > 0 && RingBufferLen(rb) == capacity
}

RingBufferAppend :: proc(rb: ^RingBuffer($T), value: T) -> (did_overwrite: bool) {
	capacity := RingBufferCap(rb)
	if rb == nil || capacity == 0 {
		return false
	}

	write_index := (rb.head + rb.count) % capacity
	if rb.count == capacity {
		write_index = rb.head
		rb.head = (rb.head + 1) % capacity
		did_overwrite = true
	} else {
		rb.count += 1
	}

	rb.data[write_index] = value
	return did_overwrite
}

RingBufferAt :: proc(rb: ^RingBuffer($T), logical_index: int) -> (value: ^T, ok: bool) {
	if rb == nil || logical_index < 0 || logical_index >= rb.count {
		return nil, false
	}

	physical_index := (rb.head + logical_index) % len(rb.data)
	return &rb.data[physical_index], true
}

RingBufferFirst :: proc(rb: ^RingBuffer($T)) -> (value: ^T, ok: bool) {
	return RingBufferAt(rb, 0)
}

RingBufferLast :: proc(rb: ^RingBuffer($T)) -> (value: ^T, ok: bool) {
	return RingBufferAt(rb, RingBufferLen(rb) - 1)
}
