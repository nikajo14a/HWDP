# HWDP: Hybrid Worker Delta-Time Production
**License:** MIT
HWDP is a headless, data-oriented simulation framework built for Godot 4 sandbox RPGs, grand strategy games, or space sims. It manages background economics, autonomous faction logic, and world events asynchronously so you can run thousands of simulated NPCs, trading caravans, and factions without destroying your rendering frame rate.
> 🇵🇱 **A Quick Note on the Name:**Tak, wiem xd.
---
## Core System Mechanics
The framework is built around four fundamental engineering choices designed to stop Godot's main scene tree loop from choking on macro-simulation math.
### 1. Hybrid (Tiered Task Distribution)
Not everything needs to run at 60 FPS. HWDP splits execution into two loops based on urgency:
* **Micro-Ticks (Frame Loop / 60+ FPS):** Runs on the main thread. This is for real-time, frame-dependent behaviors like tactical combat positioning, local pathfinding steering, and visual updates.
* **Macro-Ticks (Staggered Intervals / 2s - 10s):** Handles long-term background logic (e.g., regional economy updates, faction supply depletion, relationship decay). To prevent massive CPU spikes, updates are staggered across entities using an ID-based modulo: `if (current_tick + NPC_ID) % interval == 0:`
### 2. Worker (Asynchronous Processing via ThreadPool)
Heavy economic math and high-level behavioral state machines are offloaded entirely from the main engine thread using Godot 4’s `WorkerThreadPool`. The main thread stays completely free to handle physics interpolation, rendering, and player input, while background worker threads chew through market transactions and inventory shifts.
### 3. DT-Time (Decoupled Simulation Clock)
Simulation states are tied to an internal deterministic tick rate (`DT-Time`) rather than Godot's engine frame delta.
* **Headless Simulation:** Because logic is totally disconnected from visual `Node` updates, you can run the core loop server-side or simulate distant sectors purely in memory.
* **Fast-Forward Testing:** You can easily "turn the crank" on the simulation clock to fast-forward 100 in-game days in a few raw seconds of CPU time—perfect for verifying that your economy doesn't collapse into hyperinflation after 10 hours of gameplay.
### 4. Production (Closed-Loop Economy)
The economy operates on strict supply-and-demand dependencies. Factions dynamically reallocate resources based on systemic feedback loops:
* **Supply Disruption:** If a player or raider faction intercepts a food caravan heading to a specific outpost, that outpost's local market prices spike dynamically due to the artificial scarcity.
* **Threat Scaling:** If regional stability drops (e.g., high bandit activity), factions automatically shift resources from civilian infrastructure into military/security code. This triggers higher local guard patrol spawn rates and bumps up regional bounty payouts.
---
## The Data Pipeline
The framework operates on a strict layer system to prevent background threads from throwing errors when interacting with Godot's visual node hierarchy.

| Layer | Thread / Execution | Responsibilities |
| :--- | :--- | :--- |
| **1. View Layer** | Main Thread (~60+ FPS) | Node2D/3D rendering, screen UI, handling player inputs, real-time local movement. |
| **2. Pipeline** | DT Accumulator Loop | Accumulates time deltas, manages execution intervals, and handles handoffs to background threads. |
| **3. Processing** | `WorkerThreadPool` | Asynchronously executes background math to keep the main thread unblocked. |
| **4. Core Logic** | `HWDP_Core` Manager | High-level data state: tracking caravan routes, faction relationship matrices, and global economy metrics. |

---
## Rules of Thumb for Implementation
If you are writing code for this framework, you *must* follow these three architectural rules, or you will break thread safety and tank your performance:
1. **Strictly Separate Data from Visuals:** Do not store inventory array data, gold balances, or faction alignment variables inside your visual `CharacterBody2D` or `Sprite3D` nodes. Store them inside pure, lightweight custom `Resource` scripts (`NPCData.gd`, `SettlementData.gd`). Visual nodes should act as dumb shells that read from these resources, never calculate them.
2. **Data-Only Simulation LOD:** Distant regions and offline NPCs should exist purely as raw data entries in an array or dictionary. You should only instance actual physical scene tree nodes when an entity crosses into the player's immediate visual range.
3. **Protect Your Transaction Threads:** When worker threads are calculating transactions or updating resource pools, you **must** use a `Mutex` to lock state reading and writing. Race conditions on background threads will cause silent data corruption or hard engine crashes. Use `mutex.lock()` before processing an economy update, and `mutex.unlock()` immediately after.