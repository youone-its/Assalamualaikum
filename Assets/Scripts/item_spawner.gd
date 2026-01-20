extends Node

# Pastikan kamu sudah drag file .tscn ke slot Inspector script ini
@export var item_scene : PackedScene 

var paths = {
	"food": "res://Assets/Sprites/objects/food/",
	"drinks": "res://Assets/Sprites/objects/drinks/",
	"object": "res://Assets/Sprites/objects/object/"
}

@export var spawn_interval = 2.0 # Saya cepetin jadi 2 detik biar cepet ngetesnya
@export var max_items = 20
var timer = 0.0

# Batas Map
var limit_kiri = 0
var limit_atas = 0
var limit_kanan = 1000 # Nilai default kalau background error
var limit_bawah = 1000 # Nilai default kalau background error

func _ready():
	calculate_map_limits()

func _process(delta):
	timer += delta
	if timer >= spawn_interval:
		timer = 0.0
		if get_tree().get_nodes_in_group("items").size() < max_items:
			spawn_random_item()

func calculate_map_limits():
	# Coba cari background
	var bg = get_node_or_null("../Background")
	
	if bg:
		# CARA HITUNG YANG LEBIH AKURAT
		var rect = bg.get_rect()
		# Kita pakai global scale biar aman kalau ada parent yang di-scale
		var s = bg.global_scale 
		var pos = bg.global_position
		
		# Hitung batas pixel dunia
		limit_kiri = int(pos.x) + 100
		limit_atas = int(pos.y) + 100
		limit_kanan = int(pos.x + (rect.size.x * s.x)) - 100
		limit_bawah = int(pos.y + (rect.size.y * s.y)) - 100
		
		print("SPAWNER: Batas Map ditemukan! ", limit_kanan, " x ", limit_bawah)
	else:
		# KALAU BACKGROUND GAK KETEMU, KITA PAKAI UKURAN LAYAR AJA (DARIPADA 0)
		print("SPAWNER ERROR: Background tidak ketemu, pakai ukuran default.")
		limit_kanan = 2000 
		limit_bawah = 2000

func spawn_random_item():
	if item_scene == null:
		print("ERROR: Item Scene belum dimasukin ke Inspector!")
		return

	var keys = paths.keys()
	var random_cat = keys[randi() % keys.size()]
	var random_texture_path = get_random_file_from_dir(paths[random_cat])
	
	if random_texture_path == "": return 
	
	var item = item_scene.instantiate()
	item.setup_item(random_cat, random_texture_path)
	
	# RANDOM POSISI (Pastikan ini jalan)
	var rand_x = randf_range(limit_kiri, limit_kanan)
	var rand_y = randf_range(limit_atas, limit_bawah)
	
	item.position = Vector2(rand_x, rand_y)
	
	# Tambahkan item ke ROOT scene (Node2D), BUKAN ke Spawner
	# Biar posisinya ngikutin dunia, bukan ngikutin spawner
	get_node("/root").get_child(0).add_child(item)

func get_random_file_from_dir(path: String) -> String:
	var dir = DirAccess.open(path)
	var files = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".png"):
				files.append(file_name)
			file_name = dir.get_next()
		
		if files.size() > 0:
			return path + files[randi() % files.size()]
	return ""
