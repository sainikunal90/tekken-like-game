extends Node
## Global settings that survive scene changes (menu -> fight -> menu).
## Registered as the "GameState" autoload in project.godot.

enum Mode { VERSUS, VS_CPU, CPU_VS_CPU }

## Every playable character. To add a new fighter, create a CharacterData
## resource in data/characters/ and add its path here.
const CHARACTERS: Array[String] = [
	"res://data/characters/arjun.tres",
	"res://data/characters/mira.tres",
	"res://data/characters/kabir.tres",
	"res://data/characters/zara.tres",
]

## Every stage. Each script builds a 3D scene (see scripts/stages/).
const STAGES: Array[Dictionary] = [
	{"name": "Himalayan Pass", "script": "res://scripts/stages/stage_mountains.gd"},
	{"name": "Monsoon Temple", "script": "res://scripts/stages/stage_temple.gd"},
]

const DIFFICULTY_NAMES: Array[String] = ["Easy", "Normal", "Hard"]

const ROUNDS_TO_WIN := 2
const ROUND_TIME := 60.0

var mode: Mode = Mode.VERSUS
var p1_character_index := 0
var p2_character_index := 1
var cpu_difficulty := 1
## Index into STAGES, or -1 for a random stage each fight.
var stage_index := -1

## Forces on-screen touch buttons even on desktop (for testing). Also
## enabled by launching the game with: -- --touch
var force_touch_controls := false


func _ready() -> void:
	if "--touch" in OS.get_cmdline_user_args():
		force_touch_controls = true


func get_character(index: int) -> CharacterData:
	return load(CHARACTERS[wrapi(index, 0, CHARACTERS.size())]) as CharacterData


func get_stage_name(index: int) -> String:
	return "Random" if index < 0 else String(STAGES[index]["name"])


func create_stage() -> Stage3D:
	var index := stage_index if stage_index >= 0 else randi() % STAGES.size()
	var stage := (load(STAGES[index]["script"]) as GDScript).new() as Stage3D
	stage.name = "Stage"
	return stage


func wants_touch_controls() -> bool:
	return force_touch_controls or DisplayServer.is_touchscreen_available()
