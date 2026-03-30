class_name Follower extends Node2D



### Leave false to follow mouse
#func follow(follow_raycaster:bool=false) -> void:
	#visible = true
	#while(visible):
		#if follow_raycaster: global_position = LevelManager.instance.raycaster.collision_point
		#else: global_position = get_global_mouse_position()
		#await get_tree().process_frame


## Leave false to follow mouse
func follow(target:Node2D = null) -> void:
	#print_rich("[color=yellow][b]Follower, target = ", "<null>" if (target == null) else target.name)
	if visible:
		stop()
		await get_tree().process_frame
	
	visible = true
	while(visible):
		if target is Raycaster:
			global_position = target.collision_point
		else:
			global_position = get_global_mouse_position()
		
		await get_tree().process_frame

func stop() -> void:
	visible = false
