# Simple Platformer (Godot)

`In development`

An experiment: simple 2D platformer made with Godot where the player — a ninja — navigates through platforms, attacks enemies, and reaches the goal. Build with ChatGPT both code and art.
Follow me for progress 🇬🇧 ENG https://x.com/artemlygin | 🇺🇦 UA https://www.threads.net/@artemlygin

## 🚀 Gameplay

Controller support only (For now)
- Gimbal Left and Righr
- Press A to jump (Twice for doublejump)
- Press X to attack with a sword
- Press R1 for dash
- L1 resets the scene.
- The player can deal damage, with a chance for critical hits.
- Enemies can receive damage, show health bars, and die with knockback effects.
- Reaching the goal zone likely finishes the level.

## 🧠 Key Mechanics

### Player
- Controlled via `player.gd`
- Has an attack system using a sword hitbox (`sword_hitbox.gd`)
- Can deal damage and trigger critical hits and megacrits

### Enemy System
- Base class: `enemy_class.gd`
  - Core health and damage systems
  - Knockback and stun mechanics
  - Health bar and damage feedback
  - Death animations and cleanup
- Specific enemies:
  - `turtle_enemy.gd`: Turtle enemy
  - `dummy_enemy.gd`: Basic enemy implementation

### UI Feedback
- `HealthBar.tscn`: Dynamic health bars for enemies
  - Color changes based on health percentage
  - Shake effect on damage
- `DamageLabel.tscn` and `CritLabel.tscn`: Show floating numbers for damage and critical hits

### Goal
- `GoalZone.gd` handles level completion logic

## 🧱 Scenes Structure
```
Scenes/
├── ui/                    # UI components
│   ├── HealthBar.tscn     # Enemy health display
│   ├── DamageLabel.tscn   # Damage number display
│   └── CritLabel.tscn     # Critical hit display
├── TurtleEnemy.tscn       # Turtle enemy scene
├── DummyEnemy.tscn        # Basic enemy scene
├── main.tscn              # Main level scene
└── [Scripts]
    ├── enemy_class.gd     # Base enemy class
    ├── turtle_enemy.gd    # Turtle enemy behavior
    ├── dummy_enemy.gd     # Basic enemy behavior
    ├── player.gd          # Player controls
    ├── sword_hitbox.gd    # Attack detection
    └── GoalZone.gd        # Level completion
```

## 📜 Scripts Overview

### `player.gd`
Handles:
- Movement
- Attacking via a sword hitbox
- Dealing random damage and criticals

### `sword_hitbox.gd`
Detects enemies in the attack area and applies damage.

### Enemy System
#### `enemy_class.gd`
Base class that handles:
- Health system with visual feedback
- Knockback and stun mechanics
- Death animations and cleanup
- State management (IDLE, PATROL, AGGRO, STUNNED, DEAD)

#### `turtle_enemy.gd`
Extends base enemy with:
- Custom health values

#### `dummy_enemy.gd`
Basic enemy implementation:
- Extended health values
- Only IDLE or DEAD

### UI Components
#### `health_bar.gd`
- Dynamic health display
- Color changes based on health percentage
- Shake effect on damage
- Automatic visibility management

#### `damage_label.gd` / `crit_label.gd`
- Show floating text above enemies
- Fade out and delete themselves automatically

### `GoalZone.gd`
- When the player enters the area, the game reacts (log output)
