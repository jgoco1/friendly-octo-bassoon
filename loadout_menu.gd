extends Control
var current_missile_index = 0
var special_slots


func _ready():
	var ship_type = GameManager.selected_ship_type
	special_slots = GameManager.player_types[ship_type].get("special_scenes", [])

	update_description()  # Ensure the first missile's details appear

	# Connect buttons to their functions
	$Confirm.connect("pressed", Callable(self, "_on_confirm_pressed"))
	$RightButton.connect("pressed", Callable(self, "_on_left_pressed"))
	$LeftButton.connect("pressed", Callable(self, "_on_right_pressed"))

	for i in range(8):  # Loop through manually placed slots
		var slot_name = "MSlot" + str(i + 1)
		var option_button = get_node(slot_name)

		if i < special_slots.size():
			option_button.disabled = false
			option_button.add_item("AIM-120")  # Set default missile choice
			special_slots[i] = "AIM-120"  # Ensure player selection persists
		else:
			option_button.disabled = true
			option_button.add_item("Slot Unavailable")  # Properly mark locked slots
		
		for missile_id in GameManager.missile_types.keys():
			option_button.add_item(missile_id)  # Populate dropdown options

func update_description():
	var missile_ids = GameManager.missile_types.keys()
	if current_missile_index >= missile_ids.size():
		current_missile_index = 0  # Reset to avoid out-of-bounds
	
	var missile_id = missile_ids[current_missile_index]
	var missile_data = GameManager.missile_types[missile_id]
	$DescriptionLabel.text = missile_id + "\n" + missile_data["description"] + "\nSpeed: " + str(missile_data["speed"]) + "\nDamage: " + str(missile_data["damage"])

func _on_confirm_pressed():
	special_slots.clear()  # Reset missile selections
	
	for i in range(8):  # Loop through manually placed slots
		var slot_name = "MSlot" + str(i + 1)
		var option_button = get_node(slot_name)
		var selected_index = option_button.get_selected()  # Get selected index
		var selected_missile = option_button.get_item_text(selected_index)  # Convert index to string
		
		# Store missile selections while ignoring locked slots
		if option_button.disabled or selected_missile == "Slot Unavailable":
			continue
		
		special_slots.append(selected_missile)  # Add valid selection

	GameManager.selected_missiles = special_slots  # Store final loadout in GameManager
	GameManager.start_game()  # Start game

#func _on_missile_selected(index):
	#var slot_name = "MSlot" + str(index + 1)
	#var option_button = get_node(slot_name)
	#var selected_missile = option_button.get_selected()  # Correctly retrieve selection
#
	#if index < special_slots.size() and selected_missile != "Slot Unavailable":
		#special_slots[index] = selected_missile  # Update stored selection

func _on_left_pressed():
	var missile_ids = GameManager.missile_types.keys()
	current_missile_index = (current_missile_index - 1) % missile_ids.size()
	update_description()

func _on_right_pressed():
	var missile_ids = GameManager.missile_types.keys()
	current_missile_index = (current_missile_index + 1) % missile_ids.size()
	update_description()
