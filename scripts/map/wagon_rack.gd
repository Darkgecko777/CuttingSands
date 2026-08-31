class_name WagonRackView
extends RefCounted

const GOLD := Color(0.92, 0.78, 0.45, 1)
const MUTED := Color(0.75, 0.62, 0.42, 1)
const GHOST := Color(0.86, 0.28, 0.22, 1)


static func fill(grid: GridContainer, draft_buy: Dictionary = {}, draft_sell: Dictionary = {}) -> void:
	for child in grid.get_children():
		child.queue_free()
	var cells: Array = []
	for good_id in GameState.GOODS.keys():
		var owned := int(GameState.inventory.get(good_id, 0))
		var selling := int(draft_sell.get(good_id, 0))
		var buying := int(draft_buy.get(good_id, 0))
		var keep := max(0, owned - selling)
		var name := GameState.get_good_name(good_id)
		for _i in keep:
			cells.append({"text": name, "ghost": false})
		for _j in selling:
			cells.append({"text": name, "ghost": true})
		for _k in buying:
			cells.append({"text": name, "ghost": true})
	for i in GameState.caravan_capacity:
		var cell := Label.new()
		cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cell.custom_minimum_size = Vector2(88, 64)
		if i < cells.size():
			var entry: Dictionary = cells[i]
			cell.text = str(entry.get("text", "?"))
			cell.add_theme_color_override("font_color", GHOST if bool(entry.get("ghost", false)) else GOLD)
		else:
			cell.text = "—"
			cell.add_theme_color_override("font_color", MUTED)
		grid.add_child(cell)
