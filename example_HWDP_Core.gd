extends Node

@export var simulated_village: VillageData
const MACRO_TICK_INTERVAL: float = 5.0 # 5 real-world seconds per Day-Tick
var time_accumulator: float = 0.0

func _process(delta: float) -> void:
	time_accumulator += delta
	if time_accumulator >= MACRO_TICK_INTERVAL:
		time_accumulator -= MACRO_TICK_INTERVAL
		# Dispatches the heavy economic math safely to a background CPU worker
		WorkerThreadPool.submit_task(_run_background_simulation)

func _run_background_simulation() -> void:
	if simulated_village:
		simulated_village.process_economic_tick()
