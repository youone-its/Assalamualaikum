extends CharacterBody2D

# --- SETTINGAN KARAKTER ---
@export var max_speed = 300.0
@export var min_speed = 50.0
var current_speed = 0.0

# --- SAKLAR UTAMA ---
var is_active = false 

# --- REFERENSI ---
@onready var camera = $Camera2D
@onready var sprite = $Sprite2D # Pastikan nodenya Sprite2D biasa
@onready var survival_system = get_node("../SurvivalSystem")

func _ready():
	camera.enabled = false
	is_active = false
	
	if $CollisionShape2D.shape == null:
		var shape = RectangleShape2D.new()
		shape.size = Vector2(32, 32)
		$CollisionShape2D.shape = shape

func _physics_process(delta):
	# LOGIKA 1: JIKA TIDAK AKTIF -> DIAM TOTAL
	if not is_active:
		# KITA HAPUS "sprite.stop()" KARENA BUKAN ANIMASI
		return # Langsung berhenti, jangan jalankan kode gerak di bawah

	# LOGIKA 2: JIKA AKTIF -> GERAK
	if survival_system:
		var stamina_now = survival_system.stamina
		var max_stamina = survival_system.max_val
		var persentase = stamina_now / max_stamina
		current_speed = min_speed + (persentase * (max_speed - min_speed))
	else:
		current_speed = max_speed

	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction:
		velocity = direction * current_speed
		
		# Kurangi Stamina
		if survival_system: survival_system.kurangi_stamina_lari(delta)
		
		# Flip Gambar
		if direction.x < 0: sprite.flip_h = true
		elif direction.x > 0: sprite.flip_h = false
		
	else:
		velocity = Vector2.ZERO

	move_and_slide()

# --- FUNGSI SAKLAR ---
func set_active(status: bool):
	is_active = status
	camera.enabled = status 
	if status:
		camera.make_current()

# --- FUNGSI TERIMA ITEM ---
func ambil_item(tipe, jumlah, icon_path):
	if survival_system:
		return survival_system.tambah_item_ke_tas(tipe, jumlah, icon_path)
	return false
