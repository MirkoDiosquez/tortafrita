extends Node2D

const ENEMY_SCENE = preload("res://Escenas/enemigo_lvl_1.tscn")
const WAVES = [3, 5, 7]
const NEXT_SCENE = "res://Escenas/nivel2.tscn"

var current_wave = 0
var enemies_alive = 0

func _ready() -> void:
	_start_wave()

func _start_wave() -> void:
	if current_wave >= WAVES.size():
		get_tree().change_scene_to_file(NEXT_SCENE)
		return

	var count = WAVES[current_wave]
	enemies_alive = count
	current_wave += 1

	for i in count:
		await get_tree().create_timer(i * 0.5).timeout
		_spawn_enemy()

func _spawn_enemy() -> void:
	var enemy = ENEMY_SCENE.instantiate()
	enemy.position = Vector2(randf_range(100, 900), randf_range(150, 550))
	enemy.tree_exited.connect(_on_enemy_died)
	add_child(enemy)

func _on_enemy_died() -> void:
	enemies_alive -= 1
	if enemies_alive <= 0:
		await get_tree().create_timer(2.0).timeout
		_start_wave()
