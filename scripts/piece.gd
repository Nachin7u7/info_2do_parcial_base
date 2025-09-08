extends Node2D


# Color base de la pieza (blue, green, etc)
@export var color: String
# Tipo especial: normal, column, row, adjacent
@export var special_type: String = "normal"


var matched = false

func _ready():
	set_special_sprite()

# Cambia el sprite si la pieza es especial
func set_special_sprite():
	if special_type == "normal":
		$Sprite2D.texture = load("res://assets/pieces/%s Piece.png" % color_to_name(color))
	elif special_type == "column":
		$Sprite2D.texture = load("res://assets/pieces/%s Column.png" % color_to_name(color))
	elif special_type == "row":
		$Sprite2D.texture = load("res://assets/pieces/%s Row.png" % color_to_name(color))
	elif special_type == "adjacent":
		$Sprite2D.texture = load("res://assets/pieces/%s Adjacent.png" % color_to_name(color))

# Convierte el color a formato capitalizado para el nombre del archivo
func color_to_name(c):
	match c:
		"blue": return "Blue"
		"green": return "Green"
		"light_green": return "Light Green"
		"orange": return "Orange"
		"pink": return "Pink"
		"yellow": return "Yellow"
		_: return c.capitalize()

func move(target):
	var move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_ELASTIC)
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "position", target, 0.4)

func dim():
	$Sprite2D.modulate = Color(1, 1, 1, 0.5)
