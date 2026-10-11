extends Node
## Base de datos de items y cultivos cargada desde .tres. Autoload: ItemDB.

var items := {}  # StringName -> ItemData
var crops := {}  # StringName -> CropData

const ITEM_PATHS := [
    "res://data/items/semilla_arroz.tres",
    "res://data/items/semilla_arvejas.tres",
    "res://data/items/arroz.tres",
    "res://data/items/arvejas.tres",
    "res://data/items/azadon.tres",
    "res://data/items/celular.tres",
]
const CROP_PATHS := [
    "res://data/crops/arroz.tres",
    "res://data/crops/arvejas.tres",
]

func _ready() -> void:
    for p in ITEM_PATHS:
        var r = load(p)
        if r != null and r.id != &"":
            items[r.id] = r
    for p in CROP_PATHS:
        var c = load(p)
        if c != null and c.id != &"":
            crops[c.id] = c
    print("[ItemDB] items=%d crops=%d" % [items.size(), crops.size()])

func get_item(id: StringName) -> ItemData:
    return items.get(id)

func get_crop(id: StringName) -> CropData:
    return crops.get(id)
