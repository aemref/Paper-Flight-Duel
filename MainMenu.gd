extends Control

func _ready():
	# Butonlara tıklanınca hangi fonksiyonun çalışacağını bağlıyoruz
	$VBoxContainer/EasyButton.pressed.connect(_on_easy_pressed)
	$VBoxContainer/MediumButton.pressed.connect(_on_medium_pressed)
	$VBoxContainer/HardButton.pressed.connect(_on_hard_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_button_pressed)

func _on_easy_pressed():
	start_game(1.0) # Normal hız

func _on_medium_pressed():
	start_game(1.5) # %50 daha hızlı

func _on_hard_pressed():
	start_game(2.5) # Çok hızlı

func start_game(multiplier: float):
	# Zorluk çarpanını Global'e kaydediyoruz
	Global.difficulty_speed_multiplier = multiplier
	# Oyunu başlatıyoruz
	get_tree().change_scene_to_file("res://Game.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
