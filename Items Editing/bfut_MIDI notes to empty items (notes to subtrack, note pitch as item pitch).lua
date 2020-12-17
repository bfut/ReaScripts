--[[
  @author bfut
  @version 1.3
  @description bfut_MIDI notes to empty items (notes to subtrack, note pitch as item pitch)
  @about
    Convert MIDI notes to items
    * bfut_MIDI notes to items (explode note rows to subtracks).lua
    * bfut_MIDI notes to items (notes to subtrack, note pitch as item pitch).lua
    * bfut_MIDI notes to items (notes to subtrack, note pitch as item rate).lua
    * bfut_MIDI notes to empty items (explode note rows to subtracks).lua
    * bfut_MIDI notes to empty items (notes to subtrack, note pitch as item pitch).lua
    * bfut_MIDI notes to empty items (notes to subtrack, note pitch as item rate).lua

    Converts MIDI notes to media items in one go. Note velocity as item volume.

    HOW TO SET UP ITEM/SAMPLE LOADER:
      1) Select MIDI item(s) on one track.
      2) Select another track with various media items.
      3) Each used note row will point to one of the media items.
      4) If there are not enough media items, you'll get empty items.

    HOW TO USE:
      1) Select MIDI item(s).
      2) Select a track. (optional)
      3) Run the script.
    REQUIRES: Reaper v6.18 or later
  @changelog
    + support time signature markers
  @website https://github.com/bfut
  LICENSE:
    Copyright (C) 2017 and later Benjamin Futasz

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
--[[ CONFIG options:
      option =
        1  -- explode note rows to subtracks
        2  -- notes to subtrack, note pitch as item rate
        3  -- notes to subtrack, note pitch as item pitch

      item_loader = true|false

      reference_pitch =
        Tune MIDI editor // MIDI note pitch is 0..127, default REAPER has:
          0 C-1
          60 C4 (factory default)
          72 C5
          127 G9

      default_velocity = 1..127  // factor in note velocity
                         -inf..0  // do not factor in note velocity
                            with -1 as factory default
]]
local CONFIG = {
  option = 3
  ,item_loader = false
  ,reference_pitch = 60
  ,default_velocity = -1
  ,option2_track_name = "Piano roll"
}
function bfut_FetchSelectedMIDI_TakesOnTrack(count_sel_items)
  local MIDI_takes = {}
  local MIDI_takes_track
  local idx_first_MIDI_item = 0
  for i = 0, count_sel_items - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    if item then
      local take = reaper.GetActiveTake(item, 0)
      if take and reaper.TakeIsMIDI(take) then
        local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local take_length = reaper.TimeMap2_QNToTime(
          0,
          reaper.GetMediaSourceLength(reaper.GetMediaItemTake_Source(take)) /
            reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
        )
        for j = 0, select(2, reaper.MIDI_CountEvts(take)) - 1 do
          local MIDI_note = {reaper.MIDI_GetNote(take, j)}
          MIDI_note[4] = reaper.MIDI_GetProjTimeFromPPQPos(take, MIDI_note[4])
          while MIDI_note[4] < item_end do
            if MIDI_note[4] >= item_start then
              MIDI_takes[1] = take
              MIDI_takes_track = reaper.GetMediaItem_Track(item)
              idx_first_MIDI_item = i
              goto BREAK
            end
            MIDI_note[4] = MIDI_note[4] + take_length
          end
        end
      end
    end
  end
  ::BREAK::
  for i = idx_first_MIDI_item + 1, count_sel_items - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    if item then
      local take = reaper.GetActiveTake(item, 0)
      if take then
        if MIDI_takes_track == reaper.GetMediaItemTrack(item) then
          if reaper.TakeIsMIDI(take) then
            if select(2, reaper.MIDI_CountEvts(take)) > 0 then
              MIDI_takes[#MIDI_takes + 1] = take
            end
          end
        else
          break
        end
      end
    end
  end
  return MIDI_takes, MIDI_takes_track
end
function bfut_FetchMIDI_notes(take, default_velocity)
  local notes = {}
  local item = reaper.GetMediaItemTake_Item(take)
  local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  item_start = reaper.TimeMap2_timeToQN(0, item_start)
  item_end = reaper.TimeMap2_timeToQN(0, item_end)
  local take_sourcelength = reaper.GetMediaSourceLength(reaper.GetMediaItemTake_Source(take))
  local take_playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  take_sourcelength = take_sourcelength / take_playrate
  for i = 0, select(2, reaper.MIDI_CountEvts(take)) - 1 do
    local note = {reaper.MIDI_GetNote(take, i)}
    if default_velocity > 0 then
      note[8] = note[8] / default_velocity
    else
      note[8] = 1
    end
    note[4] = reaper.MIDI_GetProjQNFromPPQPos(take, note[4])
    note[5] = reaper.MIDI_GetProjQNFromPPQPos(take, note[5])
    while note[4] < item_end and math.abs(note[4] - item_end) > 10^-13 do
      if note[5] > item_start then
        local note_multiple_start_time = math.max(
          reaper.TimeMap2_QNToTime(0, note[4]),
          reaper.TimeMap2_QNToTime(0, item_start)
        )
        local note_multiple_end_time = math.min(
          reaper.TimeMap2_QNToTime(0, note[5]),
          reaper.TimeMap2_QNToTime(0, item_end)
        )
        if math.abs(note_multiple_end_time - note_multiple_start_time) > 0 then
          notes[#notes + 1] = {
            note[1], note[2], note[3],
            note_multiple_start_time,
            note_multiple_end_time,
            note[6], note[7], note[8]
          }
        end
      end
      note[4] = note[4] + take_sourcelength
      note[5] = note[5] + take_sourcelength
    end
  end
  return notes
end
function bfut_InsertSubTracks(parent_track, option, note_rows, track_name)
  local subtracks = {}
  local temp_idx = reaper.GetMediaTrackInfo_Value(parent_track, "IP_TRACKNUMBER")
  reaper.InsertTrackAtIndex(temp_idx, true)
  if option == 1 then
    subtracks[(note_rows[#note_rows][1])] = {note_rows[#note_rows][2], reaper.GetTrack(0, temp_idx)}
    if reaper.GetMediaTrackInfo_Value(parent_track, "I_FOLDERDEPTH") ~= 1.0 then
      reaper.SetMediaTrackInfo_Value(parent_track, "I_FOLDERDEPTH", 1.0)
      reaper.SetMediaTrackInfo_Value(subtracks[note_rows[#note_rows][1]][2], "I_FOLDERDEPTH", -1.0)
    end
    reaper.GetSetMediaTrackInfo_String(subtracks[(note_rows[#note_rows][1])][2], "P_NAME", note_rows[#note_rows][2], true)
    for i = #note_rows - 1, 1, -1 do
      reaper.InsertTrackAtIndex(temp_idx, true)
      subtracks[note_rows[i][1]] = {note_rows[i][2], reaper.GetTrack(0, temp_idx)}
      reaper.GetSetMediaTrackInfo_String(subtracks[note_rows[i][1]][2], "P_NAME", note_rows[i][2], true)
    end
  elseif option == 2 or option == 3 then
    subtracks = {{track_name, reaper.GetTrack(0, temp_idx)}}
    if reaper.GetMediaTrackInfo_Value(parent_track, "I_FOLDERDEPTH") ~= 1.0 then
      reaper.SetMediaTrackInfo_Value(parent_track, "I_FOLDERDEPTH", 1.0)
      reaper.SetMediaTrackInfo_Value(subtracks[1][2], "I_FOLDERDEPTH", -1.0)
    end
    reaper.GetSetMediaTrackInfo_String(subtracks[1][2], "P_NAME", track_name, true)
  end
  return subtracks
end
function bfut_FetchItemsFromTrack(track, limit)
  local items = {}
  for i = 0, math.min(limit, reaper.CountTrackMediaItems(track)) - 1 do
    items[i + 1] = reaper.GetTrackMediaItem(track, i)
  end
  return items
end
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
function bfut_Option1_FetchUsedNoteRowsNames(MIDI_takes, track)
  local note_rows = {}
  local hash = {}
  for i = 1, #MIDI_takes do
    local _, notecnt, _, _ = reaper.MIDI_CountEvts(MIDI_takes[i])
    for j = 0, notecnt - 1 do
      local _, _, _, _, _, channel, pitch, _ = reaper.MIDI_GetNote(MIDI_takes[i], j)
      if not hash[pitch] then
        local note_row_name = reaper.GetTrackMIDINoteNameEx(0, track, pitch, channel)
        if note_row_name then
          note_rows[#note_rows + 1] = {pitch, string.format("%s (%s)", pitch, note_row_name)}
        else
          note_rows[#note_rows + 1] = {pitch, pitch}
        end
        hash[pitch] = true
      end
    end
  end
  table.sort(note_rows, function(a, b) return a[1] > b[1] end)
  return note_rows
end
function bfut_Option1_MIDI_AsSequencer_SetDefaultFadeLengths(track, reaper_deffadelen)
  for i = 0, reaper.GetTrackNumMediaItems(track)-1 do
      local temp_item = reaper.GetTrackMediaItem(track, i)
      reaper.AddTakeToMediaItem(temp_item)
      for _, key in ipairs({"D_FADEINLEN", "D_FADEOUTLEN"}) do
        reaper.SetMediaItemInfo_Value(temp_item, key, reaper_deffadelen)
      end
  end
end
function bfut_Option1_MIDI_AsSequencer_EmptyTakes(MIDI_notes, tracks)
  for i = 1, #MIDI_notes do
    reaper.SetOnlyTrackSelected(tracks[MIDI_notes[i][7]][2], true)
    reaper.Main_OnCommandEx(40914, 0)
    reaper.GetSet_LoopTimeRange2(0, true, false, MIDI_notes[i][4], MIDI_notes[i][5], false)
    reaper.Main_OnCommandEx(40142, 0)
    local item = reaper.GetSelectedMediaItem(0, 0)
    reaper.SetMediaItemInfo_Value(item, "B_MUTE", (MIDI_notes[i][3] and 1 or 0))
    reaper.SetMediaItemInfo_Value(item, "D_VOL", MIDI_notes[i][8])
  end
end
function bfut_Option1_MIDI_AsSequencer_PasteAsTakeOnTrack(track, source_item)
  reaper.Main_OnCommandEx(40289, 0)
  reaper.SetMediaItemSelected(source_item, true)
  reaper.Main_OnCommandEx(40698, 0)
  reaper.SetMediaItemSelected(source_item, false)
  for i = 0, reaper.GetTrackNumMediaItems(track) - 1 do
    local temp_item = reaper.GetTrackMediaItem(track, i)
    reaper.SetMediaItemSelected(temp_item, true)
    reaper.Main_OnCommandEx(40603, 0)
    reaper.SetMediaItemSelected(temp_item, false)
    bfut_LimitItemsLength(temp_item)
    for _, key in ipairs({"D_FADEINLEN", "C_FADEINSHAPE", "D_FADEOUTLEN", "C_FADEOUTSHAPE"}) do
      reaper.SetMediaItemInfo_Value(
        temp_item,
        key,
        reaper.GetMediaItemInfo_Value(source_item, key)
      )
    end
  end
end
function bfut_LimitItemsLength(item)
  local item_activetake = reaper.GetActiveTake(item, 0)
  if item_activetake then
    local item_activetake_mediasourcelength, lengthIsQN = reaper.GetMediaSourceLength(reaper.GetMediaItemTake_Source(item_activetake))
    if lengthIsQN then
      item_activetake_mediasourcelength = reaper.TimeMap_QNToTime(item_activetake_mediasourcelength)
    end
    item_activetake_mediasourcelength = item_activetake_mediasourcelength / reaper.GetMediaItemTakeInfo_Value(item_activetake, "D_PLAYRATE")
    if reaper.GetMediaItemInfo_Value(item, "D_LENGTH") > item_activetake_mediasourcelength then
      reaper.SetMediaItemLength(item, item_activetake_mediasourcelength, false)
    end
  end
end
function bfut_Option2_MIDI_AsPianoRoll_EmptyTakes(MIDI_notes, track, _, reference_pitch, reaper_deffadelen)
  reaper.SetOnlyTrackSelected(track, true)
  reaper.Main_OnCommandEx(40914, 0)
  for i = 1, #MIDI_notes do
    reaper.GetSet_LoopTimeRange2(0, true, false, MIDI_notes[i][4], MIDI_notes[i][5], false)
    reaper.Main_OnCommandEx(40142, 0)
    local temp_item = reaper.GetSelectedMediaItem(0, 0)
    reaper.AddTakeToMediaItem(temp_item)
    bfut_ItemPlayrateChange(MIDI_notes[i][7], reference_pitch)
    reaper.Main_OnCommandEx(41385, 0)
    for _, key in ipairs({"D_FADEINLEN", "D_FADEOUTLEN"}) do
      reaper.SetMediaItemInfo_Value(temp_item, key, reaper_deffadelen)
    end
    reaper.SetMediaItemInfo_Value(temp_item, "B_MUTE", (MIDI_notes[i][3] and 1 or 0))
    reaper.SetMediaItemInfo_Value(temp_item, "D_VOL", MIDI_notes[i][8])
  end
end
function bfut_Option2_MIDI_AsPianoRoll(MIDI_notes, track, source_item, reference_pitch, _)
  reaper.SelectAllMediaItems(0, false)
  reaper.SetMediaItemSelected(source_item, true)
  reaper.Main_OnCommandEx(40698, 0)
  reaper.SetOnlyTrackSelected(track, true)
  reaper.Main_OnCommandEx(40914,0)
  for i = 1, #MIDI_notes do
    reaper.GetSet_LoopTimeRange2(0, true, false, MIDI_notes[i][4], MIDI_notes[i][5], false)
    reaper.Main_OnCommandEx(40142,0)
    local temp_item = reaper.GetSelectedMediaItem(0, 0)
    reaper.Main_OnCommandEx(40603, 0)
    bfut_ItemPlayrateChange(MIDI_notes[i][7], reference_pitch)
    reaper.Main_OnCommandEx(41385, 0)
    bfut_LimitItemsLength(temp_item)
    for _, key in ipairs({"D_FADEINLEN", "C_FADEINSHAPE", "D_FADEOUTLEN", "C_FADEOUTSHAPE"}) do
      reaper.SetMediaItemInfo_Value(
        temp_item,
        key,
        reaper.GetMediaItemInfo_Value(source_item, key)
      )
    end
    reaper.SetMediaItemInfo_Value(temp_item, "B_MUTE", (MIDI_notes[i][3] and 1 or 0))
    reaper.SetMediaItemInfo_Value(temp_item, "D_VOL", MIDI_notes[i][8])
  end
end
function bfut_Option3_MIDI_AsPianoRoll_EmptyTakes(MIDI_notes, track, _, reference_pitch, reaper_deffadelen)
  reaper.SetOnlyTrackSelected(track, true)
  reaper.Main_OnCommandEx(40914, 0)
  for i = 1, #MIDI_notes do
    reaper.GetSet_LoopTimeRange2(0, true, false, MIDI_notes[i][4], MIDI_notes[i][5], false)
    reaper.Main_OnCommandEx(40142, 0)
    local temp_item = reaper.GetSelectedMediaItem(0, 0)
    reaper.SetMediaItemTakeInfo_Value(
      reaper.AddTakeToMediaItem(temp_item),
      "D_PITCH",
      MIDI_notes[i][7] - reference_pitch
    )
    for _, key in ipairs({"D_FADEINLEN", "D_FADEOUTLEN"}) do
      reaper.SetMediaItemInfo_Value(temp_item, key, reaper_deffadelen)
    end
    reaper.SetMediaItemInfo_Value(temp_item, "B_MUTE", (MIDI_notes[i][3] and 1 or 0))
    reaper.SetMediaItemInfo_Value(temp_item, "D_VOL", MIDI_notes[i][8])
  end
end
function bfut_Option3_MIDI_AsPianoRoll(MIDI_notes, track, source_item, reference_pitch, _)
  reaper.SelectAllMediaItems(0, false)
  reaper.SetMediaItemSelected(source_item, true)
  reaper.Main_OnCommandEx(40698, 0)
  reaper.SetOnlyTrackSelected(track, true)
  reaper.Main_OnCommandEx(40914,0)
  for i = 1, #MIDI_notes do
    reaper.GetSet_LoopTimeRange2(0, true, false, MIDI_notes[i][4], MIDI_notes[i][5], false)
    reaper.Main_OnCommandEx(40142, 0)
    local temp_item = reaper.GetSelectedMediaItem(0, 0)
    reaper.Main_OnCommandEx(40603, 0)
    local temp_item_take = reaper.GetActiveTake(temp_item)
    reaper.SetMediaItemTakeInfo_Value(
      temp_item_take,
      "D_PITCH",
      MIDI_notes[i][7] - reference_pitch + reaper.GetMediaItemTakeInfo_Value(temp_item_take, "D_PITCH")
    )
    for _, key in ipairs({"D_FADEINLEN", "C_FADEINSHAPE", "D_FADEOUTLEN", "C_FADEOUTSHAPE"}) do
      reaper.SetMediaItemInfo_Value(
        temp_item,
        key,
        reaper.GetMediaItemInfo_Value(source_item, key)
      )
    end
    reaper.SetMediaItemInfo_Value(temp_item, "B_MUTE", (MIDI_notes[i][3] and 1 or 0))
    reaper.SetMediaItemInfo_Value(temp_item, "D_VOL", MIDI_notes[i][8])
    reaper.SetMediaItemInfo_Value(temp_item, "B_LOOPSRC", 0.0)
  end
end
local sel_MIDI_takes, MIDI_track = bfut_FetchSelectedMIDI_TakesOnTrack(reaper.CountSelectedMediaItems(0))
if not MIDI_track then
  return
end
local parent_track = reaper.GetSelectedTrack2(0, 0, false) or MIDI_track
local note_rows = {}
local subtracks = {}
local parent_track_items = {}
local retval, DEFFADELEN = reaper.get_config_var_string("deffadelen")
if not retval then
  DEFFADELEN = 0.01
end
local VIEW_START, VIEW_END = reaper.GetSet_ArrangeView2(0, false, 0, 0, -1, -1)
local TIME_SEL_START, TIME_SEL_END = reaper.GetSet_LoopTimeRange2(0, false, false, -1, -1, false)
local ORIGINAL_CURSOR_POSITION = reaper.GetCursorPosition()
local UNDO_DESC
if CONFIG["option"] == 1 and item_loader then
  UNDO_DESC = "bfut_MIDI notes to items (explode note rows to subtracks)"
elseif CONFIG["option"] == 2 and item_loader then
  UNDO_DESC = "bfut_MIDI notes to items (notes to subtrack, note pitch as item rate)"
elseif CONFIG["option"] == 3 and item_loader then
  UNDO_DESC = "bfut_MIDI notes to items (notes to subtrack, note pitch as item pitch)"
elseif CONFIG["option"] == 1 and not item_loader then
  UNDO_DESC = "bfut_MIDI notes to empty items (explode note rows to subtracks)"
elseif CONFIG["option"] == 2 and not item_loader then
  UNDO_DESC = "bfut_MIDI notes to empty items (notes to subtrack, note pitch as item rate)"
elseif CONFIG["option"] == 3 and not item_loader then
  UNDO_DESC = "bfut_MIDI notes to empty items (notes to subtrack, note pitch as item pitch)"
else
  return
end
if CONFIG["reference_pitch"] > 127 then
  CONFIG["reference_pitch"] = 127
else
  CONFIG["reference_pitch"] = math.max(math.modf(CONFIG["reference_pitch"]), 0)
end
if CONFIG["default_velocity"] > 127 then
  CONFIG["default_velocity"] = 127
else
  CONFIG["default_velocity"] = math.modf(CONFIG["default_velocity"])
end
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
reaper.GetSet_ArrangeView2(0, true, 0, 0, 0, reaper.GetProjectLength(0) + 30)
if CONFIG["option"] == 1 then
  note_rows = bfut_Option1_FetchUsedNoteRowsNames(sel_MIDI_takes, MIDI_track)
  subtracks = bfut_InsertSubTracks(
    parent_track,
    CONFIG["option"],
    note_rows,
    nil
  )
  if CONFIG["item_loader"] then
    parent_track_items = bfut_FetchItemsFromTrack(parent_track, #note_rows)
  end
  for i = 1, #sel_MIDI_takes do
    local MIDI_notes = bfut_FetchMIDI_notes(sel_MIDI_takes[i], CONFIG["default_velocity"])
    bfut_Option1_MIDI_AsSequencer_EmptyTakes(MIDI_notes, subtracks)
  end
  reaper.Main_OnCommandEx(40635, 0)
  reaper.Main_OnCommandEx(40297, 0)
  for j = #note_rows, #note_rows - #parent_track_items + 1, -1 do
    local temp_track = subtracks[(note_rows[j][1])][2]
    bfut_Option1_MIDI_AsSequencer_PasteAsTakeOnTrack(temp_track, parent_track_items[#note_rows - j + 1])
    reaper.SetTrackSelected(temp_track, true)
  end
  for j = #note_rows - #parent_track_items, 1, -1 do
    local temp_track = subtracks[(note_rows[j][1])][2]
    bfut_Option1_MIDI_AsSequencer_SetDefaultFadeLengths(temp_track, DEFFADELEN)
    reaper.SetTrackSelected(temp_track, true)
  end
  reaper.Main_OnCommandEx(40421, 0)
elseif CONFIG["option"] == 2 then
  subtracks = bfut_InsertSubTracks(
    parent_track,
    2,
    nil,
    CONFIG["option2_track_name"]
  )
  if CONFIG["item_loader"] then
    parent_track_items = bfut_FetchItemsFromTrack(parent_track, 1)
  end
  for i = 1, #sel_MIDI_takes do
    local MIDI_notes = bfut_FetchMIDI_notes(sel_MIDI_takes[i], CONFIG["default_velocity"])
    if #parent_track_items < 1 then
      bfut_Option2_MIDI_AsPianoRoll_EmptyTakes(
        MIDI_notes,
        subtracks[1][2],
        nil,
        CONFIG["reference_pitch"],
        DEFFADELEN
      )
    else
      bfut_Option2_MIDI_AsPianoRoll(
        MIDI_notes,
        subtracks[1][2],
        parent_track_items[1],
        CONFIG["reference_pitch"],
        nil
      )
    end
  end
  reaper.Main_OnCommandEx(40421, 0)
elseif CONFIG["option"] == 3 then
  subtracks = bfut_InsertSubTracks(
    parent_track,
    3,
    nil,
    CONFIG["option2_track_name"]
  )
  if CONFIG["item_loader"] then
    parent_track_items = bfut_FetchItemsFromTrack(parent_track, 1)
  end
  for i = 1, #sel_MIDI_takes do
    local MIDI_notes = bfut_FetchMIDI_notes(sel_MIDI_takes[i], CONFIG["default_velocity"])
    if #parent_track_items < 1 then
      bfut_Option3_MIDI_AsPianoRoll_EmptyTakes(
        MIDI_notes,
        subtracks[1][2],
        nil,
        CONFIG["reference_pitch"],
        DEFFADELEN
      )
    else
      bfut_Option3_MIDI_AsPianoRoll(
        MIDI_notes,
        subtracks[1][2],
        parent_track_items[1],
        CONFIG["reference_pitch"],
        nil
      )
    end
  end
  reaper.Main_OnCommandEx(40421, 0)
end
reaper.GetSet_LoopTimeRange2(0, true, false, TIME_SEL_START, TIME_SEL_END, false)
reaper.SetEditCurPos2(0, ORIGINAL_CURSOR_POSITION, false, false)
reaper.GetSet_ArrangeView2(0, true, 0, 0, VIEW_START, VIEW_END)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, UNDO_DESC, -1)