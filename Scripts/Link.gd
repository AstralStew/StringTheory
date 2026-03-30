class_name Link extends Line2D

var area : Area2D = null
var collision_polygon : CollisionPolygon2D = null
#var segment_shape : SegmentShape2D = null

@export var pin1 : Pin = null
@export var pin2 : Pin = null

@export var threaded_by : Player = null

@export var is_threaded : bool :
	get: return threaded_by != null

signal on_click_link

#region Public functions

func get_other_pin(current_pin:Pin) -> Pin:
	if current_pin == pin1:
		return pin2
	elif current_pin == pin2:
		return pin1
	else:
		push_warning(_debug_name," WARNING > Link not on provided pin! Returning null.")
		return null

func set_positions() -> void:
	clear_points()
	global_position = lerp(pin1.global_position, pin2.global_position, 0.5)
	add_point(to_local(pin1.global_position))
	add_point(to_local(pin2.global_position))
	
	update_polygon()
	
	#segment_shape.a = get_point_position(0)
	#segment_shape.b = get_point_position(1)

func thread(thread_owner:Player) -> Test:
	if is_threaded && thread_owner != null:
		print_rich("[color=996666]",_debug_name," Thread > Link is already threaded! Cancelling.[/color]")
		return Test.new(false,"Link already threaded")
	elif !is_threaded && thread_owner == null:
		print_rich("[color=996666]",_debug_name," Thread > Already unthreaded & no thread owner provided! Cancelling.[/color]")
		return Test.new(false,"Link already unthreaded")
	
	threaded_by = thread_owner
	modulate = thread_owner.player_colour if is_threaded else Color.BLACK
	
	return Test.new(true,"Success," + (" link threaded by '" + thread_owner.name + "'") if is_threaded else " link unthreaded")

#endregion




#region Internal variables

var _debug_name : String :
	get: return "[b][" + name + "][/b]"

#endregion

#region Internal functions

# Called when the node enters the scene tree for the first time.
func _init(_pin1:Pin=null,_pin2:Pin=null) -> void:
	if _pin1 == null || _pin2 == null:
		print_rich("[b][i][color=red]Link is bad, cancelling")
		return
	pin1 = _pin1
	pin1.draggable.on_moved.connect(set_positions)
	pin1.add_link(self)
	
	pin2 = _pin2
	pin2.draggable.on_moved.connect(set_positions)
	pin2.add_link(self)
	
	
	area = Area2D.new()
	area.name = "Area2D"
	add_child(area)
	area.position = Vector2.ZERO
	
	collision_polygon = CollisionPolygon2D.new()
	collision_polygon.name = "CollisionPolygon2D"
	area.add_child(collision_polygon)
	collision_polygon.position = Vector2.ZERO 
	
	set_positions()
	
	#segment_shape = SegmentShape2D.new()
	#_collision_shape.shape = segment_shape
	
	area.input_event.connect(_on_input_event)
	
	modulate = Color.BLACK
	z_index = 20
	
	name = "Link<" + pin1.name + "-" + pin2.name +">"
	


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	
	#print(_debug_name, " got input event")
	if event is InputEventMouseButton and event.is_action_pressed("mouse_left_click"):
		print(_debug_name, " got mouse click event")
		on_click_link.emit()


func update_polygon() -> void:
	var _dir : Vector2 = (pin2.global_position - pin1.global_position).normalized()
	var thickener : Vector2 = _dir.orthogonal() * 5.0
	
	var _verts : PackedVector2Array = PackedVector2Array([
		get_point_position(0) + thickener,
		get_point_position(0) - thickener,
		get_point_position(1) - thickener,
		get_point_position(1) + thickener
	])
	collision_polygon.polygon = _verts

#endregion
