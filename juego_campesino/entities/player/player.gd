class_name Player
extends CharacterBody2D
## Campesino jugable en VISTA LATERAL (plataforma):
## se mueve izquierda/derecha, cae por gravedad y salta. Interactua con E.
## Muestra "Interactuar (E)" cuando hay algo con que interactuar cerca.

@export var speed: float = 190.0
@export var jump_velocity: float = -430.0
@export var gravity: float = 1200.0

@onready var interact_area: Area2D = $InteractArea
@onready var _visual: Node2D = $Visual
@onready var _prompt: Label = $Prompt

var _facing: int = 1
var _menu_open: bool = false

func _ready() -> void:
	EventBus.menu_state_changed.connect(_on_menu_state_changed)
	if _prompt != null:
		_prompt.visible = false

func _on_menu_state_changed(is_open: bool) -> void:
	_menu_open = is_open

func _physics_process(delta: float) -> void:
	_update_prompt()

	if not is_on_floor():
		velocity.y += gravity * delta

	if _menu_open:
		velocity.x = 0.0
		move_and_slide()
		return

	var dir := Input.get_axis("move_left", "move_right")
	velocity.x = dir * speed
	if dir < 0.0:
		_set_facing(-1)
	elif dir > 0.0:
		_set_facing(1)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

func _set_facing(f: int) -> void:
	if f == _facing:
		return
	_facing = f
	_visual.scale.x = absf(_visual.scale.x) * float(f)

func _update_prompt() -> void:
	var near := false
	if not _menu_open:
		for a in interact_area.get_overlapping_areas():
			var p := a.get_parent()
			if p != null and p.has_method("interact"):
				near = true
				break
	if _prompt != null:
		_prompt.visible = near

func _unhandled_input(event: InputEvent) -> void:
	if _menu_open:
		return
	if event.is_action_pressed("interact"):
		_try_interact()

func set_menu_open(open: bool) -> void:
	_menu_open = open

func _try_interact() -> void:
	var target: Node = null
	for a in interact_area.get_overlapping_areas():
		var p := a.get_parent()
		if p != null and p.has_method("interact"):
			target = p
			break
	if target != null:
		target.interact(self)
	else:
		EventBus.notify.emit("No hay nada con que interactuar")
