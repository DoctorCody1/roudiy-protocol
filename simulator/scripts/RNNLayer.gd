extends RefCounted
class_name RNNLayer

var input_size: int
var hidden_size: int
var output_size: int

var w_ih: Array = []   # input → hidden
var w_hh: Array = []   # hidden → hidden (recurrent)
var w_ho: Array = []   # hidden → output

var hidden_state: Array = []
var output_state: Array = []

func _init(in_size: int, hid_size: int, out_size: int):
	input_size = in_size
	hidden_size = hid_size
	output_size = out_size
	_init_weights()
	reset()

func _init_weights():
	var scale_ih = sqrt(2.0 / (input_size + hidden_size))
	var scale_hh = sqrt(2.0 / (hidden_size + hidden_size))
	var scale_ho = sqrt(2.0 / (hidden_size + output_size))
	w_ih = _random_matrix(input_size, hidden_size, scale_ih)
	w_hh = _random_matrix(hidden_size, hidden_size, scale_hh)
	w_ho = _random_matrix(hidden_size, output_size, scale_ho)

func _random_matrix(rows: int, cols: int, scale: float) -> Array:
	var matrix = []
	for i in range(rows):
		var row = []
		for j in range(cols):
			row.append(randf_range(-scale, scale))
		matrix.append(row)
	return matrix

func reset():
	hidden_state = []
	for i in range(hidden_size):
		hidden_state.append(0.0)
	output_state = []
	for i in range(output_size):
		output_state.append(0.0)

func forward(input_vector: Array) -> Array:
	# 1. Приводим вход к правильному размеру
	if input_vector.size() != input_size:
		var adj = []
		adj.resize(input_size)
		for i in range(input_size):
			adj[i] = input_vector[i] if i < input_vector.size() else 0.0
		input_vector = adj

	# 2. Проверяем скрытое состояние
	if hidden_state.size() != hidden_size:
		reset()

	# 3. Матричные умножения
	var new_hidden = _matrix_vector_mul(w_ih, input_vector)   # hidden_size
	var hidden_contrib = _matrix_vector_mul(w_hh, hidden_state) # hidden_size

	# 4. Дополнительная защита (на случай, если _matrix_vector_mul вернул другую длину)
	if hidden_contrib.size() != hidden_size:
		var fixed = []
		fixed.resize(hidden_size)
		for i in range(hidden_size):
			fixed[i] = hidden_contrib[i] if i < hidden_contrib.size() else 0.0
		hidden_contrib = fixed

	if new_hidden.size() != hidden_size:
		var fixed = []
		fixed.resize(hidden_size)
		for i in range(hidden_size):
			fixed[i] = new_hidden[i] if i < new_hidden.size() else 0.0
		new_hidden = fixed

	# 5. Обновление скрытого состояния
	for i in range(hidden_size):
		new_hidden[i] += hidden_contrib[i]
		new_hidden[i] = tanh(new_hidden[i])

	hidden_state = new_hidden

	# 6. Вычисление выхода
	var out = _matrix_vector_mul(w_ho, hidden_state)  # output_size
	if out.size() != output_size:
		var fixed = []
		fixed.resize(output_size)
		for i in range(output_size):
			fixed[i] = out[i] if i < out.size() else 0.0
		out = fixed

	output_state = out
	return out

func _matrix_vector_mul(matrix: Array, vector: Array) -> Array:
	var result = []
	var vec_len = vector.size()
	for row in matrix:
		var row_len = row.size()
		var sum = 0.0
		var max_i = min(vec_len, row_len)
		for i in range(max_i):
			sum += row[i] * vector[i]
		result.append(sum)
	return result

func mutate(rate: float = 0.05, strength: float = 0.3):
	_mutate_matrix(w_ih, rate, strength)
	_mutate_matrix(w_hh, rate, strength)
	_mutate_matrix(w_ho, rate, strength)

func _mutate_matrix(matrix: Array, rate: float, strength: float):
	for i in range(matrix.size()):
		for j in range(matrix[i].size()):
			if randf() < rate:
				matrix[i][j] += randf_range(-strength, strength)

func clone() -> RNNLayer:
	var layer = RNNLayer.new(input_size, hidden_size, output_size)
	layer.w_ih = _deep_copy(w_ih)
	layer.w_hh = _deep_copy(w_hh)
	layer.w_ho = _deep_copy(w_ho)
	layer.hidden_state = hidden_state.duplicate()
	layer.output_state = output_state.duplicate()
	return layer

func _deep_copy(matrix: Array) -> Array:
	var copy = []
	for row in matrix:
		copy.append(row.duplicate())
	return copy
