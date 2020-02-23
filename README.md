# ReaScripts
ReaScripts for REAPER Digital Audio Workstation, written by bfut. 

Requirements: Reaper v6.xx, unless noted otherwise


### Installation
Copy and paste this URL in Extensions > [ReaPack](https://github.com/cfillion/reapack) > Import repositories:

```
https://github.com/bfut/ReaScripts/raw/master/index.xml
```


## Step sequencer for items
* bfut_Step sequencer (copy first item on track and fill grid bar under mouse)
* bfut_Step sequencer (copy first item on track to grid bar under mouse).lua
* bfut_Remove item under mouse cursor (delete).lua

Copies first item on track under mouse cursor to grid bar under mouse cursor. Requires [SWS] extension.

Add a source media item at the beginning of your target track. Set a time selection, e.g. 16 grid bars. Hit play. As you add and remove media items, REAPER's arrange view now behaves like a pattern-based step sequencer. Try adjusting the grid divison.

How to set up:
  1. Install the scripts, and SWS.
  2. Toggle on "Options > Trim content behind media items when editing".
  3. Set mouse modifiers (Options > Preferences > Editing Behavior > Mouse Modifiers).
  4. Open Actions > Show action list
  5. Assign keyboard shortcuts to each script (e.g. SHIFT+Q, SHIFT+A, and SHIFT+D), respectively.  
  Holding a key combination, continuously executes a script.

How to use:
  1. There must be at least one item on the track under mouse cursor.
  2. Hover mouse over arrange view.
  3. Run the script.

![alt text][trim]  
![alt text][mouse]

[trim]: https://github.com/bfut/ReaScripts/raw/rc/assets/bfut_Step-sequencer-TRIM-BEHIND-ITEMS.png "Options > Toggle trim behind items when editing"

[mouse]: https://github.com/bfut/ReaScripts/raw/rc/assets/bfut_Step-sequencer-MOUSE-MODIFIER.png "Set mouse modifiers"

## Convert MIDI notes to items
* bfut_MIDI notes to items (explode note rows to subtracks).lua
* bfut_MIDI notes to items (notes to subtrack, note pitch as item pitch).lua
* bfut_MIDI notes to items (notes to subtrack, note pitch as item rate).lua

Converts MIDI notes to media items in one go.

How to use:
  1. Select MIDI item(s), all on the same track.
  1. Select a track. (optional)
  1. Run the script.


## Copy and replace selected items
* bfut_Copy item to clipboard.lua
* bfut_Paste item from clipboard to selected items (replace).lua

Copies and replaces selected items, preserving position, length, mute status, etc. in the replaced items. Requires [SWS] extension.

How to use:
  1. Select media item.
  1. Run script "bfut_Copy item to clipboard".
  1. Select other media item(s).
  1. Run script "bfut_Paste item from clipboard to selected items (replace)".


## Replace item under mouse cursor
* bfut_Replace item under mouse cursor with selected item.lua

Replaces item under mouse cursor with selected item, preserving position, length, mute status, etc. in the replaced item. Requires [SWS] extension.

How to set up:
  1. Install the script, and SWS.
  1. Open REAPER > Actions > Show action list...
  1. Assign a keyboard shortcut to the script.

How to use:
  1. Select media item.
  1. Hover mouse over another item.
  1. Run the script.


## Copy items to project markers
* bfut_Copy items to project markers, remove overlaps.lua

Copies any number of selected items to project markers.
  
How to use:
  1. There must be at least one project marker.
  1. Select media item(s).
  1. Run the script.


## MIDI notes control ...
* bfut_MIDI notes control items stretch markers.lua
* bfut_MIDI notes split items, set items pitch.lua

Use a MIDI editor as GUI to control item stretch markers, or item pitch.

How to use:
  1. Open MIDI editor.
  1. Write MIDI notes at will (relevant properties: note start position, note pitch, note velocity).
  1. Select media item(s).
  1. Run the script.


## MIDI note row controls ...
* bfut_MIDI note row controls items pitch.lua
* bfut_MIDI note row controls items rate.lua

Use a MIDI editor as GUI to control item pitch, or item rate.

How to use:
  1. Open MIDI editor.
  1. Select media item(s).
  1. Click any note row.
  1. Run the script.
  
  
## other scripts
bfut_Split looped item into separate items.lua  
bfut_Trim to source media lengths (limit items lengths).lua


[SWS]: http://www.sws-extension.org
