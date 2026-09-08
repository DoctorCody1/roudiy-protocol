extends RefCounted
class_name GRULayer

var input_size: int
var hidden_size: int
var output_size: int

# Веса (матрицы)
var w_z: Array = []  # input → hidden (update gate)
var w_r: Array = []  # input → hidden (reset gate)
var w_h: Array = []  # input → hidden (candidate)
var u_z: Array = []  # hidden → hidden (update)
var u_r: Array = []  # hidden → hidden (reset)
var u_h: Array = []  # hidden → hidden (candidate)
var w_ho: Array = [] # hidden → output

# Состояния
var hidden_state: Array = []
var output_state: Array = []

# ---- ПАРАМЕТРЫ HEBB-ОБУЧЕНИЯ (эволюционируют) ----
var hebb_rate: float = 0.01          # скорость обучения
var hebb_decay: float = 0.001        # затухание весов
var hebb_threshold: float = 0.1      # минимальная корреляция для изменения
var hebb_momentum: float = 0.9       # инерция для обновления

# ---- ПАМЯТЬ ДЛЯ HEBB (последние активности) ----
var last_input: Array = []
var last_hidden: Array = []
var last_output: Array = []

func _init(in_size: int, hid_size: int, out_size: int, 
		   h_rate: float = 0.01, h_decay: float = 0.001, 
		   h_thresh: float = 0.1, h_momentum: float = 0.9):
	input_size = in_size
	hidden_size = hid_size
	output_size = out_size
	hebb_rate = h_rate
	hebb_decay = h_decay
	hebb_threshold = h_thresh
	hebb_momentum = h_momentum
	_init_weights()
	reset()

func _init_weights():
	var scale = sqrt(2.0 / (input_size + hidden_size))
	w_z = _random_matrix(input_size, hidden_size, scale)
	w_r = _random_matrix(input_size, hidden_size, scale)
	w_h = _random_matrix(input_size, hidden_size, scale)
	var scale_u = sqrt(2.0 / (hidden_size + hidden_size))
	u_z = _random_matrix(hidden_size, hidden_size, scale_u)
	u_r = _random_matrix(hidden_size, hidden_size, scale_u)
	u_h = _random_matrix(hidden_size, hidden_size, scale_u)
	var scale_ho = sqrt(2.0 / (hidden_size + output_size))
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
	last_input = []
	last_hidden = []
	last_output = []

func forward(input_vector: Array) -> Array:
	# Приведение размера
	if input_vector.size() != input_size:
		var adj = []
		adj.resize(input_size)
		for i in range(input_size):
			adj[i] = input_vector[i] if i < input_vector.size() else 0.0
		input_vector = adj
	# Сохраняем вход для Hebb
	last_input = input_vector.duplicate()
	# Вычисления GRU
	var z_raw = _matrix_vector_mul(w_z, input_vector) + _matrix_vector_mul(u_z, hidden_state)
	var r_raw = _matrix_vector_mul(w_r, input_vector) + _matrix_vector_mul(u_r, hidden_state)
	var h_hat_raw = _matrix_vector_mul(w_h, input_vector) + _matrix_vector_mul(u_h, hidden_state)
	# Активации
	var z = []
	var r = []
	var h_hat = []
	for i in range(hidden_size):
		z.append(_sigmoid(z_raw[i]))
		r.append(_sigmoid(r_raw[i]))
		h_hat.append(tanh(h_hat_raw[i]))
	# Новое скрытое состояние
	var new_hidden = []
	for i in range(hidden_size):
		new_hidden.append((1.0 - z[i]) * hidden_state[i] + z[i] * h_hat[i])
	# Сохраняем скрытое состояние для Hebb
	last_hidden = new_hidden.duplicate()
	hidden_state = new_hidden
	# Вычисляем выход
	var out = _matrix_vector_mul(w_ho, hidden_state)
	if out.size() != output_size:
		var fixed = []
		fixed.resize(output_size)
		for i in range(output_size):
			fixed[i] = out[i] if i < out.size() else 0.0
		out = fixed
	last_output = out.duplicate()
	output_state = out
	for i in range(output_size):
		output_state[i] = tanh(output_state[i])
	return output_state

# ---- HEBB-ОБУЧЕНИЕ (локальное, на основе корреляции) ----
func hebb_update(strength: float = 1.0):
	# Применяем Hebb-правило ко всем весам, используя последние активности
	if last_input.is_empty() or last_hidden.is_empty():
		return
	# Обновляем w_z, w_r, w_h (input → hidden)
	_hebb_matrix(w_z, last_input, last_hidden, strength)
	_hebb_matrix(w_r, last_input, last_hidden, strength)
	_hebb_matrix(w_h, last_input, last_hidden, strength)
	# Обновляем u_z, u_r, u_h (hidden → hidden)
	_hebb_matrix(u_z, last_hidden, last_hidden, strength)
	_hebb_matrix(u_r, last_hidden, last_hidden, strength)
	_hebb_matrix(u_h, last_hidden, last_hidden, strength)
	# Обновляем w_ho (hidden → output)
	_hebb_matrix(w_ho, last_hidden, last_output, strength)
	# Очищаем память, чтобы не повторять одно и то же
	last_input = []
	last_hidden = []
	last_output = []

func _hebb_matrix(matrix: Array, pre: Array, post: Array, strength: float):
	# pre и post — векторы активностей (длины совпадают с размерами матрицы)
	var lr = hebb_rate * strength
	var decay = hebb_decay
	var thresh = hebb_threshold
	for i in range(matrix.size()):
		for j in range(matrix[i].size()):
			var pre_val = pre[i] if i < pre.size() else 0.0
			var post_val = post[j] if j < post.size() else 0.0
			var correlation = pre_val * post_val
			if abs(correlation) > thresh:
				# Hebb-правило: Δw = lr * (pre * post) - decay * w
				var delta = lr * correlation - decay * matrix[i][j]
				matrix[i][j] += delta * hebb_momentum

# ---- ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ----
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

func _sigmoid(x: float) -> float:
	return 1.0 / (1.0 + exp(-x))

# ---- МУТАЦИЯ И НАСЛЕДОВАНИЕ ----
func mutate(rate: float = 0.05, strength: float = 0.3):
	_mutate_matrix(w_z, rate, strength)
	_mutate_matrix(w_r, rate, strength)
	_mutate_matrix(w_h, rate, strength)
	_mutate_matrix(u_z, rate, strength)
	_mutate_matrix(u_r, rate, strength)
	_mutate_matrix(u_h, rate, strength)
	_mutate_matrix(w_ho, rate, strength)

func _mutate_matrix(matrix: Array, rate: float, strength: float):
	for i in range(matrix.size()):
		for j in range(matrix[i].size()):
			if randf() < rate:
				matrix[i][j] += randf_range(-strength, strength)

# ---- СМЕШИВАНИЕ ВЕСОВ ДЛЯ СОЦИАЛЬНОГО ОБУЧЕНИЯ ----
func mix_weights(other: GRULayer, fraction: float):
	_mix_matrices(w_z, other.w_z, fraction)
	_mix_matrices(w_r, other.w_r, fraction)
	_mix_matrices(w_h, other.w_h, fraction)
	_mix_matrices(u_z, other.u_z, fraction)
	_mix_matrices(u_r, other.u_r, fraction)
	_mix_matrices(u_h, other.u_h, fraction)
	_mix_matrices(w_ho, other.w_ho, fraction)

func _mix_matrices(a: Array, b: Array, fraction: float):
	for i in range(a.size()):
		for j in range(a[i].size()):
			if j < b[i].size():
				a[i][j] = a[i][j] * (1.0 - fraction) + b[i][j] * fraction

func clone() -> GRULayer:
	var layer = GRULayer.new(input_size, hidden_size, output_size, 
							 hebb_rate, hebb_decay, hebb_threshold, hebb_momentum)
	layer.w_z = _deep_copy(w_z)
	layer.w_r = _deep_copy(w_r)
	layer.w_h = _deep_copy(w_h)
	layer.u_z = _deep_copy(u_z)
	layer.u_r = _deep_copy(u_r)
	layer.u_h = _deep_copy(u_h)
	layer.w_ho = _deep_copy(w_ho)
	layer.hidden_state = hidden_state.duplicate()
	layer.output_state = output_state.duplicate()
	layer.hebb_rate = hebb_rate
	layer.hebb_decay = hebb_decay
	layer.hebb_threshold = hebb_threshold
	layer.hebb_momentum = hebb_momentum
	return layer

func _deep_copy(matrix: Array) -> Array:
	var copy = []
	for row in matrix:
		copy.append(row.duplicate())
	return copy
