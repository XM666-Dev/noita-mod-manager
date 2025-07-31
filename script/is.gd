class_name IS

static func event_is_mouse_button_pressed(event: InputEvent, button_index: MouseButton):
	var mouse_button_event := event as InputEventMouseButton
	return mouse_button_event != null && \
		mouse_button_event.button_index == button_index && \
		mouse_button_event.pressed

static func event_is_mouse_button_released(event: InputEvent, button_index: MouseButton):
	var mouse_button_event := event as InputEventMouseButton
	return mouse_button_event != null && \
		mouse_button_event.button_index == button_index && \
		!mouse_button_event.pressed

static func dir_exists_absolute(path: String) -> bool:
	return path.is_absolute_path() && DirAccess.dir_exists_absolute(path)

static func json_from_native(variant: Variant, serialized_properties: Dictionary[Script, PackedStringArray] = {}) -> Variant:
	if variant is Object:
		var object := variant as Object
		var object_script: Variant = object.get_script()
		var value: Variant = serialized_properties.get(object_script)
		if value != null:
			var object_serialized_properties: PackedStringArray = value
			var json := {}
			for property_path in object_serialized_properties:
				var property_value: Variant = object.get_indexed(property_path)
				json[property_path] = json_from_native(property_value, serialized_properties)
			return json
	if variant is Array:
		var array: Array = variant
		var json_converter := json_from_native.bind(serialized_properties)
		return array.map(json_converter)
	if variant is Dictionary:
		var dictionary: Dictionary = variant
		var json_converter := json_from_native.bind(serialized_properties)
		var dictionary_keys := dictionary.keys().map(json_converter)
		var dictionary_values := dictionary.values().map(json_converter)
		return dictionary_from_entries(dictionary_keys, dictionary_values)
	return variant

static func dictionary_from_entries(keys: Array, values: Array) -> Dictionary:
	var dictionary := {}
	for i in mini(keys.size(), values.size()):
		dictionary[keys[i]] = values[i]
	return dictionary

static func script_get_default_serialized_properties(script: Script) -> PackedStringArray:
	var property_list := script.get_script_property_list()
	var property_mapper := func(property: Dictionary) -> String: return property.name
	var script_file := script.resource_path.get_file()
	var property_filter := func(property: String) -> bool: return property != script_file
	return property_list.map(property_mapper).filter(property_filter)

static func string_rpad(string: String, min_length: int) -> String:
	var utf8_length := string.to_utf8_buffer().size()
	var unicode_length := string.length()
	@warning_ignore("integer_division")
	var full_width_chars := (utf8_length - unicode_length) / 3
	return string.rpad(maxi(min_length - full_width_chars, unicode_length + 1))
