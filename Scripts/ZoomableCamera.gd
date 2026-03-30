class_name ZoomableCamera extends Camera2D


enum CameraMode {Free,Follow}


@export_category("Free Mode")

@export var mouse_move_amount = 0.9
@export var mouse_zoom_amount = 0.1

@export_category("Follow Mode")

@export var follow_default_zoom = 1.0

@export var follow_speed : float = 5.0 :
	get: return follow_speed
	set(value):
		position_smoothing_speed = value
		follow_speed = value


@export_category("READ ONLY")

@export var mode : CameraMode = CameraMode.Free
@export var follow_target : Node2D = null

static var current_zoom : Vector2 = Vector2.ONE

var move_camera:=false



var _debug_name : String :
	get: return "[b][" + name + "][/b]"


func _ready() -> void:
	if follow_target != null:
		follow(follow_target)



func be_free() -> void:
	mode = CameraMode.Free
	position_smoothing_enabled = false

func _unhandled_input(e: InputEvent) -> void:
	
	if e.is_action_pressed("camera_follow"):
		print_rich(_debug_name," Got CameraFollow input...")
		follow(follow_target)
		return
	
	if e is InputEventMouseButton:
		if e.is_action_pressed("camera_pan"):
			if mode != CameraMode.Free:
				print_rich(_debug_name," Got input, switching to Free Mode...")
				be_free()
			move_camera=true
			
		elif e.is_action_pressed("camera_zoom_in"):
			if mode == CameraMode.Free: move_to_mouse_pos(1.0)
			apply_zoom(1.0)
			
		elif e.is_action_pressed("camera_zoom_out"):
			if mode == CameraMode.Free: move_to_mouse_pos(-1.0)
			apply_zoom(-1.0)
			
		elif e.is_action_released("camera_pan"):
			move_camera=false
		return
	
	if e is InputEventMouseMotion and move_camera:
		position+=-e.relative/zoom.x
		return

func move_to_mouse_pos(zoom_direction:float)->void:
	if zoom_direction == 1.0:
		global_position=lerp(get_global_mouse_position(), global_position, mouse_move_amount)
	else:
		global_position=lerp(get_global_mouse_position(), global_position, 1+(1-mouse_move_amount))

func apply_zoom(zoom_direction:float) -> void:
	zoom = clamp(zoom * (1.0 + (mouse_zoom_amount * zoom_direction)), Vector2(0.15,0.15),Vector2(10,10))
	current_zoom = zoom



func follow(target:Node2D) -> void:
	if target == null:
		print_rich(_debug_name," Follow > No target defined! Cancelling.")
		return
	
	move_camera = false
	mode = CameraMode.Follow
	position_smoothing_enabled = true
	zoom = Vector2(follow_default_zoom, follow_default_zoom)
	
	print_rich(_debug_name," Follow > Starting to follow target '",target.name,"'")
	while(mode == CameraMode.Follow):
		global_position = target.global_position
		await get_tree().process_frame










#var zoomSpd: float = 0.05*zoom.y
#var Minzoom: float = 0.1
#var Maxzoom: float = 1.0
#var dragSen: float = 1.0
#var spd = zoomSpd*3.5*zoom.y*zoom.y ##comfortable zoom/pan speed still a bit jagged.
#
#
#
#func _input(event):
	#var mouse_position = get_global_mouse_position()
	#var mouse_delta = mouse_position - global_position
	#if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		#
		#position -= event.relative * (dragSen/zoom.y)#pretty sure this last bit is the way you get it to scale.
		#print("position = ", position)
	#
	#if event is InputEventMouseButton: #for zooming
		#if event.button_index == MOUSE_BUTTON_WHEEL_UP and zoom.y!=Maxzoom:
			#zoom += Vector2(zoomSpd,zoomSpd)
			#position += mouse_delta * spd
		#elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			#zoom -= Vector2(zoomSpd,zoomSpd)
			#if zoom.y>Minzoom:
				#position -= mouse_delta * spd 
		#
		#zoom = clamp(zoom, Vector2(Minzoom, Minzoom), Vector2(Maxzoom, Maxzoom)) #Limits the zooming
