extends Node2D
## Escena de la finca inicial. Entrega semillas de arranque y, si el jugador
## acaba de "volver a jugar" tras la cuota, le muestra una segunda oportunidad.

func _ready() -> void:
	GameState.current_region = &"finca"
	EventBus.region_entered.emit(&"finca")
	_grant_starter_kit()
	if GameState.pending_tip:
		GameState.pending_tip = false
		call_deferred("_show_tip")

func _grant_starter_kit() -> void:
	var arroz: ItemData = ItemDB.get_item(&"semilla_arroz")
	var arvejas: ItemData = ItemDB.get_item(&"semilla_arvejas")
	if arroz != null:
		Inventory.add_item(arroz, 3)
	if arvejas != null:
		Inventory.add_item(arvejas, 3)
	EventBus.notify.emit("Bienvenido a tu finca. Acercate a algo y presiona E.")

func _show_tip() -> void:
	GameUI.show_message("Tienes una segunda oportunidad. La proxima vez que lleguen a cobrar la cuota, acepta y paga para que no vuelva a pasar.", func() -> void: pass)
