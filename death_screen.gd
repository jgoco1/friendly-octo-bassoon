extends Control

@onready var score_label = $ScoreLabel
@onready var total_score_label = $TotalScoreLabel
@onready var restart_button = $RestartButton
@onready var menu_button = $MenuButton
@onready var fog_effect = $FogEffect  # Fog ambience effect

var lifetime_score = 0  
var total_score = 0  
var typed_text_lifetime = ""  
var typed_text_total = ""  
var full_text_lifetime = ""  
var full_text_total = ""  
var typing_speed = 0.05  

func _ready():
	lifetime_score = GameManager.lifetime_score
	total_score = GameManager.total_score
	# Ensure buttons are connected
	restart_button.connect("pressed", Callable(self, "_on_restart_pressed"))
	menu_button.connect("pressed", Callable(self, "_on_menu_pressed"))
	# Start with all UI elements hidden
	score_label.text = ""
	total_score_label.text = ""
	restart_button.visible = false
	menu_button.visible = false

	# Format final texts
	full_text_lifetime = "Lifetime Score: " + str(lifetime_score)
	full_text_total = "Total Score: " + str(total_score)

	# Wait before typing out scores
	await get_tree().create_timer(1.0).timeout  
	reveal_text(full_text_lifetime, score_label)

	await get_tree().create_timer(1.0).timeout  
	reveal_text(full_text_total, total_score_label)

	# Animate buttons scrolling in
	var tween = create_tween()
	tween.tween_property(restart_button, "position:y", restart_button.position.y + 50, 1.0)
	tween.tween_property(menu_button, "position:y", menu_button.position.y + 50, 1.0)

	await tween.finished  
	GameManager.lifetime_score = 0
	restart_button.visible = true
	menu_button.visible = true

func reveal_text(text, label):
	for i in range(text.length()):
		label.text += text[i]
		await get_tree().create_timer(typing_speed).timeout  

func _on_restart_pressed():
	get_tree().change_scene_to_file("res://asteroided.tscn")

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://StartMenu.tscn")
