extends Node
## Global settings that survive scene changes (menu -> fight -> menu).
## Registered as the "GameState" autoload in project.godot.

enum Mode { VERSUS, VS_CPU, CPU_VS_CPU }

## Every playable character. To add a new fighter, create a CharacterData
## resource in data/characters/ and add its path here.
const CHARACTERS: Array[String] = [
	"res://data/characters/arjun.tres",
	"res://data/characters/mira.tres",
]

const DIFFICULTY_NAMES: Array[String] = ["Easy", "Normal", "Hard"]

const ROUNDS_TO_WIN := 2
const ROUND_TIME := 60.0

var mode: Mode = Mode.VERSUS
var p1_character_index := 0
var p2_character_index := 1
var cpu_difficulty := 1

## Forces on-screen touch buttons even on desktop (for testing). Also
## enabled by launching the game with: -- --touch
var force_touch_controls := false


func _ready() -> void:
	if "--touch" in OS.get_cmdline_user_args():
		force_touch_controls = true


func get_character(index: int) -> CharacterData:
	return load(CHARACTERS[wrapi(index, 0, CHARACTERS.size())]) as CharacterData


func wants_touch_controls() -> bool:
	return force_touch_controls or DisplayServer.is_touchscreen_available()
