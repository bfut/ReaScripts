--[[
  @author bfut
  @version 2.3
  @description bfut_Copy items to regions (propagate)
  @about
    Copies selected items to project regions.

    HOW TO USE:
      1) There must be at least one region.
      2) Select media item(s).
      3) Run the script.
  @changelog
    REQUIRES: Reaper v6.82 or later
    + initial version
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
local CONFIG = {
  items_or_sel = "items"
}
local function bfut_GetProjectSamplerate()
  if reaper.GetSetProjectInfo(0, "PROJECT_SRATE_USE", -1, false) > 0.0 then
    return true, reaper.GetSetProjectInfo(0, "PROJECT_SRATE", -1, false)
  end
  return reaper.GetAudioDeviceInfo("SRATE")
end
local function bfut_GetMinItemLen()
  local retv, min_item_len = bfut_GetProjectSamplerate()
  if not retv then
    min_item_len = 384000
  end
  min_item_len = (60 / min_item_len)
  return min_item_len
end
local MIN_RANGE_LEN = bfut_GetMinItemLen()
local function bfut_GetRegionsByLength(count_markers, count_regions, min_range_len)
  local markers = {}
  local marker_idx = 1
  local continue_loop = 0
  for i = 0, count_markers + count_regions - 1 do
    local _, isregion, pos, rgnend, _, _ = reaper.EnumProjectMarkers2(0, i)
    if isregion and rgnend - pos > min_range_len then
      markers[marker_idx] = {marker_idx, pos, rgnend, nil}
      markers[marker_idx][4] = reaper.TimeMap2_timeToQN(0, markers[marker_idx][3]) - reaper.TimeMap2_timeToQN(0, markers[marker_idx][2])
      marker_idx = marker_idx + 1
    end
  end
  table.sort(markers, function(a, b) return a[3] > b[3] end)
  for i = marker_idx - 1, 1, -1 do
    if markers[i][3] >= min_range_len then
      table.sort(markers, function(a, b) return a[4] > b[4] end)
      return markers, i
    end
    markers[i] = nil
  end
end
local function bfut_UnselectItemsOutsideTimeSelection(range_begin, range_end, min_range_len)
  local count_sel_items = reaper.CountSelectedMediaItems(0)
  for i = count_sel_items - 1, 0, -1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    if pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH") - range_begin < min_range_len or
        range_end - pos < min_range_len then
      if count_sel_items == 1 then
        return false
      end
      reaper.SetMediaItemSelected(item, false)
    end
  end
  if reaper.CountSelectedMediaItems(0) < 1 then
    return false
  end
  return true
end
local retval, COUNT_MARKERS, COUNT_REGIONS = reaper.CountProjectMarkers(0)
if not retval or COUNT_REGIONS < 1 then
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
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    if pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH") - ORIGINAL_TIMESEL_START < MIN_RANGE_LEN or
        ORIGINAL_TIMESEL_END - pos < MIN_RANGE_LEN then
      count_sel_items = count_sel_items - 1
    end
  end
  if count_sel_items < 1 then
    return
  end
end
local VIEW_START, VIEW_END = reaper.GetSet_ArrangeView2(0, false, 0, 0, -1, -1)
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
if CONFIG["items_or_sel"] ~= "items" then
  bfut_UnselectItemsOutsideTimeSelection(ORIGINAL_TIMESEL_START, ORIGINAL_TIMESEL_END, MIN_RANGE_LEN)
end
local markers, count_target_markers = bfut_GetRegionsByLength(COUNT_MARKERS, COUNT_REGIONS, MIN_RANGE_LEN)
local MAX_LEN = markers[1][3]
local MAX_LEN_QN = markers[1][4]
reaper.SetCursorContext(1, nil)
if CONFIG["items_or_sel"] == "items" then
  for _, val in ipairs(markers) do
    reaper.Main_OnCommandEx(41173, 0)
    local pos = reaper.GetCursorPosition()
    local curr_timesel_start, curr_timesel_end = reaper.GetSet_LoopTimeRange2(0, true, false, pos,
      reaper.TimeMap2_QNToTime(0, reaper.TimeMap2_timeToQN(0, pos) + math.min(val[4], MAX_LEN_QN)), false)
    bfut_UnselectItemsOutsideTimeSelection(curr_timesel_start, curr_timesel_end, MIN_RANGE_LEN)
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
    local curr_timesel_start, curr_timesel_end = reaper.GetSet_LoopTimeRange2(0, true, false, markers[i][2],
      reaper.TimeMap2_QNToTime(0, reaper.TimeMap2_timeToQN(0, markers[i][2]) + math.min(markers[i + 1][4], MAX_LEN_QN)), false)
    item_left = bfut_UnselectItemsOutsideTimeSelection(curr_timesel_start, curr_timesel_end, MIN_RANGE_LEN)
    if not item_left then
      local curr_timesel_start, curr_timesel_end = reaper.GetSet_LoopTimeRange2(0, true, false, markers[i][2],
        reaper.TimeMap2_QNToTime(0, reaper.TimeMap2_timeToQN(0, markers[i][2]) + math.min(markers[i + 0][4], MAX_LEN_QN)), false)
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
reaper.Undo_EndBlock2(0, "bfut_Copy items to regions (propagate)", -1)