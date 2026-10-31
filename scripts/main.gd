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
const CAR_ERAS := ["2026 Ground Effect", "2010s V8 Hybrid", "2000s V10", "1990s V12 Classic"]
const TRACKS := [
	"Apex GP Oval", "Desert Ring", "Harbor Grand Prix",
	"Monaco Street Circuit", "Silverstone GP", "Monza", "Spa-Francorchamps",
	"Suzuka", "Bahrain International", "Singapore Marina Bay", "Albert Park",
	"Interlagos", "Zandvoort", "Imola", "Portimao"
]

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
var selected_car_era := 0
var ai_difficulty := 2
var race_mode := "RACE"
var championship_active := false
var championship_round := 0
var championship_round_complete := false
var championship_rounds := 5
var championship_base_track := 0
var championship_standings: Dictionary = {}
const CHAMPIONSHIP_POINTS := [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]
const CHAMPIONSHIP_SAVE_PATH := "user://apex_championship.cfg"
var selected_tyre_compound := "MEDIUM"
var tyre_label: Label
var systems_label: Label
var engineer_label: Label
var gap_label: Label
var setup_label: Label
var engineer_message := "Radio check. All systems ready."
var engineer_cooldown := 0.0
var last_reported_position := 1
var pit_dialog_open := false
var pit_alert_damage := false
var pit_alert_tyres := false
var pit_alert_fuel := false
var race_phase := "IDLE"
var main_race_lap_limit := 3
var penalty_seconds := 0.0
var track_limit_count := 0
var track_limit_timer := 0.0
var track_limit_outside := false
var last_seen_collision_count := 0
var is_dnf := false
var dnf_reason := ""
var race_control_label: Label
var race_flag_label: Label
var yellow_flag_timer := 0.0
var formation_ai_times: Array[Dictionary] = []
var qualifying_best_lap := INF
var qualifying_lap_invalid := false
var qualifying_lap_start_time := 0.0
var qualifying_grid_position := 1
var track_setup: Dictionary = {}
const TRACK_SETUP_PRESETS := {
	"Apex GP Oval": {"brake_bias": 56.0, "aero": 22.0, "front_wing": 18.0, "rear_wing": 22.0},
	"Desert Ring": {"brake_bias": 57.0, "aero": 64.0, "front_wing": 60.0, "rear_wing": 66.0},
	"Harbor Grand Prix": {"brake_bias": 55.0, "aero": 84.0, "front_wing": 84.0, "rear_wing": 90.0},
	"Monaco Street Circuit": {"brake_bias": 54.0, "aero": 96.0, "front_wing": 96.0, "rear_wing": 100.0},
	"Silverstone GP": {"brake_bias": 56.0, "aero": 72.0, "front_wing": 70.0, "rear_wing": 74.0},
	"Monza": {"brake_bias": 58.0, "aero": 28.0, "front_wing": 24.0, "rear_wing": 30.0},
	"Spa-Francorchamps": {"brake_bias": 56.0, "aero": 56.0, "front_wing": 52.0, "rear_wing": 60.0},
	"Suzuka": {"brake_bias": 56.0, "aero": 74.0, "front_wing": 72.0, "rear_wing": 78.0},
	"Bahrain International": {"brake_bias": 57.0, "aero": 58.0, "front_wing": 54.0, "rear_wing": 62.0},
	"Singapore Marina Bay": {"brake_bias": 54.0, "aero": 94.0, "front_wing": 92.0, "rear_wing": 98.0},
	"Albert Park": {"brake_bias": 55.0, "aero": 74.0, "front_wing": 72.0, "rear_wing": 78.0},
	"Interlagos": {"brake_bias": 56.0, "aero": 66.0, "front_wing": 63.0, "rear_wing": 69.0},
	"Zandvoort": {"brake_bias": 55.0, "aero": 84.0, "front_wing": 82.0, "rear_wing": 88.0},
	"Imola": {"brake_bias": 56.0, "aero": 62.0, "front_wing": 59.0, "rear_wing": 66.0},
	"Portimao": {"brake_bias": 56.0, "aero": 72.0, "front_wing": 69.0, "rear_wing": 75.0}
}
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
var graphics_quality := 2
var material_cache: Dictionary = {}
var world_environment: WorldEnvironment
var sun_light: DirectionalLight3D

func _ready() -> void:
	_load_championship()
	_build_environment()
	_build_menu()
	if championship_active:
		if championship_round_complete:
			call_deferred("_show_championship_continue")
		else:
			call_deferred("_resume_championship")

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
	# High is the default; Low cuts shadows and anti-aliasing for integrated GPUs.
	var shadow_distances := [55.0, 95.0, 155.0, 210.0]
	var fog_levels := [0.0008, 0.0014, 0.0019, 0.0022]
	var ambient_levels := [0.82, 0.9, 0.98, 1.02]
	var aa_modes := [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X, Viewport.MSAA_4X]
	get_viewport().msaa_3d = aa_modes[graphics_quality]
	if is_instance_valid(sun_light):
		sun_light.shadow_enabled = graphics_quality >= 1
		sun_light.directional_shadow_max_distance = shadow_distances[graphics_quality]
	if is_instance_valid(world_environment) and world_environment.environment:
		world_environment.environment.fog_enabled = graphics_quality >= 1
		world_environment.environment.fog_density = fog_levels[graphics_quality]
		world_environment.environment.ambient_light_energy = ambient_levels[graphics_quality]
		world_environment.environment.ssao_enabled = false
		world_environment.environment.ssil_enabled = false
func _build_menu() -> void:
	menu_layer = CanvasLayer.new()
	add_child(menu_layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.012, 0.022, 0.042, 0.97)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(backdrop)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 34)
	outer.add_theme_constant_override("margin_right", 34)
	outer.add_theme_constant_override("margin_top", 24)
	outer.add_theme_constant_override("margin_bottom", 24)
	menu_layer.add_child(outer)

	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 22)
	outer.add_child(layout)

	var sidebar := PanelContainer.new()
	sidebar.custom_minimum_size = Vector2(205, 0)
	var side_style := StyleBoxFlat.new()
	side_style.bg_color = Color(0.025, 0.045, 0.075, 0.98)
	side_style.border_color = Color(0.13, 0.24, 0.38, 0.9)
	side_style.set_border_width_all(1)
	side_style.set_corner_radius_all(8)
	sidebar.add_theme_stylebox_override("panel", side_style)
	layout.add_child(sidebar)
	var side_column := VBoxContainer.new()
	side_column.add_theme_constant_override("separation", 12)
	sidebar.add_child(side_column)

	var brand := Label.new()
	brand.text = "APEX\nRACING"
	brand.add_theme_font_size_override("font_size", 30)
	brand.add_theme_color_override("font_color", Color(0.91, 0.95, 1.0))
	side_column.add_child(brand)
	var season := Label.new()
	season.text = "2026  /  MOTORSPORT"
	season.add_theme_font_size_override("font_size", 10)
	season.add_theme_color_override("font_color", Color(0.42, 0.65, 0.91))
	side_column.add_child(season)
	var separator := HSeparator.new()
	side_column.add_child(separator)
	_add_menu_label(side_column, "MAIN MENU")
	var pages: Dictionary = {}
	var content_column := VBoxContainer.new()
	content_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_column.add_theme_constant_override("separation", 16)
	layout.add_child(content_column)

	var header := HBoxContainer.new()
	content_column.add_child(header)
	var heading := Label.new()
	heading.text = "WORLD OF RACING"
	heading.add_theme_font_size_override("font_size", 13)
	heading.add_theme_color_override("font_color", Color(0.56, 0.72, 0.94))
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var status := Label.new()
	status.text = "OFFLINE  •  SINGLE PLAYER"
	status.add_theme_font_size_override("font_size", 10)
	status.add_theme_color_override("font_color", Color(0.65, 0.76, 0.87))
	header.add_child(status)

	var page_host := VBoxContainer.new()
	page_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_column.add_child(page_host)

	var home := VBoxContainer.new()
	home.add_theme_constant_override("separation", 16)
	page_host.add_child(home)
	pages["HOME"] = home
	var welcome := Label.new()
	welcome.text = "WELCOME TO APEX RACING"
	welcome.add_theme_font_size_override("font_size", 29)
	welcome.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
	home.add_child(welcome)
	var tagline := Label.new()
	tagline.text = "Your grid. Your era. Your race."
	tagline.add_theme_font_size_override("font_size", 15)
	tagline.add_theme_color_override("font_color", Color(0.62, 0.72, 0.85))
	home.add_child(tagline)
	var hero := PanelContainer.new()
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var hero_style := StyleBoxFlat.new()
	hero_style.bg_color = Color(0.035, 0.075, 0.13, 0.98)
	hero_style.border_color = Color(0.12, 0.38, 0.72, 0.9)
	hero_style.set_border_width_all(1)
	hero_style.set_corner_radius_all(8)
	hero.add_theme_stylebox_override("panel", hero_style)
	home.add_child(hero)
	var hero_content := VBoxContainer.new()
	hero_content.add_theme_constant_override("separation", 12)
	hero.add_child(hero_content)
	var round_label := Label.new()
	round_label.text = "FEATURED EVENT  /  GRAND PRIX"
	round_label.add_theme_font_size_override("font_size", 11)
	round_label.add_theme_color_override("font_color", Color(0.4, 0.68, 1.0))
	hero_content.add_child(round_label)
	var hero_title := Label.new()
	hero_title.text = "TAKE YOUR PLACE\nON THE GRID"
	hero_title.add_theme_font_size_override("font_size", 32)
	hero_title.add_theme_color_override("font_color", Color(0.97, 0.98, 1.0))
	hero_content.add_child(hero_title)
	var hero_desc := Label.new()
	hero_desc.text = "Choose a team, pick your generation of Formula car and race a full 22-car field."
	hero_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_desc.add_theme_color_override("font_color", Color(0.68, 0.77, 0.88))
	hero_content.add_child(hero_desc)
	var setup_button := Button.new()
	setup_button.text = "RACE WEEKEND  →"
	setup_button.custom_minimum_size = Vector2(0, 48)
	setup_button.pressed.connect(func(): _set_menu_page(pages, "RACE"))
	hero_content.add_child(setup_button)
	var quick_button := Button.new()
	quick_button.text = "QUICK RACE  —  CURRENT SELECTION"
	quick_button.custom_minimum_size = Vector2(0, 42)
	quick_button.pressed.connect(_start_race)
	hero_content.add_child(quick_button)
	var practice_button := Button.new()
	practice_button.text = "PRACTICE VS AI  —  5 LAPS"
	practice_button.custom_minimum_size = Vector2(0, 42)
	practice_button.pressed.connect(_start_race.bind("PRACTICE"))
	hero_content.add_child(practice_button)
	var championship_button := Button.new()
	championship_button.text = "CHAMPIONSHIP  —  5 ROUND SEASON"
	championship_button.custom_minimum_size = Vector2(0, 46)
	championship_button.pressed.connect(_start_championship)
	hero_content.add_child(championship_button)
	var footer := Label.new()
	footer.text = "11 TEAMS     22 DRIVERS     %d CIRCUITS     4 CAR GENERATIONS" % TRACKS.size()
	footer.add_theme_color_override("font_color", Color(0.65, 0.75, 0.87))
	home.add_child(footer)

	var race_page := VBoxContainer.new()
	race_page.add_theme_constant_override("separation", 10)
	page_host.add_child(race_page)
	pages["RACE"] = race_page
	var race_title := Label.new()
	race_title.text = "RACE WEEKEND"
	race_title.add_theme_font_size_override("font_size", 27)
	race_page.add_child(race_title)
	_add_menu_label(race_page, "DRIVER")
	var race_driver_select := OptionButton.new()
	race_driver_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_driver_select(race_driver_select)
	race_driver_select.item_selected.connect(func(index: int): selected_driver = index)
	race_page.add_child(race_driver_select)
	_add_menu_label(race_page, "CIRCUIT")
	var track_select := OptionButton.new()
	track_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for track in TRACKS:
		track_select.add_item(track)
	track_select.select(selected_track)
	track_select.item_selected.connect(func(index: int): selected_track = index)
	race_page.add_child(track_select)
	_add_menu_label(race_page, "TYRE COMPOUND")
	var tyre_select := OptionButton.new()
	for compound in ["SOFT", "MEDIUM", "HARD"]:
		tyre_select.add_item(compound)
	tyre_select.select(1)
	tyre_select.item_selected.connect(func(index: int): selected_tyre_compound = ["SOFT", "MEDIUM", "HARD"][index])
	race_page.add_child(tyre_select)
	var race_summary := Label.new()
	race_summary.text = "2-LAP QUALIFYING  +  MAIN RACE   •   22-CAR GRID"
	race_summary.add_theme_color_override("font_color", Color(0.68, 0.77, 0.88))
	race_page.add_child(race_summary)
	var start := Button.new()
	start.text = "START RACE"
	start.custom_minimum_size = Vector2(0, 52)
	start.pressed.connect(_start_race)
	race_page.add_child(start)
	var practice_start := Button.new()
	practice_start.text = "PRACTICE RACE VS AI"
	practice_start.custom_minimum_size = Vector2(0, 46)
	practice_start.pressed.connect(_start_race.bind("PRACTICE"))
	race_page.add_child(practice_start)
	var championship_start := Button.new()
	championship_start.text = "START 5-ROUND CHAMPIONSHIP"
	championship_start.custom_minimum_size = Vector2(0, 46)
	championship_start.pressed.connect(_start_championship)
	race_page.add_child(championship_start)
	var back_race := Button.new()
	back_race.text = "BACK TO HOME"
	back_race.pressed.connect(func(): _set_menu_page(pages, "HOME"))
	race_page.add_child(back_race)

	var garage := VBoxContainer.new()
	garage.add_theme_constant_override("separation", 10)
	page_host.add_child(garage)
	pages["GARAGE"] = garage
	var garage_title := Label.new()
	garage_title.text = "GARAGE"
	garage_title.add_theme_font_size_override("font_size", 27)
	garage.add_child(garage_title)
	_add_menu_label(garage, "TEAM")
	var team_select := OptionButton.new()
	team_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for team in TEAM_NAMES:
		team_select.add_item(team)
	team_select.select(selected_team)
	garage.add_child(team_select)
	_add_menu_label(garage, "DRIVER")
	var driver_select := OptionButton.new()
	driver_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_driver_select(driver_select)
	garage.add_child(driver_select)
	team_select.item_selected.connect(func(index: int):
		selected_team = index
		selected_driver = 0
		_populate_driver_select(driver_select)
		_populate_driver_select(race_driver_select)
	)
	driver_select.item_selected.connect(func(index: int): selected_driver = index)
	_add_menu_label(garage, "CAR GENERATION")
	var era_select := OptionButton.new()
	for era_name in CAR_ERAS:
		era_select.add_item(era_name)
	era_select.select(selected_car_era)
	era_select.item_selected.connect(func(index: int): selected_car_era = index)
	garage.add_child(era_select)
	var garage_note := Label.new()
	garage_note.text = "Selected team colours are used as the car's base livery."
	garage_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	garage_note.add_theme_color_override("font_color", Color(0.65, 0.75, 0.87))
	garage.add_child(garage_note)
	var back_garage := Button.new()
	back_garage.text = "BACK TO HOME"
	back_garage.pressed.connect(func(): _set_menu_page(pages, "HOME"))
	garage.add_child(back_garage)

	var settings := VBoxContainer.new()
	settings.add_theme_constant_override("separation", 12)
	page_host.add_child(settings)
	pages["SETTINGS"] = settings
	var settings_title := Label.new()
	settings_title.text = "SETTINGS"
	settings_title.add_theme_font_size_override("font_size", 27)
	settings.add_child(settings_title)
	_add_menu_label(settings, "GRAPHICS QUALITY")
	var quality_select := OptionButton.new()
	for quality_name in ["LOW  •  INTEGRATED GPU", "BALANCED", "HIGH", "ULTRA"]:
		quality_select.add_item(quality_name)
	quality_select.select(graphics_quality)
	quality_select.item_selected.connect(func(index: int): graphics_quality = index)
	settings.add_child(quality_select)
	_add_menu_label(settings, "AI DIFFICULTY")
	var difficulty_select := OptionButton.new()
	for difficulty_name in ["ROOKIE", "AMATEUR", "PROFESSIONAL", "EXPERT", "LEGEND"]:
		difficulty_select.add_item(difficulty_name)
	difficulty_select.select(ai_difficulty)
	difficulty_select.item_selected.connect(func(index: int): ai_difficulty = index)
	settings.add_child(difficulty_select)
	var settings_note := Label.new()
	settings_note.text = "Graphics quality controls visual effects. AI difficulty changes opponent pace: Rookie is relaxed, Legend is the toughest."
	settings_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settings_note.add_theme_color_override("font_color", Color(0.65, 0.75, 0.87))
	settings.add_child(settings_note)
	var back_settings := Button.new()
	back_settings.text = "BACK TO HOME"
	back_settings.pressed.connect(func(): _set_menu_page(pages, "HOME"))
	settings.add_child(back_settings)

	for page_name in ["HOME", "RACE", "GARAGE", "SETTINGS"]:
		var nav := Button.new()
		nav.text = page_name
		nav.custom_minimum_size = Vector2(0, 44)
		nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.pressed.connect(func(): _set_menu_page(pages, page_name))
		side_column.add_child(nav)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_column.add_child(spacer)
	var build_info := Label.new()
	build_info.text = "APEX RACING\nWINDOWS EDITION"
	build_info.add_theme_font_size_override("font_size", 10)
	build_info.add_theme_color_override("font_color", Color(0.46, 0.57, 0.7))
	side_column.add_child(build_info)
	_set_menu_page(pages, "HOME")

func _set_menu_page(pages: Dictionary, selected_page: String) -> void:
	for page_name in pages:
		var page: Control = pages[page_name]
		page.visible = page_name == selected_page

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

func _start_race(mode: String = "RACE") -> void:
	if race_started:
		return
	penalty_seconds = 0.0
	track_limit_count = 0
	track_limit_timer = 0.0
	track_limit_outside = false
	last_seen_collision_count = 0
	is_dnf = false
	dnf_reason = ""
	race_mode = mode
	if race_mode == "CHAMPIONSHIP":
		selected_track = (championship_base_track + championship_round) % TRACKS.size()
	main_race_lap_limit = 5 if race_mode == "PRACTICE" or race_mode == "CHAMPIONSHIP" else 3
	race_lap_limit = 2
	race_phase = "QUALIFYING"
	qualifying_best_lap = INF
	qualifying_lap_invalid = false
	qualifying_lap_start_time = 0.0
	qualifying_grid_position = 1
	race_started = true
	yellow_flag_timer = 0.0
	if is_instance_valid(race_flag_label):
		race_flag_label.text = "GREEN FLAG"
	_apply_graphics_quality()
	menu_layer.queue_free()
	_build_track(selected_track)
	_build_player()
	_apply_track_setup()
	player.tyre_compound = selected_tyre_compound
	_build_ai()
	_build_hud()
	player.controls_enabled = false
	for opponent in get_tree().get_nodes_in_group("ai_cars"):
		opponent.set_process(false)
	engineer_message = "Two timed laps. Push when the lights go green."
	race_status_label.text = "QUALIFYING  •  TWO LAPS  •  GET READY"

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
		_:
			points = _named_circuit_points(track_index, 192)
	track_points = points
	track_radius = 52.0 if track_index == 0 else 57.0
	var road_mat := _mat(Color(0.105, 0.115, 0.13))
	var curb_red := _mat(Color(0.88, 0.055, 0.06))
	var curb_white := _mat(Color(0.88, 0.88, 0.84))
	var barrier_mat := _mat(Color(0.72, 0.75, 0.78))
	# The visible road also needs a physical surface or the player's car falls through it.
	var road_physics := StaticBody3D.new()
	road_physics.collision_layer = 1
	road_physics.collision_mask = 0
	add_child(road_physics)
	for i in range(points.size()):
		var p1: Vector3 = points[i]
		var p2: Vector3 = points[(i + 1) % points.size()]
		_road_piece(p1, p2, 15.0, road_mat)
		var segment_direction := p2 - p1
		var road_collision := CollisionShape3D.new()
		var road_shape := BoxShape3D.new()
		road_shape.size = Vector3(15.0, 0.5, segment_direction.length() + 0.3)
		road_collision.shape = road_shape
		road_collision.position = (p1 + p2) * 0.5 + Vector3(0, -0.25, 0)
		road_collision.rotation.y = atan2(-segment_direction.x, -segment_direction.z)
		road_physics.add_child(road_collision)
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

func _named_circuit_points(track_index: int, count: int) -> Array[Vector3]:
	# Distinct fictionalised centreline layouts inspired by the character of each venue.
	# These are original approximations, not surveyed or exact licensed circuit maps.
	var shapes := [
		[60.0, 43.0, 0.10, 0.08, 0.035, 0.02],
		[67.0, 40.0, 0.16, 0.045, 0.025, 0.06],
		[64.0, 46.0, 0.07, 0.14, 0.045, 0.035],
		[62.0, 39.0, 0.19, 0.12, 0.035, 0.075],
		[70.0, 42.0, 0.13, 0.055, 0.07, 0.025],
		[66.0, 38.0, 0.08, 0.035, 0.10, 0.045],
		[72.0, 45.0, 0.14, 0.09, 0.055, 0.08],
		[61.0, 44.0, 0.055, 0.15, 0.08, 0.025],
		[68.0, 41.0, 0.12, 0.07, 0.03, 0.095],
		[63.0, 42.0, 0.17, 0.045, 0.075, 0.055],
		[69.0, 39.0, 0.09, 0.11, 0.04, 0.10],
		[65.0, 46.0, 0.045, 0.16, 0.065, 0.04]
	]
	var shape: Array = shapes[clampi(track_index - 3, 0, shapes.size() - 1)]
	var points: Array[Vector3] = []
	var rx: float = shape[0]
	var rz: float = shape[1]
	for i in range(count):
		var a := TAU * float(i) / float(count)
		var x := rx * cos(a)
		var z := rz * sin(a)
		x += rx * (float(shape[2]) * sin(2.0 * a + 0.25) + float(shape[3]) * cos(3.0 * a - 0.4) + float(shape[4]) * sin(5.0 * a))
		z += rz * (float(shape[3]) * sin(2.0 * a + 0.6) + float(shape[4]) * cos(3.0 * a) + float(shape[5]) * sin(4.0 * a - 0.3))
		points.append(Vector3(x, 0.0, z))
	return points

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
	player.collision_mask = 1
	player.add_to_group("player_car")
	var player_hitbox := CollisionShape3D.new()
	var player_shape := BoxShape3D.new()
	player_shape.size = Vector3(1.8, 1.0, 4.0)
	player_hitbox.shape = player_shape
	player.add_child(player_hitbox)
	# Place the player on the selected circuit's actual start/finish waypoint.
	# This keeps the grid aligned on non-circular layouts as well as the original tracks.
	if track_points.size() >= 3:
		var start_point: Vector3 = track_points[0]
		var start_tangent := (track_points[1] - track_points[track_points.size() - 1]).normalized()
		var start_lateral := Vector3(-start_tangent.z, 0.0, start_tangent.x)
		player.position = start_point + start_lateral * 3.0 + Vector3.UP * 0.45
		player.rotation.y = atan2(-start_tangent.x, -start_tangent.z)
	else:
		player.position = Vector3(0, 0.45, -track_radius + 7)
		player.rotation.y = PI
	add_child(player)
	_car_visual(player, TEAM_COLORS[selected_team], selected_team, selected_car_era)
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
			var grid_row := int(grid_index / 2) + 1
			ai.lane_offset = -2.1 if grid_index % 2 == 0 else 2.1
			# Two-wide starting rows placed just behind the start/finish line.
			ai.phase = fposmod(1.0 - float(grid_row * 4) / float(track_points.size()), 1.0)
			ai.track_points = track_points
			var difficulty_multipliers := [0.72, 0.84, 0.96, 1.08, 1.20]
			# Keep driver-to-driver pace variation small; difficulty controls the field's base pace.
			ai.speed_factor = 0.94 + float(grid_index % 7) * 0.01
			ai.target_speed = 66.0 * difficulty_multipliers[ai_difficulty]
			ai.track_radius = track_radius
			add_child(ai)
			_car_visual(ai, TEAM_COLORS[team_index], team_index, selected_car_era)
			grid_index += 1

const TEAM_SPONSORS := [
	["MASTERCARD", "GOOGLE", "DELL", "OKX"],
	["PETRONAS", "INEOS", "CROWDSTRIKE", "UBS"],
	["ORACLE", "HONDA", "MOBIL 1", "RAUCH"],
	["HP", "SHELL", "PIRELLI", "IBM"],
	["ATLASSIAN", "DURACELL", "GULF", "KOMATSU"],
	["VISA", "CASH APP", "HUGO", "RAY-BAN"],
	["ARAMCO", "CITIZEN", "COGNIZANT", "PERONI"],
	["TOYOTA", "GR", "MoneyGram", "GENE HAAS"],
	["REVOLUT", "BP", "CASTROL", "ADIDAS"],
	["BWT", "MOTOROLA", "MICHELIN", "ALPINE"],
	["TWG", "GM", "CHEVROLET", "TOMMY HILFIGER"]
]

func _car_visual(parent: Node3D, color: Color, team_index: int, car_era: int) -> void:
	# Lightweight low-poly open-wheel car: nose, sidepods, cockpit, halo, wings and tyres.
	var carbon := Color(0.018, 0.022, 0.03)
	var tyre := Color(0.012, 0.014, 0.018)
	var rim := Color(0.32, 0.36, 0.42)
	var classic := car_era >= 2
	var nineties := car_era == 3
	var body_width := 1.12 if not classic else 1.02
	var nose_width := 0.48 if not classic else (0.62 if nineties else 0.54)
	var sidepod_width := 0.55 if not classic else 0.62
	var rear_wing_width := 2.15 if not classic else (2.45 if nineties else 2.3)
	_add_car_box(parent, Vector3(body_width, 0.28, 2.65), Vector3(0, 0.34, 0.05), color)
	_add_car_box(parent, Vector3(nose_width, 0.22, 2.0), Vector3(0, 0.34, -1.92), color.lightened(0.12))
	_add_car_box(parent, Vector3(0.72, 0.22, 1.05), Vector3(0, 0.48, 0.9), color.darkened(0.12))
	for x in [-0.72, 0.72]:
		_add_car_box(parent, Vector3(sidepod_width, 0.42, 1.45), Vector3(x, 0.38, 0.15), color.darkened(0.08))
		_add_car_box(parent, Vector3(0.12, 0.16, 0.95), Vector3(x * 1.25, 0.48, 0.15), carbon)
	_add_car_box(parent, Vector3(rear_wing_width, 0.12, 0.48), Vector3(0, 0.2, -2.75), carbon)
	_add_car_box(parent, Vector3(rear_wing_width - 0.15, 0.055, 0.28), Vector3(0, 0.29, -2.62), color)
	for x in [-1.02, 1.02]:
		_add_car_box(parent, Vector3(0.1, 0.38, 0.5), Vector3(x, 0.35, -2.72), color)
	_add_car_box(parent, Vector3(1.9, 0.12, 0.42), Vector3(0, 0.88, 1.72), carbon)
	_add_car_box(parent, Vector3(1.75, 0.08, 0.32), Vector3(0, 1.08, 1.72), color)
	for x in [-0.72, 0.72]:
		_add_car_box(parent, Vector3(0.1, 0.55, 0.36), Vector3(x, 0.72, 1.72), color)
	_add_car_box(parent, Vector3(1.0, 0.12, 0.5), Vector3(0, 0.22, 1.55), carbon)
	_add_car_box(parent, Vector3(0.56, 0.22, 0.78), Vector3(0, 0.63, -0.62), carbon)
	if car_era <= 1:
		_add_car_box(parent, Vector3(0.075, 0.12, 0.9), Vector3(0, 0.84, -0.66), rim)
		_add_car_box(parent, Vector3(0.72, 0.07, 0.075), Vector3(0, 0.88, -0.25), rim)
		for x in [-0.34, 0.34]:
			_add_car_box(parent, Vector3(0.07, 0.16, 0.08), Vector3(x, 0.82, -0.26), rim)
	else:
		# Earlier open-cockpit generations use a small windscreen instead of a halo.
		_add_car_box(parent, Vector3(0.62, 0.22, 0.12), Vector3(0, 0.79, -0.3), Color(0.12, 0.2, 0.27))
	for x in [-0.98, 0.98]:
		for z in [-1.65, 1.35]:
			_add_car_cylinder(parent, 0.48, 0.34, Vector3(x, 0.34, z), tyre)
			_add_car_cylinder(parent, 0.22, 0.355, Vector3(x * 1.01, 0.34, z), rim)
	# Small layered details add visual depth without expensive materials or textures.
	var accent := color.lightened(0.28)
	var dark_trim := Color(0.025, 0.032, 0.043)
	# Nose centre stripe and front-wing endplate accents.
	_add_car_box(parent, Vector3(0.075, 0.035, 1.45), Vector3(0, 0.485, -1.72), accent)
	for x in [-1.08, 1.08]:
		_add_car_box(parent, Vector3(0.09, 0.3, 0.42), Vector3(x, 0.36, -2.72), accent)
	# Sidepod upper trim and dark lower floor.
	for x in [-0.72, 0.72]:
		_add_car_box(parent, Vector3(0.48, 0.045, 1.12), Vector3(x, 0.605, 0.12), accent)
		_add_car_box(parent, Vector3(0.62, 0.08, 1.58), Vector3(x, 0.16, 0.18), dark_trim)
	# Engine cover spine, cockpit dashboard and rear diffuser.
	_add_car_box(parent, Vector3(0.16 if not classic else 0.25, 0.12, 1.1 if not classic else 1.35), Vector3(0, 0.66, 0.58), accent)
	if classic:
		# Longer engine cover and raised exhaust fairing evoke naturally aspirated V10/V12-era cars.
		_add_car_box(parent, Vector3(0.48, 0.16, 1.25), Vector3(0, 0.59, 1.05), color.darkened(0.16))
		_add_car_box(parent, Vector3(0.36, 0.10, 0.32), Vector3(0, 0.72, 1.55), carbon)
		if nineties:
			_add_car_box(parent, Vector3(0.42, 0.18, 0.55), Vector3(0, 0.69, 0.9), color.lightened(0.08))
	_add_car_box(parent, Vector3(0.42, 0.045, 0.24), Vector3(0, 0.77, -0.42), rim)
	_add_car_box(parent, Vector3(1.35, 0.12, 0.38), Vector3(0, 0.12, 2.0), dark_trim)
	# Rear wing endplates and subtle tyre sidewall bands.
	for x in [-0.98, 0.98]:
		_add_car_box(parent, Vector3(0.075, 0.55, 0.42), Vector3(x, 0.91, 1.72), accent)
	for x in [-0.98, 0.98]:
		for z in [-1.65, 1.35]:
			_add_car_cylinder(parent, 0.245, 0.358, Vector3(x * 1.01, 0.34, z), dark_trim)
	# Lightweight 3D sponsor wordmarks on the sidepods and upper body.
	var sponsors: Array = TEAM_SPONSORS[team_index]
	var primary_ink := Color(0.98, 0.98, 0.96)
	var accent_ink := color.lightened(0.48)
	for side in [-1.0, 1.0]:
		_add_sponsor_decal(parent, str(sponsors[0]), Vector3(side * 1.005, 0.47, 0.18), Vector3(0, side * PI / 2.0, 0), primary_ink, 0.0042, 25)
		_add_sponsor_decal(parent, str(sponsors[1]), Vector3(side * 0.77, 0.625, 0.13), Vector3(-PI / 2.0, 0, 0), accent_ink, 0.0032, 18)
		_add_sponsor_decal(parent, str(sponsors[2]), Vector3(side * 1.005, 0.47, 0.92), Vector3(0, side * PI / 2.0, 0), primary_ink, 0.0027, 16)
	_add_sponsor_decal(parent, str(sponsors[0]), Vector3(0, 0.505, -1.95), Vector3(-PI / 2.0, 0, 0), primary_ink, 0.0034, 22)
	_add_sponsor_decal(parent, str(sponsors[3]), Vector3(0, 0.73, 0.55), Vector3(-PI / 2.0, 0, 0), primary_ink, 0.0028, 16)

func _add_sponsor_decal(parent: Node3D, brand: String, pos: Vector3, rot: Vector3, ink: Color, pixel_scale: float, size: int) -> void:
	var decal := Label3D.new()
	decal.text = brand
	decal.font_size = size
	decal.pixel_size = pixel_scale
	decal.modulate = ink
	decal.outline_size = 3
	decal.outline_modulate = Color(0.015, 0.02, 0.03, 0.95)
	decal.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	decal.no_depth_test = false
	decal.position = pos
	decal.rotation = rot
	decal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	decal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(decal)

func _add_car_cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	node.mesh = mesh
	node.material_override = _car_mat(color)
	node.position = pos
	node.rotation.z = PI / 2.0
	parent.add_child(node)

func _add_car_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = _car_mat(color)
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

func _car_mat(color: Color) -> StandardMaterial3D:
	var key := "car_" + color.to_html(true)
	if material_cache.has(key):
		return material_cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.34 if color.get_luminance() > 0.12 else 0.88
	material.metallic = 0.18 if color.get_luminance() > 0.12 else 0.02
	material_cache[key] = material
	return material

func _mat(color: Color) -> StandardMaterial3D:
	if material_cache.has(color):
		return material_cache[color]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.76
	material_cache[color] = material
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
	systems_label = _hud_label("FUEL  100%  •  DAMAGE 00%", 13, Color(0.78, 0.84, 0.9))
	status_col.add_child(systems_label)
	setup_label = _hud_label("SETUP  •  BB 56%  AERO 22  FW 18  RW 22", 10, Color(0.65, 0.75, 0.87))
	status_col.add_child(setup_label)

	var engineer_panel := PanelContainer.new()
	engineer_panel.anchor_left = 1.0
	engineer_panel.anchor_right = 1.0
	engineer_panel.offset_left = -260
	engineer_panel.offset_right = -24
	engineer_panel.offset_top = 265
	engineer_panel.offset_bottom = 385
	engineer_panel.add_theme_stylebox_override("panel", _hud_style(Color(0.018, 0.027, 0.043, 0.92), Color(0.25, 0.72, 0.95, 0.9)))
	root.add_child(engineer_panel)
	var engineer_col := VBoxContainer.new()
	engineer_col.add_theme_constant_override("separation", 5)
	engineer_panel.add_child(engineer_col)
	engineer_col.add_child(_hud_label("RACE ENGINEER  /  RADIO", 11, Color(0.55, 0.78, 0.94)))
	gap_label = _hud_label("GAP BEHIND  --", 12, Color.WHITE)
	engineer_col.add_child(gap_label)
	race_control_label = _hud_label("RACE CONTROL  •  PENALTIES 0.0s", 10, Color(0.98, 0.78, 0.25))
	engineer_col.add_child(race_control_label)
	race_flag_label = _hud_label("GREEN FLAG", 13, Color(0.25, 0.95, 0.52))
	race_flag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	engineer_col.add_child(race_flag_label)
	engineer_label = _hud_label(engineer_message, 12, Color(0.9, 0.93, 0.97))
	engineer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	engineer_col.add_child(engineer_label)

	race_status_label = _hud_label("GET READY", 24, Color(0.98, 0.78, 0.25))
	race_status_label.anchor_left = 0.5
	race_status_label.anchor_right = 0.5
	race_status_label.offset_left = -180
	race_status_label.offset_right = 180
	race_status_label.offset_top = 24
	race_status_label.offset_bottom = 60
	race_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(race_status_label)

	var controls := _hud_label("WASD DRIVE     E ERS     SHIFT DRS     P PIT", 11, Color(0.72, 0.8, 0.88))
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
	if Input.is_action_just_pressed("pit_request") and race_active:
		_open_pit_strategy("Your request")
	if yellow_flag_timer > 0.0:
		yellow_flag_timer = max(0.0, yellow_flag_timer - delta)
		if yellow_flag_timer <= 0.0:
			_clear_yellow_flag()
		if yellow_flag_timer <= 0.0 and is_instance_valid(race_flag_label):
			race_flag_label.text = "GREEN FLAG"
			race_flag_label.add_theme_color_override("font_color", Color(0.25, 0.95, 0.52))
	if race_phase == "QUALIFYING_RESULTS":
		return
	if not race_active:
		countdown_remaining -= delta
		if countdown_remaining > 0.0:
			var countdown_text := "RACE  •  %d" % int(ceil(countdown_remaining))
			if race_phase == "FORMATION":
				countdown_text = "FORMATION LAP  •  %d" % int(ceil(countdown_remaining))
			elif race_phase == "QUALIFYING":
				countdown_text = "QUALIFYING  •  %d" % int(ceil(countdown_remaining))
			elif race_mode == "CHAMPIONSHIP":
				countdown_text = "CHAMPIONSHIP  •  ROUND %d/%d  •  %d" % [championship_round + 1, championship_rounds, int(ceil(countdown_remaining))]
			elif race_mode == "PRACTICE":
				countdown_text = "PRACTICE  •  %d" % int(ceil(countdown_remaining))
			race_status_label.text = countdown_text
		else:
			race_active = true
			player.controls_enabled = true
			for opponent in get_tree().get_nodes_in_group("ai_cars"):
				opponent.set_process(true)
			if race_phase == "FORMATION":
				race_status_label.text = "FORMATION LAP  •  FOLLOW THE PACK"
			elif race_phase == "QUALIFYING":
				race_status_label.text = "QUALIFYING  •  GO!"
			elif race_mode == "PRACTICE":
				race_status_label.text = "PRACTICE  •  GO!"
			else:
				race_status_label.text = "LIGHTS OUT  •  GO!"
		return
	elapsed += delta
	if is_instance_valid(player):
		if player.global_position.y < -2.0:
			_retire_player("Car went off the circuit")
			return
		if player.damage >= 100.0:
			_retire_player("Terminal car damage")
			return
		_update_track_limits(delta)
		_update_collision_penalties()
		speed_label.text = "Speed  %03d km/h\\nSession time  %05.1f s" % [int(abs(player.speed) * 3.6), elapsed]
		_update_player_lap()
		_update_sector_timing(delta)
		_update_leaderboard()
		var current_track_index := max(player_last_track_index, 0)
		player.drs_zone = current_track_index >= 8 and current_track_index <= 25
		tyre_label.text = "TYRES  %s  •  %02d%%" % [player.tyre_compound, int(player.tyre_wear)]
		systems_label.text = "FUEL  %02d%%  •  DAMAGE %02d%%" % [int(player.fuel_remaining), int(player.damage)]
		if is_instance_valid(race_control_label):
			race_control_label.text = "RACE CONTROL  •  PENALTIES %.0fs  •  LIMITS %d" % [penalty_seconds, track_limit_count]
		if not track_setup.is_empty():
			setup_label.text = "BB %.0f%%  •  AERO %.0f  •  FW %.0f / RW %.0f" % [track_setup["brake_bias"], track_setup["aero"], track_setup["front_wing"], track_setup["rear_wing"]]
		drs_label.text = "DRS  •  ACTIVE" if player.drs_active else ("DRS  •  AVAILABLE" if player.drs_zone else "DRS  •  DISABLED")
		drs_label.add_theme_color_override("font_color", Color(0.28, 0.95, 0.66) if player.drs_active else Color(0.62, 0.69, 0.76))
		var progress := _player_progress_score()
		var position := _get_player_position(progress)
		lap_label.text = "LAP  %d / %d" % [max(1, min(player_laps + 1, race_lap_limit)), race_lap_limit]
		position_label.text = "P %02d" % position
		_update_engineer(delta)
		if race_phase == "QUALIFYING" and player_laps >= 2:
			_finish_qualifying()
		elif race_phase == "FORMATION" and player_laps >= 1:
			_complete_formation_lap()
		elif race_phase == "RACE" and player_laps >= race_lap_limit:
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
			if race_phase == "QUALIFYING":
				var lap_time := elapsed - qualifying_lap_start_time
				if lap_time > 0.1 and not qualifying_lap_invalid:
					qualifying_best_lap = min(qualifying_best_lap, lap_time)
				elif qualifying_lap_invalid:
					engineer_message = "Lap deleted for track limits. Push on this lap."
				qualifying_lap_invalid = false
				qualifying_lap_start_time = elapsed
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

func _update_track_limits(delta: float) -> void:
	if (race_phase != "RACE" and race_phase != "QUALIFYING" and race_phase != "FORMATION") or track_points.size() < 4:
		return
	var nearest_index := _nearest_track_index(player.global_position)
	var nearest_distance := player.global_position.distance_to(track_points[nearest_index])
	# 9 m allows for kerbs and the spacing between generated centreline samples.
	var outside_limits := nearest_distance > 9.0 and abs(player.speed) > 8.0
	if outside_limits:
		track_limit_timer += delta
		if track_limit_timer >= 0.8 and not track_limit_outside:
			track_limit_outside = true
			if race_phase == "FORMATION":
				engineer_message = "Stay on the circuit during the formation lap."
				_trigger_yellow_flag("Car off track")
			elif race_phase == "QUALIFYING":
				qualifying_lap_invalid = true
				engineer_message = "Track limits. LAP DELETED. Stay within the white lines."
			else:
				track_limit_count += 1
				_trigger_yellow_flag("Track limits")
				if track_limit_count >= 3 and (track_limit_count - 3) % 2 == 0:
					_issue_time_penalty("Repeated track-limit violations", 5.0)
				else:
					engineer_message = "Track limits warning %d. Keep all four wheels inside the white line." % track_limit_count
			if is_instance_valid(engineer_label):
				engineer_label.text = engineer_message
	else:
		track_limit_timer = 0.0
		track_limit_outside = false

func _trigger_yellow_flag(reason: String) -> void:
	yellow_flag_timer = 6.0
	if is_instance_valid(race_flag_label):
		race_flag_label.text = "YELLOW FLAG  •  %s" % reason.to_upper()
		race_flag_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.18))
	engineer_message = "Yellow flag. Slow down, no overtaking, and be ready for the green."
	if is_instance_valid(engineer_label):
		engineer_label.text = engineer_message
	for opponent in get_tree().get_nodes_in_group("ai_cars"):
		opponent.caution_mode = true
	if is_instance_valid(player):
		player.max_speed = min(player.max_speed, 55.0)

func _clear_yellow_flag() -> void:
	for opponent in get_tree().get_nodes_in_group("ai_cars"):
		opponent.caution_mode = false
	if is_instance_valid(player):
		player.max_speed = 30.0 if race_phase == "FORMATION" else 88.0

func _update_collision_penalties() -> void:
	var current_collisions := int(player.collision_count)
	while last_seen_collision_count < current_collisions:
		last_seen_collision_count += 1
		if race_phase == "RACE":
			_trigger_yellow_flag("Incident")
		if last_seen_collision_count >= 3 and last_seen_collision_count % 2 == 1:
			_issue_time_penalty("Repeated avoidable contact", 5.0)

func _issue_time_penalty(reason: String, seconds: float) -> void:
	penalty_seconds += seconds
	engineer_message = "RACE CONTROL: %s. +%.0fs. Total penalty %.0fs." % [reason, seconds, penalty_seconds]
	if is_instance_valid(engineer_label):
		engineer_label.text = engineer_message

func _retire_player(reason: String) -> void:
	if race_finished:
		return
	is_dnf = true
	dnf_reason = reason
	if is_instance_valid(race_flag_label):
		race_flag_label.text = "RED FLAG  •  SESSION STOPPED"
		race_flag_label.add_theme_color_override("font_color", Color(1.0, 0.18, 0.2))
	race_phase = "DNF"
	engineer_message = "BOX BOX. Car retired: %s." % reason
	if is_instance_valid(engineer_label):
		engineer_label.text = engineer_message
	_finish_race()

func _position_after_penalties() -> int:
	var base_position := _get_player_position(_player_progress_score())
	if penalty_seconds <= 0.0:
		return base_position
	var player_score := _player_progress_score()
	var circuit_length := _track_length()
	var demotions := 0
	for opponent in get_tree().get_nodes_in_group("ai_cars"):
		var opponent_score := float(opponent.completed_laps * track_points.size() + opponent.progress_index)
		if opponent_score >= player_score:
			continue
		var distance_points := player_score - opponent_score
		var average_speed := max((abs(player.speed) + float(opponent.current_speed)) * 0.5, 12.0)
		var estimated_gap := distance_points * circuit_length / max(track_points.size(), 1) / average_speed
		if penalty_seconds >= estimated_gap:
			demotions += 1
	return clampi(base_position + demotions, base_position, 22)

func _track_length() -> float:
	var total := 0.0
	for i in range(track_points.size()):
		total += track_points[i].distance_to(track_points[(i + 1) % track_points.size()])
	return max(total, 1.0)

func _apply_track_setup() -> void:
	track_setup = TRACK_SETUP_PRESETS.get(TRACKS[selected_track], TRACK_SETUP_PRESETS["Desert Ring"]).duplicate(true)
	if is_instance_valid(player):
		player.brake_bias = float(track_setup["brake_bias"])
		player.aero_level = float(track_setup["aero"])
		player.front_wing = float(track_setup["front_wing"])
		player.rear_wing = float(track_setup["rear_wing"])

func _track_lane_point(index: int, offset: float) -> Vector3:
	var count := track_points.size()
	var centre: Vector3 = track_points[index % count]
	var previous: Vector3 = track_points[(index - 1 + count) % count]
	var next_point: Vector3 = track_points[(index + 1) % count]
	var tangent := (next_point - previous).normalized()
	return centre + Vector3(-tangent.z, 0.0, tangent.x) * offset + Vector3.UP * 0.45

func _finish_qualifying() -> void:
	if race_phase != "QUALIFYING":
		return
	race_phase = "QUALIFYING_RESULTS"
	race_active = false
	player.controls_enabled = false
	for opponent in get_tree().get_nodes_in_group("ai_cars"):
		opponent.set_process(false)
	var ai_times: Array[Dictionary] = []
	var circuit_length := _track_length()
	var ai_index := 0
	for opponent in get_tree().get_nodes_in_group("ai_cars"):
		var variation := 1.38 + float(ai_index % 7) * 0.045
		var simulated_time := circuit_length / max(opponent.target_speed * opponent.speed_factor, 12.0) * variation
		ai_times.append({"car": opponent, "time": simulated_time})
		ai_index += 1
	ai_times.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["time"]) < float(b["time"])
	)
	qualifying_grid_position = 1
	for entry in ai_times:
		if float(entry["time"]) < qualifying_best_lap:
			qualifying_grid_position += 1
	var result_layer := CanvasLayer.new()
	add_child(result_layer)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-245, -135)
	panel.custom_minimum_size = Vector2(490, 270)
	result_layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var heading := _hud_label("QUALIFYING COMPLETE", 24, Color(0.35, 0.82, 1.0))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var timing := _hud_label("BEST LAP  %s\\nSTARTING POSITION  P%02d" % [_format_sector_time(qualifying_best_lap if qualifying_best_lap < INF else elapsed), qualifying_grid_position], 18, Color.WHITE)
	timing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(timing)
	var note := _hud_label("Your two timed laps are complete. The grid is set from qualifying pace.", 12, Color(0.68, 0.77, 0.88))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(note)
	var start_button := Button.new()
	start_button.text = "START FORMATION LAP"
	start_button.custom_minimum_size = Vector2(0, 46)
	start_button.pressed.connect(func():
		result_layer.queue_free()
		_begin_formation_lap(ai_times)
	)
	column.add_child(start_button)
	engineer_message = "Good job. P%d on the grid. Confirm your race tyres, then we go." % qualifying_grid_position
	engineer_label.text = engineer_message

func _begin_formation_lap(ai_times: Array[Dictionary]) -> void:
	race_phase = "FORMATION"
	formation_ai_times = ai_times.duplicate()
	elapsed = 0.0
	player_laps = 0
	player_last_track_index = _nearest_track_index(player.global_position)
	countdown_remaining = 3.0
	race_active = false
	player.max_speed = 30.0
	player.controls_enabled = false
	var grid_position := 1
	for entry in ai_times:
		var opponent = entry["car"]
		if grid_position == qualifying_grid_position:
			grid_position += 1
		opponent.reset_to_grid(grid_position)
		grid_position += 1
	if qualifying_grid_position == 1:
		player.global_position = _track_lane_point(0, 2.1)
		player_last_track_index = 0
	else:
		var row := int((qualifying_grid_position - 2) / 2) + 1
		var phase := fposmod(1.0 - float(row * 4) / float(track_points.size()), 1.0)
		var row_start := int(phase * track_points.size()) % track_points.size()
		var start_index := (row_start + (1 if qualifying_grid_position % 2 == 0 else 0)) % track_points.size()
		var lane := -2.1 if qualifying_grid_position % 2 == 0 else 2.1
		player.global_position = _track_lane_point(start_index, lane)
		player_last_track_index = start_index
	player_laps = 0
	var grid_previous: Vector3 = track_points[(player_last_track_index - 1 + track_points.size()) % track_points.size()]
	var grid_next: Vector3 = track_points[(player_last_track_index + 1) % track_points.size()]
	var grid_tangent := (grid_next - grid_previous).normalized()
	player.rotation.y = atan2(-grid_tangent.x, -grid_tangent.z)
	for opponent in get_tree().get_nodes_in_group("ai_cars"):
		opponent.formation_mode = true
		opponent.set_process(false)
	engineer_message = "Formation lap. Keep position, weave gently to warm the tyres, and do not overtake."
	if is_instance_valid(engineer_label):
		engineer_label.text = engineer_message
	race_status_label.text = "FORMATION LAP  •  GET READY"
	if is_instance_valid(race_flag_label):
		race_flag_label.text = "FORMATION LAP"
		race_flag_label.add_theme_color_override("font_color", Color(0.35, 0.82, 1.0))

func _complete_formation_lap() -> void:
	for opponent in get_tree().get_nodes_in_group("ai_cars"):
		opponent.formation_mode = false
	player.max_speed = 88.0
	engineer_message = "Formation lap complete. Return to your grid slot. Stand by for lights."
	if is_instance_valid(engineer_label):
		engineer_label.text = engineer_message
	_begin_main_race(formation_ai_times)

func _begin_main_race(ai_times: Array[Dictionary]) -> void:
	race_phase = "RACE"
	player.max_speed = 88.0
	penalty_seconds = 0.0
	track_limit_count = 0
	track_limit_timer = 0.0
	track_limit_outside = false
	last_seen_collision_count = int(player.collision_count)
	is_dnf = false
	dnf_reason = ""
	race_lap_limit = main_race_lap_limit
	elapsed = 0.0
	countdown_remaining = 3.0
	race_active = false
	player_laps = 0
	player_last_track_index = 0
	sector_current = 1
	sector_elapsed = 0.0
	sector_last_index = -1
	sector_times = [0.0, 0.0, 0.0]
	qualifying_lap_start_time = 0.0
	player.tyre_compound = selected_tyre_compound
	player.tyre_wear = 100.0
	player.fuel_remaining = 100.0
	player.ers_charge = 100.0
	player.damage = 0.0
	player.velocity = Vector3.ZERO
	player.speed = 0.0
	# Sort and place the 21 AI cars around the player's qualifying position.
	var grid_position := 1
	for entry in ai_times:
		var opponent = entry["car"]
		if grid_position == qualifying_grid_position:
			grid_position += 1
		opponent.reset_to_grid(grid_position)
		grid_position += 1
	if qualifying_grid_position == 1:
		player.global_position = _track_lane_point(0, 2.1)
		player_laps = 0
		player_last_track_index = 0
	else:
		var row := int((qualifying_grid_position - 2) / 2) + 1
		var phase := fposmod(1.0 - float(row * 4) / float(track_points.size()), 1.0)
		var row_start := int(phase * track_points.size()) % track_points.size()
		var start_index := (row_start + (1 if qualifying_grid_position % 2 == 0 else 0)) % track_points.size()
		var lane := -2.1 if qualifying_grid_position % 2 == 0 else 2.1
		player.global_position = _track_lane_point(start_index, lane)
		player_laps = -1
		player_last_track_index = start_index
	var previous: Vector3 = track_points[(max(player_last_track_index, 0) - 1 + track_points.size()) % track_points.size()]
	var next_point: Vector3 = track_points[(max(player_last_track_index, 0) + 1) % track_points.size()]
	var tangent := (next_point - previous).normalized()
	player.rotation.y = atan2(-tangent.x, -tangent.z)
	player.controls_enabled = false
	last_reported_position = qualifying_grid_position
	pit_alert_damage = false
	pit_alert_tyres = false
	pit_alert_fuel = false
	engineer_message = "Race start in three. You are P%d. Watch the car behind." % qualifying_grid_position
	if is_instance_valid(engineer_label):
		engineer_label.text = engineer_message
	lap_label.text = "LAP  1 / %d" % race_lap_limit
	position_label.text = "P %02d" % qualifying_grid_position
	race_status_label.text = "GRID  •  P%02d  •  LIGHTS IN 3" % qualifying_grid_position

func _gap_to_car_behind() -> Dictionary:
	var player_score := _player_progress_score()
	var closest: Node3D = null
	var closest_score := -INF
	for opponent in get_tree().get_nodes_in_group("ai_cars"):
		var score := float(opponent.completed_laps * track_points.size() + opponent.progress_index)
		if score < player_score and score > closest_score:
			closest_score = score
			closest = opponent
	if closest == null:
		return {"name": "NONE", "gap": -1.0}
	var points_behind := player_score - closest_score
	var average_segment := _track_length() / max(track_points.size(), 1)
	var average_speed := max((abs(player.speed) + float(closest.current_speed)) * 0.5, 12.0)
	return {"name": closest.driver_name, "gap": points_behind * average_segment / average_speed}

func _update_engineer(delta: float) -> void:
	engineer_cooldown = max(0.0, engineer_cooldown - delta)
	var behind := _gap_to_car_behind()
	if float(behind["gap"]) >= 0.0:
		gap_label.text = "GAP TO %s  +%.1fs" % [str(behind["name"]).to_upper(), float(behind["gap"])]
	else:
		gap_label.text = "GAP BEHIND  NO CAR"
	var current_position := _get_player_position(_player_progress_score())
	if current_position > last_reported_position and engineer_cooldown <= 0.0:
		engineer_message = "We've lost a place. Box this lap? Choose a compound if you want to react."
		engineer_cooldown = 12.0
		last_reported_position = current_position
		_open_pit_strategy("Position change")
	elif current_position < last_reported_position and engineer_cooldown <= 0.0:
		engineer_message = "Great move. You're up to P%d. Keep pushing." % current_position
		engineer_cooldown = 8.0
		last_reported_position = current_position
	if player.damage >= 25.0 and not pit_alert_damage and not pit_dialog_open:
		pit_alert_damage = true
		engineer_message = "Damage detected. Box box. Which compound should we fit?"
		_open_pit_strategy("Damage")
	elif player.tyre_wear <= 20.0 and not pit_alert_tyres and not pit_dialog_open:
		pit_alert_tyres = true
		engineer_message = "Tyres are heavily worn. Box box. Choose your next compound."
		_open_pit_strategy("Tyre wear")
	elif player.fuel_remaining <= 15.0 and not pit_alert_fuel and not pit_dialog_open:
		pit_alert_fuel = true
		engineer_message = "Fuel is critical. Box box. Select a compound for the stop."
		_open_pit_strategy("Fuel")
	if is_instance_valid(engineer_label):
		engineer_label.text = engineer_message

func _open_pit_strategy(reason: String) -> void:
	if pit_dialog_open or not is_instance_valid(player) or race_phase != "RACE":
		return
	pit_dialog_open = true
	player.controls_enabled = false
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-220, -120)
	panel.custom_minimum_size = Vector2(440, 240)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var heading := _hud_label("BOX BOX  •  PIT STRATEGY", 22, Color(0.35, 0.82, 1.0))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var prompt := _hud_label("%s. Which tyre compound do you want?" % reason, 14, Color.WHITE)
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(prompt)
	var compound_select := OptionButton.new()
	for compound in ["SOFT", "MEDIUM", "HARD"]:
		compound_select.add_item(compound)
	compound_select.select(["SOFT", "MEDIUM", "HARD"].find(player.tyre_compound))
	column.add_child(compound_select)
	var actions := HBoxContainer.new()
	column.add_child(actions)
	var stay_button := Button.new()
	stay_button.text = "STAY OUT"
	stay_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stay_button.pressed.connect(func():
		pit_dialog_open = false
		player.controls_enabled = true
		engineer_message = "Copy. Stay out. We'll monitor the car."
		engineer_label.text = engineer_message
		layer.queue_free()
	)
	actions.add_child(stay_button)
	var box_button := Button.new()
	box_button.text = "BOX NOW  (+22s)"
	box_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box_button.pressed.connect(func():
		_complete_pit_stop(compound_select.get_item_text(compound_select.selected), layer)
	)
	actions.add_child(box_button)

func _complete_pit_stop(compound: String, layer: CanvasLayer) -> void:
	selected_tyre_compound = compound
	player.tyre_compound = compound
	player.tyre_wear = 100.0
	player.fuel_remaining = 100.0
	player.ers_charge = 100.0
	player.damage = 0.0
	elapsed += 22.0
	pit_dialog_open = false
	player.controls_enabled = true
	pit_alert_damage = false
	pit_alert_tyres = false
	pit_alert_fuel = false
	engineer_message = "Pit stop complete. %s tyres fitted, damage repaired and fuel replenished." % compound
	engineer_label.text = engineer_message
	layer.queue_free()

func _finish_race() -> void:
	race_finished = true
	player.controls_enabled = false
	for opponent in get_tree().get_nodes_in_group("ai_cars"):
		opponent.set_process(false)
	race_status_label.text = "FINISHED"
	var player_position := 22 if is_dnf else _position_after_penalties()
	var classified_time := elapsed + penalty_seconds
	var points_earned := 0
	var total_points := 0
	if race_mode == "CHAMPIONSHIP":
		points_earned = _award_championship_points()
		championship_round_complete = true
		_save_championship()
		total_points = int(championship_standings.get(DRIVERS_BY_TEAM[selected_team][selected_driver], 0))
	var result_layer := CanvasLayer.new()
	add_child(result_layer)
	var result_panel := PanelContainer.new()
	result_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result_panel.position = Vector2(-260, -165)
	result_panel.custom_minimum_size = Vector2(520, 330)
	result_layer.add_child(result_panel)
	var result_column := VBoxContainer.new()
	result_panel.add_child(result_column)
	var heading := Label.new()
	heading.text = "RACE  •  DNF" if is_dnf else (("CHAMPIONSHIP  •  ROUND %d COMPLETE" % (championship_round + 1)) if race_mode == "CHAMPIONSHIP" else ("PRACTICE COMPLETE" if race_mode == "PRACTICE" else "RACE COMPLETE"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 25)
	result_column.add_child(heading)
	var result := Label.new()
	if race_mode == "CHAMPIONSHIP":
		result.text = ("%s  •  DNF\n%s\n0 points  •  %s\nPenalties: %.0fs" % [DRIVERS_BY_TEAM[selected_team][selected_driver], TRACKS[selected_track], dnf_reason, penalty_seconds]) if is_dnf else ("%s finishes P%d\n%s\n+%d points  •  Season total: %d\nClassified time: %05.1f s  (+%.0fs penalties)" % [DRIVERS_BY_TEAM[selected_team][selected_driver], player_position, TRACKS[selected_track], points_earned, total_points, classified_time, penalty_seconds])
	else:
		result.text = ("%s  •  DNF\n%s\n%s\nPenalties: %.0fs" % [DRIVERS_BY_TEAM[selected_team][selected_driver], TRACKS[selected_track], dnf_reason, penalty_seconds]) if is_dnf else ("%s finishes P%d\n%d laps  •  %s\nClassified time: %05.1f s  (+%.0fs penalties)" % [DRIVERS_BY_TEAM[selected_team][selected_driver], player_position, race_lap_limit, TRACKS[selected_track], classified_time, penalty_seconds])
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_column.add_child(result)
	if race_mode == "CHAMPIONSHIP":
		var table_title := Label.new()
		table_title.text = "DRIVER CHAMPIONSHIP STANDINGS"
		table_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_column.add_child(table_title)
		var standings_label := Label.new()
		standings_label.text = _championship_standings_text()
		standings_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_column.add_child(standings_label)
		var season_button := Button.new()
		season_button.custom_minimum_size = Vector2(0, 42)
		if championship_round + 1 < championship_rounds:
			season_button.text = "NEXT ROUND  →"
			season_button.pressed.connect(_advance_championship)
		else:
			season_button.text = "FINISH CHAMPIONSHIP"
			season_button.pressed.connect(_complete_championship)
		result_column.add_child(season_button)
	else:
		var close_button := Button.new()
		close_button.text = "EXIT GAME"
		close_button.pressed.connect(func(): get_tree().quit())
		result_column.add_child(close_button)

func _start_championship() -> void:
	championship_active = true
	championship_round_complete = false
	championship_round = 0
	championship_base_track = selected_track
	championship_standings.clear()
	_save_championship()
	_start_race("CHAMPIONSHIP")

func _advance_championship() -> void:
	championship_round_complete = false
	championship_round += 1
	_save_championship()
	get_tree().reload_current_scene()

func _resume_championship() -> void:
	_start_race("CHAMPIONSHIP")

func _show_championship_continue() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-250, -170)
	panel.custom_minimum_size = Vector2(500, 340)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var heading := Label.new()
	heading.text = "CHAMPIONSHIP ROUND %d COMPLETE" % (championship_round + 1)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 24)
	column.add_child(heading)
	var standings := Label.new()
	standings.text = "SAVED SEASON STANDINGS\\n" + _championship_standings_text()
	standings.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(standings)
	var continue_button := Button.new()
	continue_button.custom_minimum_size = Vector2(0, 44)
	if championship_round + 1 < championship_rounds:
		continue_button.text = "CONTINUE TO NEXT ROUND"
		continue_button.pressed.connect(_advance_championship)
	else:
		continue_button.text = "FINISH SEASON"
		continue_button.pressed.connect(_complete_championship)
	column.add_child(continue_button)

func _complete_championship() -> void:
	championship_active = false
	championship_round_complete = false
	championship_round = 0
	championship_standings.clear()
	_save_championship()
	get_tree().reload_current_scene()

func _award_championship_points() -> int:
	var entries: Array[Dictionary] = []
	var player_name: String = DRIVERS_BY_TEAM[selected_team][selected_driver]
	if not is_dnf:
		var penalty_progress := penalty_seconds * 35.0 * float(track_points.size()) / _track_length()
		entries.append({"name": player_name, "progress": _player_progress_score() - penalty_progress})
	for opponent in get_tree().get_nodes_in_group("ai_cars"):
		entries.append({"name": opponent.driver_name, "progress": float(opponent.completed_laps * track_points.size() + opponent.progress_index)})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["progress"]) > float(b["progress"])
	)
	var earned := 0
	for i in range(min(entries.size(), CHAMPIONSHIP_POINTS.size())):
		var driver_name: String = str(entries[i]["name"])
		var award: int = CHAMPIONSHIP_POINTS[i]
		championship_standings[driver_name] = int(championship_standings.get(driver_name, 0)) + award
		if driver_name == player_name:
			earned = award
	_save_championship()
	return earned

func _championship_standings_text() -> String:
	var rows: Array[Dictionary] = []
	for driver_name in championship_standings:
		rows.append({"name": driver_name, "points": int(championship_standings[driver_name])})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["points"]) > int(b["points"])
	)
	var lines := PackedStringArray()
	for i in range(min(rows.size(), 5)):
		lines.append("%d. %s   %d PTS" % [i + 1, rows[i]["name"], rows[i]["points"]])
	return "\n".join(lines)

func _save_championship() -> void:
	var config := ConfigFile.new()
	config.set_value("season", "active", championship_active)
	config.set_value("season", "round", championship_round)
	config.set_value("season", "round_complete", championship_round_complete)
	config.set_value("season", "team", selected_team)
	config.set_value("season", "driver", selected_driver)
	config.set_value("season", "car_era", selected_car_era)
	config.set_value("season", "difficulty", ai_difficulty)
	config.set_value("season", "tyre", selected_tyre_compound)
	config.set_value("season", "base_track", championship_base_track)
	config.set_value("season", "standings", championship_standings)
	config.save(CHAMPIONSHIP_SAVE_PATH)

func _load_championship() -> void:
	var config := ConfigFile.new()
	if config.load(CHAMPIONSHIP_SAVE_PATH) != OK:
		return
	championship_active = bool(config.get_value("season", "active", false))
	championship_round = clampi(int(config.get_value("season", "round", 0)), 0, championship_rounds - 1)
	championship_round_complete = bool(config.get_value("season", "round_complete", false))
	selected_team = clampi(int(config.get_value("season", "team", selected_team)), 0, TEAM_NAMES.size() - 1)
	selected_driver = clampi(int(config.get_value("season", "driver", selected_driver)), 0, DRIVERS_BY_TEAM[selected_team].size() - 1)
	selected_car_era = clampi(int(config.get_value("season", "car_era", selected_car_era)), 0, CAR_ERAS.size() - 1)
	ai_difficulty = clampi(int(config.get_value("season", "difficulty", ai_difficulty)), 0, 4)
	selected_tyre_compound = str(config.get_value("season", "tyre", selected_tyre_compound))
	championship_base_track = int(config.get_value("season", "base_track", 0))
	championship_standings = config.get_value("season", "standings", {})
