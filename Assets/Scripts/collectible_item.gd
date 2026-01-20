extends Area2D

var item_type = ""
var restore_amount = 0.0
var texture_path_saved = "" # Simpan path gambar

var player_terdekat = null

func setup_item(kategori: String, path_gambar: String):
	# Simpan path buat dikirim ke inventory nanti
	texture_path_saved = path_gambar
	$Sprite2D.texture = load(path_gambar)
	item_type = kategori
	
	match item_type:
		"food": restore_amount = 20.0
		"drinks": restore_amount = 30.0
		"object": restore_amount = 15.0

func _ready():
	z_index = 5
	$PickupButton.text = "[E]"
	$PickupButton.visible = false
	$PickupButton.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event):
	if event.is_action_pressed("interact") and player_terdekat:
		proses_ambil_barang()

func _on_body_entered(body):
	if body.name == "CharacterBody2D":
		player_terdekat = body
		$PickupButton.visible = true

func _on_body_exited(body):
	if body.name == "CharacterBody2D":
		player_terdekat = null
		$PickupButton.visible = false

func proses_ambil_barang():
	if player_terdekat and player_terdekat.has_method("ambil_item"):
		# KIRIM JUGA TEXTURE PATH-NYA
		var sukses = player_terdekat.ambil_item(item_type, restore_amount, texture_path_saved)
		
		# Hanya hapus barang kalau tas muat (sukses)
		if sukses:
			queue_free()
