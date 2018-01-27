--[[
  @author bfut
  @version 1.0
  DESCRIPTION: bfut_MIDI notes to items (notes to subtrack, note pitch as item pitch)
  HOW TO USE:
    1) Select MIDI Item(s), all on the same track.
    2) Select a track. (optional)
    3) Run the script.
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
local script_config = {
  reference_pitch = 60
  ,track_name = "Piano roll"
  ,item_loader = true
}
local reaper = reaper
local function bfut_ConvertPPQPosToProjTime(MIDI_take,MIDI_notes)
  for i=1,#MIDI_notes do
    MIDI_notes[i][4] = reaper.MIDI_GetProjTimeFromPPQPos(MIDI_take,MIDI_notes[i][4])
    MIDI_notes[i][5] = reaper.MIDI_GetProjTimeFromPPQPos(MIDI_take,MIDI_notes[i][5])
  end
  return MIDI_notes
end
local function bfut_FetchItemsFromTrack(track,limit)
  local num_media_items = reaper.CountTrackMediaItems(track)
  local items = {}
  if num_media_items < limit then
    limit = num_media_items
  end
  for i=0,limit-1 do
    items[i+1] = reaper.GetTrackMediaItem(track,i)
  end
  return items
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
local function bfut_MIDI_HasNotes(item_take)
  local _,notecnt,_,_ = reaper.MIDI_CountEvts(item_take)
  return notecnt > 0
end
local function bfut_FetchSelectedMIDI_TakesOnTrack(track,num_selected_items)
  local MIDI_takes = {}
  if track == nil then return MIDI_takes end
  for i=0,num_selected_items-1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    local item_take = reaper.GetActiveTake(item,0)
    if item_take ~= nil and track == reaper.GetMediaItemTrack(item) and reaper.TakeIsMIDI(item_take) and bfut_MIDI_HasNotes(item_take) then
      MIDI_takes[#MIDI_takes+1] = item_take
    end
  end
  return MIDI_takes
end
local function FetchUserPreference(key,ini_path)
  local f = io.open(ini_path,"rb")
  local s = f:read("*all")
  f:close() 
  local s1,s2 = string.find(s,key.."=",1,true)
  if s1 == nil then return nil end
  local s3 = string.find(s,"\n",s1,true)
  s = s:sub(s2+1,s3-1):gsub("[\r]","")
  return s
end
local function bfut_InsertSubTracks(parent_track,option,note_rows,track_name)
  local subtracks = {}
  local temp_idx = reaper.GetMediaTrackInfo_Value(parent_track,"IP_TRACKNUMBER")
  reaper.InsertTrackAtIndex(temp_idx,true)
  if option == 1 then
    subtracks[(note_rows[#note_rows][1])] = {note_rows[#note_rows][2], reaper.GetTrack(0,temp_idx)}
    if reaper.GetMediaTrackInfo_Value(parent_track,"I_FOLDERDEPTH") ~= 1.0 then
      reaper.SetMediaTrackInfo_Value(parent_track,"I_FOLDERDEPTH",1.0)
      reaper.SetMediaTrackInfo_Value(subtracks[note_rows[#note_rows][1]][2],"I_FOLDERDEPTH",-1.0)
    end
    reaper.GetSetMediaTrackInfo_String(subtracks[(note_rows[#note_rows][1])][2],"P_NAME",note_rows[#note_rows][2],true)
    for i=#note_rows-1,1,-1 do
      reaper.InsertTrackAtIndex(temp_idx,true)
      subtracks[note_rows[i][1]] = {note_rows[i][2], reaper.GetTrack(0,temp_idx)}
      reaper.GetSetMediaTrackInfo_String(subtracks[note_rows[i][1]][2],"P_NAME",note_rows[i][2],true)
    end
  elseif option == 2 then
    subtracks = {{track_name, reaper.GetTrack(0,temp_idx)}}
    if reaper.GetMediaTrackInfo_Value(parent_track,"I_FOLDERDEPTH") ~= 1.0 then
      reaper.SetMediaTrackInfo_Value(parent_track,"I_FOLDERDEPTH",1.0)
      reaper.SetMediaTrackInfo_Value(subtracks[1][2],"I_FOLDERDEPTH",-1.0)
    end
    reaper.GetSetMediaTrackInfo_String(subtracks[1][2],"P_NAME",track_name,true)
  end
  return subtracks
end
local function bfut_LimitPitch(pitch)
  if pitch < 0 then return 0 end
  if pitch > 127 then return 127 end
  return math.modf(pitch)
end
local function bfut_GetTimeSelection()
  reaper.Main_OnCommandEx(40630,0)
  local startpos = reaper.GetCursorPosition(0)
  reaper.Main_OnCommandEx(40631,0)
  return startpos,reaper.GetCursorPosition(0)-startpos
end
local function bfut_SetTimeSelection(startpos,endpos)
  reaper.Main_OnCommandEx(40635,0)
  reaper.SetEditCurPos2(0,startpos,false,false)
  reaper.Main_OnCommandEx(40625,0)
  reaper.SetEditCurPos2(0,endpos,false,false)
  reaper.Main_OnCommandEx(40626,0)
end
local function bfut_Option3_MIDI_AsPianoRoll_EmptyTakes(MIDI_notes,track,_,reference_pitch,reaper_deffadelen)
  reaper.SetOnlyTrackSelected(track,true)
  reaper.Main_OnCommandEx(40914,0)
  for i=1,#MIDI_notes do
    bfut_SetTimeSelection(MIDI_notes[i][4],MIDI_notes[i][5])
    reaper.Main_OnCommandEx(40142,0)
    local temp_item = reaper.GetSelectedMediaItem(0,0)
    reaper.SetMediaItemTakeInfo_Value(
      reaper.AddTakeToMediaItem(temp_item)
      ,"D_PITCH"
      ,MIDI_notes[i][7]-reference_pitch
    )
    reaper.SetMediaItemInfo_Value(temp_item,"D_FADEINLEN",reaper_deffadelen)
    reaper.SetMediaItemInfo_Value(temp_item,"D_FADEOUTLEN",reaper_deffadelen)
    reaper.SetMediaItemInfo_Value(temp_item,"B_MUTE",( MIDI_notes[i][3] and 1 or 0 ))
  end
end
local function bfut_Option3_MIDI_AsPianoRoll(MIDI_notes,track,new_item,reference_pitch,_)
  reaper.Main_OnCommandEx(40289,0)
  reaper.SetMediaItemSelected(new_item,true)
  reaper.Main_OnCommandEx(40698,0)
  reaper.SetOnlyTrackSelected(track,true)
  reaper.Main_OnCommandEx(40914,0)
  for i=1,#MIDI_notes do
    bfut_SetTimeSelection(MIDI_notes[i][4],MIDI_notes[i][5])
    reaper.Main_OnCommandEx(40142,0)
    local temp_item = reaper.GetSelectedMediaItem(0,0)
    reaper.Main_OnCommandEx(40603,0)
    local temp_item_take = reaper.GetActiveTake(temp_item)
    reaper.SetMediaItemTakeInfo_Value(
      temp_item_take
      ,"D_PITCH"
      ,MIDI_notes[i][7]-reference_pitch+reaper.GetMediaItemTakeInfo_Value(temp_item_take,"D_PITCH")
    )
    reaper.SetMediaItemInfo_Value(temp_item,"D_FADEINLEN",
      reaper.GetMediaItemInfo_Value(new_item,"D_FADEINLEN"))
    reaper.SetMediaItemInfo_Value(temp_item,"C_FADEINSHAPE",
      reaper.GetMediaItemInfo_Value(new_item,"C_FADEINSHAPE"))
    reaper.SetMediaItemInfo_Value(temp_item,"D_FADEOUTLEN",
      reaper.GetMediaItemInfo_Value(new_item,"D_FADEOUTLEN"))
    reaper.SetMediaItemInfo_Value(temp_item,"C_FADEOUTSHAPE",
      reaper.GetMediaItemInfo_Value(new_item,"C_FADEOUTSHAPE"))
    reaper.SetMediaItemInfo_Value(temp_item,"B_MUTE",(MIDI_notes[i][3] and 1 or 0))
    reaper.SetMediaItemInfo_Value(temp_item,"B_LOOPSRC", 0.0 )
  end
end
local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items < 1 then return end
local source_track = reaper.GetMediaItemTrack(reaper.GetSelectedMediaItem(0,0))
local sel_MIDI_takes_source_track = bfut_FetchSelectedMIDI_TakesOnTrack(source_track,num_selected_items)
if #sel_MIDI_takes_source_track < 1 then return end
local c = reaper.GetCursorPosition(0)
local timesel_start,timesel_len = bfut_GetTimeSelection()
local parent_track = reaper.GetSelectedTrack2(0,0,false) or source_track
local note_rows = {}
local subtracks = {}
local parent_track_items = {}
local reaper_deffadelen = tonumber(FetchUserPreference("deffadelen",reaper.get_ini_file())) or 0.01
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
subtracks = bfut_InsertSubTracks(
  parent_track,
  2,
  nil,
  script_config["track_name"]
)
if script_config["item_loader"] then
  parent_track_items = bfut_FetchItemsFromTrack(parent_track,1) 
end
for i=1,#sel_MIDI_takes_source_track do
  local MIDI_notes = bfut_FetchMIDI_notes(sel_MIDI_takes_source_track[i])
  MIDI_notes = bfut_ConvertPPQPosToProjTime(sel_MIDI_takes_source_track[i],MIDI_notes)
  if #parent_track_items < 1 then
    bfut_Option3_MIDI_AsPianoRoll_EmptyTakes(
      MIDI_notes,
      subtracks[1][2],
      nil,
      bfut_LimitPitch(script_config["reference_pitch"]),
      reaper_deffadelen
    )
  else
    bfut_Option3_MIDI_AsPianoRoll(
      MIDI_notes,
      subtracks[1][2],
      parent_track_items[1],
      bfut_LimitPitch(script_config["reference_pitch"]),
      nil
    )
  end
end
reaper.Main_OnCommandEx(40421,0)
bfut_SetTimeSelection(timesel_start,timesel_start+timesel_len)
reaper.SetEditCurPos2(0,c,false,false)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0,"bfut_MIDI notes to items (notes to subtrack, note pitch as item pitch)",-1)