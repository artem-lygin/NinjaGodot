# Simple Platformer (Godot)

### `In development'

A simple 2D platformer made with Godot where the player — a ninja — navigates through platforms, attacks dummies, and reaches the goal.

## 🚀 Gameplay

- Use arrow keys to move.
- Press A to jump (with doublejump).
- Press X to attack with a sword.
- The player can deal damage, with a chance for critical hits.
- Dummies (enemies) can receive damage and die.
- Reaching the goal zone likely finishes the level.

## 🧠 Key Mechanics

### Player
- Controlled via `player.gd`
- Has an attack system using a sword hitbox (`sword_hitbox.gd`)
- Can deal damage and trigger critical hits

### Enemy (Dummy)
- Script: `dummy.gd`
- Receives damage and plays hit reactions

### UI Feedback
- `DamageLabel.tscn` and `CritLabel.tscn` show floating numbers for damage and critical hits

### Goal
- `GoalZone.gd` handles level completion logic

## 🧱 Scenes
- `Scenes/main.tscn`: Main level scene
- `Player.tscn`: Contains player node and logic
- `Dummy.tscn`: Enemy scene
- `DamageLabel.tscn` and `CritLabel.tscn`: Show feedback on hits
- `GoalZone.gd`: Marks the end of the level

## 📜 Scripts Overview

### `player.gd`
Handles:
- Movement
- Attacking via a sword hitbox
- Dealing random damage and criticals

### `sword_hitbox.gd`
Detects enemies in the attack area and applies damage.

### `dummy.gd`
- Responds to being hit
- Displays damage or crit labels
- Plays a death animation when HP reaches 0

### `damage_label.gd` / `crit_label.gd`
- Show floating text above enemies
- Fade out and delete themselves automatically

### `GoalZone.gd`
- When the player enters the area, the game reacts (likely ends or triggers victory)
