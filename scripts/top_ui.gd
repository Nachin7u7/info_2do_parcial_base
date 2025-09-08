extends TextureRect

@onready var score_label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label
@onready var result_banner = $ResultBanner
@onready var result_label = $ResultBanner/result_label

# top_ui.gd

func set_score(n: int) -> void:
	if score_label:
		score_label.text = str(n)

func set_moves(n: int) -> void:
	if counter_label:
		counter_label.text = str(n)

func set_time(seconds: int) -> void:
	if counter_label:
		counter_label.text = str(seconds)

func set_mode_moves() -> void:
	if counter_label:
		counter_label.text = "0"  
		
func set_mode_timed() -> void:
	if counter_label:
		counter_label.text = "0" 

func show_result_banner(text: String) -> void:
	if result_label:
		result_label.text = text
	if result_banner:
		result_banner.show()

func hide_result_banner() -> void:
	if result_banner:
		result_banner.visible = false
