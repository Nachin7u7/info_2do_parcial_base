extends TextureRect

@onready var score_label = $MarginContainer/VBoxContainer/HBoxContainer/score_label
@onready var time_label = $MarginContainer/VBoxContainer/HBoxContainer/time_label
@onready var counter_label = $MarginContainer/VBoxContainer/HBoxContainer/counter_label

var current_score = 0
var current_count = 0

func update_moves(moves):
	counter_label.text = str(moves)

func update_time(time):
	var minutes = time / 60
	var seconds = time % 60
	time_label.text = "Tiempo: " + str(minutes) + ":" + str(seconds).pad_zeros(2)

func update_score(score, target):
	score_label.text = str(score) + "/" + str(target)
	# También actualizar el tiempo
	var grid = get_parent().get_node("grid")
	if grid:
		var minutes = int(grid.time_left) / 60
		var seconds = int(grid.time_left) % 60
		time_label.text = str(minutes) + ":" + str(seconds).pad_zeros(2)
