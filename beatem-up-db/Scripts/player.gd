extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var Cooldown = $Cooldown
@onready var attack_zone = $AttackZone
@onready var health_bar = $HealthBar
@onready var shield_bar = $ShieldBar
@onready var shield_regen_time = $ShieldRegenTime

const maxHealth = 100
const maxShield = 100
const regenShield = 1
const shieldDamageMulti = 2
const SPEED = 200.0

var currentHealth = maxHealth
var currentShield = maxShield
var is_defending = false
var is_attacking = false
var can_attack = true
var aim = Vector2.RIGHT
var enemies_in_range = []

## Limites horizontales - el HordeManager los modifica para bloquear avance
var min_x: float = 15.0
var max_x: float = 10000000.0


func _ready() -> void:
	attack_zone.body_entered.connect(_on_attack_zone_body_entered)
	attack_zone.body_exited.connect(_on_attack_zone_body_exited)
	anim.animation_finished.connect(_on_animation_finished)
	health_bar.max_value = maxHealth
	health_bar.value = currentHealth
	shield_bar.max_value = maxShield
	shield_bar.value = currentShield

func _physics_process(delta: float) -> void:
	var direction = Vector2.ZERO
	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	direction = direction.normalized()

	velocity = direction * SPEED
	move_and_slide()

	position.x = clamp(position.x, min_x, max_x)
	position.y = clamp(position.y, 110, 670)

	if not is_attacking and direction.x != 0:
		aim = Vector2.RIGHT * sign(direction.x)
		anim.flip_h = direction.x < 0

	attack_zone.position.x = abs(attack_zone.position.x) * aim.x

	if Input.is_action_pressed("block") and currentShield > 0:
		is_defending = true	
		if not is_attacking:
			anim.play("Guard")
	else:
		is_defending = false

	if Input.is_action_just_pressed("attack") and can_attack and not is_attacking and not is_defending:
		_start_attack()
		return

	if not is_attacking and not is_defending:
		if direction != Vector2.ZERO:
			anim.play("Run")
		else:
			anim.play("Idle")

func take_damage(amount: int) -> void:
	if is_defending and currentShield > 0:
		var shield_damage = amount * shieldDamageMulti
		currentShield -= shield_damage
		currentShield = max(currentShield, 0)
		shield_bar.value = currentShield
		shield_regen_time.start()
		if currentShield <= 0:
			is_defending = false
	else:
		currentHealth -= amount
		currentHealth = max(currentHealth, 0)
		health_bar.value = currentHealth

	if currentHealth <= 0:
		_die()

func heal(amount: int) -> void:
	currentHealth = min(currentHealth + amount, maxHealth)
	health_bar.value = currentHealth
		

		
func _die() -> void:
	print("Player muerto")

func _on_attack_zone_body_entered(body: Node) -> void:
	if body.has_method("take_damage") and body != self:
		enemies_in_range.append(body)

func _on_attack_zone_body_exited(body: Node) -> void:
	if body.has_method("take_damage"):
		enemies_in_range.erase(body)

func _start_attack() -> void:
	is_attacking = true
	can_attack = false
	anim.play("Ataque")
	for enemy in enemies_in_range:
		if is_instance_valid(enemy):
			enemy.take_damage(10)

func _on_animation_finished() -> void:
	if anim.animation == "Ataque":
		is_attacking = false
		Cooldown.start()

func _on_cooldown_timeout() -> void:
	can_attack = true

func _on_shield_regen_time_timeout() -> void:
	if currentShield < maxShield:
		currentShield = min(currentShield + regenShield, maxShield)
		shield_bar.value = currentShield
		if currentShield < maxShield:
			shield_regen_time.start()
