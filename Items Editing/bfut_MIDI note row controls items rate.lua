--[[
  @author bfut
  @version 1.0
  DESCRIPTION: bfut_MIDI note row controls items rate
  HOW TO USE:
    1) Open MIDI editor.
    2) Select media item(s).
    3) Click any note row.
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
--[[ config defaults:
  reference_pitch = 60
  
  allowed values: 0..127
]]
local config = {
  reference_pitch = 60
}
local reaper = reaper
function bfut_ItemPlayrateChange(pitch,reference_pitch)
  local semitone_change = math.abs(pitch-reference_pitch)
  local positive_change = pitch-reference_pitch >= 0
  if positive_change then
    for i=1,semitone_change do
      reaper.Main_OnCommandEx(40797,0)
    end
  else
    for i=1,semitone_change do
      reaper.Main_OnCommandEx(40798,0)
    end
  end
end
local function bfut_LimitPitch(pitch)
  if pitch < 0 then return 0 end
  if pitch > 127 then return 127 end
  return math.modf(pitch)
end
local count_sel_items = reaper.CountSelectedMediaItems(0)
if count_sel_items < 1 then return end
local hwnd = reaper.MIDIEditor_GetActive()
if hwnd == nil then return end
local MIDI_take = reaper.MIDIEditor_GetTake(hwnd)
if MIDI_take == nil then return end
config["reference_pitch"] = bfut_LimitPitch(config["reference_pitch"])
local sel_items = {}
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock2(0)
for i=0,count_sel_items-1 do sel_items[#sel_items+1] = reaper.GetSelectedMediaItem(0,i) end
reaper.Main_OnCommandEx(40289,0)
for i=0,count_sel_items-1 do
  reaper.SetMediaItemSelected(sel_items[i+1],true)
  if reaper.GetActiveTake(sel_items[i+1],0) ~= nil then
    reaper.Main_OnCommandEx(40652,0)
    bfut_ItemPlayrateChange(reaper.MIDIEditor_GetSetting_int(hwnd,"active_note_row"),config["reference_pitch"])
  end
  reaper.SetMediaItemSelected(sel_items[i+1],false)
end
for i=0,count_sel_items-1 do reaper.SetMediaItemSelected(sel_items[i+1],true) end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0,"bfut_MIDI note row controls items rate",-1)