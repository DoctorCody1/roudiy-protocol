extends RefCounted
class_name Ganglion

var gru: GRULayer
var input_size: int
var hidden_size: int
var output_size: int
var min_hidden: int = 4
var max_hidden: int = 64

var hebb_rate: float
var hebb_decay: float
var hebb_threshold: float
var hebb_momentum: float

func _init(in_size: int, hid_size: int, out_size: int,
		   h_rate: float = 0.01, h_decay: float = 0.001,
		   h_thresh: float = 0.1, h_momentum: float = 0.9):
	input_size = in_size
	hidden_size = clamp(hid_size, min_hidden, max_hidden)
	output_size = out_size
	hebb_rate = h_rate
	hebb_decay = h_decay
	hebb_threshold = h_thresh
	hebb_momentum = h_momentum
	gru = GRULayer.new(in_size, hidden_size, out_size,
					   hebb_rate, hebb_decay, hebb_threshold, hebb_momentum)

func forward(input_vector: Array) -> Array:
	return gru.forward(input_vector)

func hebb_update(strength: float = 1.0):
	gru.hebb_update(strength)

func reset():
	gru.reset()

func mutate(rate: float = 0.05, strength: float = 0.3):
	gru.mutate(rate, strength)
	# Мутация параметров Hebb (эволюция обучения)
	if randf() < 0.1:
		hebb_rate *= (1.0 + randf_range(-0.2, 0.2))
		hebb_rate = clamp(hebb_rate, 0.001, 0.1)
	if randf() < 0.1:
		hebb_decay *= (1.0 + randf_range(-0.2, 0.2))
		hebb_decay = clamp(hebb_decay, 0.0001, 0.01)
	if randf() < 0.1:
		hebb_threshold *= (1.0 + randf_range(-0.2, 0.2))
		hebb_threshold = clamp(hebb_threshold, 0.01, 0.5)

func mix_weights(other: Ganglion, fraction: float):
	gru.mix_weights(other.gru, fraction)
	# Также смешиваем параметры Hebb
	hebb_rate = hebb_rate * (1.0 - fraction) + other.hebb_rate * fraction
	hebb_decay = hebb_decay * (1.0 - fraction) + other.hebb_decay * fraction
	hebb_threshold = hebb_threshold * (1.0 - fraction) + other.hebb_threshold * fraction
	hebb_momentum = hebb_momentum * (1.0 - fraction) + other.hebb_momentum * fraction

func clone(mutate_arch: bool = true) -> Ganglion:
	var new_hidden = hidden_size
	if mutate_arch and randf() < 0.05:
		var change = (randi() % 3 + 1) * 2
		if randf() < 0.5:
			new_hidden = max(min_hidden, hidden_size - change)
		else:
			new_hidden = min(max_hidden, hidden_size + change)
	if new_hidden != hidden_size:
		var new_g = Ganglion.new(input_size, new_hidden, output_size,
								 hebb_rate, hebb_decay, hebb_threshold, hebb_momentum)
		new_g.mutate(0.1, 0.3)
		return new_g
	var g = Ganglion.new(input_size, hidden_size, output_size,
						 hebb_rate, hebb_decay, hebb_threshold, hebb_momentum)
	g.gru = gru.clone()
	return g

func get_size() -> Dictionary:
	return {
		"input": input_size,
		"hidden": hidden_size,
		"output": output_size
	}
