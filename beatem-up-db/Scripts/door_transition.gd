## Puerta de transición entre escenarios.
## Solo se activa cuando el HordeManager emite all_hordes_completed.
extends Area2D

@export var next_scene_path: String = ""
@export var horde_manager_path: NodePath

var is_active: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	visible = false  # Oculta hasta que se active
	monitoring = false
	
	if horde_manager_path:
		var hm = get_node(horde_manager_path)
		if hm:
			hm.all_hordes_completed.connect(_activate)

func _activate() -> void:
	is_active = true
	visible = true
	monitoring = true
	# Opcional: animación o efecto visual para indicar que se abrió

func _on_body_entered(body: Node) -> void:
	if not is_active:
		return
	if body.has_method("take_damage") and body.has_method("heal"):
		# Es el player
		if next_scene_path != "":
			get_tree().change_scene_to_file(next_scene_path)
		else:
			push_warning("Door: no hay escena siguiente configurada!")
