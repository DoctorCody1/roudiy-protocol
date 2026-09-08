extends Node2D

# ------------------------------------------------------------------
#  УПРАВЛЕНИЕ
# ------------------------------------------------------------------
var timer: Timer
var current_speed: float = 1.0
var step_mode: bool = false
var selected_agent_id: int = -1
var teleport_mode: bool = false
var global_brain_selected_for_teleport: bool = false
# ------------------------------------------------------------------
#  ВИЗУАЛЬНЫЕ СЛОИ
# ------------------------------------------------------------------
var world_layer: WorldLayer = null
var agent_layer: Node2D = null

# ------------------------------------------------------------------
#  ИНИЦИАЛИЗАЦИЯ
# ------------------------------------------------------------------
func _ready():
	# 1. Создаём WorldLayer
	world_layer = WorldLayer.new()
	add_child(world_layer)
	
	# 2. Запускаем симуляцию
	SimManager.instance.initialize(20, 64)
	
	# 3. Создаём визуальные слои
	_create_visual_layers()
	
	# 4. Таймер
	timer = Timer.new()
	timer.wait_time = 0.2
	timer.timeout.connect(_on_timer)
	add_child(timer)
	timer.start()
	
	# 5. Ввод
	set_process_input(true)
	
	print("Управление: Пробел — пауза, 1-5 — скорость, S — пошаговый режим, → — шаг, клик — выбрать агента, R — случайный агент")

# ------------------------------------------------------------------
#  ВИЗУАЛЬНЫЕ СЛОИ
# ------------------------------------------------------------------
func _create_visual_layers():
	if world_layer:
		world_layer.update_world()
	
	agent_layer = Node2D.new()
	agent_layer.name = "AgentLayer"
	add_child(agent_layer)

func update_agents():
	if not agent_layer:
		return
	for child in agent_layer.get_children():
		child.queue_free()
	
	var sim = SimManager.instance
	if not sim:
		return
	for agent in sim.agents:
		if agent.alive:
			var dot = Dot.new(agent)
			agent_layer.add_child(dot)

func update_visuals():
	if world_layer:
		world_layer.update_world()
	update_agents()

# ------------------------------------------------------------------
#  ТАЙМЕР
# ------------------------------------------------------------------
func _on_timer():
	if not step_mode:
		SimManager.instance.step()
		update_visuals()
		
		if selected_agent_id != -1 and SimManager.instance.time % 10 == 0:
			var agent = find_agent_by_id(selected_agent_id)
			if agent and agent.alive:
				print(agent.get_thoughts())
			else:
				selected_agent_id = -1
				print("Выбранный агент умер, выделение снято")

# ------------------------------------------------------------------
#  ОБРАБОТКА ВВОДА
# ------------------------------------------------------------------
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		
		if teleport_mode and global_brain_selected_for_teleport:
			var target_pos = mouse_pos / 10.0
			var gb_agent = SimManager.instance.global_brain.agent_self if SimManager.instance.global_brain else null
			if gb_agent:
				gb_agent.teleport_to(target_pos)
				teleport_mode = false
				global_brain_selected_for_teleport = false
				print("[GlobalBrain] Teleported to " + str(target_pos))
			return

		var clicked_agent = null
		var min_dist = 999.0
		var gb_agent = SimManager.instance.global_brain.agent_self if SimManager.instance.global_brain else null
		
		if gb_agent and gb_agent.alive:
			var dist = mouse_pos.distance_to(gb_agent.pos * 10)
			if dist < 15.0 and dist < min_dist:
				min_dist = dist
				clicked_agent = gb_agent
		
		for agent in SimManager.instance.agents:
			if not agent.alive or agent == gb_agent:
				continue
			var dist = mouse_pos.distance_to(agent.pos * 10)
			if dist < 10.0 and dist < min_dist:
				min_dist = dist
				clicked_agent = agent
		
		if clicked_agent != null:
			if clicked_agent == gb_agent:
				teleport_mode = true
				global_brain_selected_for_teleport = true
				print("[GlobalBrain] Selected for teleportation. Click on the map to teleport.")
				return
			else:
				selected_agent_id = clicked_agent.id
				print("Выбран агент " + str(selected_agent_id))
				print(clicked_agent.get_thoughts())
		else:
			if selected_agent_id != -1:
				selected_agent_id = -1
				print("Выделение снято")
			if not teleport_mode:
				teleport_mode = false
				global_brain_selected_for_teleport = false

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				timer.paused = not timer.paused
				print("Пауза: ", "включена" if timer.paused else "выключена")
			KEY_1:
				set_speed(0.2)
			KEY_2:
				set_speed(0.5)
			KEY_3:
				set_speed(1.0)
			KEY_4:
				set_speed(2.0)
			KEY_5:
				set_speed(5.0)
			KEY_S:
				step_mode = not step_mode
				print("Пошаговый режим: ", "включен" if step_mode else "выключен")
			KEY_RIGHT:
				if step_mode:
					SimManager.instance.step_once()
					update_visuals()
					print("Шаг выполнен")
			KEY_R:
				var alive_agents = SimManager.instance.agents.filter(func(a): return a.alive)
				if not alive_agents.is_empty():
					var agent = alive_agents[randi() % alive_agents.size()]
					selected_agent_id = agent.id
					print("Случайно выбран агент " + str(selected_agent_id))
					print(agent.get_thoughts())

# ------------------------------------------------------------------
#  СКОРОСТЬ
# ------------------------------------------------------------------
func set_speed(speed: float):
	current_speed = max(0.1, speed)
	timer.wait_time = 0.2 / current_speed
	print("Скорость установлена: ", current_speed, "x")

# ------------------------------------------------------------------
#  ВСПОМОГАТЕЛЬНЫЕ
# ------------------------------------------------------------------
func find_agent_by_id(id: int):
	for agent in SimManager.instance.agents:
		if agent.id == id:
			return agent
	return null
