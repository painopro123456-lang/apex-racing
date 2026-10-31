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
var gear_label: Label
var ers_bar: ProgressBar
var ers_percent_label: Label
var drs_label: Label
var menu_layer: CanvasLayer
var elapsed := 0.0
var track_radius := 52.0
var track_points: Array[Vector3] = []
var selected_team := 0
var selected_driver := 0
var selected_track := 0
var selected_tyre_compound := "MEDIUM"
var tyre_label: Label
var systems_label: Label
var race_started := false
var countdown_remaining := 3.0
var race_active := false
var race_finished := false
var player_laps := 0
var player_last_track_index := -1
var race_lap_limit := 3
var race_status_label: Label
var lap_label: Label
var position_label: Label
var leaderboard_rows: Array[Label] = []
var sector_labels: Array[Label] = []
var sector_current := 1
var sector_elapsed := 0.0
var sector_last_index := -1
var sector_times: Array[float] = [0.0, 0.0, 0.0]
var graphics_quality := 1
var world_environment: WorldEnvironment
var sun_light: DirectionalLight3D

func _ready() -> void:
	_build_environment()
	_build_menu()

func _build_environment() -> void:
	var env_node := WorldEnvironment.new()
	world_environment = env_node
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.32, 0.49, 0.67)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.84, 0.9)
	env.ambient_light_energy = 0.95
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.fog_enabled = true
	env.fog_light_color = Color(0.55, 0.66, 0.76)
	env.fog_density = 0.0018
	env_node.environment = env
	add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun_light = sun
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.shadow_enabled = true
	sun.light_energy = 1.25
	sun.directional_shadow_max_distance = 180.0
	add_child(sun)
	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(300, 300)
	ground.mesh = ground_mesh
	ground.material_override = _mat(Color(0.10, 0.24, 0.13))
	ground.position.y = -0.2
	add_child(ground)

func _apply_graphics_quality() -> void:
	var shadow_distances := [65.0, 110.0, 160.0, 220.0]
	var fog_levels := [0.0009, 0.0018, 0.0022, 0.0026]
	var ambient_levels := [0.78, 0.95, 1.0, 1.05]
	if is_instance_valid(sun_light):
		sun_light.shadow_enabled = graphics_quality > 0
		sun_light.directional_shadow_max_distance = shadow_distances[graphics_quality]
	if is_instance_valid(world_environment) and world_environment.environment:
		world_environment.environment.fog_enabled = graphics_quality >= 1
		world_environment.environment.fog_density = fog_levels[graphics_quality]
		world_environment.environment.ambient_light_energy = ambient_levels[graphics_quality]
		world_environment.environment.ssao_enabled = graphics_quality >= 2

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
	_add_menu_label(column, "TYRE COMPOUND")
	var tyre_select := OptionButton.new()
	tyre_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for compound in ["SOFT", "MEDIUM", "HARD"]:
		tyre_select.add_item(compound)
	tyre_select.select(1)
	tyre_select.item_selected.connect(func(index: int): selected_tyre_compound = ["SOFT", "MEDIUM", "HARD"][index])
	column.add_child(tyre_select)
	_add_menu_label(column, "GRAPHICS QUALITY")
	var quality_select := OptionButton.new()
	quality_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for quality_name in ["LOW  •  INTEGRATED GPU", "BALANCED", "HIGH", "ULTRA"]:
		quality_select.add_item(quality_name)
	quality_select.select(graphics_quality)
	quality_select.item_selected.connect(func(index: int): graphics_quality = index)
	column.add_child(quality_select)
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
	_apply_graphics_quality()
	menu_layer.queue_free()
	_build_track(selected_track)
	_build_player()
	player.tyre_compound = selected_tyre_compound
	_build_ai()
	_build_hud()
	player.controls_enabled = false
	for opponent in get_tree().get_nodes_in_group("ai_cars"):
		opponent.set_process(false)
	race_status_label.text = "GET READY  3"

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
	var curb_red := _mat(Color(0.88, 0.055, 0.06))
	var curb_white := _mat(Color(0.88, 0.88, 0.84))
	var barrier_mat := _mat(Color(0.72, 0.75, 0.78))
	for i in range(points.size()):
		var p1: Vector3 = points[i]
		var p2: Vector3 = points[(i + 1) % points.size()]
		_road_piece(p1, p2, 15.0, road_mat)
		var outward1 := p1.normalized()
		var outward2 := p2.normalized()
		var curb_material: Material = curb_red if i % 2 == 0 else curb_white
		_road_piece(p1 + outward1 * 8.2, p2 + outward2 * 8.2, 1.15, curb_material)
		_road_piece(p1 - outward1 * 8.2, p2 - outward2 * 8.2, 1.15, curb_material)
		if i % 2 == 0:
			_barrier_piece(p1 + outward1 * 11.0, p2 + outward2 * 11.0, barrier_mat)
			_barrier_piece(p1 - outward1 * 11.0, p2 - outward2 * 11.0, barrier_mat)
	_add_start_finish_line(points, road_mat)
	_add_trackside_scenery(points)
	_add_pit_lane(points, road_mat)
	_add_box(Vector3(0, 1, -track_radius - 17), Vector3(38, 2, 8), Color(0.68, 0.73, 0.8))

func _add_trackside_scenery(points: Array[Vector3]) -> void:
	# Sparse, low-poly trackside dressing keeps the circuit readable on integrated GPUs.
	var trunk_mat := _mat(Color(0.22, 0.14, 0.08))
	var foliage_mat := _mat(Color(0.10, 0.29, 0.16))
	var stand_mat := _mat(Color(0.20, 0.23, 0.29))
	var seat_mat := _mat(Color(0.78, 0.80, 0.84))
	var scenery_step := [24, 12, 8, 5][graphics_quality]
	for i in range(5, points.size(), scenery_step):
		var p: Vector3 = points[i]
		var outward := Vector3(p.x, 0.0, p.z).normalized()
		for side in [-1.0, 1.0]:
			var location := p + outward * side * 20.0
			var trunk := MeshInstance3D.new()
			var trunk_mesh := CylinderMesh.new()
			trunk_mesh.top_radius = 0.22
			trunk_mesh.bottom_radius = 0.32
			trunk_mesh.height = 2.2
			trunk.mesh = trunk_mesh
			trunk.material_override = trunk_mat
			trunk.position = location + Vector3(0, 1.1, 0)
			add_child(trunk)
			var crown := MeshInstance3D.new()
			var crown_mesh := SphereMesh.new()
			crown_mesh.radius = 1.35
			crown_mesh.height = 2.7
			crown.mesh = crown_mesh
			crown.material_override = foliage_mat
			crown.position = location + Vector3(0, 2.9, 0)
			add_child(crown)
	# A compact grandstand gives the start/finish area a stronger race-event feel.
	if points.size() > 24:
		var centre: Vector3 = points[12]
		var tangent := (points[13] - points[11]).normalized()
		var lateral := Vector3(-tangent.z, 0.0, tangent.x)
		var stand_origin := centre + lateral * 25.0
		for tier in range(4):
			var tier_box := MeshInstance3D.new()
			var tier_mesh := BoxMesh.new()
			tier_mesh.size = Vector3(17.0 - float(tier) * 1.8, 0.65, 2.0)
			tier_box.mesh = tier_mesh
			tier_box.material_override = stand_mat
			tier_box.position = stand_origin + Vector3(0, 1.0 + float(tier) * 0.72, -float(tier) * 1.4)
			tier_box.rotation.y = atan2(-tangent.x, -tangent.z)
			add_child(tier_box)
			var seat_strip := MeshInstance3D.new()
			var seat_mesh := BoxMesh.new()
			seat_mesh.size = Vector3(16.0 - float(tier) * 1.8, 0.12, 0.18)
			seat_strip.mesh = seat_mesh
			seat_strip.material_override = seat_mat
			seat_strip.position = tier_box.position + Vector3(0, 0.38, 0.72)
			seat_strip.rotation.y = tier_box.rotation.y
			add_child(seat_strip)

func _barrier_piece(p1: Vector3, p2: Vector3, material: Material) -> void:
	var barrier := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.55, 1.15, p1.distance_to(p2) + 0.35)
	barrier.mesh = mesh
	barrier.material_override = material
	barrier.position = (p1 + p2) * 0.5 + Vector3(0, 0.58, 0)
	barrier.rotation.y = atan2(-(p2.x - p1.x), -(p2.z - p1.z))
	add_child(barrier)

func _add_start_finish_line(points: Array[Vector3], road_material: Material) -> void:
	if points.size() < 3:
		return
	var p1: Vector3 = points[0]
	var p2: Vector3 = points[1]
	var line := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(15.0, 0.025, 0.85)
	line.mesh = mesh
	line.material_override = _mat(Color(0.92, 0.92, 0.88))
	line.position = (p1 + p2) * 0.5 + Vector3(0, 0.105, 0)
	line.rotation.y = atan2(-(p2.x - p1.x), -(p2.z - p1.z))
	add_child(line)

func _add_pit_lane(points: Array[Vector3], road_material: Material) -> void:
	# A lightweight parallel pit lane beside the opening section of each prototype circuit.
	var lane_points: Array[Vector3] = []
	var limit := min(18, points.size() - 1)
	for i in range(limit + 1):
		var previous: Vector3 = points[(i - 1 + points.size()) % points.size()]
		var next_point: Vector3 = points[(i + 1) % points.size()]
		var tangent := (next_point - previous).normalized()
		var lateral := Vector3(-tangent.z, 0.0, tangent.x)
		lane_points.append(points[i] + lateral * 20.0)
	for i in range(lane_points.size() - 1):
		_road_piece(lane_points[i], lane_points[i + 1], 8.0, road_material)
		if i % 2 == 0:
			_road_piece(lane_points[i] + Vector3(0, 0.12, 0), lane_points[i + 1] + Vector3(0, 0.12, 0), 0.16, _mat(Color(0.92, 0.92, 0.88)))
	for stall in range(8):
		var index := min(2 + stall * 2, lane_points.size() - 2)
		var p: Vector3 = lane_points[index]
		var p_next: Vector3 = lane_points[index + 1]
		var box := MeshInstance3D.new()
		var box_mesh := BoxMesh.new()
		box_mesh.size = Vector3(2.8, 0.035, 4.0)
		box.mesh = box_mesh
		box.material_override = _mat(Color(0.78, 0.8, 0.83))
		box.position = (p + p_next) * 0.5 + Vector3(0, 0.13, 0)
		box.rotation.y = atan2(-(p_next.x - p.x), -(p_next.z - p.z))
		add_child(box)
	if lane_points.size() > 8:
		var middle: Vector3 = lane_points[8]
		_add_box(middle + Vector3(0, 2.2, -8), Vector3(20, 4.4, 7), Color(0.28, 0.32, 0.39))

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
	player.collision_layer = 1
	player.collision_mask = 0
	var player_hitbox := CollisionShape3D.new()
	var player_shape := BoxShape3D.new()
	player_shape.size = Vector3(1.8, 1.0, 4.0)
	player_hitbox.shape = player_shape
	player.add_child(player_hitbox)
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
	# Lightweight low-poly open-wheel car: nose, sidepods, cockpit, halo, wings and tyres.
	var carbon := Color(0.018, 0.022, 0.03)
	var tyre := Color(0.012, 0.014, 0.018)
	var rim := Color(0.32, 0.36, 0.42)
	_add_car_box(parent, Vector3(1.12, 0.28, 2.65), Vector3(0, 0.34, 0.05), color)
	_add_car_box(parent, Vector3(0.48, 0.22, 2.0), Vector3(0, 0.34, -1.92), color.lightened(0.12))
	_add_car_box(parent, Vector3(0.72, 0.22, 1.05), Vector3(0, 0.48, 0.9), color.darkened(0.12))
	for x in [-0.72, 0.72]:
		_add_car_box(parent, Vector3(0.55, 0.42, 1.45), Vector3(x, 0.38, 0.15), color.darkened(0.08))
		_add_car_box(parent, Vector3(0.12, 0.16, 0.95), Vector3(x * 1.25, 0.48, 0.15), carbon)
	_add_car_box(parent, Vector3(2.15, 0.12, 0.48), Vector3(0, 0.2, -2.75), carbon)
	_add_car_box(parent, Vector3(2.0, 0.055, 0.28), Vector3(0, 0.29, -2.62), color)
	for x in [-1.02, 1.02]:
		_add_car_box(parent, Vector3(0.1, 0.38, 0.5), Vector3(x, 0.35, -2.72), color)
	_add_car_box(parent, Vector3(1.9, 0.12, 0.42), Vector3(0, 0.88, 1.72), carbon)
	_add_car_box(parent, Vector3(1.75, 0.08, 0.32), Vector3(0, 1.08, 1.72), color)
	for x in [-0.72, 0.72]:
		_add_car_box(parent, Vector3(0.1, 0.55, 0.36), Vector3(x, 0.72, 1.72), color)
	_add_car_box(parent, Vector3(1.0, 0.12, 0.5), Vector3(0, 0.22, 1.55), carbon)
	_add_car_box(parent, Vector3(0.56, 0.22, 0.78), Vector3(0, 0.63, -0.62), carbon)
	_add_car_box(parent, Vector3(0.075, 0.12, 0.9), Vector3(0, 0.84, -0.66), rim)
	_add_car_box(parent, Vector3(0.72, 0.07, 0.075), Vector3(0, 0.88, -0.25), rim)
	for x in [-0.34, 0.34]:
		_add_car_box(parent, Vector3(0.07, 0.16, 0.08), Vector3(x, 0.82, -0.26), rim)
	for x in [-0.98, 0.98]:
		for z in [-1.65, 1.35]:
			_add_car_cylinder(parent, 0.48, 0.34, Vector3(x, 0.34, z), tyre)
			_add_car_cylinder(parent, 0.22, 0.355, Vector3(x * 1.01, 0.34, z), rim)

func _add_car_cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	node.mesh = mesh
	node.material_override = _mat(color)
	node.position = pos
	node.rotation.z = PI / 2.0
	parent.add_child(node)

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
	material.roughness = 0.82
	return material

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	# Live timing tower at the upper left.
	var board := PanelContainer.new()
	board.position = Vector2(24, 22)
	board.custom_minimum_size = Vector2(218, 0)
	board.add_theme_stylebox_override("panel", _hud_style(Color(0.018, 0.027, 0.043, 0.9), Color(0.25, 0.72, 0.95, 0.9)))
	root.add_child(board)
	var board_col := VBoxContainer.new()
	board_col.add_theme_constant_override("separation", 3)
	board.add_child(board_col)
	var board_title := _hud_label("LIVE TIMING  /  22 CARS", 12, Color(0.55, 0.78, 0.94))
	board_col.add_child(board_title)
	lap_label = _hud_label("LAP  1 / %d" % race_lap_limit, 15, Color.WHITE)
	board_col.add_child(lap_label)
	position_label = _hud_label("P 01", 12, Color(0.95, 0.78, 0.28))
	board_col.add_child(position_label)
	var board_divider := HSeparator.new()
	board_col.add_child(board_divider)
	for row_index in range(22):
		var row := _hud_label("%02d   ---" % (row_index + 1), 11, Color(0.82, 0.87, 0.93))
		row.custom_minimum_size.y = 14
		board_col.add_child(row)
		leaderboard_rows.append(row)

	# Sector timing card in the upper right.
	var sectors := PanelContainer.new()
	sectors.anchor_left = 1.0
	sectors.anchor_right = 1.0
	sectors.offset_left = -205
	sectors.offset_right = -24
	sectors.offset_top = 22
	sectors.offset_bottom = 145
	sectors.add_theme_stylebox_override("panel", _hud_style(Color(0.018, 0.027, 0.043, 0.9), Color(0.25, 0.72, 0.95, 0.9)))
	root.add_child(sectors)
	var sectors_col := VBoxContainer.new()
	sectors_col.add_theme_constant_override("separation", 7)
	sectors.add_child(sectors_col)
	sectors_col.add_child(_hud_label("SECTOR TIMES", 12, Color(0.55, 0.78, 0.94)))
	for sector_index in range(3):
		var sector_row := _hud_label("S%d     --:--.---" % (sector_index + 1), 15, Color.WHITE)
		sectors_col.add_child(sector_row)
		sector_labels.append(sector_row)

	# Bottom-centre telemetry pod, inspired by modern single-seater race displays.
	var telemetry := PanelContainer.new()
	telemetry.anchor_left = 0.5
	telemetry.anchor_right = 0.5
	telemetry.anchor_top = 1.0
	telemetry.anchor_bottom = 1.0
	telemetry.offset_left = -250
	telemetry.offset_right = 250
	telemetry.offset_top = -158
	telemetry.offset_bottom = -20
	telemetry.add_theme_stylebox_override("panel", _hud_style(Color(0.012, 0.019, 0.03, 0.94), Color(0.18, 0.58, 0.82, 0.95)))
	root.add_child(telemetry)
	var telemetry_col := VBoxContainer.new()
	telemetry_col.add_theme_constant_override("separation", 5)
	telemetry.add_child(telemetry_col)
	var top_row := HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_theme_constant_override("separation", 22)
	telemetry_col.add_child(top_row)
	var speed_stack := VBoxContainer.new()
	speed_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_child(speed_stack)
	speed_label = _hud_label("000", 42, Color.WHITE)
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speed_stack.add_child(speed_label)
	var speed_unit := _hud_label("KM/H", 10, Color(0.55, 0.72, 0.84))
	speed_unit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speed_stack.add_child(speed_unit)
	var gear_stack := VBoxContainer.new()
	gear_stack.custom_minimum_size.x = 82
	gear_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_child(gear_stack)
	gear_label = _hud_label("N", 38, Color(0.98, 0.77, 0.22))
	gear_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gear_stack.add_child(gear_label)
	var gear_caption := _hud_label("GEAR", 10, Color(0.55, 0.72, 0.84))
	gear_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gear_stack.add_child(gear_caption)

	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 12)
	telemetry_col.add_child(bottom_row)
	var ers_caption := _hud_label("ERS", 12, Color(0.36, 0.86, 0.72))
	bottom_row.add_child(ers_caption)
	ers_bar = ProgressBar.new()
	ers_bar.custom_minimum_size = Vector2(260, 13)
	ers_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ers_bar.min_value = 0
	ers_bar.max_value = 100
	ers_bar.show_percentage = false
	bottom_row.add_child(ers_bar)
	ers_percent_label = _hud_label("100%", 12, Color.WHITE)
	bottom_row.add_child(ers_percent_label)

	# DRS and tyre status are separated from the main speed readout.
	var status := PanelContainer.new()
	status.anchor_left = 1.0
	status.anchor_right = 1.0
	status.offset_left = -205
	status.offset_right = -24
	status.offset_top = 158
	status.offset_bottom = 252
	status.add_theme_stylebox_override("panel", _hud_style(Color(0.018, 0.027, 0.043, 0.88), Color(0.25, 0.72, 0.95, 0.9)))
	root.add_child(status)
	var status_col := VBoxContainer.new()
	status_col.add_theme_constant_override("separation", 5)
	status.add_child(status_col)
	drs_label = _hud_label("DRS  •  DISABLED", 16, Color(0.62, 0.69, 0.76))
	status_col.add_child(drs_label)
	tyre_label = _hud_label("TYRE  MEDIUM  •  100%", 13, Color.WHITE)
	status_col.add_child(tyre_label)
	systems_label = _hud_label("FUEL  100%", 13, Color(0.78, 0.84, 0.9))
	status_col.add_child(systems_label)

	race_status_label = _hud_label("GET READY", 24, Color(0.98, 0.78, 0.25))
	race_status_label.anchor_left = 0.5
	race_status_label.anchor_right = 0.5
	race_status_label.offset_left = -180
	race_status_label.offset_right = 180
	race_status_label.offset_top = 24
	race_status_label.offset_bottom = 60
	race_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(race_status_label)

	var controls := _hud_label("WASD DRIVE     E ERS     SHIFT DRS", 11, Color(0.72, 0.8, 0.88))
	controls.anchor_left = 0.5
	controls.anchor_right = 0.5
	controls.anchor_top = 1.0
	controls.anchor_bottom = 1.0
	controls.offset_left = -180
	controls.offset_right = 180
	controls.offset_top = -18
	controls.offset_bottom = -2
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(controls)

func _hud_label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _hud_style(fill: Color, edge: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _process(delta: float) -> void:
	if not race_started or race_finished:
		return
	if not race_active:
		countdown_remaining -= delta
		if countdown_remaining > 0.0:
			race_status_label.text = "GET READY  %d" % int(ceil(countdown_remaining))
		else:
			race_active = true
			player.controls_enabled = true
			for opponent in get_tree().get_nodes_in_group("ai_cars"):
				opponent.set_process(true)
			race_status_label.text = "LIGHTS OUT  •  GO!"
		return
	elapsed += delta
	if is_instance_valid(player):
		speed_label.text = "Speed  %03d km/h\nRace time  %05.1f s" % [int(abs(player.speed) * 3.6), elapsed]
		_update_player_lap()
		_update_sector_timing(delta)
		_update_leaderboard()
		var current_track_index := max(player_last_track_index, 0)
		player.drs_zone = current_track_index >= 8 and current_track_index <= 25
		tyre_label.text = "TYRES  %s  •  %02d%%" % [player.tyre_compound, int(player.tyre_wear)]
		systems_label.text = "FUEL  %02d%%" % int(player.fuel_remaining)
		drs_label.text = "DRS  •  ACTIVE" if player.drs_active else ("DRS  •  AVAILABLE" if player.drs_zone else "DRS  •  DISABLED")
		drs_label.add_theme_color_override("font_color", Color(0.28, 0.95, 0.66) if player.drs_active else Color(0.62, 0.69, 0.76))
		var progress := _player_progress_score()
		var position := _get_player_position(progress)
		lap_label.text = "LAP  %d / %d" % [min(player_laps + 1, race_lap_limit), race_lap_limit]
		position_label.text = "P %02d" % position
		if player_laps >= race_lap_limit:
			_finish_race()

func _update_sector_timing(delta: float) -> void:
	if track_points.is_empty():
		return
	sector_elapsed += delta
	var current_index := _nearest_track_index(player.global_position)
	if sector_last_index < 0:
		sector_last_index = current_index
		return
	var count := track_points.size()
	var crossed := false
	if sector_current == 1 and sector_last_index < int(count / 3.0) and current_index >= int(count / 3.0):
		crossed = true
	elif sector_current == 2 and sector_last_index < int(count * 2.0 / 3.0) and current_index >= int(count * 2.0 / 3.0):
		crossed = true
	elif sector_current == 3 and sector_last_index > int(count * 0.8) and current_index < int(count * 0.2):
		crossed = true
	if crossed:
		sector_times[sector_current - 1] = sector_elapsed
		sector_labels[sector_current - 1].text = "S%d     %s" % [sector_current, _format_sector_time(sector_elapsed)]
		sector_labels[sector_current - 1].add_theme_color_override("font_color", Color(0.28, 0.95, 0.66))
		sector_current = 1 if sector_current == 3 else sector_current + 1
		sector_elapsed = 0.0
		sector_labels[sector_current - 1].text = "S%d     LIVE" % sector_current
		sector_labels[sector_current - 1].add_theme_color_override("font_color", Color(0.98, 0.78, 0.25))
	sector_last_index = current_index

func _format_sector_time(value: float) -> String:
	var minutes := int(value / 60.0)
	var seconds := fposmod(value, 60.0)
	return "%02d:%06.3f" % [minutes, seconds]

func _update_leaderboard() -> void:
	var standings: Array[Dictionary] = []
	standings.append({
		"name": DRIVERS_BY_TEAM[selected_team][selected_driver],
		"team": TEAM_NAMES[selected_team],
		"progress": _player_progress_score(),
		"is_player": true
	})
	for opponent in get_tree().get_nodes_in_group("ai_cars"):
		standings.append({
			"name": opponent.driver_name,
			"team": "",
			"progress": float(opponent.completed_laps * track_points.size() + opponent.progress_index),
			"is_player": false
		})
	standings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["progress"]) > float(b["progress"])
	)
	for i in range(min(standings.size(), leaderboard_rows.size())):
		var entry: Dictionary = standings[i]
		var driver_name: String = str(entry["name"])
		var short_name := driver_name.to_upper()
		var parts := short_name.split(" ")
		var display_name := parts[parts.size() - 1] if parts.size() > 0 else short_name
		leaderboard_rows[i].text = "%02d   %s%s" % [i + 1, display_name, "  YOU" if bool(entry["is_player"]) else ""]
		leaderboard_rows[i].add_theme_color_override("font_color", Color(0.35, 0.82, 1.0) if bool(entry["is_player"]) else Color(0.82, 0.87, 0.93))
	position_label.text = "P %02d" % (_get_player_position(_player_progress_score()))

func _nearest_track_index(position: Vector3) -> int:
	var nearest_index := 0
	var nearest_distance := INF
	for i in range(track_points.size()):
		var distance := position.distance_squared_to(track_points[i])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = i
	return nearest_index

func _update_player_lap() -> void:
	if track_points.is_empty():
		return
	var current_index := _nearest_track_index(player.global_position)
	if player_last_track_index >= 0:
		var count := track_points.size()
		if player_last_track_index > int(count * 0.8) and current_index < int(count * 0.2):
			player_laps += 1
	player_last_track_index = current_index

func _player_progress_score() -> float:
	return float(player_laps * track_points.size() + max(player_last_track_index, 0))

func _get_player_position(player_progress: float) -> int:
	var ahead := 0
	for opponent in get_tree().get_nodes_in_group("ai_cars"):
		var score := float(opponent.completed_laps * track_points.size() + opponent.progress_index)
		if score > player_progress:
			ahead += 1
	return ahead + 1

func _finish_race() -> void:
	race_finished = true
	player.controls_enabled = false
	for opponent in get_tree().get_nodes_in_group("ai_cars"):
		opponent.set_process(false)
	race_status_label.text = "FINISHED"
	var result_layer := CanvasLayer.new()
	add_child(result_layer)
	var result_panel := PanelContainer.new()
	result_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result_panel.position = Vector2(-210, -100)
	result_panel.custom_minimum_size = Vector2(420, 200)
	result_layer.add_child(result_panel)
	var result_column := VBoxContainer.new()
	result_panel.add_child(result_column)
	var heading := Label.new()
	heading.text = "RACE COMPLETE"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 28)
	result_column.add_child(heading)
	var result := Label.new()
	result.text = "%s finishes P%d\n3 laps  •  %s\nRace time: %05.1f s" % [DRIVERS_BY_TEAM[selected_team][selected_driver], _get_player_position(_player_progress_score()), TRACKS[selected_track], elapsed]
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_column.add_child(result)
	var close_button := Button.new()
	close_button.text = "EXIT GAME"
	close_button.pressed.connect(func(): get_tree().quit())
	result_column.add_child(close_button)
