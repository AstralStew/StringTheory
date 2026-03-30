class_name Pin extends Node2D

var sprite : Sprite2D = null
var draggable : Draggable = null 


@export var max_links := 3


@export_category("READ ONLY")

@export var evidence : Evidence = null

@export var links : Array[Link] = []
@export var link_count : int = 0:
	get: return links.size()
@export var full : bool = false:
	get: return link_count >= max_links


@export var occupant : Node2D = null :
	get: return occupant
	set(value):
		occupant = value
		on_occupied.emit(occupant)
@export var occupied := false :
	get:
		if occupant != null: return true
		else: return false


signal on_click_pin
signal on_occupied(new_occupant)

#region Public functions

func add_link(link:Link) -> void:
	print(_debug_name, " Added link: ",link)
	links.append(link)

func get_linked_pins() -> Array[Pin]:
	var _linked_pins : Array[Pin] = []
	for link in links:
		var _other_pin = link.get_other_pin(self)
		if _other_pin != null:
			_linked_pins.append(_other_pin)
	return _linked_pins

func is_linked_to_pin(target_pin:Pin) -> bool:
	for link in links:
		var _other_pin = link.get_other_pin(self)
		if target_pin == _other_pin:
			return true
	return false

func get_link_to_pin(target_pin:Pin) -> Link:
	for link in links:
		var _other_pin = link.get_other_pin(self)
		if target_pin == _other_pin:
			return link
	return null

#endregion




#region Internal variables

var _setup_finished := false

var _debug_name : String :
	get: return "[" + name + "]"

#endregion


#region Internal functions


func _ready() -> void:
	# NOTE -> Only necessary if placed in editor
	if !_setup_finished:
		setup()

func setup() -> void:
	sprite = $Sprite2D
	draggable = $Draggable
	
	draggable.on_click.connect(on_click_pin.emit)
	
	
	_setup_finished = true


#endregion
