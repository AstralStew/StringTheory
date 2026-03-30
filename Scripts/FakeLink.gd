class_name FakeLink extends Line2D

@export var move_speed : float =50.0
@export var valid_colour : Color = Color(0,1,0,0.5)
@export var invalid_colour : Color = Color(1,0,0,0.5)

var valid : bool = false :
	get: return valid
	set(value):
		valid = value
		default_color = valid_colour if value else invalid_colour

func _ready() -> void:
	z_index = 20
	valid = false


func follow(target:Node2D = null, max_length:float = 0.0) -> void:
	print_rich("[color=cyan][b]FakeLink, max length = ",max_length)
	if visible:
		visible = false
		await get_tree().process_frame
	
	visible = true
	var old_pos:Vector2
	var pos:Vector2
	while(visible):
		old_pos = points[1]
		clear_points()
		add_point(Vector2.ZERO)
		
		if target == null:
			if max_length == 0.0:
				pos = get_global_mouse_position()
			else: pos = global_position + (max_length * (get_global_mouse_position() - global_position).normalized())
			
		elif target is Raycaster:
			if max_length == 0.0: pos = target.collision_point
			else: pos = global_position + (max_length * (target.collision_point - global_position).normalized())
			
		else:
			if max_length == 0.0: pos = target.global_position
			else: pos = global_position + (max_length * (target.global_position - global_position).normalized())
		
		pos = to_local(pos)
		add_point(lerp(old_pos,pos,0.2)) # .move_toward(pos,move_speed))#old_pos.move_toward(to_local(pos),move_speed * get_process_delta_time()))
		print("pos=",pos,", old_pos=",old_pos)
		await get_tree().process_frame
