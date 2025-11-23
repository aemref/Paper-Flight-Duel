# UI.gd - Power Bar Gösterimi
extends CanvasLayer

signal retry_game
signal back_to_menu

var status_label: Label
var power_bar: ProgressBar
var results_panel: PanelContainer
var results_text: Label
var p1_score_text: Label
var p2_score_text: Label

func _ready():
	# Node referansları
	status_label = $StatusLabel
	power_bar = $PowerBar
	results_panel = $ResultsPanel
	results_text = $ResultsPanel/VBoxContainer/ResultsText
	p1_score_text = $ResultsPanel/VBoxContainer/P1ScoreText
	p2_score_text = $ResultsPanel/VBoxContainer/P2ScoreText
	
	# Başlangıçta panel gizli
	results_panel.visible = false
	
	# PowerBar'ı görünür yap ve kontrol et
	if power_bar:
		power_bar.visible = true
		print("PowerBar bulundu ve görünür yapıldı")
	else:
		print("HATA: PowerBar bulunamadı!")
	
	if status_label:
		status_label.visible = true
		print("StatusLabel bulundu")
	
	# Buton bağlantıları
	$ResultsPanel/VBoxContainer/RetryButton.pressed.connect(_on_retry_button_pressed)
	$ResultsPanel/VBoxContainer/MenuButton.pressed.connect(_on_menu_button_pressed)

func _on_game_update_ui_text(text: String):
	if status_label:
		status_label.text = text

func _on_game_update_angle(_angle: float):
	# Artık ok Game.gd'de kontrol ediliyor
	pass

func _on_game_update_power_bar(power: float, min_p: float, max_p: float):
	if power_bar:
		power_bar.min_value = min_p
		power_bar.max_value = max_p
		power_bar.value = power
		
		# Renk değiştir (yeşilden kırmızıya)
		var percentage = (power - min_p) / (max_p - min_p)
		var bar_color = Color(percentage, 1.0 - percentage, 0.0)
		
		# Godot 4 için renk değiştirme
		power_bar.modulate = bar_color

func _on_game_show_results(p1_dist: float, p2_dist: float):
	if results_panel:
		results_panel.visible = true
	
	if p1_score_text:
		p1_score_text.text = "🖤 Black Plane: %.1f m" % p1_dist
	
	if p2_score_text:
		p2_score_text.text = "💛 Yellow Plane: %.1f m" % p2_dist
	
	if results_text:
		if p1_dist > p2_dist:
			results_text.text = "🏆 BLACK PLANE WINS! 🏆"
		elif p2_dist > p1_dist:
			results_text.text = "🏆 YELLOW PLANE WINS! 🏆"
		else:
			results_text.text = "⚖️ IT'S A TIE! ⚖️"

func _on_retry_button_pressed():
	if results_panel:
		results_panel.visible = false
	emit_signal("retry_game")

func _on_menu_button_pressed():
	emit_signal("back_to_menu")
