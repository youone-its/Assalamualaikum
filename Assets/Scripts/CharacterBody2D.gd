extends CharacterBody2D

@export var speed = 400 

@onready var camera = $Camera2D

# Variabel batas map
var limit_kiri = 0
var limit_atas = 0
var limit_kanan = 0
var limit_bawah = 0

func _ready():
	# Biar Player digambar DI DEPAN background (Layering)
	z_index = 10 
	
	# Paksa Kamera Aktif & Reset Posisinya ke Player
	camera.enabled = true
	camera.make_current()
	camera.position_smoothing_enabled = false # Matikan smoothing sebentar biar instant
	
	# 1. CARI BACKGROUND
	var background_node = get_node_or_null("../Background")
	
	if background_node:
		# 2. HITUNG BATAS MAP
		var rect = background_node.get_rect()
		var scale_bg = background_node.scale
		
		limit_kiri = int(rect.position.x * scale_bg.x)
		limit_atas = int(rect.position.y * scale_bg.y)
		limit_kanan = int((rect.position.x + rect.size.x) * scale_bg.x)
		limit_bawah = int((rect.position.y + rect.size.y) * scale_bg.y)
		
		# 3. SETTING LIMIT KAMERA
		camera.limit_left = limit_kiri
		camera.limit_top = limit_atas
		camera.limit_right = limit_kanan
		camera.limit_bottom = limit_bawah
		
		# 4. PINDAHKAN PLAYER KE TENGAH
		var tengah_x = (limit_kiri + limit_kanan) / 2.0
		var tengah_y = (limit_atas + limit_bawah) / 2.0
		global_position = Vector2(tengah_x, tengah_y)
		
		# Reset kamera biar langsung snap ke player yang baru pindah
		camera.reset_smoothing()
		
		print("--- SUKSES: Player ada di ", global_position, " ---")
		
	else:
		printerr("ERROR: Node 'Background' tidak ketemu! Cek nama node.")

func _physics_process(_delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# 5. CLAMP
	global_position.x = clamp(global_position.x, limit_kiri, limit_kanan)
	global_position.y = clamp(global_position.y, limit_atas, limit_bawah)
