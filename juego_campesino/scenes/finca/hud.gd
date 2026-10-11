extends CanvasLayer
## HUD de la finca: dinero + notificaciones. Escucha el EventBus.

@onready var money_label: Label = $MoneyLabel
@onready var notify_label: Label = $NotifyLabel

var _tween: Tween

func _ready() -> void:
    EventBus.money_changed.connect(_on_money_changed)
    EventBus.notify.connect(_on_notify)
    _on_money_changed(GameState.money)
    notify_label.text = ""

func _on_money_changed(amount: int) -> void:
    money_label.text = "Dinero: $%d" % amount

func _on_notify(msg: String) -> void:
    notify_label.text = msg
    if _tween != null and _tween.is_valid():
        _tween.kill()
    notify_label.modulate.a = 1.0
    _tween = create_tween()
    _tween.tween_interval(1.8)
    _tween.tween_property(notify_label, "modulate:a", 0.0, 0.6)
