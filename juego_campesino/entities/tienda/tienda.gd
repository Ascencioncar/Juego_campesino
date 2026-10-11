extends Node2D
## Puesto de la tienda rural. Interactuar (E) abre la tienda.

func interact(_who: Node) -> void:
    GameUI.open_shop()
