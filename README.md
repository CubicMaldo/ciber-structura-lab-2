# CyberQuest — project scaffold

This repository is a Godot 4.x project scaffold for the "CyberQuest: Guardianes de la Red Global" lab.

What is included:
- Scenes: `MainMenu.tscn`, `MissionSelect.tscn`, `scenes/missions/Mission_1.tscn` (examples)
- Scripts: autoload templates (`scripts/managers/GameManager.gd`, `scripts/managers/SceneManager.gd`), UI controllers, mission controllers, and `GraphDisplay` visualization bridge.

Next steps:
- Open `project.godot` in Godot 4.5 (or compatible 4.x) and register the following AutoLoads:
  - `res://scripts/managers/GameManager.gd` as `GameManager`
  - `res://scripts/managers/SceneManager.gd` as `SceneManager`

Then open `scenes/MainMenu.tscn` and press Play to start iterating on UI and visuals.
