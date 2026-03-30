class_name Evidence extends Node2D

var hidden_tag : Tag = preload("res://Resources/Tags/Tag_Hidden.tres")

var sprite : Sprite2D = null
var draggable : Draggable = null
var pins_holder : Node2D = null
var mc_content : MarginContainer = null
var mc_hidden : MarginContainer = null

@export var max_pins := 3

@export var random_colour_on_start := true
@export var random_type_on_start := true
@export var random_level_on_start := true

@export_category("READ ONLY")

@export var tags : Array[Tag] = []

@export var is_hidden : bool = true :
	get: return has_tag(hidden_tag).result
		#return !mc_content.visible
	set(value):
		if value:
			is_hidden = add_tag(hidden_tag).result
		else:
			is_hidden = remove_tag(hidden_tag).result
		#mc_content.visible = !value
		#mc_hidden.visible = value

@export var pins : Array[Pin] :
	get: 
		var _pins : Array[Pin] 
		for child in pins_holder.get_children():
			_pins.append(child as Pin)
		return _pins
@export var pin_count : int :
	get: return pins.size()

@export var at_max_pins : bool :
	get: return pins.size() >= max_pins

@export var occupied : bool :
	get:
		for _pin in pins:
			if _pin.occupied:
				return true
		return false


signal on_click_evidence

signal on_occupied(new_occupant)


#region Internal variables

var _setup_finished := false

var _debug_name : String :
	get: return "[b][" + name + "][/b]"

#endregion



#region Public functions

func register_pin(_new_pin:Pin) -> void:
	pins_holder.add_child(_new_pin)
	_new_pin.evidence = self
	_new_pin.name = name + "|Pin"
	
	draggable.on_moved.connect(_new_pin.draggable.on_moved.emit)
	_new_pin.on_occupied.connect(on_occupied.emit)



# TAGS

func has_tag(_tag:Tag,key_only:bool=false) -> Test:
	
	if key_only:
		for tag in tags:
			if _tag.key == tag.key:
				return Test.new(true,"")
		return Test.new(false,"No tag with key '"+_tag.key+"' present")
	else:
		if tags.has(_tag):
			return Test.new(true,"")
		return Test.new(false,"No matching results")

func add_tag(_tag:Tag,allow_multiples:bool=false) -> Test:
	
	if !allow_multiples && has_tag(_tag,true).result:
		print_rich(_debug_name," AddTag > Tag '"+_tag.key+"' already present, cancelling")
		return Test.new(false,"Tag '"+_tag.key+"' already present")
	
	tags.append(_tag)
	_set_graphics()
	return Test.new(true,"")

func remove_tag(_tag:Tag) -> Test:
	
	if !has_tag(_tag).result:
		print_rich(_debug_name," RemoveTag > Tag '"+_tag.key+"' not found, cancelling")
		return Test.new(false,"Tag '"+_tag.key+"' not found")
	
	tags.remove_at(tags.find(_tag))
	_set_graphics()
	return Test.new(true,"")



# HIDE & REVEAL

func hide_me() -> Test:
	#Ignore if the evidence is already hidden
	if is_hidden:
		print_rich(_debug_name," Hide > Already hidden, ignoring")
		return Test.new(false,"Evidence is already hidden")
	
	#Ignore if the pin is occupied
	if occupied:
		print_rich(_debug_name," Hide > Occupied by player, ignoring")
		return Test.new(false,"Evidence is occupied")
	
	is_hidden = true
	return Test.new(true,"")

func reveal_me() -> Test:
	#Ignore if the evidence is already hidden
	if !is_hidden:
		print_rich(_debug_name," Hide > Already revealed, ignoring")
		return Test.new(false,"Evidence is already revealed")
	
	is_hidden = false
	return Test.new(true,"")


#endregion






#region Internal functions

func _ready() -> void:
	# NOTE -> Only necessary if placed in editor
	if !_setup_finished:
		setup()
	name = "Evidence"



func setup() -> void:
	sprite = $Sprite2D
	draggable = $Draggable
	pins_holder = $PinsHolder
	mc_content = $PanelContainer/MC_Content
	mc_hidden = $PanelContainer/MC_Hidden
	
	draggable.on_click.connect(on_click_evidence.emit)
	on_occupied.connect(_occupied)
	
	tags.append(hidden_tag)
	
	_set_graphics()
	
	_setup_finished = true

func _occupied(new_target:Node2D) -> void:
	# Reveal evidence if hidden
	if is_hidden && (new_target as Player) != null:
		is_hidden = false

func _set_graphics() -> void:
	var _is_domain := false
	for tag in tags:
		if tag.key == "Colour":
			var color_icon = $PanelContainer/MC_Content/MarginContainer/HBoxContainer/ColourIcon
			if tag.value == "Red": color_icon.self_modulate = Color.html("e82428")
			elif tag.value == "Blue": color_icon.self_modulate = Color.html("23439b")
			elif tag.value == "Green": color_icon.self_modulate = Color.html("17884d")
			elif tag.value == "Purple": color_icon.self_modulate = Color.html("9364a9")
		elif tag.key == "Type":
			var type_icon = $PanelContainer/MC_Content/MarginContainer/HBoxContainer/ColourIcon/TypeIcon
			if tag.value == "Item": type_icon.texture = load("res://Assets/Sprites/ItemSolo.png")
			if tag.value == "Location": type_icon.texture = load("res://Assets/Sprites/LocationSolo.png")
			if tag.value == "Person": type_icon.texture = load("res://Assets/Sprites/PersonSolo.png")
		elif tag.key == "Domain":
			_is_domain = true
			$PanelContainer/MC_Content/MarginContainer/DomainTag.visible = true
	
	$PanelContainer/MC_Content/MarginContainer/HBoxContainer/Rtl_Level.text = str(max_pins)
	
	# Hide content if hidden
	var _test = has_tag(hidden_tag)
	mc_content.visible = !_test.result
	mc_hidden.visible = _test.result
	
	$PanelContainer.self_modulate = Color.WHITE if _test.result || !_is_domain else Color.BLACK
	

#endregion
