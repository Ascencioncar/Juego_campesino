class_name ItemData
extends Resource
## Datos de un objeto del juego (semilla, producto, herramienta, etc.).
## Separa el CONTENIDO (editable como .tres) de la LOGICA.

enum Category { SEMILLA, PRODUCTO, HERRAMIENTA, CELULAR, ESPECIAL }

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var category: Category = Category.PRODUCTO
@export var buy_price: int = 0   # 0 = no se puede comprar en tienda
@export var sell_price: int = 0  # 0 = no se puede vender
@export var max_stack: int = 99
@export var stackable: bool = true
