extends CharacterBody2D

@export var speed = 400 

# --- UI REFERENSI ---
# Pastikan nama node di Scene Tree sesuai huruf besar/kecilnya
@onready var ui_health = $CanvasLayer/StatusBars/HealthBar
@onready var ui_hunger = $CanvasLayer/StatusBars/HungerBar
@onready var ui_thirst = $CanvasLayer/StatusBars/ThirstBar
@onready var ui_stamina = $CanvasLayer/StatusBars/StaminaBar
@onready var ui_sanity = $CanvasLayer/StatusBars/SanityBar

# --- DAY/NIGHT CYCLE REFERENSI ---
# Kita cari CanvasModulate di level (Node tetangga player)
@onready var day_night_modulate = get_node_or_null("../DayNightCycle")

# --- PAUSE MENU REFERENSI ---
@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var tombol_save = $CanvasLayer/PauseMenu/VBoxContainer/TombolSave
@onready var tombol_keluar = $CanvasLayer/PauseMenu/VBoxContainer/TombolKeluar
@onready var camera = $Camera2D

# --- STATS VARIABLES ---
var max_val = 100.0
var health = 100.0
var hunger = 100.0
var thirst = 100.0
var stamina = 100.0
var sanity = 100.0

# --- TIME SYSTEM ---
# 1 Hari Game = 5 Menit Realtime = 300 Detik
var seconds_per_day = 300.0 
var current_time = 0.0 # Menyimpan waktu berjalan (0 - 300)

# --- MAP LIMITS ---
var limit_kiri = 0
var limit_atas = 0
var limit_kanan = 0
var limit_bawah = 0

# --- WARNA WAKTU (GRADIENT) ---
# Kita definisikan warna langit manual lewat kode
var gradient_warna = Gradient.new()

func _ready():
	setup_gradient_waktu() # Bikin warna pagi/siang/malam
	
	# Setup Kamera & Map (Kode lama)
	z_index = 10 
	camera.enabled = true
	camera.make_current()
	camera.position_smoothing_enabled = false
	
	var background_node = get_node_or_null("../Background")
	if background_node:
		var rect = background_node.get_rect()
		var scale_bg = background_node.scale
		limit_kiri = int(rect.position.x * scale_bg.x)
		limit_atas = int(rect.position.y * scale_bg.y)
		limit_kanan = int((rect.position.x + rect.size.x) * scale_bg.x)
		limit_bawah = int((rect.position.y + rect.size.y) * scale_bg.y)
		
		camera.limit_left = limit_kiri
		camera.limit_top = limit_atas
		camera.limit_right = limit_kanan
		camera.limit_bottom = limit_bawah
		
		load_game_data() # Load Posisi DAN Stats
		camera.reset_smoothing()
	else:
		printerr("ERROR: Background tidak ketemu!")

	tombol_save.pressed.connect(fungsi_save)
	tombol_keluar.pressed.connect(fungsi_keluar)

func _physics_process(delta):
	# 1. MOVEMENT
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction:
		velocity = direction * speed
		# Kurangi stamina dikit kalau jalan (opsional)
		stamina = clamp(stamina - (2.0 * delta), 0, max_val)
	else:
		velocity = Vector2.ZERO
		# Regen stamina kalau diam
		stamina = clamp(stamina + (5.0 * delta), 0, max_val)

	move_and_slide()
	global_position.x = clamp(global_position.x, limit_kiri, limit_kanan)
	global_position.y = clamp(global_position.y, limit_atas, limit_bawah)

func _process(delta):
	# --- LOGIKA SURVIVAL BERJALAN DISINI ---
	
	# 1. UPDATE WAKTU
	current_time += delta
	if current_time >= seconds_per_day:
		current_time = 0.0 # Reset ke pagi hari setelah 5 menit
	
	# 2. KURANGI STATS (DECAY)
	# Hunger: Habis 1/3 (33.3) dalam 1 hari (300 detik)
	var hunger_loss_per_sec = (max_val / 3.0) / seconds_per_day
	hunger -= hunger_loss_per_sec * delta
	
	# Thirst: Habis 1 Full (100) dalam 1 hari (300 detik)
	var thirst_loss_per_sec = max_val / seconds_per_day
	thirst -= thirst_loss_per_sec * delta
	
	# Sanity: (Contoh) Habis kalau malam hari
	if current_time > seconds_per_day * 0.75: # Kalau sudah malam (> 75% waktu)
		sanity -= 2.0 * delta
	
	# Clamp biar gak minus
	health = clamp(health, 0, max_val)
	hunger = clamp(hunger, 0, max_val)
	thirst = clamp(thirst, 0, max_val)
	sanity = clamp(sanity, 0, max_val)
	
	# 3. UPDATE UI VISUAL
	ui_health.value = health
	ui_hunger.value = hunger
	ui_thirst.value = thirst
	ui_stamina.value = stamina
	ui_sanity.value = sanity
	
	# 4. UPDATE WARNA DUNIA (DAY/NIGHT)
	if day_night_modulate:
		# Hitung progress hari (0.0 sampai 1.0)
		var progress = current_time / seconds_per_day
		# Ambil warna dari gradient
		day_night_modulate.color = gradient_warna.sample(progress)

# --- INPUT ESC ---
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	var is_paused = get_tree().paused
	get_tree().paused = !is_paused
	pause_menu.visible = !is_paused

# --- SETUP WARNA PAGI SIANG MALAM ---
func setup_gradient_waktu():
	# Kita bikin gradient manual lewat kode biar praktis
	# 0.0 = Pagi, 0.5 = Siang, 0.75 = Sore, 1.0 = Malam -> Pagi
	gradient_warna.add_point(0.0, Color("4d4d4d"))   # Dini Hari (Gelap)
	gradient_warna.add_point(0.2, Color("ffffff"))   # Pagi (Terang Normal)
	gradient_warna.add_point(0.7, Color("ffffff"))   # Sore (Masih Terang)
	gradient_warna.add_point(0.85, Color("ffb275"))  # Senja (Oranye)
	gradient_warna.add_point(0.95, Color("1e1e32"))  # Malam (Biru Gelap)

# --- SAVE SYSTEM UPDATE ---
func fungsi_save():
	var config = ConfigFile.new()
	# Simpan Posisi
	config.set_value("player", "pos_x", global_position.x)
	config.set_value("player", "pos_y", global_position.y)
	
	# Simpan Stats & Waktu
	config.set_value("stats", "health", health)
	config.set_value("stats", "hunger", hunger)
	config.set_value("stats", "thirst", thirst)
	config.set_value("stats", "sanity", sanity)
	config.set_value("world", "time", current_time)
	
	config.save("user://savegame.cfg")
	print("GAME SAVED! Time: ", current_time)
	toggle_pause()

# --- LOAD SYSTEM UPDATE ---
func load_game_data():
	var config = ConfigFile.new()
	var err = config.load("user://savegame.cfg")
	
	if err == OK:
		# Load Posisi
		var x = config.get_value("player", "pos_x", 0)
		var y = config.get_value("player", "pos_y", 0)
		global_position = Vector2(x, y)
		
		# Load Stats (Default 100 kalau gak ketemu)
		health = config.get_value("stats", "health", 100.0)
		hunger = config.get_value("stats", "hunger", 100.0)
		thirst = config.get_value("stats", "thirst", 100.0)
		sanity = config.get_value("stats", "sanity", 100.0)
		
		# Load Waktu
		current_time = config.get_value("world", "time", 0.0)
		
		print("DATA LOADED. Stats recovered.")
	else:
		# Posisi Tengah Default
		var tengah_x = (limit_kiri + limit_kanan) / 2.0
		var tengah_y = (limit_atas + limit_bawah) / 2.0
		global_position = Vector2(tengah_x, tengah_y)

func fungsi_keluar():
	get_tree().quit()
