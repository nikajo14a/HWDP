extends Node

@export var simulated_village: VillageData
const MACRO_TICK_INTERVAL: float = 5.0 
var time_accumulator: float = 0.0

# Tracks the background task so we know if it's still running
var _sim_task_id: int = -1
var _data_mutex: Mutex = Mutex.new()

func _process(delta: float) -> void:
	time_accumulator += delta
	if time_accumulator >= MACRO_TICK_INTERVAL:
		time_accumulator -= MACRO_TICK_INTERVAL
		
		# Safety check: If the previous tick is STILL running, don't start a new one!
		if _sim_task_id != -1 and not WorkerThreadPool.is_task_completed(_sim_task_id):
			print("Warning: Previous simulation tick took too long! Skipping this tick.")
			return
			
		# Dispatch safely to background thread
		_sim_task_id = WorkerThreadPool.submit_task(_run_background_simulation)

func _run_background_simulation() -> void:
	if simulated_village:
		# LOCK the data before modifying it on this thread
		_data_mutex.lock()
		
		simulated_village.process_economic_tick()
		
		# UNLOCK it as soon as we are done so the main thread can access it again
		_data_mutex.unlock()

# Helper function if your UI or Main Thread needs to read village data safely
func get_safe_village_data() -> VillageData:
	_data_mutex.lock()
	var data = simulated_village
	_data_mutex.unlock()
	return data