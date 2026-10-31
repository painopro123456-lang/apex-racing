extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player_car.gd")
const AI_SCRIPT = preload("res://scripts/ai_car.gd")

const TEAM_NAMES := [
	"McLaren", "Mercedes", "Red Bull Racing", "Ferrari", "Williams",
	"Racing Bulls", "Aston Martin", "Haas", "Audi", "Alpine", "Cadillac"
]
# Approximate team colour palettes for menu/car identification; these are not official liveries.
const TEAM_COLORS := [
	Color(1.0, 0.40, 0.05), Color(0.00, 0.72, 0.68), Color(0.05, 0.10, 0.30),
	Color(0.82, 0.04, 0.08), Color(0.05, 0.22, 0.72), Color(0.12, 0.30, 0.62),
	Color(0.02, 0.30, 0.18), Color(0.18, 0.20, 0.23), Color(0.65, 0.69, 0.73),
	Color(0.02, 0.25, 0.65), Color(0.08, 0.09, 0.12)
]
const DRIVERS_BY_TEAM := [
	["Lando Norris", "Oscar Piastri"],
	["George Russell", "Kimi Antonelli"],
	["Max Verstappen", "Isack Hadjar"],
	["Charles Leclerc", "Lewis Hamilton"],
	["Alex Albon", "Carlos Sainz"],
	["Liam Lawson", "Arvid Lindblad"],
	["Fernando Alonso", "Lance Stroll"],
	["Esteban Ocon", "Oliver Bearman"],
	["Nico Hulkenberg", "Gabriel Bortoleto"],
	["Pierre Gasly", "Franco Colapinto"],
	["Sergio Perez", "Valtteri Bottas"]
]
const DRIVER_NUMBERS_BY_TEAM := [
	["1", "81"], ["63", "12"], ["3", "6"], ["16", "44"], ["23", "55"],
	["30", "41"], ["14", "18"], ["31", "87"], ["27", "5"], ["10", "43"], ["11", "77"]
]
const TRACKS := ["Apex GP Oval", "Desert Ring", "Harbor Grand Prix"]

var player: CharacterBody3D
var speed_label: Label
var menu_layer: CanvasLayer
var elapsed := 0.0
var track_radius := 52.0
var track_points: Array[Vector3] = []
var selected_team := 0
var selected_driver := 0
var selected_track := 0
var race_started := false

func _ready() -> void:
	_build_environment()
	_build_menu()

func _build_environment() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.38, 0.58, 0.75)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.84, 0.9)
	env.ambient_light_energy = 0.8
	env_node.environment = env
	add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(300, 300)
	ground.mesh = ground_mesh
	ground.material_override = _mat(Color(0.12, 0.27, 0.16))
	ground.position.y = -0.2
	add_child(ground)

func _build_menu() -> void:
	menu_layer = CanvasLayer.new()
	add_child(menu_layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.015, 0.025, 0.045, 0.94)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(610, 0)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 13)
	panel.add_child(column)
	var title := Label.new()
	title.text = "APEX RACING"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "CHOOSE YOUR CAR, DRIVER AND CIRCUIT"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.55, 0.72, 0.95))
	column.add_child(subtitle)
	_add_menu_label(column, "TEAM / CAR")
	var team_select := OptionButton.new()
	team_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for team in TEAM_NAMES:
		team_select.add_item(team)
	team_select.selected = selected_team
	team_select.item_selected.connect(func(index: int): selected_team = index)
	column.add_child(team_select)
	_add_menu_label(column, "YOUR DRIVER")
	var driver_select := OptionButton.new()
	driver_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_driver_select(driver_select)
	driver_select.item_selected.connect(func(index: int): selected_driver = index)
	team_select.item_selected.connect(func(index: int):
		selected_team = index
		selected_driver = 0
		_populate_driver_select(driver_select)
	)
	column.add_child(driver_select)
	_add_menu_label(column, "CIRCUIT")
	var track_select := OptionButton.new()
	track_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for track in TRACKS:
		track_select.add_item(track)
	track_select.selected = selected_track
	track_select.item_selected.connect(func(index: int): selected_track = index)
	column.add_child(track_select)
	var info := Label.new()
	info.text = "11 real 2026 teams  •  22 drivers  •  3 circuits  •  22-car grid"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88))
	column.add_child(info)
	var start := Button.new()
	start.text = "START RACE"
	start.custom_minimum_size = Vector2(0, 52)
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start.pressed.connect(_start_race)
	column.add_child(start)
	var note := Label.new()
	note.text = "2026 driver roster • team colours are approximate, not official liveries."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 11)
	note.add_theme_color_override("font_color", Color(0.58, 0.62, 0.7))
	column.add_child(note)

func _populate_driver_select(driver_select: OptionButton) -> void:
	driver_select.clear()
	for i in range(DRIVERS_BY_TEAM[selected_team].size()):
		var driver_name: String = DRIVERS_BY_TEAM[selected_team][i]
		var driver_number: String = DRIVER_NUMBERS_BY_TEAM[selected_team][i]
		driver_select.add_item("%s  (#%s)" % [driver_name, driver_number])
	driver_select.select(selected_driver)

func _add_menu_label(parent: VBoxContainer, text_value: String) -> void:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.55, 0.72, 0.95))
	parent.add_child(label)

func _start_race() -> void:
	if race_started:
		return
	race_started = true
	menu_layer.queue_free()
	_build_track(selected_track)
	_build_player()
	_build_ai()
	_build_hud()

func _build_track(track_index: int) -> void:
	var points: Array[Vector3] = []
	match track_index:
		0:
			for i in range(128):
				var a := TAU * float(i) / 128.0
				points.append(Vector3(cos(a) * 52.0, 0, sin(a) * 52.0))
		1:
			points = _rounded_rect_points(78.0, 42.0, 15.0, 128)
		2:
			for i in range(160):
				var a := TAU * float(i) / 160.0
				var radius_x := 58.0 + 13.0 * sin(3.0 * a) + 5.0 * cos(5.0 * a)
				var radius_z := 43.0 + 9.0 * cos(2.0 * a)
				points.append(Vector3(cos(a) * radius_x, 0, sin(a) * radius_z))
	track_points = points
	track_radius = 52.0 if track_index == 0 else 57.0
	var road_mat := _mat(Color(0.105, 0.115, 0.13))
	var curb_mat := _mat(Color(0.9, 0.12, 0.12))
	for i in range(points.size()):
		var p1: Vector3 = points[i]
		var p2: Vector3 = points[(i + 1) % points.size()]
		_road_piece(p1, p2, 15.0, road_mat)
		var outward1 := p1.normalized()
		var outward2 := p2.normalized()
		_road_piece(p1 + outward1 * 8.2, p2 + outward2 * 8.2, 1.0, curb_mat)
		_road_piece(p1 - outward1 * 8.2, p2 - outward2 * 8.2, 1.0, curb_mat)
	_add_box(Vector3(0, 1, -track_radius - 17), Vector3(38, 2, 8), Color(0.68, 0.73, 0.8))

func _rounded_rect_points(width: float, depth: float, radius: float, count: int) -> Array[Vector3]:
	var pts: Array[Vector3] = []
	var centers := [
		Vector2(width / 2.0 - radius, -depth / 2.0 + radius),
		Vector2(width / 2.0 - radius, depth / 2.0 - radius),
		Vector2(-width / 2.0 + radius, depth / 2.0 - radius),
		Vector2(-width / 2.0 + radius, -depth / 2.0 + radius)
	]
	for corner in range(4):
		var start_angle := -PI / 2.0 + float(corner) * PI / 2.0
		for j in range(count / 4):
			var a := start_angle + (PI / 2.0) * float(j) / float(count / 4)
			var c: Vector2 = centers[corner]
			pts.append(Vector3(c.x + cos(a) * radius, 0, c.y + sin(a) * radius))
	return pts

func _road_piece(p1: Vector3, p2: Vector3, width: float, mat: Material) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, 0.16, p1.distance_to(p2) + 0.55)
	node.mesh = mesh
	node.material_override = mat
	node.position = (p1 + p2) * 0.5 + Vector3(0, 0.02, 0)
	node.rotation.y = atan2(-(p2.x - p1.x), -(p2.z - p1.z))
	add_child(node)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.set_script(PLAYER_SCRIPT)
	player.position = Vector3(0, 0.45, -track_radius + 7)
	player.rotation.y = PI
	add_child(player)
	_car_visual(player, TEAM_COLORS[selected_team])
	var camera := Camera3D.new()
	camera.position = Vector3(0, 4.8, 10.5)
	camera.rotation_degrees = Vector3(-18, 0, 0)
	camera.current = true
	player.add_child(camera)

func _build_ai() -> void:
	var grid_index := 0
	for team_index in range(TEAM_NAMES.size()):
		for driver_index in range(DRIVERS_BY_TEAM[team_index].size()):
			if team_index == selected_team and driver_index == selected_driver:
				continue
			var ai := Node3D.new()
			ai.set_script(AI_SCRIPT)
			ai.driver_name = DRIVERS_BY_TEAM[team_index][driver_index]
			ai.driver_number = DRIVER_NUMBERS_BY_TEAM[team_index][driver_index]
			ai.lane_offset = -5.0 + float(grid_index % 6) * 1.8
			ai.phase = float(grid_index) / 21.0
			ai.track_points = track_points
			ai.speed_factor = 0.78 + float(grid_index % 7) * 0.035
			ai.track_radius = track_radius
			add_child(ai)
			_car_visual(ai, TEAM_COLORS[team_index])
			grid_index += 1

func _car_visual(parent: Node3D, color: Color) -> void:
	_add_car_box(parent, Vector3(1.5, 0.38, 3.6), Vector3(0, 0.36, 0), color)
	_add_car_box(parent, Vector3(0.55, 0.2, 1.45), Vector3(0, 0.34, -2.0), color.lightened(0.12))
	_add_car_box(parent, Vector3(2.0, 0.12, 0.45), Vector3(0, 0.22, -2.65), Color(0.02, 0.025, 0.035))
	_add_car_box(parent, Vector3(2.0, 0.5, 0.32), Vector3(0, 0.72, 1.35), Color(0.02, 0.025, 0.035))
	for x in [-0.88, 0.88]:
		for z in [-1.05, 1.12]:
			_add_car_box(parent, Vector3(0.36, 0.46, 0.76), Vector3(x, 0.25, z), Color(0.012, 0.014, 0.018))

func _add_car_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = _mat(color)
	node.position = pos
	parent.add_child(node)

func _add_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = _mat(color)
	node.position = pos
	add_child(node)

func _mat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(22, 20)
	panel.custom_minimum_size = Vector2(320, 112)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = "%s  /  %s  (#%s)" % [TEAM_NAMES[selected_team], DRIVERS_BY_TEAM[selected_team][selected_driver], DRIVER_NUMBERS_BY_TEAM[selected_team][selected_driver]]
	title.add_theme_font_size_override("font_size", 15)
	column.add_child(title)
	speed_label = Label.new()
	speed_label.add_theme_font_size_override("font_size", 20)
	column.add_child(speed_label)
	var circuit := Label.new()
	circuit.text = "%s  •  22-car field" % TRACKS[selected_track]
	column.add_child(circuit)
	var controls := Label.new()
	controls.text = "WASD / Arrow keys to drive"
	controls.position = Vector2(22, 670)
	layer.add_child(controls)

func _process(delta: float) -> void:
	if not race_started:
		return
	elapsed += delta
	if is_instance_valid(player):
		speed_label.text = "Speed  %03d km/h\nSession  %05.1f s" % [int(abs(player.speed) * 3.6), elapsed]
