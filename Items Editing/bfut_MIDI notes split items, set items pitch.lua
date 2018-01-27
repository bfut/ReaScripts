--[[
  @author bfut
  @link https://github.com/bfut
  @version 1.0
  DESCRIPTION: bfut_MIDI notes split items, set items pitch
  HOW TO USE:
    1) Open MIDI editor.
    2) Write MIDI notes at will (relevant properties: note start position, note pitch).
    3) Select media item(s).
    4) Run the script.
  REQUIRES: Reaper v5.70 or later
  LICENSE:
    Copyright (c) 2017 and later Benjamin Futasz <bendfu@gmail.com><https://github.com/bfut>
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]
local config = {
  reference_pitch = 60
}
local reaper = reaper
local function bfut_LimitPitch(pitch)
  if pitch < 0 then return 0 end
  if pitch > 127 then return 127 end
  return math.modf(pitch)
end
local function bfut_FetchMIDI_notes(MIDI_take)
  local MIDI_notes = {} 
  local i=0
  repeat
    i=i+1
    MIDI_notes[i] = {reaper.MIDI_GetNote(MIDI_take,i-1)}
  until not MIDI_notes[i][1]
  MIDI_notes[i] = nil
  return MIDI_notes
end
local function bfut_GetRelativeNoteStartPosPitch2(MIDI_take,MIDI_notes,config)
  local MIDI_item = reaper.GetMediaItemTake_Item(MIDI_take)
  local MIDI_item_length = reaper.GetMediaItemInfo_Value(MIDI_item,"D_LENGTH")
  local relative_note_startpos_projtime = {0}
  local relative_note_pitch = {0}
  for i=1,#MIDI_notes do
    relative_note_startpos_projtime[#relative_note_startpos_projtime+1] = (reaper.MIDI_GetProjTimeFromPPQPos(MIDI_take,MIDI_notes[i][4])
                                                                            -reaper.GetMediaItemInfo_Value(MIDI_item,"D_POSITION"))
                                                                           /MIDI_item_length
    if relative_note_startpos_projtime[#relative_note_startpos_projtime] >= 1 then
      relative_note_startpos_projtime[#relative_note_startpos_projtime] = nil
    elseif relative_note_startpos_projtime[#relative_note_startpos_projtime]-relative_note_startpos_projtime[#relative_note_startpos_projtime-1] == 0 then
      relative_note_startpos_projtime[#relative_note_startpos_projtime] = nil
      relative_note_pitch[#relative_note_pitch] = nil
      relative_note_pitch[#relative_note_pitch+1] = MIDI_notes[i][7]-config["reference_pitch"]
    else
      relative_note_pitch[#relative_note_pitch+1] = MIDI_notes[i][7]-config["reference_pitch"]
    end
  end
  relative_note_startpos_projtime[#relative_note_startpos_projtime+1] = 1
  relative_note_pitch[#relative_note_pitch+1] = 0
  return relative_note_startpos_projtime,relative_note_pitch
end
local function bfut_SplitItmsIntoSeparateItms2(item,relative_note_startpos_projtime,relative_note_pitch)
  local item_length = reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
  local item_startpos = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
  local item_activetake = reaper.GetActiveTake(item,0)
  local item_pitch
  if item_activetake ~= nil then item_pitch = reaper.GetMediaItemTakeInfo_Value(item_activetake,"D_PITCH") end  
  local temp_item = item
  reaper.SelectAllMediaItems(0,false)
  reaper.SetMediaItemSelected(temp_item,true)
  for j=1,#relative_note_startpos_projtime-1 do
    local temp_item_activetake = reaper.GetActiveTake(temp_item,0)
    if temp_item_activetake ~= nil then
      reaper.SetMediaItemTakeInfo_Value(temp_item_activetake,"D_PITCH",relative_note_pitch[j]+item_pitch)
      temp_item = reaper.SplitMediaItem(temp_item,item_startpos+item_length*relative_note_startpos_projtime[j+1])
    end
  end
  return
end
local count_sel_items = reaper.CountSelectedMediaItems(0)
if count_sel_items < 1 then return end
local item = {}
local hwnd = reaper.MIDIEditor_GetActive()
if hwnd == nil then return end
local MIDI_take = reaper.MIDIEditor_GetTake(hwnd)
if MIDI_take == nil then return end
config["reference_pitch"] = bfut_LimitPitch(config["reference_pitch"])
local MIDI_notes = bfut_FetchMIDI_notes(MIDI_take)
if #MIDI_notes < 1 then return end
local relative_note_startpos_projtime,relative_note_pitch = bfut_GetRelativeNoteStartPosPitch2(
                                                              MIDI_take
                                                              ,MIDI_notes
                                                              ,config
                                                            )
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock2(0)
for i=0,count_sel_items-1 do
  item[i] = reaper.GetSelectedMediaItem(0,i)
end
for i=0,count_sel_items-1 do
  bfut_SplitItmsIntoSeparateItms2(item[i],relative_note_startpos_projtime,relative_note_pitch)
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0,"bfut_MIDI notes split items, set items pitch",-1)