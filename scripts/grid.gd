extends Node2D

# state machine
enum {WAIT, MOVE}
var state

# grid
@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int

# piece array
var possible_pieces = [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/light_green_piece.tscn"),
	preload("res://scenes/pink_piece.tscn"),
	preload("res://scenes/yellow_piece.tscn"),
	preload("res://scenes/orange_piece.tscn"),
]
# current pieces in scene
var all_pieces = []

# swap back
var piece_one = null
var piece_two = null
var last_place = Vector2.ZERO
var last_direction = Vector2.ZERO
var move_checked = false

# touch variables
var first_touch = Vector2.ZERO
var final_touch = Vector2.ZERO
var is_controlling = false


# scoring variables and signals
var current_score = 0
var target_score = 1000  # puntos necesarios para ganar
var points_per_match = 50

# Sistema de niveles
var level = 1
var moves_left = 30
var time_left = 120.0  # 2 minutos
var min_moves = 5
var min_time = 10.0
var moves_decrement = 5
var time_decrement = 20.0
var game_won = false
var game_lost = false


# Called when the node enters the scene tree for the first time.
func _ready():
	state = MOVE
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()
	update_ui()

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start - offset * row
	return Vector2(new_x, new_y)

func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)

func in_grid(column, row):
	return column >= 0 and column < width and row >= 0 and row < height

func spawn_pieces():
	var special_types = ["column", "row", "adjacent"]
	for i in width:
		for j in height:
			# random number
			var rand = randi_range(0, possible_pieces.size() - 1)
			# instance
			var piece = possible_pieces[rand].instantiate()

			# Probabilidad baja de pieza especial (por ejemplo 7%)
			if randi_range(1, 100) <= 7:
				# Elegir tipo especial aleatorio
				var stype = special_types[randi_range(0, special_types.size() - 1)]
				piece.special_type = stype
			else:
				piece.special_type = "normal"

			# repeat until no matches
			var max_loops = 100
			var loops = 0
			while (match_at(i, j, piece.color) and loops < max_loops):
				rand = randi_range(0, possible_pieces.size() - 1)
				loops += 1
				piece = possible_pieces[rand].instantiate()
				# Reasignar tipo especial si corresponde
				if randi_range(1, 100) <= 7:
					var stype = special_types[randi_range(0, special_types.size() - 1)]
					piece.special_type = stype
				else:
					piece.special_type = "normal"
			add_child(piece)
			piece.position = grid_to_pixel(i, j)
			# fill array with pieces
			all_pieces[i][j] = piece

func match_at(i, j, color):
	# check left
	if i > 1:
		if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].color == color and all_pieces[i - 2][j].color == color:
				return true
	# check down
	if j> 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color and all_pieces[i][j - 2].color == color:
				return true

func touch_input():
	# No procesar input si el juego terminó
	if game_won or game_lost:
		return

	var mouse_pos = get_global_mouse_position()
	var grid_pos = pixel_to_grid(mouse_pos.x, mouse_pos.y)
	if Input.is_action_just_pressed("ui_touch") and in_grid(grid_pos.x, grid_pos.y):
		first_touch = grid_pos
		is_controlling = true

	# release button
	if Input.is_action_just_released("ui_touch") and in_grid(grid_pos.x, grid_pos.y) and is_controlling:
		is_controlling = false
		final_touch = grid_pos
		touch_difference(first_touch, final_touch)

func swap_pieces(column, row, direction: Vector2):
	# No permitir intercambios si el juego terminó
	if game_won or game_lost:
		return

	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	if first_piece == null or other_piece == null:
		return
	# swap
	state = WAIT
	store_info(first_piece, other_piece, Vector2(column, row), direction)
	all_pieces[column][row] = other_piece
	all_pieces[column + direction.x][row + direction.y] = first_piece
	#first_piece.position = grid_to_pixel(column + direction.x, row + direction.y)
	#other_piece.position = grid_to_pixel(column, row)
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_piece.move(grid_to_pixel(column, row))

	# reducir movimientos cuando se hace un intercambio
	moves_left -= 1
	update_ui()

	if not move_checked:
		find_matches()

	# verificar si se acabaron los movimientos
	if moves_left <= 0 and not game_won:
		game_lost = true
		game_over()

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = MOVE
	move_checked = false

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	# should move x or y?
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
	if abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))

func _process(delta):
	# Solo procesar si el juego no ha terminado
	if state == MOVE and not game_won and not game_lost:
		touch_input()

	# actualizar timer solo si el juego sigue activo
	if time_left > 0 and not game_won and not game_lost:
		time_left -= delta
		update_ui()
	elif not game_won and not game_lost:
		game_lost = true
		game_over()

func find_matches():

	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				var specials = []
				# detect horizontal matches
				if (
					i > 0 and i < width - 1
					and all_pieces[i - 1][j] != null and all_pieces[i + 1][j] != null
					and all_pieces[i - 1][j].color == current_color and all_pieces[i + 1][j].color == current_color
				):
					var match_pieces = [all_pieces[i - 1][j], all_pieces[i][j], all_pieces[i + 1][j]]
					for p in match_pieces:
						if p.special_type != "normal":
							specials.append({'piece': p, 'i': i if p == all_pieces[i][j] else (i-1 if p == all_pieces[i-1][j] else i+1), 'j': j})
					for p in match_pieces:
						p.matched = true
						p.dim()
				# detect vertical matches
				if (
					j > 0 and j < height - 1
					and all_pieces[i][j - 1] != null and all_pieces[i][j + 1] != null
					and all_pieces[i][j - 1].color == current_color and all_pieces[i][j + 1].color == current_color
				):
					var match_pieces = [all_pieces[i][j - 1], all_pieces[i][j], all_pieces[i][j + 1]]
					for p in match_pieces:
						if p.special_type != "normal":
							specials.append({'piece': p, 'i': i, 'j': j if p == all_pieces[i][j] else (j-1 if p == all_pieces[i][j-1] else j+1)})
					for p in match_pieces:
						p.matched = true
						p.dim()

				# Procesar piezas especiales encontradas
				for s in specials:
					var stype = s['piece'].special_type
					var si = s['i']
					var sj = s['j']
					if stype == "column":
						eliminate_column(si)
					elif stype == "row":
						eliminate_row(sj)
					elif stype == "adjacent":
						eliminate_adjacent(si, sj)

	get_parent().get_node("destroy_timer").start()

# Elimina toda la columna i
func eliminate_column(i):
	for j in height:
		if all_pieces[i][j] != null:
			all_pieces[i][j].matched = true
			all_pieces[i][j].dim()

# Elimina toda la fila j
func eliminate_row(j):
	for i in width:
		if all_pieces[i][j] != null:
			all_pieces[i][j].matched = true
			all_pieces[i][j].dim()

# Elimina piezas adyacentes a (i, j)
func eliminate_adjacent(i, j):
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var ni = i + dx
			var nj = j + dy
			if in_grid(ni, nj) and all_pieces[ni][nj] != null:
				all_pieces[ni][nj].matched = true
				all_pieces[ni][nj].dim()

func destroy_matched():
	var was_matched = false
	var pieces_destroyed = 0
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				was_matched = true
				pieces_destroyed += 1
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null

	# agregar puntos por piezas destruidas
	if pieces_destroyed > 0:
		current_score += pieces_destroyed * points_per_match
		update_ui()
		check_win_condition()

	move_checked = true
	if was_matched:
		get_parent().get_node("collapse_timer").start()
	else:
		swap_back()

func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				print(i, j)
				# look above
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("refill_timer").start()

func refill_columns():

	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				# random number
				var rand = randi_range(0, possible_pieces.size() - 1)
				# instance
				var piece = possible_pieces[rand].instantiate()
				# repeat until no matches
				var max_loops = 100
				var loops = 0
				while (match_at(i, j, piece.color) and loops < max_loops):
					rand = randi_range(0, possible_pieces.size() - 1)
					loops += 1
					piece = possible_pieces[rand].instantiate()
				add_child(piece)
				piece.position = grid_to_pixel(i, j - y_offset)
				piece.move(grid_to_pixel(i, j))
				# fill array with pieces
				all_pieces[i][j] = piece

	check_after_refill()

func check_after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i, j, all_pieces[i][j].color):
				find_matches()
				get_parent().get_node("destroy_timer").start()
				return
	state = MOVE

	move_checked = false

func _on_destroy_timer_timeout():
	print("destroy")
	destroy_matched()

func _on_collapse_timer_timeout():
	print("collapse")
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()

func game_over():
	state = WAIT

	# Detener todos los timers
	get_parent().get_node("destroy_timer").stop()
	get_parent().get_node("collapse_timer").stop()
	get_parent().get_node("refill_timer").stop()

	var banner = get_parent().get_node("game_over_banner")
	var banner_label = get_parent().get_node("game_over_banner/banner_label")

	if game_won:
		print("¡GANASTE! Puntuación: ", current_score, "/", target_score)
		banner_label.text = "YOU WIN!\nPress ENTER\nfor\nlevel: " + str(level + 1)
		banner_label.modulate = Color.GREEN
	else:
		if moves_left <= 0:
			print("PERDISTE - Se acabaron los movimientos")
			banner_label.text = "YOU LOSE!\nNo more \nmoves"
		else:
			print("PERDISTE - Se acabó el tiempo")
			banner_label.text = "YOU LOSE!\nTime's up"
		banner_label.modulate = Color.RED
		print("Puntuación final: ", current_score, "/", target_score)

	# Mostrar banner
	banner.visible = true
	if game_won:
		print("Presiona ENTER para avanzar al siguiente nivel")
	else:
		print("Presiona ENTER para reiniciar")

func check_win_condition():
	if current_score >= target_score:
		game_won = true
		game_over()

func update_ui():
	var top_ui = get_parent().get_node("top_ui")
	if top_ui:
		top_ui.update_moves(moves_left)
		top_ui.update_score(current_score, target_score)

func restart_game():
	# Ocultar banner
	var banner = get_parent().get_node("game_over_banner")
	banner.visible = false

	# Si el jugador ganó, avanzar de nivel y aumentar dificultad
	if game_won:
		level += 1
		# Alternar reducción entre movimientos y tiempo
		if level % 2 == 0:
			# Reducir movimientos
			moves_left = max(min_moves, moves_left - moves_decrement)
			time_left = time_left  # mantener tiempo
		else:
			# Reducir tiempo
			time_left = max(min_time, time_left - time_decrement)
			moves_left = moves_left  # mantener movimientos
		print("Nivel avanzado: ", level, " | Movimientos: ", moves_left, " | Tiempo: ", time_left)
	else:
		# Reiniciar a valores base si perdió
		level = 1
		moves_left = 30
		time_left = 120.0

	# reiniciar variables
	current_score = 0
	game_won = false
	game_lost = false
	state = MOVE

	# limpiar piezas existentes
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null

	# generar nuevas piezas
	spawn_pieces()
	update_ui()
	print("Juego reiniciado. Nivel actual: ", level)

func _input(event):
	# Si el juego terminó, ENTER reinicia o avanza de nivel
	if (game_won or game_lost) and event.is_action_pressed("ui_accept"):
		restart_game()
