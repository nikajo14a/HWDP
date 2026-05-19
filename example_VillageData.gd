class_name VillageData
extends Resource

@export var village_name: String
@export var market_prices: Dictionary = {"wheat": 10}
@export var population: Array[NPCData] = []

# This function is safe to run on background Worker threads
func process_economic_tick() -> void:
	for npc in population:
		var has_eaten = npc.consume_daily_food()
		if not has_eaten:
			# Staggered evaluation: NPC interacts with local market data
			_handle_npc_market_interaction(npc)

func _handle_npc_market_interaction(npc: NPCData) -> void:
	var current_price = market_prices.get("wheat", 10)
	if npc.gold >= current_price:
		npc.gold -= current_price
		npc.inventory["wheat"] = npc.inventory.get("wheat", 0) + 1
	else:
		# NPC is bankrupt and starving -> Baseline triggers for criminal alignment
		pass
