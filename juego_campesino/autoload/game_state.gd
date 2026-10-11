extends Node
## Estado global de la partida + economia central. Autoload: GameState.
## Dinero en PESOS COLOMBIANOS (COP).

const STARTING_MONEY := 60000

var money: int = STARTING_MONEY
var current_region: StringName = &"finca"
var unlocked_regions: Array[StringName] = [&"finca", &"pueblo"]
var has_phone: bool = false

# Estadisticas
var total_harvested: int = 0
var total_sales: int = 0
var harvested_crops := {}

# Evento de la cuota
var pending_cuota: bool = false
var cuota_done: bool = false
var pending_tip: bool = false  # mostrar aviso de "segunda oportunidad" al reaparecer

func _ready() -> void:
    EventBus.money_changed.emit(money)

# ---------- Dinero ----------

func format_cop(amount: int) -> String:
    var neg := amount < 0
    var s := str(absi(amount))
    var out := ""
    var c := 0
    for i in range(s.length() - 1, -1, -1):
        out = s[i] + out
        c += 1
        if c % 3 == 0 and i > 0:
            out = "." + out
    return "%s$%s" % ["-" if neg else "", out]

func can_afford(cost: int) -> bool:
    return money >= cost

func add_money(amount: int) -> void:
    money += amount
    EventBus.money_changed.emit(money)

func take_money(amount: int) -> void:
    money = maxi(0, money - amount)
    EventBus.money_changed.emit(money)

func spend_money(amount: int) -> bool:
    if amount > money:
        return false
    money -= amount
    EventBus.money_changed.emit(money)
    return true

# ---------- Tienda (economia centralizada y validada) ----------

func buy(data: ItemData, qty: int = 1) -> bool:
    if data == null or data.buy_price <= 0 or qty <= 0:
        return false
    if data.category == ItemData.Category.CELULAR and has_phone:
        EventBus.notify.emit("Ya tienes un celular")
        return false
    var cost := data.buy_price * qty
    if not can_afford(cost):
        EventBus.notify.emit("No te alcanza la plata")
        return false
    spend_money(cost)
    if data.category == ItemData.Category.CELULAR:
        has_phone = true
    else:
        Inventory.add_item(data, qty)
    EventBus.item_bought.emit(data.id, qty)
    EventBus.notify.emit("Compraste %s" % data.display_name)
    return true

func sell(id: StringName, qty: int = 1) -> bool:
    var data := Inventory.get_data(id)
    if data == null or data.sell_price <= 0 or qty <= 0:
        return false
    if not Inventory.has(id, qty):
        EventBus.notify.emit("No tienes suficientes")
        return false
    Inventory.remove_item(id, qty)
    add_money(data.sell_price * qty)
    total_sales += 1
    pending_cuota = true
    EventBus.item_sold.emit(id, qty)
    EventBus.notify.emit("Vendiste %s por %s" % [data.display_name, format_cop(data.sell_price * qty)])
    return true

# ---------- Regiones ----------

func is_region_unlocked(region_id: StringName) -> bool:
    return region_id in unlocked_regions

func unlock_region(region_id: StringName) -> void:
    if region_id not in unlocked_regions:
        unlocked_regions.append(region_id)
        EventBus.region_unlocked.emit(region_id)

func register_harvest(crop_id: StringName, amount: int) -> void:
    total_harvested += amount
    harvested_crops[crop_id] = int(harvested_crops.get(crop_id, 0)) + 1
    EventBus.crop_harvested.emit(crop_id, amount)

# ---------- Reinicio (volver a jugar) ----------

func reset() -> void:
    money = STARTING_MONEY
    current_region = &"finca"
    unlocked_regions.clear()
    unlocked_regions.append(&"finca")
    unlocked_regions.append(&"pueblo")
    has_phone = false
    total_harvested = 0
    total_sales = 0
    harvested_crops.clear()
    pending_cuota = false
    cuota_done = false
    EventBus.money_changed.emit(money)
