--[[
  @author bfut
  @version 2.0
  @description bfut_Copy items to project markers, remove overlaps
  @about
    Copies any number of selected items to project markers.

    HOW TO USE:
      1) There must be at least one project marker.
      2) Select media item(s).
      3) Run the script.

    REQUIRES: Reaper v6.04 or later
  @changelog
    + native trim behind items behavior
    + native envelope behavior
    + inherit item grouping behavior from native copy+paste
    + improved performance
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
local function bfut_GetMarkersByDistanceToNext(count_markers, count_regions)
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
    if markers[i][3] > 0 then
      break
    end
    markers[i] = nil
  end
  return markers
end
local function bfut_SetTimeSelection(timesel_start, timesel_len)
  reaper.Main_OnCommandEx(40635, 0)
  reaper.MoveEditCursor(timesel_start - reaper.GetCursorPosition(0), false)
  reaper.MoveEditCursor(timesel_len, true)
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
local PLAY_STATE = reaper.GetPlayStateEx(0)
local PLAY_POSITION = reaper.GetPlayPosition()
if PLAY_STATE == 1 then
  reaper.CSurf_OnPause()
end
reaper.Main_OnCommandEx(40630, 0)
local ORIGINAL_TIMESEL_START = reaper.GetCursorPosition(0)
reaper.Main_OnCommandEx(40631, 0)
local ORIGINAL_TIMESEL_LEN = reaper.GetCursorPosition(0) - ORIGINAL_TIMESEL_START
local markers = bfut_GetMarkersByDistanceToNext(COUNT_MARKERS, COUNT_REGIONS)
reaper.Main_OnCommandEx(41174, 0)
markers[1][3] = reaper.GetCursorPosition()
reaper.Main_OnCommandEx(41173, 0)
markers[1][3] = markers[1][3] - reaper.GetCursorPosition()
local SEL_ITEMS_LEN = markers[1][3]
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
reaper.SetCursorContext(1, nil)
for _, val in ipairs(markers) do
  reaper.Main_OnCommandEx(41173, 0)
  bfut_SetTimeSelection(reaper.GetCursorPosition(), math.min(val[3], SEL_ITEMS_LEN))
  reaper.GoToMarker(0, val[1], true)
  reaper.Main_OnCommandEx(41383, 0)
  reaper.Main_OnCommandEx(40058, 0)
end
bfut_SetTimeSelection(ORIGINAL_TIMESEL_START, ORIGINAL_TIMESEL_LEN)
reaper.MoveEditCursor(PLAY_POSITION - reaper.GetCursorPosition(0), false)
if PLAY_STATE then
  reaper.CSurf_OnPause()
else
  reaper.CSurf_GoEnd()
end
reaper.Main_OnCommandEx(41174, 0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "bfut_Copy items to project markers, remove overlaps", -1)