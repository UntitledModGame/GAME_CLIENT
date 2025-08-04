

## Architecture:



#### 3 programs:
- Game-Client
- Launcher
- Maker-Client (auxiliary program for Makers; see `VISION.md`)



Keep it super fucking simple:
When Game-Client starts:

- If server: start server.
- If client: join the game.

When the program boots, the player is spawned in. No menus, no BS.
*Menus are inside the launcher, NOT the game client!*

(Similar to the league-of-legends launcher)
This includes server-list, friends-lists, game-explorer, etc.





## Whats defined in the base-engine?
- ECS, Erchetypes, Attachments
- Events, Questions
- Localization infrastructure
- Input handling (+ Panel system?)
- Sound/Music API
- Texture-atlas
- Camera handler
- UI system? Kirigami? LUI?
- Richtext
- Objects (from objects mod)
- Player-entities (like godot? Have skins?)
- Networking (super-simple)
- Chunking
- Terrain Gridmaps, Ground Gridmaps
- Rendering of Terrain/Ground Gridmaps
- Lightmap
- Physics system
- Serialization / Chunking
- Properties management (ie similar to properties mod from old-umg)
- Holdable items
- Basic components (x,y, vx, vy, image, health, maxHealth, team)


## Whats defined in the mods?
- Packet-types
- Inventory system (???)
- World-generation
- All Mobs, Animals, Structures, Terrain-types
- Weapons, Items, Tools, Crafting-system
- Fire, Rain, Weather, Fog



