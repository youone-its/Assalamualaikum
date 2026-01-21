extends Control

@export var zoom_level = 0.15
@export var radius = 75.0

# WARNA BARU
var warna_bg = Color(0, 0, 0, 0.5)
var warna_player = Color(0, 0.5, 1)     # Biru Laut (Kita)
var warna_teman = Color(1, 1, 1)        # Putih (Teman/Karakter Lain)

# Warna Marker
var warna_kuning = Color(1, 1, 0)       # Consumable
var warna_hijau = Color(0, 1, 0)        # Collection
var warna_merah = Color(1, 0, 0)        # Important

@onready var system = get_node("../../SurvivalSystem")

func _process(delta):
	queue_redraw()

func _draw():
	var center = size / 2
	draw_circle(center, radius, warna_bg)
	
	if not system or not system.player_aktif: return
	var my_pos = system.player_aktif.global_position

	# 1. Gambar Player (Kita) - Biru
	draw_circle(center, 4.0, warna_player)
	
	# 2. Gambar Karakter Lain (Teman) - Putih
	for char_node in system.char_nodes:
		if char_node == system.player_aktif: continue
		var target_pos = char_node.global_position
		draw_icon_radar(center, my_pos, target_pos, warna_teman, 3.0)

	# 3. Gambar Marker (Warna-Warni)
	for marker_data in system.list_markers:
		# Cek format data dulu (biar save file lama gak crash)
		if typeof(marker_data) == TYPE_DICTIONARY:
			var pos = marker_data["pos"]
			var tipe = marker_data["tipe"]
			var warna_target = Color(1,1,1)
			
			match tipe:
				"consumable": warna_target = warna_kuning
				"collection": warna_target = warna_hijau
				"important":  warna_target = warna_merah
			
			draw_icon_radar(center, my_pos, pos, warna_target, 3.0)
			
		elif typeof(marker_data) == TYPE_VECTOR2:
			# Support untuk save file lama (Default Kuning)
			draw_icon_radar(center, my_pos, marker_data, warna_kuning, 3.0)

func draw_icon_radar(center, my_pos, target_pos, color, size_dot):
	var diff = target_pos - my_pos
	var screen_diff = diff * zoom_level
	if screen_diff.length() > radius:
		screen_diff = screen_diff.normalized() * (radius - 2.0)
	draw_circle(center + screen_diff, size_dot, color)
