## Script para la escena principal del nivel.
## Adjuntar a la raíz Node2D de la escena del nivel.
##
## Este script es un ejemplo. Podés configurar las hordas desde el inspector
## del nodo HordeManager, o directamente en este script.
extends Node2D

@onready var horde_manager = $HordeManager
@onready var door = $Door
@onready var player = $Player

func _ready() -> void:
	# Conectar señales del HordeManager
	horde_manager.all_hordes_completed.connect(_on_all_hordes_completed)
	horde_manager.horde_started.connect(_on_horde_started)
	horde_manager.horde_completed.connect(_on_horde_completed)

func _on_horde_started(index: int) -> void:
	print("¡Horda ", index + 1, " comenzó!")

func _on_horde_completed(index: int) -> void:
	print("¡Horda ", index + 1, " completada! Avanzá →")

func _on_all_hordes_completed() -> void:
	print("¡Todas las hordas derrotadas! La puerta se abrió.")
	# La puerta se activa sola via la señal all_hordes_completed
