extends Area2D

@export var heal_amount: int = 20
var lifetime: float = 10.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# El item desaparece después de un tiempo
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _on_body_entered(body: Node) -> void:
	if body.has_method("heal"):
		body.heal(heal_amount)
		queue_free()
