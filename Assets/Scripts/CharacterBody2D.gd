extends CharacterBody2D

# Settingan Speed
var max_speed = 300.0 # Speed saat segar bugar
var min_speed = 50.0  # Speed saat ngos-ngosan (stamina 0)
var current_speed = 0.0 # Ini nanti dihitung otomatis

@onready var camera = $Camera2D
@onready var survival_system = $SurvivalSystem

# Variabel batas map
var limit_kiri = 0; var limit_atas = 0; var limit_kanan = 0; var limit_bawah = 0

func _ready():
	setup_camera_map()

# --- FUNGSI AMBIL ITEM (DIPANGGIL DARI COLLECTIBLE ITEM) ---
func ambil_item(tipe: String, jumlah: float, icon_path: String):
	# Oper ke sistem survival (Inventory)
	if survival_system:
		var berhasil = survival_system.tambah_item_ke_tas(tipe, jumlah, icon_path)
		return berhasil # Balikin status berhasil/gagal ke item
	return false

func _physics_process(delta):
	# 1. HITUNG SPEED BERDASARKAN STAMINA
	if survival_system:
		# Ambil nilai stamina (0 - 100)
		var stamina_now = survival_system.stamina
		var max_stamina = survival_system.max_val
		
		# Rumus Matematika: Persentase Stamina
		# Kalau stamina 100% -> Speed 300
		# Kalau stamina 0% -> Speed 50
		var persentase = stamina_now / max_stamina
		current_speed = min_speed + (persentase * (max_speed - min_speed))
	else:
		# Fallback kalau survival system error
		current_speed = max_speed

	# 2. MOVEMENT
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction:
		velocity = direction * current_speed
		
		# Kurangi stamina (Panggil fungsi di SurvivalSystem)
		if survival_system:
			survival_system.kurangi_stamina_lari(delta)
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	
	# Clamp posisi map
	global_position.x = clamp(global_position.x, limit_kiri, limit_kanan)
	global_position.y = clamp(global_position.y, limit_atas, limit_bawah)

func setup_camera_map():
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
		
		camera.reset_smoothing()
	else:
		printerr("ERROR: Background tidak ketemu!")
