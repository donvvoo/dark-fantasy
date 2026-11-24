## Captures the game's screens for QA evidence (not shipped).
## Run: xvfb-run godot --path . --rendering-driver opengl3 -s res://tests/capture/capture_screens.gd -- <out_dir>
extends SceneTree

var out_dir := "res://production/qa/evidence"
var main: Node

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	main = load("res://src/main.tscn").instantiate()
	root.add_child(main)
	_run()

func _wait(frames: int) -> void:
	for i in frames: await process_frame

func _shot(name: String) -> void:
	await _wait(3)
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join("godot-%s.png" % name))
	print("shot %s  fps %d  draw calls %d  frame ms %.1f  mem MB %d" % [name, Engine.get_frames_per_second(), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, OS.get_static_memory_usage() / 1048576])

func _run() -> void:
	var game = root.get_node("Game")
	await _wait(5)
	await _shot("title")
	game.reset()
	main.scene = "play"
	for i in 8:
		game.tap_attack(main.enemy_x())
		await _wait(12)
	game.state.gold = 5000.0
	game.buy_hero(1); game.buy_hero(2)
	await _wait(60)
	await _shot("play")
	if "anim" in OS.get_cmdline_user_args():
		game.state.lv.pyro = 1
		for i in 10:
			await _wait(4)
			await _shot("anim-%d" % i)
		quit()
		return
	for tab in ([] if OS.get_cmdline_user_args().size() > 1 else ["skill", "gear", "adv", "quest", "rebirth"]):
		game.state.tab = tab
		await _shot(tab)
	game.state.tab = "party"
	for z in [[14, "village"], [8, "forest"], [20, "waste"], [26, "castle"]]:
		game.state.stage = z[0]; game.state.bestStage = z[0]
		for k in 10:
			await _wait(1)
			print("  frame %d mem MB %d" % [k, OS.get_static_memory_usage() / 1048576])
		await _shot("zone-" + z[1])
	game.state.keys = 1
	game.enter_dungeon()
	await _wait(90)
	await _shot("dungeon")
	quit()
