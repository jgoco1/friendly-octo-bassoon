extends Control

@onready var username_field = $UsernameInput
@onready var password_field = $PasswordInput
@onready var login_button = $LoginButton
@onready var status_label = $StatusLabel

var user_profiles = {}  # Dictionary to store user profiles

func _ready():
	load_profiles()  # Load existing profiles from JSON
	login_button.connect("pressed", Callable(self, "_on_login_pressed"))
	username_field.connect("focus_entered", Callable(self, "_on_username_input_focused"))
	password_field.connect("focus_entered", Callable(self, "_on_password_input_focused"))

func _on_login_pressed():
	var username = username_field.text.strip_edges()
	var password = password_field.text.strip_edges()

	if username in user_profiles:
		if user_profiles[username]["password"] == hash_password(password):  # Compare hashed passwords
			GameManager.selected_username = username
			GameManager.total_score = user_profiles[username]["points"]
			get_tree().change_scene_to_file("res://StartMenu.tscn")
		else:
			status_label.text = "Incorrect password!"
	else:
		# Create a new user profile with a **hashed** password
		user_profiles[username] = {
			"password": hash_password(password),
			"points": 0,
			"date_created": Time.get_unix_time_from_system()
		}
		save_profiles()
		GameManager.selected_username = username
		GameManager.total_score = 0
		get_tree().change_scene_to_file("res://StartMenu.tscn")
		
func _on_username_input_focus_entered():
	username_field.grab_focus()

func _on_password_input_focus_entered():
	password_field.grab_focus()

func load_profiles():
	var file = FileAccess.open("user_profiles.json", FileAccess.READ)
	if file:
		user_profiles = JSON.parse_string(file.get_as_text())
		file.close()

func save_profiles():
	var json_data = JSON.stringify(user_profiles)
	var file = FileAccess.open("user_profiles.json", FileAccess.WRITE)
	if file:
		file.store_string(json_data)
		file.close()
		print("Profiles saved successfully!")

	GameManager.load_profiles()  # Reload GameManager profiles after saving
	
func update_user_points(username, new_points):
	if username in user_profiles:
		user_profiles[username]["points"] = new_points
		save_profiles()

func hash_password(password: String) -> String:
	return password.md5_text()  # Generates an MD5 hash
