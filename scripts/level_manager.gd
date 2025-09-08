extends Node

enum LevelType { MOVES, TIMED }

@export var level_type: LevelType = LevelType.MOVES
@export var target_score: int = 500
@export var level_moves: int = 15
@export var level_time: int = 30

var running: bool = false
var current_score: int = 0
var remaining_moves: int = 0
var remaining_time: int = 0

@onready var grid  = $"grid"
@onready var hud  = $"top_ui"
@onready var timer := Timer.new()
@onready var result_banner := $"top_ui/ResultBanner"

func _ready() -> void:
	if result_banner:
		result_banner.hide()

	add_child(timer)
	timer.wait_time = 1.0
	timer.one_shot = false
	timer.timeout.connect(_on_timer_tick)

	if grid:
		if grid.has_signal("swap_started"):
			grid.swap_started.connect(_on_grid_swap_started)
		if grid.has_signal("match_resolved"):
			grid.match_resolved.connect(_on_grid_match_resolved)
	else:
		print("error")
	if level_type == LevelType.MOVES:
		start_moves_level(target_score, level_moves)
	else:
		start_timed_level(target_score, level_time)


func start_moves_level(target: int, moves: int) -> void:
	level_type = LevelType.MOVES
	running = true
	current_score = 0
	target_score = target
	remaining_moves = moves
	remaining_time = 0

	if hud:
		hud.set_mode_moves()
		hud.set_score(current_score)
		hud.set_moves(remaining_moves)

	timer.stop()

func start_timed_level(target: int, seconds: int) -> void:
	level_type = LevelType.TIMED
	running = true
	current_score = 0
	target_score = target
	remaining_moves = 0
	remaining_time = max(0, seconds)

	if hud:
		hud.set_mode_timed()
		hud.set_score(current_score)
		hud.set_time(remaining_time)

	timer.start()

	if remaining_time <= 0:
		timer.stop()
		running = false
		if grid and grid.has_method("game_over"):
			grid.game_over()

func _on_timer_tick() -> void:
	if not running: return
	if level_type != LevelType.TIMED: return

	remaining_time -= 1
	if hud:
		hud.set_time(remaining_time)

	if remaining_time <= 0:
		timer.stop()
		running = false
		if grid and grid.has_method("game_over"):
			grid.game_over()
		print("Game Over")
		# BANNER: sólo cuando termina el tiempo
		if hud and hud.has_method("show_result_banner"):
			hud.show_result_banner("💔YOU LOSE💔")

func _on_grid_swap_started() -> void:
	if not running:
		return
	if level_type == LevelType.MOVES:
		remaining_moves -= 1
		if hud:
			hud.set_moves(remaining_moves)

		if remaining_moves <= 0:
			running = false
			if grid and grid.has_method("game_over"):
				grid.game_over()
			print("Game Over")
			if hud and hud.has_method("show_result_banner"):
				if current_score >= target_score:
					hud.show_result_banner("🎉YOU WIN🎉")
				else:
					hud.show_result_banner("💔YOU LOSE💔")

func _on_grid_match_resolved(points: int, cascade: int) -> void:
	if not running:
		return
	current_score += points
	if hud:
		hud.set_score(current_score)
	if current_score >= target_score and running:
		running = false
		if grid and grid.has_method("game_over"):
			grid.game_over()
		print("You Win")
		if hud and hud.has_method("show_result_banner"):
			hud.show_result_banner("🎉YOU WIN🎉")
