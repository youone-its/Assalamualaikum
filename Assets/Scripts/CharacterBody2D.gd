extends CharacterBody2D

@export var speed = 400 

@onready var camera = $Camera2D

# --- REFERENSI UI (SESUAIKAN NAMA NODE KALAU BEDA) ---
# Pastikan susunan node kamu sudah sesuai langkah 1
@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var tombol_save = $CanvasLayer/PauseMenu/VBoxContainer/TombolSave
@onready var tombol_keluar = $CanvasLayer/PauseMenu/VBoxContainer/TombolKeluar

# Variabel batas map
var limit_kiri = 0
var limit_atas = 0
var limit_kanan = 0
var limit_bawah = 0

func _ready():
	# --- BAGIAN SETUP KAMERA & MAP (YANG TADI) ---
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
		
		# Cek apakah ada save data? Kalau ada, load posisi.
		load_game_data()
		
		camera.reset_smoothing()
	else:
		printerr("ERROR: Background tidak ketemu!")

	# --- SETUP TOMBOL (CONNECT SIGNAL LEWAT KODE) ---
	# Biar gak usah klik-klik inspector signal
	tombol_save.pressed.connect(fungsi_save)
	tombol_keluar.pressed.connect(fungsi_keluar)

func _physics_process(_delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	global_position.x = clamp(global_position.x, limit_kiri, limit_kanan)
	global_position.y = clamp(global_position.y, limit_atas, limit_bawah)

# --- FUNGSI INPUT (UNTUK TOMBOL ESC) ---
func _input(event):
	if event.is_action_pressed("ui_cancel"): # Ini tombol ESC default
		toggle_pause()

func toggle_pause():
	# Cek status pause sekarang
	var is_paused = get_tree().paused
	
	# Balik statusnya (kalau true jadi false, false jadi true)
	get_tree().paused = !is_paused
	
	# Munculin/Umpetin menu
	pause_menu.visible = !is_paused

# --- FUNGSI SAVE ---
func fungsi_save():
	var config = ConfigFile.new()
	
	# Simpan posisi X dan Y
	config.set_value("player", "pos_x", global_position.x)
	config.set_value("player", "pos_y", global_position.y)
	
	# Simpan ke file di komputer
	config.save("user://savegame.cfg")
	print("GAME DISIMPAN! Posisi: ", global_position)
	
	# (Opsional) Tutup menu setelah save
	toggle_pause()

# --- FUNGSI LOAD (DIPANGGIL OTOMATIS SAAT START) ---
func load_game_data():
	var config = ConfigFile.new()
	var err = config.load("user://savegame.cfg")
	
	# Kalau file save ada, kita pake posisinya
	if err == OK:
		var x = config.get_value("player", "pos_x", 0)
		var y = config.get_value("player", "pos_y", 0)
		global_position = Vector2(x, y)
		print("DATA LOADED: Pindah ke posisi save terakhir.")
	else:
		# Kalau gak ada save, taruh di tengah map kayak biasa
		var tengah_x = (limit_kiri + limit_kanan) / 2.0
		var tengah_y = (limit_atas + limit_bawah) / 2.0
		global_position = Vector2(tengah_x, tengah_y)
		print("NEW GAME: Spawn di tengah.")

# --- FUNGSI KELUAR ---
func fungsi_keluar():
	get_tree().quit()
