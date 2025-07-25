

## Architecture:



#### 3 programs:
- Game-Client
- Launcher
- Maker-Client (auxiliary program for Makers; see `VISION.md`)



Keep it super fucking simple:
When this program starts:

- If hosting: Start server
- Load mods
- Load world. (If world doesn't exist, generate new world)
- Join server, player is spawned in. No menus, no BS.

IMPORTANT DETAIL: ^^^^
There are no menus!!! The world is instantly loaded!!!!
The "menu" is in the launcher.
(Similar to the league-of-legends launcher)
This includes server-list, friends-lists, game-explorer, etc.





## Whats defined in the base-engine?
- ECS, Erchetypes
- EvBuses, QBuses
- Localization infrastructure
- Input handling
- Sound/Music API
- Texture-atlas
- Camera handler
- UI system? Kirigami? LUI?
- Richtext
- Objects (from objects mod)
- Player-entities (like godot? Have skins?)
- Networking (super-simple)
- ECS
- Chunking
- Terrain Gridmaps, Ground Gridmaps
- Rendering of Terrain/Ground Gridmaps
- Lightmap
- Physics system
- Serialization / Chunking
- Properties management (ie similar to properties mod from old-umg)
- Holdable items
- Basic components (x,y, vx, vy, image, health, maxHealth)


## Whats defined in the mods?
- Packet-types
- Inventory system (???)
- World-generation
- All Mobs, Animals, Structures, Terrain-types
- Weapons, Items, Tools, Crafting-system
- Fire, Rain, Weather, Fog



