--[[
  @author bfut
  @version 2.1
  @description bfut_Copy items within time selection to project markers, remove overlaps
  @about
    Copies any selected items within time selection to project markers.

    HOW TO USE:
      1) There must be at least one project marker.
      2) Select media item(s).
      3) Set time selection that at least partially overlaps selected item(s).
      4) Run the script.

    REQUIRES: Reaper v6.04 or later
  @changelog
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
--[[ CONFIG options:
  items_or_sel = "items"|"sel"
]]
local CONFIG = {
  items_or_sel = "sel"
}
local function bfut_GetMarkersByDistanceToNext(count_markers, count_regions, offset)
  local markers = {}
  local marker_idx = 2
  local continue_loop = 0
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
    if markers[i][3] > offset then
      return markers, i
    end
    markers[i] = nil
  end
end
local retval, COUNT_MARKERS, COUNT_REGIONS = reaper.CountProjectMarkers(0)
if not retval or COUNT_MARKERS < 1 then
  return
end
local FIRST_ITEM = reaper.GetSelectedMediaItem(0, 0)
if not FIRST_ITEM then
  return
end
reaper.SetOnlyTrackSelected(reaper.GetMediaItem_Track(FIRST_ITEM))
reaper.Main_OnCommandEx(40914, 0)
local PLAY_POSITION = reaper.GetPlayPosition()
local ORIGINAL_TIMESEL_START, ORIGINAL_TIMESEL_END = reaper.GetSet_LoopTimeRange2(0, false, false, -1, -1, false)
local _offset = 0
if CONFIG["items_or_sel"] ~= "items" then
  reaper.Main_OnCommandEx(41173, 0)
  _offset = math.max(reaper.GetCursorPosition() - ORIGINAL_TIMESEL_START, 0)
end
local markers, count_target_markers = bfut_GetMarkersByDistanceToNext(COUNT_MARKERS, COUNT_REGIONS, _offset + 2.2204460492503e-12)
if CONFIG["items_or_sel"] == "items" then
  reaper.Main_OnCommandEx(41174, 0)
  markers[1][3] = reaper.GetCursorPosition()
  reaper.Main_OnCommandEx(41173, 0)
  markers[1][3] = markers[1][3] - reaper.GetCursorPosition()
else
  markers[1][3] = ORIGINAL_TIMESEL_END - ORIGINAL_TIMESEL_START
end
local MAX_LEN = markers[1][3]
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
reaper.SetCursorContext(1, nil)
if CONFIG["items_or_sel"] == "items" then
  for _, val in ipairs(markers) do
    reaper.Main_OnCommandEx(41173, 0)
    local pos = reaper.GetCursorPosition()
    reaper.GetSet_LoopTimeRange2(0, true, false, pos, pos + math.min(val[3], MAX_LEN), false)
    reaper.GoToMarker(0, val[1], true)
    reaper.Main_OnCommandEx(41383, 0)
    reaper.Main_OnCommandEx(40058, 0)
  end
  reaper.GetSet_LoopTimeRange2(0, true, false, ORIGINAL_TIMESEL_START, ORIGINAL_TIMESEL_END, false)
else
  reaper.Main_OnCommandEx(41383, 0)
  for i = 1, count_target_markers - 1 do
    reaper.SetEditCurPos2(0, markers[i][2], false, false)
    reaper.Main_OnCommandEx(40058, 0)
    reaper.GetSet_LoopTimeRange2(0, true, false, markers[i][2], markers[i][2] + math.min(markers[i + 1][3], MAX_LEN), false)
    reaper.Main_OnCommandEx(41383, 0)
  end
  reaper.SetEditCurPos2(0, markers[count_target_markers][2], false, false)
  reaper.Main_OnCommandEx(40058, 0)
  reaper.GetSet_LoopTimeRange2(0, true, false, markers[count_target_markers][2], markers[count_target_markers][2] + math.min(markers[count_target_markers][3], MAX_LEN), false)
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "bfut_Copy items within time selection to project markers, remove overlaps", -1)