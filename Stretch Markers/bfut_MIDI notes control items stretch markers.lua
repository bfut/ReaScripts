--[[
  @author bfut
  @version 1.0
  DESCRIPTION: bfut_MIDI notes control items stretch markers
  HOW TO USE:
    1) Open MIDI editor.
    2) Write MIDI notes at will (relevant properties: note start position, note pitch, note velocity).
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
--[[ config defaults:
  reference_pitch = 60--allowed values: Integer 1...126
  ,pitch_factor_func = "bfut_NormalizeZeroOneX"--function should return Number -1..1
  
  ,default_velocity = 96--allowed values: Integer 2...127
  ,velocity_factor_func = "bfut_NormalizeMinusOneZeroOne"--function should return non-negative Number
]]
local config = {
  reference_pitch = 60
  ,pitch_factor_func = "bfut_NormalizeMinusOneZeroOne"
  ,default_velocity = 96
  ,velocity_factor_func = "bfut_NormalizeZeroOneX"
}
local reaper = reaper
function bfut_FetchMIDI_notes(MIDI_take)
  local MIDI_notes = {} 
  local i=0
  repeat
    i=i+1
    MIDI_notes[i] = {reaper.MIDI_GetNote(MIDI_take,i-1)}
  until not MIDI_notes[i][1]
  MIDI_notes[i] = nil
  return MIDI_notes
end
local function bfut_LimitPitch(pitch)
  if pitch < 0 then return 0 end
  if pitch > 127 then return 127 end
  return math.modf(pitch)
end
function bfut_NormalizeMinusOneZeroOne(valIN,offset)
  if offset == (0 or 127) then return end
  if valIN >= offset then
    return (valIN-offset)/(127-offset)
  else
    return (valIN-offset)/offset
  end
end
function bfut_NormalizeZeroOneX(valIN,offset)
  if offset == 1 then return end
  return (valIN-1)/(offset-1)
end
function bfut_GetRelativeNoteStartPosPitchVel(MIDI_take,MIDI_notes,config)
  local MIDI_item = reaper.GetMediaItemTake_Item(MIDI_take)
  local MIDI_item_length = reaper.GetMediaItemInfo_Value(MIDI_item,"D_LENGTH")
  local relative_note_startpos_projtime = {0}
  local relative_note_pitch = {0}
  local relative_note_vel = {1}
  for i=1,#MIDI_notes do
    relative_note_startpos_projtime[#relative_note_startpos_projtime+1] = (reaper.MIDI_GetProjTimeFromPPQPos(MIDI_take,MIDI_notes[i][4])
                                                                            -reaper.GetMediaItemInfo_Value(MIDI_item,"D_POSITION"))
                                                                           /MIDI_item_length
    if relative_note_startpos_projtime[#relative_note_startpos_projtime] >= 1 then
      relative_note_startpos_projtime[#relative_note_startpos_projtime] = nil
    elseif relative_note_startpos_projtime[#relative_note_startpos_projtime]-relative_note_startpos_projtime[#relative_note_startpos_projtime-1] == 0 then
      relative_note_startpos_projtime[#relative_note_startpos_projtime] = nil
      relative_note_pitch[#relative_note_pitch] = nil
      relative_note_vel[#relative_note_vel] = nil
      relative_note_pitch[#relative_note_pitch+1] = _G[config["pitch_factor_func"]](MIDI_notes[i][7],config["reference_pitch"])
      relative_note_vel[#relative_note_vel+1] = _G[config["velocity_factor_func"]](MIDI_notes[i][8],config["default_velocity"])
    else
      relative_note_pitch[#relative_note_pitch+1] = _G[config["pitch_factor_func"]](MIDI_notes[i][7],config["reference_pitch"])
      relative_note_vel[#relative_note_vel+1] = _G[config["velocity_factor_func"]](MIDI_notes[i][8],config["default_velocity"])
    end
  end
  relative_note_startpos_projtime[#relative_note_startpos_projtime+1] = 1.0
  relative_note_pitch[#relative_note_pitch+1] = 0
  relative_note_vel[#relative_note_vel+1] = 1
  if #relative_note_startpos_projtime < 2 then
    return nil 
  else
    return relative_note_startpos_projtime,relative_note_pitch,relative_note_vel
  end
end
local count_sel_items = reaper.CountSelectedMediaItems(0)
if count_sel_items < 1 then return end
local hwnd = reaper.MIDIEditor_GetActive()
if hwnd == nil then return end
local MIDI_take = reaper.MIDIEditor_GetTake(hwnd)
if MIDI_take == nil then return end
config["reference_pitch"] = bfut_LimitPitch(config["reference_pitch"])
config["default_velocity"] = bfut_LimitPitch(config["default_velocity"])
local MIDI_notes = bfut_FetchMIDI_notes(MIDI_take)
local relative_note_startpos_projtime,relative_note_pitch,relative_note_vel = bfut_GetRelativeNoteStartPosPitchVel(
                                                                                MIDI_take
                                                                                ,MIDI_notes
                                                                                ,config
                                                                              )
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock2(0)
if #MIDI_notes < 1 or #relative_note_startpos_projtime < 2 then 
  for i=0,count_sel_items-1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    local item_activetake = reaper.GetActiveTake(item,0)
      if item_activetake ~= nil then
        reaper.DeleteTakeStretchMarkers(item_activetake,0,reaper.GetTakeNumStretchMarkers(item_activetake))
      end
  end
else
  for i=0,count_sel_items-1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    local item_activetake = reaper.GetActiveTake(item,0)
    if item_activetake ~= nil then
      reaper.DeleteTakeStretchMarkers(item_activetake,0,reaper.GetTakeNumStretchMarkers(item_activetake))
      local item_length = reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
      for j=0,#relative_note_startpos_projtime-1 do
        if reaper.SetTakeStretchMarker(item_activetake,-1,relative_note_startpos_projtime[j+1]*item_length) == -1 then
          reaper.ShowConsoleMsg(" "..tostring("error inserting Stretchmarker").."\n")
        end
      end
      for j=0,#relative_note_startpos_projtime-2 do
        reaper.SetTakeStretchMarkerSlope(item_activetake,j,-relative_note_pitch[j+1])
        reaper.SetTakeStretchMarker(item_activetake,j,(relative_note_startpos_projtime[j+1]*item_length)
                                                        *relative_note_vel[j+1]
                                                      )
      end
    end
  end
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0,"bfut_MIDI notes control items stretch markers",-1)