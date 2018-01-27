--[[
  @author bfut
  @version 1.0
  DESCRIPTION: bfut_MIDI notes to items (notes to subtrack, note pitch as item rate)
  HOW TO USE:
    1) Select MIDI item(s), all on the same track.
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
  ["option"] = 2
  ,["option2_reference_pitch"] = 60
  ,["option2_track_name"] = "Piano roll"
  ,["item loader"] = true
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
local function bfut_FetchUserPreference(name)
  local f = io.open(reaper.get_ini_file(),"rb")
  local s = f:read("*all")
  f:close() 
  local s1,s2 = string.find(s,name.."=",1,true)
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
local function bfut_ItemPlayrateChange(pitch,reference_pitch)
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
local function bfut_Option1_FetchUsedNoteRowsNames(MIDI_takes,track)
  local note_rows = {}
  local hash = {}
  for i=1,#MIDI_takes do
    local _,notecnt,_,_ = reaper.MIDI_CountEvts(MIDI_takes[i])
    for j=0,notecnt-1 do
      local _,_,_,_,_,channel,pitch,_ = reaper.MIDI_GetNote(MIDI_takes[i],j)
      if not hash[pitch] then
        local note_row_name = reaper.GetTrackMIDINoteNameEx(0,track,pitch,channel)
        if note_row_name ~= nil then
          note_rows[#note_rows+1] = {pitch, pitch .. " ("..note_row_name..")"}
        else
          note_rows[#note_rows+1] = {pitch, pitch}
        end
        hash[pitch] = true
      end
    end
  end
  table.sort(note_rows, function(a,b) return a[1]>b[1] end)
  return note_rows
end
local function bfut_Option1_MIDI_AsSequencer_SetDefaultFadeLengths(track,_,reaper_deffadelen)
  for i=0,reaper.GetTrackNumMediaItems(track)-1 do
    local temp_item = reaper.GetTrackMediaItem(track,i)
    reaper.AddTakeToMediaItem(temp_item)
    reaper.SetMediaItemInfo_Value(temp_item,"D_FADEINLEN",reaper_deffadelen)
    reaper.SetMediaItemInfo_Value(temp_item,"D_FADEOUTLEN",reaper_deffadelen)
  end
end
local function bfut_SetTimeSelection(startpos,endpos)
  reaper.Main_OnCommandEx(40635,0)
  reaper.MoveEditCursor(startpos-reaper.GetCursorPosition(0),false)
  reaper.MoveEditCursor(endpos-reaper.GetCursorPosition(0),true)
end
local function bfut_Option1_MIDI_AsSequencer_EmptyTakes(MIDI_notes,tracks)
  if reaper.APIExists("ULT_SetMediaItemNote") then
    for i=1,#MIDI_notes do
      reaper.SetOnlyTrackSelected(tracks[MIDI_notes[i][7]][2],true)
      reaper.Main_OnCommandEx(40914,0)
      bfut_SetTimeSelection(MIDI_notes[i][4],MIDI_notes[i][5])
      reaper.Main_OnCommandEx(40142,0)
      reaper.SetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0,0),"B_MUTE",(MIDI_notes[i][3] and 1 or 0))
      reaper.ULT_SetMediaItemNote(reaper.GetSelectedMediaItem(0,0),
        "muted,channel,pitch,velocity\n"..
        tostring(MIDI_notes[i][3])..","..
        (MIDI_notes[i][6]+1)..","..
        MIDI_notes[i][7]..","..
        MIDI_notes[i][8]..
        "\n"
      )
    end
  else
    for i=1,#MIDI_notes do
      reaper.SetOnlyTrackSelected(tracks[MIDI_notes[i][7]][2],true)
      reaper.Main_OnCommandEx(40914,0)
      bfut_SetTimeSelection(MIDI_notes[i][4],MIDI_notes[i][5])
      reaper.Main_OnCommandEx(40142,0)
      reaper.SetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0,0),"B_MUTE",(MIDI_notes[i][3] and 1 or 0))
    end
  end
end
local function bfut_Option2_MIDI_AsPianoRoll_EmptyTakes(MIDI_notes,track,_,reference_pitch,reaper_deffadelen)
  reaper.SetOnlyTrackSelected(track,true)
  reaper.Main_OnCommandEx(40914,0)
  if reaper.APIExists("ULT_SetMediaItemNote") then
    for i=1,#MIDI_notes do
      bfut_SetTimeSelection(MIDI_notes[i][4],MIDI_notes[i][5])
      reaper.Main_OnCommandEx(40142,0)
      local temp_item = reaper.GetSelectedMediaItem(0,0)
      reaper.AddTakeToMediaItem(temp_item)
      bfut_ItemPlayrateChange(MIDI_notes[i][7],reference_pitch)
      reaper.Main_OnCommandEx(41385,0)
      reaper.SetMediaItemInfo_Value(temp_item,"D_FADEINLEN",reaper_deffadelen)
      reaper.SetMediaItemInfo_Value(temp_item,"D_FADEOUTLEN",reaper_deffadelen)
      reaper.SetMediaItemInfo_Value(temp_item,"B_MUTE",( MIDI_notes[i][3] and 1 or 0 ))
      reaper.ULT_SetMediaItemNote(reaper.GetSelectedMediaItem(0,0),
        "muted,channel,pitch,velocity\n"..
        tostring(MIDI_notes[i][3])..","..
        (MIDI_notes[i][6]+1)..","..
        MIDI_notes[i][7]..","..
        MIDI_notes[i][8]..
        "\n"
      )
    end
  else
    for i=1,#MIDI_notes do
      bfut_SetTimeSelection(MIDI_notes[i][4],MIDI_notes[i][5])
      reaper.Main_OnCommandEx(40142,0)
      local temp_item = reaper.GetSelectedMediaItem(0,0)
      reaper.AddTakeToMediaItem(temp_item)
      bfut_ItemPlayrateChange(MIDI_notes[i][7],reference_pitch)
      reaper.Main_OnCommandEx(41385,0)
      reaper.SetMediaItemInfo_Value(temp_item,"D_FADEINLEN",reaper_deffadelen)
      reaper.SetMediaItemInfo_Value(temp_item,"D_FADEOUTLEN",reaper_deffadelen)
      reaper.SetMediaItemInfo_Value(temp_item,"B_MUTE",( MIDI_notes[i][3] and 1 or 0 ))
    end
  end
end
local function bfut_Option1_MIDI_AsSequencer_PasteAsTakeOnTrack(track,new_item,_)
  reaper.Main_OnCommandEx(40289,0)
  reaper.SetMediaItemSelected(new_item,true)
  reaper.Main_OnCommandEx(40698,0)
  reaper.SetMediaItemSelected(new_item,false)
  for i=0,reaper.GetTrackNumMediaItems(track)-1 do
    local temp_item = reaper.GetTrackMediaItem(track,i)
    reaper.SetMediaItemSelected(temp_item,true)
    reaper.Main_OnCommandEx(40603,0)
    reaper.SetMediaItemSelected(temp_item,false)
    reaper.SetMediaItemInfo_Value(temp_item,"D_FADEINLEN",
      reaper.GetMediaItemInfo_Value(new_item,"D_FADEINLEN"))
    reaper.SetMediaItemInfo_Value(temp_item,"C_FADEINSHAPE",
      reaper.GetMediaItemInfo_Value(new_item,"C_FADEINSHAPE"))
    reaper.SetMediaItemInfo_Value(temp_item,"D_FADEOUTLEN",
      reaper.GetMediaItemInfo_Value(new_item,"D_FADEOUTLEN"))
    reaper.SetMediaItemInfo_Value(temp_item,"C_FADEOUTSHAPE",
      reaper.GetMediaItemInfo_Value(new_item,"C_FADEOUTSHAPE"))
  end
end
local function bfut_Option2_MIDI_AsPianoRoll(MIDI_notes,track,new_item,reference_pitch,_)
  reaper.Main_OnCommandEx(40289,0)
  reaper.SetMediaItemSelected(new_item,true)
  reaper.Main_OnCommandEx(40698,0)
  reaper.SetOnlyTrackSelected(track,true)
  reaper.Main_OnCommandEx(40914,0)
  if reaper.APIExists("ULT_SetMediaItemNote") then
    for i=1,#MIDI_notes do
      bfut_SetTimeSelection(MIDI_notes[i][4],MIDI_notes[i][5])
      reaper.Main_OnCommandEx(40142,0)
      local temp_item = reaper.GetSelectedMediaItem(0,0)
      reaper.Main_OnCommandEx(40603,0)
      bfut_ItemPlayrateChange(MIDI_notes[i][7],reference_pitch)
      reaper.Main_OnCommandEx(41385,0)
      reaper.SetMediaItemInfo_Value(temp_item,"D_FADEINLEN",
        reaper.GetMediaItemInfo_Value(new_item,"D_FADEINLEN"))
      reaper.SetMediaItemInfo_Value(temp_item,"C_FADEINSHAPE",
        reaper.GetMediaItemInfo_Value(new_item,"C_FADEINSHAPE"))
      reaper.SetMediaItemInfo_Value(temp_item,"D_FADEOUTLEN",
        reaper.GetMediaItemInfo_Value(new_item,"D_FADEOUTLEN"))
      reaper.SetMediaItemInfo_Value(temp_item,"C_FADEOUTSHAPE",
        reaper.GetMediaItemInfo_Value(new_item,"C_FADEOUTSHAPE"))
      reaper.SetMediaItemInfo_Value(temp_item,"B_MUTE",(MIDI_notes[i][3] and 1 or 0))
      reaper.ULT_SetMediaItemNote(reaper.GetSelectedMediaItem(0,0),
        "muted,channel,pitch,velocity\n"..
        tostring(MIDI_notes[i][3])..","..
        (MIDI_notes[i][6]+1)..","..
        MIDI_notes[i][7]..","..
        MIDI_notes[i][8]..
        "\n"
      )
    end
  else
    for i=1,#MIDI_notes do
      bfut_SetTimeSelection(MIDI_notes[i][4],MIDI_notes[i][5])
      reaper.Main_OnCommandEx(40142,0)
      local temp_item = reaper.GetSelectedMediaItem(0,0)
      reaper.Main_OnCommandEx(40603,0)
      bfut_ItemPlayrateChange(MIDI_notes[i][7],reference_pitch)
      reaper.Main_OnCommandEx(41385,0)
      reaper.SetMediaItemInfo_Value(temp_item,"D_FADEINLEN",
        reaper.GetMediaItemInfo_Value(new_item,"D_FADEINLEN"))
      reaper.SetMediaItemInfo_Value(temp_item,"C_FADEINSHAPE",
        reaper.GetMediaItemInfo_Value(new_item,"C_FADEINSHAPE"))
      reaper.SetMediaItemInfo_Value(temp_item,"D_FADEOUTLEN",
        reaper.GetMediaItemInfo_Value(new_item,"D_FADEOUTLEN"))
      reaper.SetMediaItemInfo_Value(temp_item,"C_FADEOUTSHAPE",
        reaper.GetMediaItemInfo_Value(new_item,"C_FADEOUTSHAPE"))
      reaper.SetMediaItemInfo_Value(temp_item,"B_MUTE",(MIDI_notes[i][3] and 1 or 0))
    end
  end
end
reaper.Undo_BeginBlock2(0)
local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items < 1 then return end
if not (script_config["option2_reference_pitch"] >= 0
  and script_config["option2_reference_pitch"] <= 127) then return end
local source_track = reaper.GetMediaItemTrack(reaper.GetSelectedMediaItem(0,0))
local sel_MIDI_takes_source_track = bfut_FetchSelectedMIDI_TakesOnTrack(source_track,num_selected_items)
if #sel_MIDI_takes_source_track < 1 then return end
local parent_track = reaper.GetSelectedTrack2(0,0,false) or source_track
local note_rows = {}
local subtracks = {}
local parent_track_items = {}
local reaper_deffadelen = tonumber(bfut_FetchUserPreference("deffadelen")) or 0.01
local undo_desc
reaper.PreventUIRefresh(1)
if script_config["option"] == 1 then
  undo_desc = "bfut_MIDI Notes to Items (explode note rows to subtracks)"
  note_rows = bfut_Option1_FetchUsedNoteRowsNames(sel_MIDI_takes_source_track,source_track)
  subtracks = bfut_InsertSubTracks(parent_track,script_config["option"],note_rows,nil)
  if script_config["item loader"] then
    parent_track_items = bfut_FetchItemsFromTrack(parent_track,#note_rows) 
  end
  for i=1,#sel_MIDI_takes_source_track do
    local MIDI_notes = bfut_FetchMIDI_notes(sel_MIDI_takes_source_track[i])
    MIDI_notes = bfut_ConvertPPQPosToProjTime(sel_MIDI_takes_source_track[i],MIDI_notes)
    bfut_Option1_MIDI_AsSequencer_EmptyTakes(MIDI_notes,subtracks)
  end
  reaper.Main_OnCommandEx(40635,0)
  reaper.Main_OnCommandEx(40297,0)
  for j=#note_rows,#note_rows-#parent_track_items+1,-1 do
    local temp_track = subtracks[note_rows[j][1]     ][2]
    bfut_Option1_MIDI_AsSequencer_PasteAsTakeOnTrack(temp_track,parent_track_items[#note_rows-j+1],nil)
    reaper.SetTrackSelected(temp_track,true)
  end
  for j=#note_rows-#parent_track_items,1,-1 do
    local temp_track = subtracks[(note_rows[j][1])][2]
    bfut_Option1_MIDI_AsSequencer_SetDefaultFadeLengths(temp_track,nil,reaper_deffadelen)
    reaper.SetTrackSelected(temp_track,true)
  end
  reaper.Main_OnCommandEx(40421,0)
end
if script_config["option"] == 2 then
  undo_desc = "bfut_MIDI Notes to Items (notes to subtrack, note pitch as item rate)"
  subtracks = bfut_InsertSubTracks(parent_track,
    script_config["option"],
    nil,
    script_config["option2_track_name"])
  if script_config["item loader"] then
    parent_track_items = bfut_FetchItemsFromTrack(parent_track,1)
  end
  for i=1,#sel_MIDI_takes_source_track do
    local MIDI_notes = bfut_FetchMIDI_notes(sel_MIDI_takes_source_track[i])
    MIDI_notes = bfut_ConvertPPQPosToProjTime(sel_MIDI_takes_source_track[i],MIDI_notes)
    if #parent_track_items < 1 then
      bfut_Option2_MIDI_AsPianoRoll_EmptyTakes(MIDI_notes,
        subtracks[1][2],
        nil,
        script_config["option2_reference_pitch"],
        reaper_deffadelen)
    else
      bfut_Option2_MIDI_AsPianoRoll(MIDI_notes,
        subtracks[1][2],
        parent_track_items[1],
        script_config["option2_reference_pitch"],
        nil)
    end
  end
  reaper.Main_OnCommandEx(40421,0)
end
reaper.Main_OnCommandEx(40635,0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0,undo_desc,-1)