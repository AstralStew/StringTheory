class_name Player extends Node2D

var icon : Panel = null
var draggable : Draggable = null

@export var player_colour : Color = Color.WHITE :
	set(value):
		if icon: icon.self_modulate = value
		player_colour = value

@export_category("READ ONLY")

@export var current_evidence : Evidence = null
@export var current_pin : Pin = null

@export var current_objective : Objective = null
@export var threaded_links : Array[Link] = []

signal on_click_player
signal on_occupy_pin

signal on_objective_gained
signal on_objective_completed
signal on_objective_lost

signal on_threaded_link

#region Public functions

func move_to_pin(target_pin:Pin) -> Test:
	if target_pin == current_pin:
		print(_debug_name," MoveToPin > I'm already at that pin! Returning false.")
		return Test.new(false,"Already at that pin")
	if target_pin.occupied:
		print(_debug_name," MoveToPin > Pin is already occupied! Returning false.")
		return Test.new(false,"Pin is already occupied")
	
	_occupy_pin(target_pin)
	
	return Test.new(true,"Success, moved to pin '" + target_pin.name + "'") 

func backtrack(target_pin:Pin) -> Test:
	# Check if we're even on a pin (should be but y'know)
	if current_pin == null:
		print(_debug_name," Backtrack > Player not on a pin! Returning false.")
		return Test.new(false,"Player not at a pin somehow")
	
	# Check this isn't the pin we're already on
	if target_pin == current_pin:
		print(_debug_name," Backtrack > I'm already at that pin! Returning false.")
		return Test.new(false,"Already at that pin")
	
	# Check we aren't linked to the pin...
	if !current_pin.get_linked_pins().has(target_pin):
		# ... or we arne't on the same evidence as the pin
		if target_pin.evidence != current_pin.evidence || target_pin.evidence == null:
			print(_debug_name," Backtrack > Pin not linked to my pin or at my evidence! Returning false.")
			return Test.new(false,"Pin is not linked here or at evidence")
	
	# Check the target pin isn't already occupied
	if target_pin.occupied:
		print(_debug_name," Backtrack > Pin is already occupied! Returning false.")
		return Test.new(false,"Pin is already occupied")
	
	_occupy_pin(target_pin)
	
	return Test.new(true,"Success, backtracked to pin '" + target_pin.name + "'") 


func register_objective(_objective:Objective) -> void:
	if _objective == null:
		print(_debug_name," RegisterObjective > ERR - No Objective defined! Ignoring.")
		return
	
	# Deregister the old objective if necessary
	if current_objective != null:
		print(_debug_name," RegisterObjective > Removing previous objective first...")
		on_objective_lost.emit()
	
	# Make sure the objective is registered before saving it
	var test = current_objective.register(self)
	if !test.result:
		print(_debug_name," RegisterObjective > ERR - Register failed, reason: ", test.reason)
	current_objective = _objective


func register_link(_link:Link) -> Test:
	if threaded_links.has(_link):
		print(_debug_name," RegisterLink > ERR - Link already registered! Ignoring.")
		return Test.new(false,"Link already registered")
	
	threaded_links.append(_link)
	on_threaded_link.emit()
	print(_debug_name," RegisterLink > Registered link: ", _link.name)
	return Test.new(true,"Registered link: " + _link.name)


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
		setup(global_position)

func setup(_position:Vector2 = position) -> void:
	icon = $Icon
	draggable = $Draggable
	name = "Player"
	
	global_position = _position
	draggable.on_click.connect(on_click_player.emit)
	
	player_colour = Color.from_hsv(randf() * 360,1,1)
	
	#player_colour = Color(player_colour.r,player_colour.g,player_colour.b)
	
	_setup_finished = true

func _occupy_pin(_target_pin:Pin) -> void:
	if current_pin != null: 
		current_pin.occupant = null
		current_pin.draggable.on_moved.disconnect(_move_with_pin)
	
	current_pin = _target_pin
	current_evidence = _target_pin.evidence
	_target_pin.occupant = self
	current_pin.draggable.on_moved.connect(_move_with_pin)
	
	global_position = _target_pin.global_position
	on_occupy_pin.emit()


func _move_with_pin() -> void:
	global_position = current_pin.global_position


#endregion
