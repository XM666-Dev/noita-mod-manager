extends ItemList

class DragData:
	var selected_items: PackedInt32Array

@export var default_preview_image: Texture2D = null

func _get_drag_data(_at_position: Vector2) -> Variant:
	var drag_data := DragData.new()
	var selected_items := get_selected_items()
	drag_data.selected_items = selected_items
	var label := Label.new()
	label.text = get_item_text(selected_items[0])
	set_drag_preview(label)
	return drag_data

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is DragData

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var to_item := get_item_at_position(at_position)
	var drag_data: DragData = data
	var down := drag_data.selected_items[0] < to_item
	if down:
		drag_data.selected_items.reverse()
	for selected_item in drag_data.selected_items:
		if down:
			to_item -= 1
		move_item(selected_item, to_item)
		if !down:
			to_item += 1
	Main.config.mod_config.clear()
	for item_index in item_count:
		var mod_element: ModElement = get_item_metadata(item_index)
		Main.config.mod_config.append(mod_element)
	Main.write_mod_config()

func update() -> void:
	clear()
	for mod_element in Main.config.mod_config:
		var mod := Main.find_mod(mod_element)
		if mod == null:
			continue
		var item_text := get_mod_item_text(mod_element)
		var item_icon := get_mod_item_icon(mod_element)
		var item_index := add_item(item_text, item_icon)
		var item_bg_color := get_mod_item_bg_color(mod_element)
		var item_fg_color := get_mod_item_fg_color(mod_element)
		var item_icon_modulate := get_mod_item_icon_modulate(mod_element)
		set_item_custom_bg_color(item_index, item_bg_color)
		set_item_custom_fg_color(item_index, item_fg_color)
		set_item_icon_modulate(item_index, item_icon_modulate)
		set_item_tooltip(item_index, mod.description)
		set_item_metadata(item_index, mod_element)

func get_mod_item_text(mod_element: ModElement) -> String:
	var mod := Main.find_mod(mod_element)
	var text := mod.name
	if text.is_empty():
		text = mod.id
	if !mod_element.enabled:
		text = "(已禁用) " + text
	var tags: Array = mod.workshop_tags
	if mod.workshop_id != 0:
		tags.push_front("创意工坊")
	var tags_string := ",".join(tags.map(TranslationServer.translate))
	var utf8_length := tags_string.to_utf8_buffer().size()
	var unicode_length := tags_string.length()
	@warning_ignore("integer_division")
	var full_width_chars := (utf8_length - unicode_length) / 3
	return IS.string_rpad(text, 80 - unicode_length - full_width_chars, 2) + tags_string

func get_mod_item_icon(mod_element: ModElement) -> Texture2D:
	var mod := Main.find_mod(mod_element)
	var item_icon := mod.workshop_preview_image
	if item_icon != null:
		return item_icon
	return default_preview_image

func get_mod_item_bg_color(mod_element: ModElement) -> Color:
	if mod_element.enabled:
		return Color(0.5, 0.5, 0.5, 0.5)
	return Color(0, 0, 0, 0)

func get_mod_item_fg_color(mod_element: ModElement) -> Color:
	var mod := Main.find_mod(mod_element)
	var text := mod.name
	if text.is_empty():
		text = mod.id
	if text.similarity(%SearchEdit.text) > 0.25:
		return Color.GREEN
	return Color.BLACK

func get_mod_item_icon_modulate(mod_element: ModElement) -> Color:
	if mod_element.enabled:
		return Color.WHITE
	return Color.DIM_GRAY


func _on_item_activated(index: int) -> void:
	var mod_element: ModElement = get_item_metadata(index)
	mod_element.enabled = !mod_element.enabled
	set_item_text(index, get_mod_item_text(mod_element))
	set_item_custom_bg_color(index, get_mod_item_bg_color(mod_element))
	set_item_icon_modulate(index, get_mod_item_icon_modulate(mod_element))
	Main.write_mod_config()


func _on_item_clicked(index: int, _at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_on_item_activated(index)


func _on_search_edit_text_changed(_new_text: String) -> void:
	for item_index in item_count:
		var mod_element: ModElement = get_item_metadata(item_index)
		set_item_custom_fg_color(item_index, get_mod_item_fg_color(mod_element))
