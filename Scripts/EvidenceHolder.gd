class_name EvidenceHolder extends Node

#@onready var domain_tag := preload("res://Resources/Tags/Tag_Domain.tres")
@onready var evidence_prefab := preload("res://Assets/Scenes/evidence.tscn")

signal on_evidence_created(evidence)
signal on_evidence_clicked(evidence)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# NOTE -> Only necessary if placed in editor
	for evidence:Evidence in get_children():
		evidence.on_click_evidence.connect(on_evidence_clicked.emit.bind(evidence))
		#evidence.add_to_group("Evidence")


#region Internal variables

var _debug_name : String :
	get: return "[b][" + name + "][/b]"

#endregion



#region Create evidence

func create_evidence() -> Evidence:
	var _new_evidence : Evidence = evidence_prefab.instantiate()
	_new_evidence.setup()
	add_child(_new_evidence)
	_new_evidence.add_to_group("Evidence")
	set_evidence_tags(_new_evidence)
	#for _tag in _new_evidence.tags:
		#if has_domain(_tag).result:
			#_new_evidence.add_tag(domain_tag)
			#break
	return _new_evidence

func create_evidence_at_position(global_pos:Vector2) -> Evidence:
	var _new_evidence : Evidence = create_evidence()
	_new_evidence.global_position = global_pos
	_new_evidence.on_click_evidence.connect(on_evidence_clicked.emit.bind(_new_evidence))
	on_evidence_created.emit(_new_evidence)
	return _new_evidence

#endregion


func set_evidence_tags(_evidence:Evidence, _random_colour:bool=true,_random_type:bool=true,_random_level:bool=true) -> void:
	var options:Array
	if _random_colour:
		# Pick a random Colour tag
		options = ["res://Resources/Tags/Tag_Colour_Red.tres",
		"res://Resources/Tags/Tag_Colour_Blue.tres",
		"res://Resources/Tags/Tag_Colour_Green.tres",
		"res://Resources/Tags/Tag_Colour_Purple.tres"]
		_evidence.add_tag(load(options.pick_random()))
	
	if _random_type:
		# Pick a random Type tag
		options = ["res://Resources/Tags/Tag_Type_Item.tres",
		"res://Resources/Tags/Tag_Type_Location.tres",
		"res://Resources/Tags/Tag_Type_Person.tres"]
		_evidence.add_tag(load(options.pick_random()))
	
	if _random_level:
		# Pick level 1 - 3
		options = ["res://Resources/Tags/Tag_Level_1.tres",
		"res://Resources/Tags/Tag_Level_2.tres",
		"res://Resources/Tags/Tag_Level_3.tres"]
		_evidence.max_pins = randi_range(1,3)
		_evidence.add_tag(load(options[_evidence.max_pins-1]))
