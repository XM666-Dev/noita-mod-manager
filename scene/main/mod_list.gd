extends ItemList

class DragData:
	var selected_items: PackedInt32Array

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
	#var i := 1
	#var flag := drag_data.selected_items[0] < to_item
	#if flag:
	#if drag_data.selected_items[0] < to_item:
		#to_item -= 1
		#i = -1
		#drag_data.selected_items.reverse()
	if down:
		drag_data.selected_items.reverse()
	for selected_item in drag_data.selected_items:
		if down:
			to_item -= 1
		move_item(selected_item, to_item)
		if !down:
			to_item += 1
		#print(selected_item, " to ", to_item)
		#to_item += i
		#to_item -= 1 if flag else -1
		#if !flag:
			#to_item += 1
		#else:
			#to_item -= 1
		#else:
		#if flag:
			#to_item -= 1
		#move_item_ordered(selected_item, to_item)
		#to_item -= 1
	#if to_item > drag_data.selected_items[0]:
		#to_item -= 1
		#to_item += 1
	#var to_item := get_item_at_position_rect(at_position + get_scroll_amount())

#func move_item_ordered(from_idx: int, to_idx: int) -> void:
	#if from_idx < to_idx:
		#to_idx -= 1
	#move_item(from_idx, to_idx)
	#print(from_idx, " to ", to_idx)

#func get_item_at_position_rect(at_position: Vector2) -> int:
	#for item_index in item_count:
		#var item_rect := get_item_rect(item_index)
		#if item_rect.has_point(at_position):
			#return item_index
	#return -1

#func get_scroll_amount() -> Vector2:
	#var h_scroll_bar := get_h_scroll_bar()
	#var v_scroll_bar := get_v_scroll_bar()
	#return Vector2(h_scroll_bar.value, v_scroll_bar.value)

#func _process(delta: float) -> void:
	#queue_redraw()

#func _draw() -> void:
	#for item_index in item_count:
		#var item_rect := get_item_rect(item_index)
		#item_rect.position -= get_scroll_amount()
		#var color := Color.from_hsv(fmod(item_index / 8.0, 1), 1, 1)
		#draw_rect(item_rect, color, false)
