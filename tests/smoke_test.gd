extends SceneTree
## Headless smoke test: plays a full CPU vs CPU match at high speed and
## checks that a winner is decided without script errors.
##
## Run from the project folder:
##   godot --headless --fixed-fps 60 --script res://tests/smoke_test.gd
## (--fixed-fps lets it run much faster than real time.)

const MAX_SECONDS := 600.0

var _elapsed := 0.0
var _fight: Node


func _initialize() -> void:
	var game_state := root.get_node("GameState")
	game_state.mode = 2  # GameState.Mode.CPU_VS_CPU
	game_state.cpu_difficulty = 1
	change_scene_to_file("res://scenes/fight.tscn")


func _process(delta: float) -> bool:
	_elapsed += delta
	var fight := current_scene
	if fight and fight.name == "Fight":
		var wins: Array = fight.round_wins
		if wins[0] >= 2 or wins[1] >= 2:
			print("SMOKE TEST PASSED: rounds P1 %d - P2 %d after %d rounds (%.0fs game time)"
					% [wins[0], wins[1], fight.round_number, _elapsed])
			quit(0)
			return true
	if _elapsed > MAX_SECONDS:
		push_error("SMOKE TEST FAILED: match did not finish")
		quit(1)
		return true
	return false
