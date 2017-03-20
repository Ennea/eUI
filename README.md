# eUI
Version 1.0

#### License
All files are released under the MIT license (see LICENSE). Exceptions to this are LibStub, CallbackHandler-1.0 and LibKeyBound-1.0 (part of eActionBars and eActionBindings), the originals of which were released into the public domain, so I'm releasing the changes I made into the public domain as well.

## What is eUI?
eUI is a small collection of interface addons I've written for WoW v1.12.1. Most addons only make slight changes to the look and behavior of the default interface. Every addon can also be used individually, but they all depend on LuaExtender. LuaExtender adds some global functions that can be used by other addons. Some of those functions were added in later Lua or WoW versions. Full list at the very bottom.

If you find any bugs or have any suggestions, please don't hesitate to open an issue.

### QoLI
**Q**uality **o**f **L**ife **I**mprovements is a collection of smaller featuers and bug fixes that did not warrant an addon of their own.\
It currently fixes the following bugs:
* properly cleans up the quest watch list when turning in completed quests, allowing tracking of the maximum of 5 quests at all times

And adds the following features:
* holding shift when opening mail automatically loots money/items
* icons of known recipes in the auction house are grayed out

### eActionBars
* streamlines the look of action buttons
* only shows key bindings and macro names on hover
* adds LibKeyBound support (/kb in game)
* shows icons, count and tooltips of items for macros that use LuaExtender's UseItemByName\
  for example, consider this macro:\
  `/run if IsAltKeyDown() then CastSpellByName('Conjure Water') else UseItemByName('Conjured Spring Water') end`\
  when placed inside an action bar, it will show the icon, item count and tooltip of _Conjured Spring Water_

### eActionBindings
* adds 12 invisible action buttons to bind hotkeys to
* use /eab in game to open

### eBuffs
* streamlines the look of buffs
* does not currently include target, party or raid buffs

### eDurability
* shows total durability of your eqipment in the character window

### eMap
* removes the black backgrounds from the map and makes it smaller
* enables you to move your character while the map is open
* adds player and mouse coordinates to the map

### eMinimap
* hides zoom buttons
* enables mouse wheel zoom
* slims down the look of the zone text
* adds latency and addon memory use to the time tooltip

### eQuest
* adds quest levels to the quest log

### eTooltip
* adds icons to tooltips wherever possible (spells, items, ...)
* adds a border to the health bar on unit tooltips
* adds additional content to unit tooltips

### eUnitFrames
* changes mana bar color to a lighter blue for better visibility
* colors player names according to their class
* only shows the target's name background if it's a mob that hasn't been tapped by you
* makes you elite :)

### LuaExtender
Added "future" Lua functionality:
* _G
* select()
* print()
* string.match()
* math.modf()

Non-standard Lua functions:
* string.join(separator, ...) - joins arguments 2 to n using the given separator
* string.trim(str) - trims whitespaces
* math.round(number, place) - rounds a given number to a certain place, e.g. math.round(3.14159, 0.001) is 3.142

Added "future" WoW API:
* IsLoggedIn()
* IsModifierKeyDown()

Non-standard WoW API-like functions:
* post_hook([table], function, hookFunction) - acts pretty much exactly like hooksecurefunc() would, hookFunction gets the same arguments as the function that is being hooked; if table is given, table.function is being hooked and hookFunction is being executed afterwards; if table is not given, the function to be hooked is assumed to be a global one
* pre_hook([table], function, hookFunction) - same as post_hook(), but executes hookFunction before the original
* replace_hook([table], function, hookFunction) - same as post_hook(), but replaces the original function entirely and passes it to hookFunction as the first argument
* GetContainerItemByName(name) - returns bag, slot, count, texture if the given item is found in the player's bags: case insensitive

Non-standard WoW API-like functions that will be useful for macros:
* UseItemByName(name) - uses GetContainerItemByName() to use an item from the player's bags; kinda like /use in future WoW versions
