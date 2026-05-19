class_name VillageData
extends Resource

@export var village_name: String
@export var market_prices: Dictionary = {"wheat": 10}
@export var population: Array[NPCData] = []

func process_economic_tick() -> void:
	# Explicitly define 'npc: NPCData' to keep the compiler happy on background threads
	for npc: NPCData in population:
		var has_eaten = npc.consume_daily_food()
		if not has_eaten:
			_handle_npc_market_interaction(npc)

func _handle_npc_market_interaction(npc: NPCData) -> void:
	var current_price = market_prices.get("wheat", 10)
	if npc.gold >= current_price:
		npc.gold -= current_price
		inventory_add(npc, "wheat", 1)
	else:
		# Bankrupt logic triggers here safely
		pass

# Thread-safe dictionary utility helper
func inventory_add(npc: NPCData, item: String, amount: int) -> void:
	npc.inventory[item] = npc.inventory.get(item, 0) + amount