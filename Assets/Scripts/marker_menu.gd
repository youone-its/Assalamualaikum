extends PanelContainer

@onready var system = get_node("../../SurvivalSystem") # Sesuaikan path ke System

func _ready():
	visible = false # Sembunyi di awal
	
	# Hubungkan tombol (Signal)
	$VBoxContainer/Consumable.pressed.connect(func(): pilih_marker("consumable"))
	$VBoxContainer/Collection.pressed.connect(func(): pilih_marker("collection"))
	$VBoxContainer/Important.pressed.connect(func(): pilih_marker("important"))
	$VBoxContainer/Batal.pressed.connect(tutup_menu)

func buka_menu():
	visible = true
	# Biar mouse muncul dan bisa klik
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 

func tutup_menu():
	visible = false
	# Balikin mouse jadi ketangkep game lagi (kalau gamemu FPS/TopDown yg hide mouse)
	# Input.mouse_mode = Input.MOUSE_MODE_CAPTURED 

func pilih_marker(tipe):
	if system:
		system.simpan_marker_baru(tipe)
	tutup_menu()
