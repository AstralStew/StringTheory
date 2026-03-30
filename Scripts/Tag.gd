class_name Tag extends Resource

@export var key : StringName = ""
@export var value : String = ""

func _init(_key="",_value="") -> void:
	key = _key
	value = _value


## NOTE > May not be necessary anymore
func compare(_tag:Tag) -> Test:
	if _tag.key != key:
		return Test.new(false,"Key '"+_tag.key+"' does not match tag '"+key+"'")
	if _tag.value != value:
		return Test.new(false,"Value '"+_tag.value+"' of key '"+_tag.key+"' does not match value '"+value+"'")
	
	return Test.new(true,"")
