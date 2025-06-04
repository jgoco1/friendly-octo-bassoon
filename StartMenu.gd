extends Control

var ship_types = ["Cross_Wing", "Bomber", "Pi_Fighter"]  # List of available ship types
var selected_index = 0  # Tracks current selection

@onready var ship_title = $ShipTitleLabel
@onready var ship_description = $ShipDescriptionLabel
@onready var prev_button = $PrevShipButton
@onready var next_button = $NextShipButton
@onready var start_button = $StartButton
@onready var ship_preview = $ShipPreview  # Reference AnimatedSprite2D


@onready var username_label = $UsernameLabel
@onready var points_label = $TotalPointsLabel
@onready var logout_button = $LogoutButton

func _ready():
	update_ship_display()
	prev_button.connect("pressed", Callable(self, "_on_prev_pressed"))
	next_button.connect("pressed", Callable(self, "_on_next_pressed"))
	start_button.connect("pressed", Callable(self, "_on_start_pressed"))
	username_label.text = "Logged in as: " + GameManager.selected_username
	points_label.text = "Total Points: " + str(GameManager.total_score)
	logout_button.connect("pressed", Callable(self, "_on_logout_pressed"))

func _on_prev_pressed():
	selected_index = (selected_index - 1 + ship_types.size()) % ship_types.size()
	update_ship_display()

func _on_next_pressed():
	selected_index = (selected_index + 1) % ship_types.size()
	update_ship_display()
	
func _on_logout_pressed():
	GameManager.selected_username = ""
	get_tree().change_scene_to_file("res://LoginScreen.tscn")

func update_ship_display():
	var selected_type = ship_types[selected_index]

	ship_title.text = selected_type
	ship_description.text = GameManager.player_types[selected_type]["description"]
	ship_preview.frames = GameManager.player_types[selected_type]["animation_frames"]  # Set animation frames
	ship_preview.play("Forward")  # Play default animation

func _on_start_pressed():
	GameManager.selected_ship_type = ship_types[selected_index]  # Store selection
	GameManager.loadout_menu()
