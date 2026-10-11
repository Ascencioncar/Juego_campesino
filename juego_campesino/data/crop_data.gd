class_name CropData
extends Resource
## Datos de un cultivo: que semilla consume, que producto da y como crece.

@export var id: StringName = &""
@export var display_name: String = ""
@export var seed_item: ItemData     # item semilla que se consume al sembrar
@export var product_item: ItemData  # item cosechado que entra al inventario
@export var grow_time: float = 6.0  # segundos totales de crecimiento (prototipo: corto)
@export var stages: int = 3         # numero de etapas visibles de crecimiento
@export var yield_amount: int = 2   # productos obtenidos por cosecha
