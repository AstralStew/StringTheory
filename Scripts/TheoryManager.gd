class_name TheoryManager extends Node


@onready var domain_tag := preload("res://Resources/Tags/Tag_Domain.tres")

@export var domains : Array[Tag] = []


var _debug_name : String :
	get: return "[b][" + name + "][/b]"


#region Domain functions

func add_domain(_tag:Tag) -> Test:
	if has_domain(_tag).result:
		print_rich(_debug_name," AddDomain > Tag '"+_tag.key+"="+str(_tag.value)+"' already present, cancelling")
		return Test.new(false,"Tag '"+_tag.key+"="+str(_tag.value)+"' already present")
	else:
		domains.append(_tag)
		_apply_domains()
		return Test.new(true,"")

func has_domain(_tag:Tag) -> Test:
	print_rich(_debug_name," HasDomain > Checking tag '"+_tag.key+"="+str(_tag.value)+"'...")
	if domains.has(_tag):
		print_rich(_debug_name," HasDomain > Found '"+_tag.key+"="+str(_tag.value)+"', returning true")
		return Test.new(true,"")
	
	print_rich(_debug_name," HasDomain > Did not find '"+_tag.key+"="+str(_tag.value)+"', returning false")
	return Test.new(false,"No matching results")


func check_evidence_for_domains(_evidence:Evidence, _add_tag_if_applicable:bool=false) -> bool:
		for domain in domains:
			if _evidence.has_tag(domain).result:
				if _add_tag_if_applicable:
					_evidence.add_tag(domain_tag)
				return true
		return false


func _apply_domains() -> void:
	for _evidence:Evidence in get_tree().get_nodes_in_group("Evidence"):
		if _evidence.has_tag(domain_tag).result:
			continue
		if check_evidence_for_domains(_evidence):
			_evidence.add_tag(domain_tag)

	# Change domain text
	var _domain_list : String 
	for domain in domains:
		_domain_list += str(domain.value) + " ("+domain.key+")"
	#domain_text.text = "[b]Domains:[/b]  " + _domain_list


#endregion
