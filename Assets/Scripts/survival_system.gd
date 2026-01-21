extends Node

# ==========================================
# 1. SETUP REFERENSI
# ==========================================

@onready var char_nodes = [
	$"../Person",    # Index 0
	$"../Hexapod",   # Index 1
	$"../Quadruped"  # Index 2
]

# Path File Save
const SAVE_PATH = "user://savegame.save"

# DATABASE KARAKTER (Inventory + Stats + POSISI)
var db_karakter = {
	0: { "nama": "Person", "max_tas": 10, "puse_kanan": true, "stats": {}, "pos": Vector2.ZERO },
	1: { "nama": "Hexapod", "max_tas": 15, "puse_kanan": false, "stats": {}, "pos": Vector2.ZERO },
	2: { "nama": "Quadruped", "max_tas": 15, "puse_kanan": false, "stats": {}, "pos": Vector2.ZERO }
}

var current_char_index = 0 
var player_aktif = null

# ==========================================
# 2. VARIABEL AKTIF (Display)
# ==========================================
var health = 100.0; var hunger = 100.0; var thirst = 100.0
var stamina = 100.0; var sanity = 100.0
var max_val = 100.0

var tas_isi = []
var item_tangan_kiri = null
var item_tangan_kanan = null
var max_slot_saat_ini = 10
var punya_tangan_kanan = true

@onready var inv_window = $"../CanvasLayer/InventoryWindow"
@onready var grid_container = $"../CanvasLayer/InventoryWindow/GridBarang"
@onready var slot_kiri_icon = $"../CanvasLayer/HUD_Bawah/SlotKiri/TextureRect"
@onready var slot_kanan_icon = $"../CanvasLayer/HUD_Bawah/SlotKanan/TextureRect"
@onready var slot_kanan_box = $"../CanvasLayer/HUD_Bawah/SlotKanan" 

@onready var ui_health = $"../CanvasLayer/StatusBars/HealthBar"
@onready var ui_hunger = $"../CanvasLayer/StatusBars/HungerBar"
@onready var ui_thirst = $"../CanvasLayer/StatusBars/ThirstBar"
@onready var ui_stamina = $"../CanvasLayer/StatusBars/StaminaBar"
@onready var ui_sanity = $"../CanvasLayer/StatusBars/SanityBar"

@export var seconds_per_day = 300.0 
var current_time = 0.0
var gradient_warna = Gradient.new()
@onready var day_night_modulate = get_node_or_null("../../DayNightCycle")

# ==========================================
# 3. MAIN LOOP & INIT
# ==========================================

func _ready():
	setup_tema_waktu()
	setup_pause_menu()
	
	# Matikan semua karakter dulu
	for c in char_nodes: c.set_active(false)
	
	# --- LOGIKA LOAD GAME ---
	# Cek apakah ada file save?
	if FileAccess.file_exists(SAVE_PATH):
		print("File Save Ditemukan! Memuat data...")
		load_game_from_disk()
	else:
		print("Save Tidak Ditemukan. Memulai Game Baru...")
		init_database_awal()
		# Set posisi awal default (jika perlu)
		# db_karakter[0]["pos"] = Vector2(0,0)
		load_character_data(0)

func _process(delta):
	update_waktu(delta)
	update_warna_langit()
	if player_aktif: 
		update_stats_decay(delta)
		handle_sanity_stamina(delta)
	update_ui_visual()

func _input(event):
	if event.is_action_pressed("ui_cancel"): toggle_pause()
	if event.is_action_pressed("switch_char"): switch_character()
	if event.is_action_pressed("buka_tas"): toggle_inventory_window()
	if event.is_action_pressed("slot_kiri"): gunakan_item_tangan("kiri")
	if event.is_action_pressed("slot_kanan"):
		if punya_tangan_kanan: gunakan_item_tangan("kanan")

# ==========================================
# 4. SISTEM SAVE & LOAD (DISK)
# ==========================================

func save_game_to_disk():
	# 1. Pastikan data karakter yang SEDANG dimainkan tersimpan ke DB dulu
	save_current_data_to_ram()
	
	# 2. Update POSISI semua karakter ke Database
	for i in range(char_nodes.size()):
		db_karakter[i]["pos"] = char_nodes[i].global_position
	
	# 3. Bungkus semua data penting
	var data_save = {
		"database": db_karakter,
		"current_idx": current_char_index,
		"time": current_time
	}
	
	# 4. Tulis ke File
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(data_save)
	file.close()
	
	print("Game Berhasil Disimpan ke: ", SAVE_PATH)
	toggle_pause() # Tutup menu pause

func load_game_from_disk():
	# 1. Buka File
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data_save = file.get_var()
	file.close()
	
	# 2. Kembalikan Data ke Variabel System
	db_karakter = data_save["database"]
	current_char_index = data_save["current_idx"]
	current_time = data_save["time"]
	
	# 3. Pindahkan Posisi Karakter Sesuai Save
	for i in range(char_nodes.size()):
		char_nodes[i].global_position = db_karakter[i]["pos"]
	
	# 4. Aktifkan Karakter Terakhir
	load_character_data(current_char_index)

# ==========================================
# 5. LOGIKA SWITCH CHARACTER & DB (RAM)
# ==========================================

func init_database_awal():
	for i in db_karakter.keys():
		db_karakter[i]["tas"] = []
		db_karakter[i]["kiri"] = null
		db_karakter[i]["kanan"] = null
		db_karakter[i]["stats"] = { "hp": 100.0, "hunger": 100.0, "thirst": 100.0, "stamina": 100.0, "sanity": 100.0 }
		# Posisi awal diambil dari posisi editor saat ini
		db_karakter[i]["pos"] = char_nodes[i].global_position

func switch_character():
	save_current_data_to_ram()
	char_nodes[current_char_index].set_active(false)
	current_char_index = (current_char_index + 1) % 3
	load_character_data(current_char_index)

func save_current_data_to_ram():
	var data = db_karakter[current_char_index]
	data["tas"] = tas_isi
	data["kiri"] = item_tangan_kiri
	data["kanan"] = item_tangan_kanan
	data["stats"]["hp"] = health
	data["stats"]["hunger"] = hunger
	data["stats"]["thirst"] = thirst
	data["stats"]["stamina"] = stamina
	data["stats"]["sanity"] = sanity
	# Simpan posisi karakter aktif saat ini
	data["pos"] = char_nodes[current_char_index].global_position

func load_character_data(index):
	var data = db_karakter[index]
	tas_isi = data["tas"]
	item_tangan_kiri = data["kiri"]
	item_tangan_kanan = data["kanan"]
	max_slot_saat_ini = data["max_tas"]
	punya_tangan_kanan = data["puse_kanan"]
	
	health = data["stats"]["hp"]
	hunger = data["stats"]["hunger"]
	thirst = data["stats"]["thirst"]
	stamina = data["stats"]["stamina"]
	sanity = data["stats"]["sanity"]
	
	player_aktif = char_nodes[index]
	slot_kanan_box.visible = punya_tangan_kanan
	update_ui_inventory()
	update_ui_visual() 
	char_nodes[index].set_active(true)

# ==========================================
# 6. UI & HELPER
# ==========================================
# Bagian ini sama seperti sebelumnya, tapi cek fungsi setup_pause_menu di bawah!

func toggle_inventory_window():
	inv_window.visible = !inv_window.visible
	update_ui_inventory()
	if inv_window.visible and tas_isi.size() > 0:
		await get_tree().process_frame
		if grid_container.get_child_count() > 0:
			grid_container.get_child(0).grab_focus()

func tambah_item_ke_tas(tipe, amount, icon_path):
	if tas_isi.size() < max_slot_saat_ini:
		var data = {"tipe": tipe, "restore": amount, "icon": icon_path}
		tas_isi.append(data)
		update_ui_inventory()
		return true
	return false

func update_ui_inventory():
	if item_tangan_kiri: slot_kiri_icon.texture = load(item_tangan_kiri["icon"])
	else: slot_kiri_icon.texture = null
	if item_tangan_kanan: slot_kanan_icon.texture = load(item_tangan_kanan["icon"])
	else: slot_kanan_icon.texture = null
	
	for child in grid_container.get_children(): child.queue_free()
	
	for i in range(tas_isi.size()):
		var item = tas_isi[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(64, 64)
		btn.focus_mode = Control.FOCUS_ALL 
		var icon = TextureRect.new()
		icon.texture = load(item["icon"])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(40, 40)
		icon.position = Vector2(12, 12)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon)
		btn.gui_input.connect(func(ev): _on_item_gui_input(ev, i))
		grid_container.add_child(btn)

func _on_item_gui_input(event, index):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_L:
			equip_spesifik(index, "kiri")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			if punya_tangan_kanan:
				equip_spesifik(index, "kanan")
				get_viewport().set_input_as_handled()

func equip_spesifik(index, sisi):
	var barang_tas = tas_isi[index]
	if sisi == "kiri":
		if item_tangan_kiri: tas_isi.append(item_tangan_kiri)
		item_tangan_kiri = barang_tas
	elif sisi == "kanan":
		if item_tangan_kanan: tas_isi.append(item_tangan_kanan)
		item_tangan_kanan = barang_tas
	tas_isi.remove_at(index)
	update_ui_inventory()
	await get_tree().process_frame
	if grid_container.get_child_count() > 0:
		var new_idx = clamp(index, 0, grid_container.get_child_count()-1)
		grid_container.get_child(new_idx).grab_focus()

func gunakan_item_tangan(sisi):
	var barang = null
	if sisi == "kiri": barang = item_tangan_kiri
	elif sisi == "kanan": barang = item_tangan_kanan
	
	if barang:
		match barang["tipe"]:
			"food": hunger += barang["restore"]
			"drinks": thirst += barang["restore"]
			"object": sanity += barang["restore"]
		
		if sisi == "kiri": item_tangan_kiri = null
		elif sisi == "kanan": item_tangan_kanan = null
		clamp_stats()
		update_ui_inventory()

func handle_sanity_stamina(delta):
	if player_aktif.velocity == Vector2.ZERO:
		sanity -= 3.0 * delta
		stamina = clamp(stamina + (15.0 * delta), 0, max_val)
	else:
		sanity += 5.0 * delta
	sanity = clamp(sanity, 0, max_val)

func kurangi_stamina_lari(delta):
	stamina = clamp(stamina - (8.0 * delta), 0, max_val)

func update_stats_decay(delta):
	hunger -= ((max_val / 3.0) / seconds_per_day) * delta
	thirst -= (max_val / seconds_per_day) * delta
	clamp_stats()

func clamp_stats():
	health = clamp(health, 0, max_val); hunger = clamp(hunger, 0, max_val)
	thirst = clamp(thirst, 0, max_val)

func setup_tema_waktu():
	gradient_warna.add_point(0.0, Color("1e1e32")); gradient_warna.add_point(0.1, Color("ffb275"))
	gradient_warna.add_point(0.2, Color("ffffff")); gradient_warna.add_point(0.7, Color("ffffff"))
	gradient_warna.add_point(0.85, Color("ffb275")); gradient_warna.add_point(1.0, Color("1e1e32"))

func update_waktu(delta):
	current_time += delta
	if current_time >= seconds_per_day: current_time = 0.0

func update_warna_langit():
	if day_night_modulate:
		day_night_modulate.color = gradient_warna.sample(current_time / seconds_per_day)

func update_ui_visual():
	if ui_health: ui_health.value = health
	if ui_hunger: ui_hunger.value = hunger
	if ui_thirst: ui_thirst.value = thirst
	if ui_stamina: ui_stamina.value = stamina
	if ui_sanity: ui_sanity.value = sanity

func setup_pause_menu():
	var btn_save = $"../CanvasLayer/PauseMenu/VBoxContainer/TombolSave"
	var btn_exit = $"../CanvasLayer/PauseMenu/VBoxContainer/TombolKeluar"
	
	# --- PERBAIKAN TOMBOL SAVE ---
	# Sekarang tombol save akan memanggil fungsi save_game_to_disk()
	if btn_save: 
		btn_save.pressed.disconnect(save_game_to_disk) if btn_save.pressed.is_connected(save_game_to_disk) else null
		btn_save.pressed.connect(save_game_to_disk)
		
	if btn_exit: 
		btn_exit.pressed.connect(func(): get_tree().quit())

func toggle_pause():
	var is_paused = get_tree().paused
	get_tree().paused = !is_paused
	var pm = $"../CanvasLayer/PauseMenu"
	if pm: pm.visible = !is_paused
