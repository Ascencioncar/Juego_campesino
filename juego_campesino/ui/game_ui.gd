extends CanvasLayer
## UI central (autoload: GameUI).
## HUD (dinero COP + avisos) + Inventario (I) + Tienda + Celular (C) + Dialogos.
## Incluye el evento de la "cuota" y la pantalla de Volver a jugar.

const BUY_CATALOG: Array[StringName] = [&"semilla_arroz", &"semilla_arvejas", &"azadon", &"celular"]
const CUOTA_AMOUNT := 20000

var _current_modal: String = "none"  # none|inventory|shop|phone|dialog

var _ui: Control
var _dim: ColorRect
var _center: CenterContainer

var _money_label: Label
var _notify_label: Label
var _notify_tween: Tween

var _inv_panel: PanelContainer
var _inv_grid: GridContainer
var _inv_detail: Label

var _shop_panel: PanelContainer
var _shop_money: Label
var _shop_list: VBoxContainer
var _shop_tab_buy: Button
var _shop_tab_sell: Button
var _shop_mode: String = "buy"

var _phone_panel: PanelContainer
var _phone_home: GridContainer
var _phone_app: VBoxContainer
var _phone_app_title: Label
var _phone_app_body: VBoxContainer

var _dlg_panel: PanelContainer
var _dlg_text: Label
var _dlg_buttons: HBoxContainer

var _collector: Node2D

func _ready() -> void:
    layer = 10
    _build_root()
    _build_hud()
    _build_inventory()
    _build_shop()
    _build_phone()
    _build_dialog()
    EventBus.money_changed.connect(_on_money_changed)
    EventBus.notify.connect(_on_notify)
    EventBus.inventory_changed.connect(_on_inventory_changed)
    _on_money_changed(GameState.money)

# ===================== construccion =====================

func _build_root() -> void:
    _ui = Control.new()
    _ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_ui)

    _dim = ColorRect.new()
    _dim.color = Color(0, 0, 0, 0.55)
    _dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _dim.visible = false
    _dim.mouse_filter = Control.MOUSE_FILTER_STOP
    _ui.add_child(_dim)

    _center = CenterContainer.new()
    _center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _ui.add_child(_center)

func _style_hud_label(l: Label, size: int) -> void:
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", Color(1, 1, 1))
    l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
    l.add_theme_constant_override("outline_size", 5)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _build_hud() -> void:
    _money_label = Label.new()
    _money_label.position = Vector2(16, 12)
    _style_hud_label(_money_label, 24)
    _ui.add_child(_money_label)

    _notify_label = Label.new()
    _notify_label.position = Vector2(16, 48)
    _style_hud_label(_notify_label, 18)
    _ui.add_child(_notify_label)

func _new_modal_panel(min_size: Vector2) -> VBoxContainer:
    var panel := PanelContainer.new()
    panel.visible = false
    panel.custom_minimum_size = min_size
    _center.add_child(panel)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 18)
    margin.add_theme_constant_override("margin_right", 18)
    margin.add_theme_constant_override("margin_top", 16)
    margin.add_theme_constant_override("margin_bottom", 16)
    panel.add_child(margin)
    var vb := VBoxContainer.new()
    vb.add_theme_constant_override("separation", 10)
    margin.add_child(vb)
    vb.set_meta("panel", panel)
    return vb

func _title(text: String) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", 26)
    return l

func _build_inventory() -> void:
    var vb := _new_modal_panel(Vector2(480, 380))
    _inv_panel = vb.get_meta("panel")
    vb.add_child(_title("Inventario"))
    _inv_grid = GridContainer.new()
    _inv_grid.columns = 3
    _inv_grid.add_theme_constant_override("h_separation", 8)
    _inv_grid.add_theme_constant_override("v_separation", 8)
    vb.add_child(_inv_grid)
    _inv_detail = Label.new()
    _inv_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _inv_detail.custom_minimum_size = Vector2(440, 56)
    _inv_detail.text = "Selecciona un objeto para ver detalles."
    vb.add_child(_inv_detail)
    var close := Button.new()
    close.text = "Cerrar (I)"
    close.pressed.connect(_hide_modal)
    vb.add_child(close)

func _build_shop() -> void:
    var vb := _new_modal_panel(Vector2(500, 440))
    _shop_panel = vb.get_meta("panel")
    vb.add_child(_title("Tienda Rural"))
    _shop_money = Label.new()
    vb.add_child(_shop_money)
    var tabs := HBoxContainer.new()
    _shop_tab_buy = Button.new()
    _shop_tab_buy.text = "Comprar"
    _shop_tab_buy.pressed.connect(_set_shop_mode.bind("buy"))
    _shop_tab_sell = Button.new()
    _shop_tab_sell.text = "Vender"
    _shop_tab_sell.pressed.connect(_set_shop_mode.bind("sell"))
    tabs.add_child(_shop_tab_buy)
    tabs.add_child(_shop_tab_sell)
    vb.add_child(tabs)
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(460, 270)
    vb.add_child(scroll)
    _shop_list = VBoxContainer.new()
    _shop_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _shop_list.add_theme_constant_override("separation", 6)
    scroll.add_child(_shop_list)
    var close := Button.new()
    close.text = "Salir"
    close.pressed.connect(close_shop)
    vb.add_child(close)

func _build_phone() -> void:
    var vb := _new_modal_panel(Vector2(340, 520))
    _phone_panel = vb.get_meta("panel")
    vb.add_child(_title("Celular"))
    _phone_home = GridContainer.new()
    _phone_home.columns = 2
    _phone_home.add_theme_constant_override("h_separation", 12)
    _phone_home.add_theme_constant_override("v_separation", 12)
    vb.add_child(_phone_home)
    var apps := [["Mapas", "mapas"], ["Viajes", "viajes"], ["Logros", "logros"], ["Info", "info"]]
    for app in apps:
        var b := Button.new()
        b.text = app[0]
        b.custom_minimum_size = Vector2(145, 95)
        b.pressed.connect(_open_phone_app.bind(app[1]))
        _phone_home.add_child(b)
    _phone_app = VBoxContainer.new()
    _phone_app.visible = false
    _phone_app.add_theme_constant_override("separation", 8)
    vb.add_child(_phone_app)
    _phone_app_title = _title("")
    _phone_app.add_child(_phone_app_title)
    _phone_app_body = VBoxContainer.new()
    _phone_app_body.add_theme_constant_override("separation", 6)
    _phone_app.add_child(_phone_app_body)
    var back := Button.new()
    back.text = "Volver"
    back.pressed.connect(_phone_show_home)
    _phone_app.add_child(back)
    var close := Button.new()
    close.text = "Cerrar (C)"
    close.pressed.connect(_hide_modal)
    vb.add_child(close)

func _build_dialog() -> void:
    var vb := _new_modal_panel(Vector2(500, 220))
    _dlg_panel = vb.get_meta("panel")
    _dlg_text = Label.new()
    _dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _dlg_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _dlg_text.add_theme_font_size_override("font_size", 20)
    _dlg_text.custom_minimum_size = Vector2(450, 110)
    vb.add_child(_dlg_text)
    _dlg_buttons = HBoxContainer.new()
    _dlg_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
    _dlg_buttons.add_theme_constant_override("separation", 20)
    vb.add_child(_dlg_buttons)

# ===================== HUD =====================

func _on_money_changed(amount: int) -> void:
    _money_label.text = "Plata: %s" % GameState.format_cop(amount)

func _on_notify(msg: String) -> void:
    _notify_label.text = msg
    if _notify_tween != null and _notify_tween.is_valid():
        _notify_tween.kill()
    _notify_label.modulate.a = 1.0
    _notify_tween = create_tween()
    _notify_tween.tween_interval(2.4)
    _notify_tween.tween_property(_notify_label, "modulate:a", 0.0, 0.6)

func _on_inventory_changed() -> void:
    if _current_modal == "inventory":
        _refresh_inventory()
    elif _current_modal == "shop":
        _refresh_shop()

# ===================== input =====================

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("open_inventory"):
        if _current_modal == "inventory":
            _hide_modal()
        elif _current_modal == "none":
            toggle_inventory()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("open_phone"):
        if _current_modal == "phone":
            _hide_modal()
        elif _current_modal == "none":
            if GameState.has_phone:
                open_phone()
            else:
                EventBus.notify.emit("No tienes celular. Compralo en la tienda.")
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("ui_cancel"):
        if _current_modal == "inventory":
            _hide_modal()
        elif _current_modal == "shop":
            close_shop()
        elif _current_modal == "phone":
            _hide_modal()

# ===================== inventario =====================

func toggle_inventory() -> void:
    _refresh_inventory()
    _show_modal("inventory", _inv_panel)

func _refresh_inventory() -> void:
    for c in _inv_grid.get_children():
        c.queue_free()
    var items := Inventory.all_items()
    if items.is_empty():
        var empty := Label.new()
        empty.text = "(vacio)"
        _inv_grid.add_child(empty)
    for entry in items:
        var data: ItemData = entry.data
        var amount: int = entry.amount
        var btn := Button.new()
        btn.custom_minimum_size = Vector2(140, 64)
        btn.clip_text = true
        btn.text = "%s\nx%d" % [data.display_name, amount]
        btn.pressed.connect(_show_item_detail.bind(data, amount))
        _inv_grid.add_child(btn)

func _show_item_detail(data: ItemData, amount: int) -> void:
    var extra := ""
    if data.sell_price > 0:
        extra = "  Venta: %s c/u" % GameState.format_cop(data.sell_price)
    _inv_detail.text = "%s (x%d)\n%s%s" % [data.display_name, amount, data.description, extra]

# ===================== tienda =====================

func open_shop() -> void:
    _shop_mode = "buy"
    _refresh_shop()
    _show_modal("shop", _shop_panel)

func close_shop() -> void:
    _hide_modal()
    if GameState.pending_cuota and not GameState.cuota_done:
        GameState.pending_cuota = false
        call_deferred("_start_cuota")

func _set_shop_mode(mode: String) -> void:
    _shop_mode = mode
    _refresh_shop()

func _refresh_shop() -> void:
    _shop_money.text = "Plata: %s" % GameState.format_cop(GameState.money)
    _shop_tab_buy.disabled = _shop_mode == "buy"
    _shop_tab_sell.disabled = _shop_mode == "sell"
    for c in _shop_list.get_children():
        c.queue_free()
    if _shop_mode == "buy":
        for id in BUY_CATALOG:
            var data: ItemData = ItemDB.get_item(id)
            if data == null:
                continue
            if data.id == &"celular" and GameState.has_phone:
                continue
            _add_shop_row(data.display_name, data.buy_price, "Comprar", _do_buy.bind(data))
    else:
        var any := false
        for entry in Inventory.all_items():
            var data: ItemData = entry.data
            if data.sell_price <= 0:
                continue
            any = true
            _add_shop_row("%s  (x%d)" % [data.display_name, entry.amount], data.sell_price, "Vender", _do_sell.bind(data.id))
        if not any:
            var l := Label.new()
            l.text = "No tienes productos para vender."
            _shop_list.add_child(l)

func _add_shop_row(row_name: String, price: int, action: String, cb: Callable) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    var n := Label.new()
    n.text = row_name
    n.custom_minimum_size = Vector2(210, 36)
    n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var p := Label.new()
    p.text = GameState.format_cop(price)
    p.custom_minimum_size = Vector2(110, 36)
    p.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    var b := Button.new()
    b.text = action
    b.pressed.connect(cb)
    row.add_child(n)
    row.add_child(p)
    row.add_child(b)
    _shop_list.add_child(row)

func _do_buy(data: ItemData) -> void:
    GameState.buy(data, 1)
    _refresh_shop()

func _do_sell(id: StringName) -> void:
    GameState.sell(id, 1)
    _refresh_shop()

# ===================== celular =====================

func open_phone() -> void:
    _phone_show_home()
    _show_modal("phone", _phone_panel)

func _phone_show_home() -> void:
    _phone_app.visible = false
    _phone_home.visible = true

func _open_phone_app(app: String) -> void:
    _phone_home.visible = false
    _phone_app.visible = true
    for c in _phone_app_body.get_children():
        c.queue_free()
    match app:
        "info":
            _phone_app_title.text = "Informacion"
            _phone_line("Dinero: %s" % GameState.format_cop(GameState.money))
            _phone_line("Productos cosechados: %d" % GameState.total_harvested)
            _phone_line("Ventas realizadas: %d" % GameState.total_sales)
            _phone_line("Regiones desbloqueadas: %d" % GameState.unlocked_regions.size())
            _phone_line("Celular: Si")
        "mapas":
            _phone_app_title.text = "Mapas"
            _phone_line("Finca inicial  -  (estas aqui)")
            _phone_line("Pueblo  -  desbloqueado")
            _phone_line("Valle agricola  -  BLOQUEADO")
        "viajes":
            _phone_app_title.text = "Viajes"
            _phone_line("Pueblo  -  Pasaje: %s" % GameState.format_cop(3000))
            _phone_line("Valle agricola  -  Bloqueado")
            _phone_line("")
            _phone_line("(Los viajes se activaran cuando se construyan las otras regiones.)")
        "logros":
            _phone_app_title.text = "Logros"
            _phone_line(_ach(GameState.total_harvested > 0) + "Primeros pasos: primera cosecha")
            _phone_line(_ach(GameState.total_sales > 0) + "Primer negocio: primera venta")
            _phone_line(_ach(GameState.has_phone) + "Tecnologia campesina: comprar celular")
            _phone_line(_ach(GameState.total_harvested >= 10) + "Manos campesinas: cosechar 10")

func _ach(done: bool) -> String:
    return "[X] " if done else "[ ] "

func _phone_line(text: String) -> void:
    var l := Label.new()
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.custom_minimum_size = Vector2(300, 0)
    l.text = text
    _phone_app_body.add_child(l)

# ===================== dialogos =====================

func show_message(text: String, cont_cb: Callable) -> void:
    _dlg_text.text = text
    _clear_dialog_buttons()
    _add_dialog_button("Continuar", cont_cb)
    _show_modal("dialog", _dlg_panel)

func ask_yes_no(question: String, yes_cb: Callable, no_cb: Callable) -> void:
    _dlg_text.text = question
    _clear_dialog_buttons()
    _add_dialog_button("Si", yes_cb)
    _add_dialog_button("No", no_cb)
    _show_modal("dialog", _dlg_panel)

func show_action(text: String, button_label: String, cb: Callable) -> void:
    _dlg_text.text = text
    _clear_dialog_buttons()
    _add_dialog_button(button_label, cb)
    _show_modal("dialog", _dlg_panel)

func _clear_dialog_buttons() -> void:
    for c in _dlg_buttons.get_children():
        c.queue_free()

func _add_dialog_button(label: String, cb: Callable) -> void:
    var b := Button.new()
    b.text = label
    b.custom_minimum_size = Vector2(120, 42)
    b.pressed.connect(func() -> void:
        _hide_modal()
        cb.call()
    )
    _dlg_buttons.add_child(b)

# ===================== cuota =====================

func _start_cuota() -> void:
    _spawn_collector()
    show_message("¡Ojo, campesino! Estamos recogiendo la cuota.", _ask_cuota)

func _ask_cuota() -> void:
    ask_yes_no("¿Quiere dar la cuota?", _cuota_yes, _cuota_no)

func _cuota_yes() -> void:
    GameState.cuota_done = true
    GameState.take_money(CUOTA_AMOUNT)
    EventBus.notify.emit("Pagaste la cuota: te quitaron %s." % GameState.format_cop(CUOTA_AMOUNT))
    if _collector != null:
        _collector.queue_free()
        _collector = null

func _cuota_no() -> void:
    GameState.cuota_done = true
    EventBus.menu_state_changed.emit(true)  # congela al jugador durante la escena
    _arm_collector()
    _spawn_blood()
    _flash_red()
    _tint_player_dead()
    await get_tree().create_timer(1.1).timeout
    show_action("El cobrador saco la escopeta y te disparo por negarte a pagar la cuota.", "Volver a jugar", _restart_game)

func _restart_game() -> void:
    GameState.reset()
    Inventory.clear()
    GameState.pending_tip = true
    _collector = null
    get_tree().reload_current_scene()

# ---- efectos de la escena del disparo ----

func _player_node() -> Node2D:
    var scene := get_tree().current_scene
    if scene == null:
        return null
    return scene.get_node_or_null("Player")

func _arm_collector() -> void:
    if _collector == null:
        return
    var gun := Polygon2D.new()
    gun.color = Color(0.1, 0.1, 0.1)
    gun.position = Vector2(-6, -4)
    gun.polygon = PackedVector2Array([Vector2(-34, -5), Vector2(6, -5), Vector2(6, 2), Vector2(-34, 2)])
    _collector.add_child(gun)

func _spawn_blood() -> void:
    var scene := get_tree().current_scene
    var player := _player_node()
    if scene == null or player == null:
        return
    var p := CPUParticles2D.new()
    p.position = player.position + Vector2(0, -10)
    p.z_index = 50
    p.emitting = true
    p.one_shot = true
    p.explosiveness = 0.95
    p.amount = 64
    p.lifetime = 0.9
    p.direction = Vector2(-1, -0.4)
    p.spread = 130.0
    p.initial_velocity_min = 120.0
    p.initial_velocity_max = 360.0
    p.gravity = Vector2(0, 650)
    p.scale_amount_min = 2.0
    p.scale_amount_max = 4.5
    p.color = Color(0.75, 0.05, 0.05)
    scene.add_child(p)

func _flash_red() -> void:
    var flash := ColorRect.new()
    flash.color = Color(0.85, 0.0, 0.0, 0.0)
    flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _ui.add_child(flash)
    var tw := create_tween()
    tw.tween_property(flash, "color:a", 0.5, 0.08)
    tw.tween_property(flash, "color:a", 0.0, 0.7)
    tw.tween_callback(flash.queue_free)

func _tint_player_dead() -> void:
    var player := _player_node()
    if player != null:
        player.modulate = Color(1, 0.3, 0.3)

func _spawn_collector() -> void:
    var scene := get_tree().current_scene
    if scene == null:
        return
    var px := 0.0
    var player := _player_node()
    if player != null:
        px = player.position.x
    _collector = _make_collector()
    _collector.position = Vector2(px + 110, 285)
    scene.add_child(_collector)

func _make_collector() -> Node2D:
    var root := Node2D.new()
    var body := Polygon2D.new()
    body.color = Color(0.22, 0.22, 0.28)
    body.polygon = PackedVector2Array([Vector2(-11, -15), Vector2(11, -15), Vector2(11, 15), Vector2(-11, 15)])
    root.add_child(body)
    var hat := Polygon2D.new()
    hat.color = Color(0.12, 0.12, 0.12)
    hat.polygon = PackedVector2Array([Vector2(-15, -15), Vector2(15, -15), Vector2(9, -27), Vector2(-9, -27)])
    root.add_child(hat)
    var bandana := Polygon2D.new()
    bandana.color = Color(0.75, 0.2, 0.2)
    bandana.polygon = PackedVector2Array([Vector2(-11, -8), Vector2(11, -8), Vector2(11, -3), Vector2(-11, -3)])
    root.add_child(bandana)
    return root

# ===================== modales =====================

func _hide_all_panels() -> void:
    _inv_panel.visible = false
    _shop_panel.visible = false
    _phone_panel.visible = false
    _dlg_panel.visible = false

func _show_modal(modal_name: String, panel: PanelContainer) -> void:
    _hide_all_panels()
    panel.visible = true
    _dim.visible = true
    _current_modal = modal_name
    EventBus.menu_state_changed.emit(true)

func _hide_modal() -> void:
    _hide_all_panels()
    _dim.visible = false
    _current_modal = "none"
    EventBus.menu_state_changed.emit(false)
