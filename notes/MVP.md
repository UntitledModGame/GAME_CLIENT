

# MVP:

Playable sandbox game.
The absolute bare-neccessary features that we need:


### GAME-CLIENT:
Main game client.
- play/host a game.
- Grid-system
- Mod-loading
- Multiplayer syncing
- (^^^ thats honestly it.. we dont need anything fancy)


### MAKER-CLIENT:
Used to develop gamemodes. 
Auxiliary program that runs alongside the GAME-CLIENT.
- Players can search for mods to add (JUST STATIC-DATA SEARCH!!!)
- Mods can be uploaded
- Gamemodes can be uploaded


### LAUNCHER:
- Gamemodes can be chosen from
- You can explore / create / join servers
- Will create an instance of `GAME-CLIENT`


---

LESS LINES OF CODE IS BETTER. Remember tinygrad.
Embrace YAGNI. Add it later after you have secured VC.


For maker-client mod-search, dont do a stupid cloud-based search.
Just keep it really fucking simple.  
Have a static-list of all mods, and update them manually;
(push and deploy at end of day or somethn?)


