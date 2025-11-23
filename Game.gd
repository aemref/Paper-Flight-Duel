# Game.gd - DÜZELTİLMİŞ VERSİYON (Fırlatma Hatası Giderildi)
extends Node2D

@export var plane_black_scene: PackedScene
@export var plane_yellow_scene: PackedScene

enum GameState { PLAYER1_AIM, PLAYER2_AIM, FLYING, ROUND_OVER, GAME_OVER }

var current_state: GameState = GameState.PLAYER1_AIM
var current_player: int = 1
var current_plane: RigidBody2D 

# --- Difficulty & Physics Parameters ---
var base_power_speed: float = 600.0
var base_angle_speed: float = 40.0

var launch_power: float = 500.0
var max_power: float = 1500.0
var min_power: float = 200.0
var power_direction: int = 1

var launch_angle: float = -45.0
var min_angle: float = -80.0
var max_angle: float = -10.0
var angle_direction: int = 1

var launch_position: Vector2 = Vector2(100, 400)
var aiming_stage: String = "angle"

# --- Nodes ---
var arrow: Sprite2D
var player_black: Sprite2D
var player_yellow: Sprite2D
var camera: Camera2D

# --- Round & Score System ---
var current_round: int = 1
var max_rounds: int = 3
var p1_total_score: float = 0.0
var p2_total_score: float = 0.0

# --- YENİ EKLENEN: Koruma Süresi ---
var landing_check_timer: float = 0.0

signal update_ui_text(text: String)
signal update_power_bar(power: float, min_p: float, max_p: float)
signal update_angle(angle: float)
signal show_results(p1_dist: float, p2_dist: float)

func _ready():
    arrow = $Arrow
    player_black = $PlayerBlack
    player_yellow = $PlayerYellow
    camera = $Camera2D
    
    # Global zorluk ayarını çek
    if has_node("/root/Global"): # Hata almamak için kontrol
        base_power_speed *= Global.difficulty_speed_multiplier
        base_angle_speed *= Global.difficulty_speed_multiplier
    
    start_game()

func start_game():
    p1_total_score = 0.0
    p2_total_score = 0.0
    current_round = 1
    start_new_turn_setup()

func start_new_turn_setup():
    current_player = 1
    launch_power = min_power
    power_direction = 1
    launch_angle = (min_angle + max_angle) / 2.0
    angle_direction = 1
    aiming_stage = "angle"
    
    emit_signal("update_power_bar", min_power, min_power, max_power)
    
    if camera:
        camera.position = Vector2(573, 321)
    
    if arrow: arrow.visible = true
    if player_black: player_black.visible = true
    if player_yellow: player_yellow.visible = false
    
    if current_plane:
        current_plane.queue_free()
        current_plane = null
        
    set_state(GameState.PLAYER1_AIM)

func _process(delta: float):
    if current_state == GameState.PLAYER1_AIM or current_state == GameState.PLAYER2_AIM:
        handle_aiming(delta)
    
    elif current_state == GameState.FLYING:
        # Delta'yı buraya gönderiyoruz ki süreyi düşebilelim
        check_plane_landed(delta)
        update_camera_follow()

func handle_aiming(delta: float):
    if aiming_stage == "angle":
        launch_angle += base_angle_speed * angle_direction * delta
        if launch_angle >= max_angle:
            launch_angle = max_angle
            angle_direction = -1
        elif launch_angle <= min_angle:
            launch_angle = min_angle
            angle_direction = 1
        
        if arrow: arrow.rotation_degrees = launch_angle
        emit_signal("update_angle", launch_angle)
        
    elif aiming_stage == "power":
        launch_power += base_power_speed * power_direction * delta
        if launch_power >= max_power:
            launch_power = max_power
            power_direction = -1
        elif launch_power <= min_power:
            launch_power = min_power
            power_direction = 1
        
        emit_signal("update_power_bar", launch_power, min_power, max_power)
    
    if Input.is_action_just_pressed("p1_launch") or Input.is_action_just_pressed("p2_launch"):
        if aiming_stage == "angle":
            aiming_stage = "power"
            if arrow: arrow.visible = false
            update_ui_for_power()
        elif aiming_stage == "power":
            launch_plane()

func update_camera_follow():
    if current_plane and is_instance_valid(current_plane) and camera:
        if current_plane.global_position.x > camera.position.x:
            
            camera.position.x = current_plane.global_position.x
            
            camera.position.y = current_plane.global_position.y
func update_ui_for_power():
    var p_name = "🖤 P1" if current_player == 1 else "💛 P2"
    emit_signal("update_ui_text", "%s - SET POWER!" % p_name)

func launch_plane():
    var scene = plane_black_scene if current_player == 1 else plane_yellow_scene
    if !scene: return
    
    current_plane = scene.instantiate()
    current_plane.position = launch_position
    current_plane.rotation_degrees = launch_angle
    add_child(current_plane)
    current_plane.sleeping = false
    
    var impulse = Vector2.from_angle(deg_to_rad(launch_angle)) * launch_power
    current_plane.apply_central_impulse(impulse)
    
    # --- DÜZELTME BURADA ---
    # Uçak fırlatıldıktan sonra 1 saniye boyunca yere inip inmediğini kontrol etme.
    # Bu, fizik motorunun uçağı hızlandırmasına zaman tanır.
    landing_check_timer = 1.0 
    
    set_state(GameState.FLYING)

func check_plane_landed(delta: float):
    # Eğer hala koruma süresindeysek, süreyi azalt ve fonksiyondan çık.
    if landing_check_timer > 0:
        landing_check_timer -= delta
        return

    # Koruma süresi bittikten sonra normal kontrolleri yap
    if current_plane and (current_plane.sleeping or current_plane.linear_velocity.length() < 5):
        plane_has_landed()

func plane_has_landed():
    var distance = max(0, current_plane.global_position.x - launch_position.x)
    
    if current_player == 1:
        p1_total_score += distance
        current_player = 2
        
        aiming_stage = "angle"
        launch_power = min_power
        launch_angle = (min_angle + max_angle) / 2.0
        emit_signal("update_power_bar", min_power, min_power, max_power)
        
        if camera: camera.position = Vector2(573, 321)
        
        if player_black: player_black.visible = false
        if player_yellow: player_yellow.visible = true
        if arrow: arrow.visible = true
        
        # P1 uçağını sahnede bırak (Referansı sil ama objeyi silme, böylece yerde görünür)
        # Sadece yeni atış yapılırken silinecek (start_new_turn_setup fonksiyonunda)
        current_plane = null 
        
        set_state(GameState.PLAYER2_AIM)
        
    else:
        p2_total_score += distance
        current_plane = null
        
        if current_round < max_rounds:
            current_round += 1
            start_new_turn_setup()
        else:
            set_state(GameState.GAME_OVER)

func set_state(new_state):
    current_state = new_state
    match current_state:
        GameState.PLAYER1_AIM:
            emit_signal("update_ui_text", "Round %d/%d - 🖤 P1 AIM" % [current_round, max_rounds])
        GameState.PLAYER2_AIM:
            emit_signal("update_ui_text", "Round %d/%d - 💛 P2 AIM" % [current_round, max_rounds])
        GameState.FLYING:
            emit_signal("update_ui_text", "✈️ Flying...")
        GameState.GAME_OVER:
            emit_signal("update_ui_text", "🏆 FINAL RESULTS 🏆")
            emit_signal("show_results", p1_total_score, p2_total_score)

func _on_ui_retry_game():
    for child in get_children():
        if child is RigidBody2D:
            child.queue_free()
    start_game()

func _on_ui_back_to_menu():
    get_tree().change_scene_to_file("res://MainMenu.tscn")
