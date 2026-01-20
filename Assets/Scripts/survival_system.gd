extends Node

# --- SETTING WAKTU ---
@export var seconds_per_day = 300.0 
var current_time = 0.0

# --- REFERENSI UI STATS ---
@onready var ui_health = $"../CanvasLayer/StatusBars/HealthBar"
@onready var ui_hunger = $"../CanvasLayer/StatusBars/HungerBar"
@onready var ui_thirst = $"../CanvasLayer/StatusBars/ThirstBar"
@onready var ui_sanity = $"../CanvasLayer/StatusBars/SanityBar"
@onready var ui_stamina = $"../CanvasLayer/StatusBars/StaminaBar"

# --- REFERENSI UI INVENTORY ---
@onready var inv_window = $"../CanvasLayer/InventoryWindow"
@onready var grid_container = $"../CanvasLayer/InventoryWindow/GridBarang"
@onready var slot_kiri_icon = $"../CanvasLayer/HUD_Bawah/SlotKiri/TextureRect"
@onready var slot_kanan_icon = $"../CanvasLayer/HUD_Bawah/SlotKanan/TextureRect"

# --- DATA PLAYER & SYSTEM ---
@onready var player = get_parent()
@onready var day_night_modulate = get_node_or_null("../../DayNightCycle")
@onready var pause_menu = $"../CanvasLayer/PauseMenu"

# --- STATS ---
var max_val = 100.0
var health = 100.0; var hunger = 100.0; var thirst = 100.0
var stamina = 100.0; var sanity = 100.0
var gradient_warna = Gradient.new()

# --- SYSTEM INVENTORY BARU ---
# Format Data Barang: { "tipe": "food", "amount": 20, "icon": "res://path/img.png" }
var tas_isi = [] # Array kosong, maksimal 10
var max_slot_tas = 10
var item_tangan_kiri = null
var item_tangan_kanan = null

func _ready():
	setup_tema_waktu()
	# Load game & update tampilan inventory kosong
	update_ui_inventory() 
	
	# Pause Menu Connect
	$"../CanvasLayer/PauseMenu/VBoxContainer/TombolSave".pressed.connect(save_game)
	$"../CanvasLayer/PauseMenu/VBoxContainer/TombolKeluar".pressed.connect(quit_game)

func _process(delta):
	update_waktu(delta)
	update_stats_decay(delta)
	handle_sanity_mechanic(delta)
	handle_stamina_regen(delta)
	update_ui_visual()
	update_warna_langit()

# --- INPUT KEYBOARD (1, 2, 3) ---
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		
	# LOGIKA BUKA TAS (UPDATE)
	if event.is_action_pressed("buka_tas"): # Tekan 2
		inv_window.visible = !inv_window.visible
		update_ui_inventory()
		
		# FITUR BARU: Kalau tas dibuka dan ada isinya, langsung fokus ke item pertama
		# Biar panah keyboard langsung jalan
		if inv_window.visible and tas_isi.size() > 0:
			# Kita tunggu sebentar (1 frame) biar UI selesai digambar dulu
			await get_tree().process_frame
			var item_pertama = grid_container.get_child(0)
			if item_pertama:
				item_pertama.grab_focus()

	if event.is_action_pressed("slot_kiri"):
		gunakan_item_tangan("kiri")
		
	if event.is_action_pressed("slot_kanan"):
		gunakan_item_tangan("kanan")

# --- UPDATE TAMPILAN INVENTORY (UPDATE BESAR) ---
func update_ui_inventory():
	# 1. Update Icon Tangan (Sama kayak dulu)
	if item_tangan_kiri: slot_kiri_icon.texture = load(item_tangan_kiri["icon"])
	else: slot_kiri_icon.texture = null
		
	if item_tangan_kanan: slot_kanan_icon.texture = load(item_tangan_kanan["icon"])
	else: slot_kanan_icon.texture = null
	
	# 2. Bersihkan Grid
	for child in grid_container.get_children():
		child.queue_free()
		
	# 3. Gambar Ulang Isi Tas
	for i in range(tas_isi.size()):
		var item = tas_isi[i]
		var tombol_slot = Button.new()
		tombol_slot.custom_minimum_size = Vector2(64, 64)
		
		# PENTING: Aktifkan Fokus Keyboard biar bisa navigasi Panah
		tombol_slot.focus_mode = Control.FOCUS_ALL 
		
		# Set Icon
		var icon_rect = TextureRect.new()
		icon_rect.texture = load(item["icon"])
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.custom_minimum_size = Vector2(40, 40)
		icon_rect.position = Vector2(12, 12)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tombol_slot.add_child(icon_rect)
		
		# LOGIKA BARU: Deteksi Tombol L dan R pada item ini
		# Kita pakai sinyal 'gui_input' untuk mendeteksi keyboard saat tombol ini fokus
		tombol_slot.gui_input.connect(func(ev): _on_item_gui_input(ev, i))
		
		grid_container.add_child(tombol_slot)

# --- FUNGSI DETEKSI TOMBOL L / R (BARU) ---
func _on_item_gui_input(event, index):
	if event is InputEventKey and event.pressed:
		
		# Jika tekan L -> Masuk Kiri
		if event.keycode == KEY_L:
			equip_spesifik(index, "kiri")
			get_viewport().set_input_as_handled() # Stop input biar gak nembus
			
		# Jika tekan R -> Masuk Kanan
		elif event.keycode == KEY_R:
			equip_spesifik(index, "kanan")
			get_viewport().set_input_as_handled()

# --- FUNGSI EQUIP CANGGIH (BARU) ---
# Bisa tukar barang (Swap) kalau tangan penuh
func equip_spesifik(index, sisi):
	var barang_dari_tas = tas_isi[index]
	
	if sisi == "kiri":
		# Kalau tangan kiri udah ada isinya, balikin ke tas dulu
		if item_tangan_kiri != null:
			tas_isi.append(item_tangan_kiri)
		
		# Pasang barang baru
		item_tangan_kiri = barang_dari_tas
		
	elif sisi == "kanan":
		# Kalau tangan kanan udah ada isinya, balikin ke tas dulu
		if item_tangan_kanan != null:
			tas_isi.append(item_tangan_kanan)
			
		# Pasang barang baru
		item_tangan_kanan = barang_dari_tas

	# Hapus barang yang tadi diambil dari tas
	tas_isi.remove_at(index)
	
	# Refresh UI
	update_ui_inventory()
	
	# KEMBALIKAN FOKUS KURSOR (PENTING)
	# Karena tombolnya hancur saat refresh, fokus hilang. Kita harus set ulang.
	await get_tree().process_frame # Tunggu UI jadi
	if grid_container.get_child_count() > 0:
		# Coba fokus ke index yang sama, atau mundur 1 kalau indexnya ilang
		var new_index = clamp(index, 0, grid_container.get_child_count() - 1)
		grid_container.get_child(new_index).grab_focus()

# --- FUNGSI AMBIL BARANG (DIPANGGIL ITEM) ---
# Diubah: Tidak langsung dimakan, tapi masuk tas
func tambah_item_ke_tas(tipe, amount, icon_path):
	if tas_isi.size() < max_slot_tas:
		# Buat data barang
		var data_barang = {
			"tipe": tipe,
			"restore": amount,
			"icon": icon_path
		}
		tas_isi.append(data_barang)
		print("Barang masuk tas: ", tipe)
		update_ui_inventory() # Refresh gambar tas
		return true # Berhasil ambil
	else:
		print("TAS PENUH!")
		return false # Gagal ambil

func equip_dari_tas(index):
	# Ambil barang dari array tas
	var barang = tas_isi[index]
	
	# Pindahkan ke tangan kiri (Contoh sederhana: Selalu ke kiri dulu)
	# Kalau mau canggih: Cek mana yang kosong
	if item_tangan_kiri == null:
		item_tangan_kiri = barang
		tas_isi.remove_at(index) # Hapus dari tas
	elif item_tangan_kanan == null:
		item_tangan_kanan = barang
		tas_isi.remove_at(index)
	else:
		print("Tangan Penuh! Buang/Pakai dulu.")
	
	update_ui_inventory()

func gunakan_item_tangan(sisi):
	var barang = null
	if sisi == "kiri": barang = item_tangan_kiri
	elif sisi == "kanan": barang = item_tangan_kanan
	
	if barang:
		# EFEK MAKAN/MINUM
		match barang["tipe"]:
			"food": hunger += barang["restore"]
			"drinks": thirst += barang["restore"]
			"object": sanity += barang["restore"]
		
		print("Memakai item: ", barang["tipe"])
		
		# Hapus dari tangan setelah dipakai
		if sisi == "kiri": item_tangan_kiri = null
		elif sisi == "kanan": item_tangan_kanan = null
		
		# Clamp stats & Update Visual
		clamp_stats()
		update_ui_visual()
		update_ui_inventory()

# --- FUNGSI STANDAR LAINNYA (SAMA KAYAK DULU) ---
func clamp_stats():
	health = clamp(health, 0, max_val); hunger = clamp(hunger, 0, max_val)
	thirst = clamp(thirst, 0, max_val); sanity = clamp(sanity, 0, max_val)
	stamina = clamp(stamina, 0, max_val)

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

func update_stats_decay(delta):
	hunger -= ((max_val / 3.0) / seconds_per_day) * delta
	thirst -= (max_val / seconds_per_day) * delta

func handle_sanity_mechanic(delta):
	if player.velocity == Vector2.ZERO: sanity -= 3.0 * delta
	else: sanity += 5.0 * delta
	sanity = clamp(sanity, 0, max_val)

func handle_stamina_regen(delta):
	if player.velocity == Vector2.ZERO: stamina = clamp(stamina + (15.0 * delta), 0, max_val)
	
func kurangi_stamina_lari(delta):
	stamina = clamp(stamina - (5.0 * delta), 0, max_val)

func update_ui_visual():
	if ui_health: ui_health.value = health
	if ui_hunger: ui_hunger.value = hunger
	if ui_thirst: ui_thirst.value = thirst
	if ui_stamina: ui_stamina.value = stamina
	if ui_sanity: ui_sanity.value = sanity

# PAUSE & SAVE (SEDERHANA)
func toggle_pause():
	var is_paused = get_tree().paused
	get_tree().paused = !is_paused
	if pause_menu: pause_menu.visible = !is_paused

func save_game(): print("Save Placeholder"); toggle_pause()
func quit_game(): get_tree().quit()
