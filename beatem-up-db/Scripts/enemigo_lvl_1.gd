extends CharacterBody2D

signal enemy_died(enemy: CharacterBody2D)

@onready var anim = $AnimatedSprite2D
@onready var sight_area = $DetectionArea
@onready var attack_area = $AttackZone
@onready var attack_cooldown = $Cooldown

const SPEED = 180.0
const PATROL_SPEED = 90.0
const MAX_HEALTH = 25
const ATTACK_DAMAGE = 10
const ATTACK_DISTANCE = 40 

## Probabilidad de soltar item de vida (0.0 a 1.0)
@export var health_drop_chance: float = 0.3
var health_pickup_scene: PackedScene = preload("res://Escenas/health_pickup.tscn")

var current_health = MAX_HEALTH
var player = null
var in_sight = false
var in_range = false
var is_attacking = false
var is_hit = false
var is_dead = false
var can_attack = true
var patrol_direction = Vector2.RIGHT
var patrol_timer = 0.0
var last_direction_x = 1.0

const PATROL_CHANGE_TIME = 2.0

func _ready() -> void:
	attack_cooldown.timeout.connect(_on_attack_cooldown_timeout)
	patrol_direction = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN].pick_random()
	
	sight_area.body_entered.connect(_on_sight_area_body_entered)
	sight_area.body_exited.connect(_on_sight_area_body_exited)
	
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)
	
	anim.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if is_dead or is_attacking or is_hit:
		return

	position.x = clamp(position.x, 15, 10000000)
	position.y = clamp(position.y, 110, 670)

	if in_sight and player != null:
		if in_range and can_attack:
			_attack()
		else:
			_follow()
	else:
		_patrol(delta)

	move_and_slide()

func _update_facing(dir_x: float) -> void:
	if dir_x != 0:
		last_direction_x = sign(dir_x)
	anim.flip_h = last_direction_x < 0
	attack_area.position.x = abs(attack_area.position.x) * last_direction_x

func _follow() -> void:
	var direction = (player.global_position - global_position).normalized()
	var dist = global_position.distance_to(player.global_position)

	if dist < ATTACK_DISTANCE:
		velocity = Vector2.ZERO
	else:
		velocity = direction * SPEED

	# Siempre mirar hacia el jugador, incluso si está arriba/abajo
	var diff_x = player.global_position.x - global_position.x
	_update_facing(diff_x)

	anim.play("enemy_run")

func _patrol(delta: float) -> void:
	patrol_timer += delta 
	
	if patrol_timer >= PATROL_CHANGE_TIME:
		patrol_timer = 0.0
		patrol_direction = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN].pick_random()

	velocity = patrol_direction * PATROL_SPEED

	_update_facing(patrol_direction.x)

	anim.play("enemy_run")

func _attack() -> void:
	is_attacking = true
	can_attack = false
	velocity = Vector2.ZERO
	# Actualizar dirección hacia el jugador antes de atacar
	if player != null:
		var diff_x = player.global_position.x - global_position.x
		_update_facing(diff_x)
	else:
		_update_facing(last_direction_x)

	anim.play("enemy_attack")
	attack_cooldown.start()

func take_damage(amount: int) -> void:
	if is_dead:
		return
	is_attacking = false
	current_health -= amount
	current_health = max(current_health, 0)
	if current_health <= 0:
		_die()
	else:
		is_hit = true
		velocity = Vector2.ZERO
		anim.play("enemy_hited")

func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	_try_drop_health()
	enemy_died.emit(self)
	anim.play("enemy_dead")

func _try_drop_health() -> void:
	if randf() <= health_drop_chance:
		var pickup = health_pickup_scene.instantiate()
		pickup.global_position = global_position
		get_tree().current_scene.add_child(pickup)

func _on_animation_finished() -> void:
	if anim.animation == "enemy_attack":
		is_attacking = false
		if player != null:
			player.take_damage(ATTACK_DAMAGE)

	elif anim.animation == "enemy_hited":
		is_hit = false

	elif anim.animation == "enemy_dead":
		queue_free()

func _on_sight_area_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("take_damage"):
		player = body
		in_sight = true

func _on_sight_area_body_exited(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("take_damage"):
		player = null
		in_sight = false

func _on_attack_area_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("take_damage"):
		in_range = true

func _on_attack_area_body_exited(body: Node) -> void:
	if body is CharacterBody2D and body.has_method("take_damage"):
		in_range = false

func _on_attack_cooldown_timeout() -> void:
	can_attack = true
