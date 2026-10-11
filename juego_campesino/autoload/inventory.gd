extends Node
## Inventario central y VALIDADO. Autoload: Inventory.
## La UI nunca modifica cantidades directamente: todo pasa por aqui.

const MAX_SLOTS := 24

# id:StringName -> {"data": ItemData, "amount": int}
var _slots := {}

func get_amount(id: StringName) -> int:
    if _slots.has(id):
        return _slots[id].amount
    return 0

func has(id: StringName, amount: int = 1) -> bool:
    return get_amount(id) >= amount

func used_slots() -> int:
    return _slots.size()

func is_full() -> bool:
    return used_slots() >= MAX_SLOTS

func add_item(data: ItemData, amount: int = 1) -> bool:
    if data == null or amount <= 0:
        return false
    if not _slots.has(data.id):
        if is_full():
            EventBus.inventory_full.emit(data.id)
            EventBus.notify.emit("Inventario lleno")
            return false
        _slots[data.id] = {"data": data, "amount": 0}
    _slots[data.id].amount += amount
    EventBus.item_added.emit(data.id, amount)
    EventBus.inventory_changed.emit()
    return true

func remove_item(id: StringName, amount: int = 1) -> bool:
    if amount <= 0 or not has(id, amount):
        return false
    _slots[id].amount -= amount
    if _slots[id].amount <= 0:
        _slots.erase(id)
    EventBus.item_removed.emit(id, amount)
    EventBus.inventory_changed.emit()
    return true

func get_data(id: StringName) -> ItemData:
    if _slots.has(id):
        return _slots[id].data
    return null

func all_items() -> Array:
    return _slots.values()

func clear() -> void:
    _slots.clear()
    EventBus.inventory_changed.emit()
