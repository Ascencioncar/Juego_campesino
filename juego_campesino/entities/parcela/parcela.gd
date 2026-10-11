class_name Parcela
extends Node2D
## Parcela de cultivo. Ciclo de estados:
## VACIA -> PREPARADA -> (sembrar) -> CRECIENDO -> LISTA -> (cosechar) -> VACIA

enum State { VACIA, PREPARADA, SEMBRADA, CRECIENDO, LISTA }

const STATE_NAMES := ["Vacia", "Preparada", "Sembrada", "Creciendo", "Lista!"]

@export var crop: CropData  # cultivo que se siembra en esta parcela (prototipo)

var _state: State = State.VACIA
var _growth: float = 0.0
var _current_crop: CropData

@onready var _plot: Polygon2D = $Plot
@onready var _plant: Polygon2D = $Plant
@onready var _label: Label = $Label

func _ready() -> void:
	_refresh()

func _process(delta: float) -> void:
	if _state == State.CRECIENDO and _current_crop != null:
		_growth += delta
		if _growth >= _current_crop.grow_time:
			_state = State.LISTA
		_refresh()

func interact(_who: Node) -> void:
	match _state:
		State.VACIA:
			_prepare()
		State.PREPARADA:
			_plant_seed()
		State.SEMBRADA, State.CRECIENDO:
			EventBus.notify.emit("El cultivo todavia esta creciendo")
		State.LISTA:
			_harvest()

func _prepare() -> void:
	_state = State.PREPARADA
	EventBus.notify.emit("Tierra preparada")
	_refresh()

func _plant_seed() -> void:
	var c := crop
	if c == null:
		EventBus.notify.emit("No hay cultivo configurado")
		return
	if c.seed_item == null or not Inventory.has(c.seed_item.id, 1):
		EventBus.notify.emit("No tienes semillas de %s" % c.display_name)
		return
	Inventory.remove_item(c.seed_item.id, 1)
	_current_crop = c
	_state = State.CRECIENDO
	_growth = 0.0
	EventBus.crop_planted.emit(c.id)
	EventBus.notify.emit("Sembraste %s" % c.display_name)
	_refresh()

func _harvest() -> void:
	var c := _current_crop
	if c == null:
		return
	var amount := c.yield_amount
	if c.product_item != null:
		for i in amount:
			Inventory.add_item(c.product_item, 1)
	GameState.register_harvest(c.id, amount)
	EventBus.notify.emit("Cosechaste %d %s" % [amount, c.display_name])
	_current_crop = null
	_growth = 0.0
	_state = State.VACIA
	_refresh()

func _refresh() -> void:
	var state_txt: String = STATE_NAMES[_state]
	if _label != null:
		_label.text = state_txt
	if _plot != null:
		_plot.color = Color(0.45, 0.30, 0.18) if _state >= State.PREPARADA else Color(0.35, 0.5, 0.25)
	if _plant != null:
		_plant.visible = _state >= State.SEMBRADA
		if _current_crop != null and _state >= State.SEMBRADA:
			var t := 1.0
			if _current_crop.grow_time > 0.0:
				t = clampf(_growth / _current_crop.grow_time, 0.0, 1.0)
			var stages := maxi(_current_crop.stages, 1)
			var stage := clampi(int(t * stages), 0, stages - 1)
			var s := lerpf(0.4, 1.0, float(stage + 1) / float(stages))
			_plant.scale = Vector2(s, s)
			_plant.color = Color(0.9, 0.8, 0.2) if _state == State.LISTA else Color(0.2, 0.7, 0.2)
