extends Control

var ship_types = ["Bomber", "Pi_Fighter", "Cross_Wing"]  # List of available ship types
var selected_index = 0  # Tracks current selection

@onready var ship_title = $ShipTitleLabel
@onready var ship_description = $ShipDescriptionLabel
@onready var prev_button = $PrevShipButton
@onready var next_button = $NextShipButton
@onready var start_button = $StartButton
@onready var ship_preview = $ShipPreview  # Reference AnimatedSprite2D

func _ready():
	update_ship_display()
	prev_button.connect("pressed", Callable(self, "_on_prev_pressed"))
	next_button.connect("pressed", Callable(self, "_on_next_pressed"))
	start_button.connect("pressed", Callable(self, "_on_start_pressed"))

func _on_prev_pressed():
	selected_index = (selected_index - 1 + ship_types.size()) % ship_types.size()
	update_ship_display()

func _on_next_pressed():
	selected_index = (selected_index + 1) % ship_types.size()
	update_ship_display()

func update_ship_display():
	var selected_type = ship_types[selected_index]

	ship_title.text = selected_type
	ship_description.text = GameManager.player_types[selected_type]["description"]
	ship_preview.frames = GameManager.player_types[selected_type]["animation_frames"]  # Set animation frames
	ship_preview.play("Forward")  # Play default animation

func _on_start_pressed():
	GameManager.selected_ship_type = ship_types[selected_index]  # Store selection
	GameManager.start_game()
