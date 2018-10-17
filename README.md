# ReaScripts
ReaScripts for REAPER Digital Audio Workstation, written by bfut. 

#### Installation
Only Reaper v5.95 (or higher) is required, unless noted otherwise.
Copy and paste this URL in Extensions > [ReaPack](https://github.com/cfillion/reapack) > Import a repository:

```
https://github.com/bfut/ReaScripts/raw/master/index.xml
```


## Copy and replace selected items
* bfut_Copy item to clipboard.lua
* bfut_Paste item from clipboard to selected items (replace).lua

Copies and replaces selected items, preserving position, length, mute status, etc. in the replaced items. Requires [SWS](http://www.sws-extension.org/) extension.

How to use:
  1) Select media item.
  2) Run script "bfut_Copy item to clipboard".
  3) Select other media item(s).
  4) Run script "bfut_Paste item from clipboard to selected items (replace)".


## Replace item under mouse cursor
* bfut_Replace item under mouse cursor with selected item.lua

Replaces item under mouse cursor with selected item, preserving position, length, mute status, etc. in the replaced item. Requires [SWS](http://www.sws-extension.org/) extension.

How to use:
  1) Select media item.
  2) Hover mouse over another item.
  3) Run the script.


## Convert MIDI notes to items
* bfut_MIDI notes to items (explode note rows to subtracks).lua  
* bfut_MIDI notes to items (notes to subtrack, note pitch as item pitch).lua  
* bfut_MIDI notes to items (notes to subtrack, note pitch as item rate).lua  

Converts MIDI notes to media items in one go.

How to use:  
  1) Select MIDI item(s), all on the same track.  
  2) Select a track. (optional)  
  3) Run the script.  
  
  
## MIDI notes control ...
* bfut_MIDI notes control items stretch markers.lua  
* bfut_MIDI notes split items, set items pitch.lua  

Use a MIDI editor as GUI to control item stretch markers, or item pitch.

How to use:  
  1) Open MIDI editor.  
  2) Write MIDI notes at will (relevant properties: note start position, note pitch, note velocity).  
  3) Select media item(s).  
  4) Run the script.  


## MIDI note row controls ...
* bfut_MIDI note row controls items pitch.lua  
* bfut_MIDI note row controls items rate.lua  

Use a MIDI editor as GUI to control item pitch, or item rate.

How to use:  
  1) Open MIDI editor.  
  2) Select media item(s).  
  3) Click any note row.  
  4) Run the script.  


## Copy items to project markers
* bfut_Copy items to project markers, remove overlaps.lua  

Copies any number of selected items to project markers.  
  
How to use:  
  1) Make sure there is at least one project marker.  
  2) Select media item(s).  
  3) Run the script.  
  
  
## other scripts
bfut_Split looped item into separate items.lua  
bfut_Trim to source media lengths (limit items lengths).lua  
