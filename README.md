# ReaScripts
ReaScripts for REAPER, written by bfut. Only Reaper v5.70 (or higher) is required.

#### Installation
Copy and paste this URL in Extensions > [ReaPack](https://github.com/cfillion/reapack) > Import a repository:

```
https://github.com/bfut/ReaScripts/raw/master/index.xml
```


## Convert MIDI notes to items (offline sequencer)
* bfut_MIDI notes to items (explode note rows to subtracks).lua  
* bfut_MIDI notes to items (notes to subtrack, note pitch as item pitch).lua  
* bfut_MIDI notes to items (notes to subtrack, note pitch as item rate).lua  

Converts MIDI notes to media items in one go. Turns the MIDI editor into a powerful sequencer.  

How to use:  
  1) Select MIDI item(s), all on the same track.  
  2) Select a track. (optional)  
  3) Run the script.  
  
  
## MIDI notes control ...
* bfut_MIDI notes control items stretch markers.lua  
* bfut_MIDI notes split items, set items pitch.lua  

Use a MIDI editor as GUI to control item stretch markers, or item pitch. See script code for config options.  

How to use:  
  1) Open MIDI editor.  
  2) Write MIDI notes at will (relevant properties: note start position, note pitch, note velocity).  
  3) Select media item(s).  
  4) Run the script.  


## MIDI note row controls ...
* bfut_MIDI note row controls items pitch.lua  
* bfut_MIDI note row controls items rate.lua  

Use a MIDI editor as GUI to control item pitch, or item rate. See script code for config options.  

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
