--[[
  @author bfut
  @version 2.2
  @description bfut_Copy items to project markers, remove overlaps
  @about
    Propagates selected items to project markers.

    HOW TO USE:
      1) There must be at least one project marker.
      2) Select media item(s).
      3) Run the script.

    REQUIRES: Reaper v6.69 or later
  @changelog
    + ignore markers with distance to next below time range length threshold
    + Fix: strictly paste items to area between markers
    + Fix: paste items to respective original tracks
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
  items_or_sel = "items"|"sel"  -- Copy items to or copy items within time selection to
]]
local CONFIG = {
  items_or_sel = "items"
}
local function bfut_GetMarkersByDistanceToNext(count_markers, count_regions)
  local markers = {}
  local marker_idx = 2
  local continue_loop = 0
  local min_note_len = 4.2615384614919 * 10^-5
  for i = 0, count_markers + count_regions - 1 do
    local retval, isregion, pos, _, _, _ = reaper.EnumProjectMarkers2(0, i)
    continue_loop = i
    if retval and not isregion then
      markers[1] = {1, pos, pos}
      break
    end
  end
  for i = continue_loop + 1, count_markers + count_regions - 1 do
    local _, isregion, pos, _, _, _ = reaper.EnumProjectMarkers2(0, i)
    if not isregion then
      markers[marker_idx-1][3] = pos - markers[marker_idx-1][2]
      markers[marker_idx] = {marker_idx, pos, pos}
      marker_idx = marker_idx + 1
    end
  end
  markers[marker_idx-1][3] = 1 / 0
  table.sort(markers, function(a, b) return a[3] > b[3] end)
  for i = marker_idx - 1, 1, -1 do
    if markers[i][3] >= min_note_len then
      return markers, i
    end
    markers[i] = nil
  end
end
local function bfut_UnselectItemsOutsideSelectionRange(range_begin, range_end)
  local count_sel_items = reaper.CountSelectedMediaItems(0)
  for i = count_sel_items - 1, 0, -1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    if item then
      local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      if pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH") <= range_begin or pos >= range_end then
        if count_sel_items == 1 then
          return false
        end
        reaper.SetMediaItemSelected(item, false)
      end
    end
  end
  if reaper.CountSelectedMediaItems(0) < 1 then
    return false
  end
  return true
end
local retval, COUNT_MARKERS, COUNT_REGIONS = reaper.CountProjectMarkers(0)
if not retval or COUNT_MARKERS < 1 then
  return
end
if not reaper.GetSelectedMediaItem(0, 0) then
  return
end
local ORIGINAL_TIMESEL_START, ORIGINAL_TIMESEL_END = reaper.GetSet_LoopTimeRange2(0, false, false, -1, -1, false)
if CONFIG["items_or_sel"] ~= "items" then
  local count_sel_items = reaper.CountSelectedMediaItems(0)
  for i = count_sel_items - 1, 0, -1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    if item then
      local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      if pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH") <= ORIGINAL_TIMESEL_START or pos >= ORIGINAL_TIMESEL_END then
        count_sel_items = count_sel_items - 1
      end
    end
  end
  if count_sel_items < 1 then
    return
  end
end
local VIEW_START, VIEW_END = reaper.GetSet_ArrangeView2(0, false, 0, 0, -1, -1)
local UNDO_DESC
if CONFIG["items_or_sel"] == "items" then
  UNDO_DESC = "bfut_Copy items to project markers, remove overlaps"
else
  UNDO_DESC = "bfut_Copy items within time selection to project markers, remove overlaps"
end
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
if CONFIG["items_or_sel"] ~= "items" then
  for i = reaper.CountSelectedMediaItems(0) - 1, 0, -1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    if item then
      local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      if pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH") <= ORIGINAL_TIMESEL_START or pos >= ORIGINAL_TIMESEL_END then
        reaper.SetMediaItemSelected(item, false)
      end
    end
  end
end
local markers, count_target_markers = bfut_GetMarkersByDistanceToNext(COUNT_MARKERS, COUNT_REGIONS)
if CONFIG["items_or_sel"] == "items" then
  reaper.Main_OnCommandEx(41174, 0)
  markers[1][3] = reaper.GetCursorPosition()
  reaper.Main_OnCommandEx(41173, 0)
  markers[1][3] = markers[1][3] - reaper.GetCursorPosition()
else
  markers[1][3] = ORIGINAL_TIMESEL_END - ORIGINAL_TIMESEL_START
end
local MAX_LEN = markers[1][3]
reaper.SetCursorContext(1, nil)
if CONFIG["items_or_sel"] == "items" then
  for _, val in ipairs(markers) do
    reaper.Main_OnCommandEx(41173, 0)
    local pos = reaper.GetCursorPosition()
    local curr_timesel_start, curr_timesel_end = reaper.GetSet_LoopTimeRange2(0, true, false, pos, pos + math.min(val[3], MAX_LEN), false)
    bfut_UnselectItemsOutsideSelectionRange(curr_timesel_start, curr_timesel_end)
    reaper.SetOnlyTrackSelected(reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0)))
    reaper.Main_OnCommandEx(40914, 0)
    reaper.SetEditCurPos2(0, val[2], false, false)
    reaper.Main_OnCommandEx(41383, 0)
    reaper.Main_OnCommandEx(40058, 0)
  end
  reaper.GetSet_LoopTimeRange2(0, true, false, ORIGINAL_TIMESEL_START, ORIGINAL_TIMESEL_END, false)
else
  reaper.SetOnlyTrackSelected(reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0)))
  reaper.Main_OnCommandEx(40914, 0)
  local item_left = true
  for i = 1, count_target_markers - 1 do
    reaper.Main_OnCommandEx(41383, 0)
    reaper.SetEditCurPos2(0, markers[i][2], false, false)
    reaper.Main_OnCommandEx(40058, 0)
    local curr_timesel_start, curr_timesel_end = reaper.GetSet_LoopTimeRange2(0, true, false, markers[i][2], markers[i][2] + math.min(markers[i + 1][3], MAX_LEN), false)
    item_left = bfut_UnselectItemsOutsideSelectionRange(curr_timesel_start, curr_timesel_end)
    if not item_left then
      local curr_timesel_start, curr_timesel_end = reaper.GetSet_LoopTimeRange2(0, true, false, markers[i][2], markers[i][2] + math.min(markers[i + 0][3], MAX_LEN), false)
      break
    end
    reaper.SetOnlyTrackSelected(reaper.GetMediaItem_Track(reaper.GetSelectedMediaItem(0, 0)))
    reaper.Main_OnCommandEx(40914, 0)
  end
  if item_left then
    reaper.Main_OnCommandEx(41383, 0)
    reaper.SetEditCurPos2(0, markers[count_target_markers][2], false, false)
    reaper.Main_OnCommandEx(40058, 0)
    local curr_timesel_start, curr_timesel_end = reaper.GetSet_LoopTimeRange2(0, true, false, markers[count_target_markers][2], markers[count_target_markers][2] + math.min(markers[count_target_markers][3], MAX_LEN), false)
  end
end
reaper.GetSet_ArrangeView2(0, true, 0, 0, VIEW_START, VIEW_END)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, UNDO_DESC, -1)