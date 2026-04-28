## HordeManager: controla oleadas de enemigos en un nivel beat 'em up.
## Colocalo como nodo en la escena del nivel.
## 
## Configura las hordas desde el inspector con horde_configs.
## Cada horda define: cantidad de enemigos, posición X de zona, y limites del jugador.
extends Node

signal all_hordes_completed
signal horde_started(horde_index: int)
signal horde_completed(horde_index: int)

@export var enemy_scene: PackedScene = preload("res://Escenas/enemigo_lvl_1.tscn")
@export var boss_scene: PackedScene
@export var player_path: NodePath

## Configuración de cada horda: [[cant_enemigos, spawn_x_min, spawn_x_max, player_min_x, player_max_x], ...]
## Ejemplo: [[4, 400, 700, 15, 750], [5, 900, 1200, 750, 1300], [6, 1400, 1700, 1300, 1800]]
@export var horde_configs: Array[PackedFloat32Array] = []

## Posición X del boss (se usa player_min_x y player_max_x del último rango + margen)
@export var boss_spawn_position: Vector2 = Vector2(2000, 350)
@export var boss_player_min_x: float = 1800.0
@export var boss_player_max_x: float = 2200.0

## Delay entre hordas
@export var delay_between_hordes: float = 2.0
## Rango Y donde pueden spawnear enemigos
@export var spawn_y_min: float = 150.0
@export var spawn_y_max: float = 600.0

var player: CharacterBody2D
var current_horde: int = -1
var enemies_alive: int = 0
var total_hordes: int = 0
var boss_defeated: bool = false

func _ready() -> void:
	if player_path:
		player = get_node(player_path)
	else:
		# Intentar encontrar al player automáticamente
		player = _find_player()
	
	total_hordes = horde_configs.size()
	
	if total_hordes > 0:
		_start_next_horde()
	else:
		push_warning("HordeManager: No hay hordas configuradas!")

func _find_player() -> CharacterBody2D:
	for child in get_tree().current_scene.get_children():
		if child is CharacterBody2D and child.has_method("take_damage") and child.has_method("heal"):
			return child
	return null

func _start_next_horde() -> void:
	current_horde += 1
	
	if current_horde >= total_hordes:
		# Todas las hordas completadas, spawnear boss si hay
		if boss_scene:
			_spawn_boss()
		else:
			all_hordes_completed.emit()
		return
	
	await get_tree().create_timer(delay_between_hordes).timeout
	
	var config = horde_configs[current_horde]
	# config: [cant_enemigos, spawn_x_min, spawn_x_max, player_min_x, player_max_x]
	var enemy_count = int(config[0])
	var spawn_x_min = config[1]
	var spawn_x_max = config[2]
	var p_min_x = config[3]
	var p_max_x = config[4]
	
	# Bloquear al jugador en la zona
	if player:
		player.min_x = p_min_x
		player.max_x = p_max_x
	
	enemies_alive = enemy_count
	horde_started.emit(current_horde)
	
	# Spawnear enemigos
	for i in range(enemy_count):
		var enemy = enemy_scene.instantiate()
		var spawn_x = randf_range(spawn_x_min, spawn_x_max)
		var spawn_y = randf_range(spawn_y_min, spawn_y_max)
		enemy.global_position = Vector2(spawn_x, spawn_y)
		enemy.enemy_died.connect(_on_enemy_died)
		get_tree().current_scene.add_child(enemy)

func _on_enemy_died(_enemy: CharacterBody2D) -> void:
	enemies_alive -= 1
	if enemies_alive <= 0:
		horde_completed.emit(current_horde)
		# Liberar al jugador temporalmente para que avance
		if player:
			player.max_x = 10000000.0
		_start_next_horde()

func _spawn_boss() -> void:
	if player:
		player.min_x = boss_player_min_x
		player.max_x = boss_player_max_x
	
	var boss = boss_scene.instantiate()
	boss.global_position = boss_spawn_position
	if boss.has_signal("enemy_died"):
		boss.enemy_died.connect(_on_boss_died)
	get_tree().current_scene.add_child(boss)

func _on_boss_died(_boss) -> void:
	boss_defeated = true
	if player:
		player.max_x = 10000000.0
	all_hordes_completed.emit()
