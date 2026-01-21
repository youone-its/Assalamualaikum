extends Area2D

var item_type = ""
var restore_amount = 0.0
var texture_path_saved = ""
var player_terdekat = null

func setup_item(kategori: String, path_gambar: String):
	texture_path_saved = path_gambar
	$Sprite2D.texture = load(path_gambar)
	item_type = kategori
	match item_type:
		"food": restore_amount = 20.0
		"drinks": restore_amount = 30.0
		"object": restore_amount = 15.0

func _ready():
	z_index = 5
	$PickupButton.visible = false
	$PickupButton.text = "[E]"
	# Animasi
	scale = Vector2(0, 0)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BOUNCE)

func _input(event):
	# Cek input HANYA jika player_terdekat valid
	if event.is_action_pressed("interact") and player_terdekat != null:
		proses_ambil_barang()

func _on_body_entered(body):
	# Cek GRUP, bukan nama node
	if body.is_in_group("players"):
		player_terdekat = body
		$PickupButton.visible = true

func _on_body_exited(body):
	if body == player_terdekat:
		player_terdekat = null
		$PickupButton.visible = false

func proses_ambil_barang():
	if player_terdekat and player_terdekat.has_method("ambil_item"):
		var sukses = player_terdekat.ambil_item(item_type, restore_amount, texture_path_saved)
		if sukses:
			queue_free()
