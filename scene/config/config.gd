class_name Config extends Resource

static var serialized_properties: PackedStringArray = IS.script_get_default_serialized_properties(Config)

@export var game_dir: String = ""
@export var workshop_dir: String = ""
@export var mod_config: Array[ModElement] = []

func merge(json: Dictionary) -> void:
	var keys := json.keys()
	var property_filter := func(key: String) -> bool: return key in serialized_properties
	keys = keys.filter(property_filter)
	for key in keys:
		set(key, json[key])
