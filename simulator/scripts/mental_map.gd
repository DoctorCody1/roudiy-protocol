extends RefCounted
class_name MentalMap

var input_size: int = 16
var hidden_size: int = 12
var output_size: int = 16

var w_in: Array = []   # hidden_size x input_size
var w_out: Array = []  # output_size x hidden_size
var hidden_state: Array = []

var learning_rate: float = 0.02
var decay: float = 0.001

func _init(in_sz: int = 16, hid_sz: int = 12, out_sz: int = 16):
	input_size = in_sz
	hidden_size = hid_sz
	output_size = out_sz
	_init_weights()
	reset()

func _init_weights():
	var scale_in = sqrt(2.0 / (input_size + hidden_size))
	var scale_out = sqrt(2.0 / (hidden_size + output_size))
	w_in = _random_matrix(hidden_size, input_size, scale_in)
	w_out = _random_matrix(output_size, hidden_size, scale_out)

func _random_matrix(rows: int, cols: int, scale: float) -> Array:
	var m = []
	for i in range(rows):
		var row = []
		for j in range(cols):
			row.append(randf_range(-scale, scale))
		m.append(row)
	return m

func reset():
	hidden_state = []
	for i in range(hidden_size):
		hidden_state.append(0.0)

func _matrix_vector_mul(matrix: Array, vector: Array) -> Array:
	var result = []
	var vec_len = vector.size()
	for row in matrix:
		var sum = 0.0
		var row_len = row.size()
		var max_i = min(vec_len, row_len)
		for i in range(max_i):
			sum += row[i] * vector[i]
		result.append(sum)
	return result

func predict(input_vector: Array) -> Array:
	if input_vector.size() != input_size:
		var adj = []
		adj.resize(input_size)
		for i in range(input_size):
			adj[i] = input_vector[i] if i < input_vector.size() else 0.0
		input_vector = adj

	# hidden = tanh(w_in * input) — w_in имеет размер hidden_size x input_size
	var hidden = _matrix_vector_mul(w_in, input_vector)
	for i in range(hidden_size):
		hidden[i] = tanh(hidden[i])

	# output = tanh(w_out * hidden) — w_out имеет размер output_size x hidden_size
	var output = _matrix_vector_mul(w_out, hidden)
	for i in range(output_size):
		output[i] = tanh(output[i])

	hidden_state = hidden
	return output

func update_with_input(input_vector: Array, prediction: Array, target: Array, strength: float = 1.0):
	if prediction.size() != output_size or target.size() != output_size or input_vector.size() != input_size:
		return
	var error = []
	for i in range(output_size):
		error.append(target[i] - prediction[i])

	# Обновляем w_out (output_size x hidden_size)
	for i in range(output_size):
		for j in range(hidden_size):
			var delta = learning_rate * strength * error[i] * hidden_state[j]
			w_out[i][j] += delta - decay * w_out[i][j]

	# Обратное распространение до hidden
	var hidden_error = []
	for i in range(hidden_size):
		var sum = 0.0
		for j in range(output_size):
			sum += error[j] * w_out[j][i]   # w_out[j][i] — вес от hidden[i] к output[j]
		hidden_error.append(sum * (1.0 - hidden_state[i] * hidden_state[i]))

	# Обновляем w_in (hidden_size x input_size)
	for i in range(hidden_size):
		for j in range(input_size):
			var delta = learning_rate * strength * hidden_error[i] * input_vector[j]
			w_in[i][j] += delta - decay * w_in[i][j]

func mutate(rate: float = 0.05, strength: float = 0.3):
	_mutate_matrix(w_in, rate, strength)
	_mutate_matrix(w_out, rate, strength)

func _mutate_matrix(matrix: Array, rate: float, strength: float):
	for i in range(matrix.size()):
		for j in range(matrix[i].size()):
			if randf() < rate:
				matrix[i][j] += randf_range(-strength, strength)

func mix(other: MentalMap, fraction: float):
	_mix_matrices(w_in, other.w_in, fraction)
	_mix_matrices(w_out, other.w_out, fraction)

func _mix_matrices(a: Array, b: Array, fraction: float):
	for i in range(a.size()):
		for j in range(a[i].size()):
			if j < b[i].size():
				a[i][j] = a[i][j] * (1.0 - fraction) + b[i][j] * fraction

func clone() -> MentalMap:
	var new_map = MentalMap.new(input_size, hidden_size, output_size)
	new_map.w_in = _deep_copy(w_in)
	new_map.w_out = _deep_copy(w_out)
	new_map.hidden_state = hidden_state.duplicate()
	new_map.learning_rate = learning_rate
	new_map.decay = decay
	return new_map

func _deep_copy(matrix: Array) -> Array:
	var copy = []
	for row in matrix:
		copy.append(row.duplicate())
	return copy
