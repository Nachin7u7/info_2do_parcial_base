
extends Control

# Lista de dificultades y escenas
var difficulties = [
	{"name": "Moves – Easy", "scene": "res://scenes/game_moves_easy.tscn"},
	{"name": "Moves – Hard", "scene": "res://scenes/game_moves_hard.tscn"},
	{"name": "Timed – Easy", "scene": "res://scenes/game_timed_easy.tscn"},
	{"name": "Timed – Hard", "scene": "res://scenes/game_timed_hard.tscn"}
]
var current_index := 0

func _ready() -> void:
	print("Menu listo slide")
	$Background/ArrowLeft.pressed.connect(_on_arrow_left)
	$Background/ArrowRight.pressed.connect(_on_arrow_right)
	$Background/SelectButton.pressed.connect(_on_select)
	_update_slide()
	set_process_input(true)

func _on_arrow_left() -> void:
	if current_index > 0:
		current_index -= 1
		_animate_slide(-1)

func _on_arrow_right() -> void:
	if current_index < len(difficulties) - 1:
		current_index += 1
		_animate_slide(1)

func _on_select() -> void:
	var scene_path = difficulties[current_index]["scene"]
	print("Seleccionado: ", difficulties[current_index]["name"])
	get_tree().change_scene_to_file(scene_path)

func _update_slide():
	var hbox = $Background/SlideContainer/Difficulties
	for i in range(hbox.get_child_count()):
		var panel = hbox.get_child(i)
		panel.modulate = Color(1,1,1, 1 if i == current_index else 0.5)
		panel.scale = Vector2(1.1,1.1) if i == current_index else Vector2(0.9,0.9)
	hbox.set_position(Vector2(-350 * current_index, 0))

func _animate_slide(direction: int):
	var hbox = $Background/SlideContainer/Difficulties
	var tween = create_tween()
	tween.tween_property(hbox, "position:x", -350 * current_index, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_update_slide()

func _input(event):
	if event is InputEventScreenDrag:
		if event.relative.x < -30:
			_on_arrow_right()
		elif event.relative.x > 30:
			_on_arrow_left()
