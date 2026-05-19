class_name NPCData
extends Resource

@export var npc_name: String = "Unnamed Citizen"
@export var gold: int = 100
@export var inventory: Dictionary = {"wheat": 3}
@export var relationships: Dictionary = {} # Format: {"Target_NPC_ID": Opinion_Score}

func consume_daily_food() -> bool:
	if inventory.get("wheat", 0) > 0:
		inventory["wheat"] -= 1
		return true # Sustained
	
	return false 
# Starving -> Triggers threat/desperation state
