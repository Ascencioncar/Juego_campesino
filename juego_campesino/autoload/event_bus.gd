extends Node
## Bus central de senales del juego. Autoload: EventBus.

# Economia
signal money_changed(new_amount: int)

# Inventario
signal inventory_changed()
signal item_added(id: StringName, amount: int)
signal item_removed(id: StringName, amount: int)
signal inventory_full(id: StringName)

# Agricultura
signal crop_planted(crop_id: StringName)
signal crop_harvested(crop_id: StringName, amount: int)

# Tienda
signal item_bought(id: StringName, amount: int)
signal item_sold(id: StringName, amount: int)

# Regiones / viajes
signal region_unlocked(region_id: StringName)
signal region_entered(region_id: StringName)

# Logros
signal achievement_unlocked(id: StringName)

# UI / feedback
signal notify(message: String)
signal menu_state_changed(is_open: bool)
