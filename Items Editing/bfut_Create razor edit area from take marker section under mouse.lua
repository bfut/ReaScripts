--[[
  @author bfut
  @version 1.0
  @description bfut_Create razor edit area from take marker section under mouse
  @about
  @about
    Select take marker section
    * bfut_Create razor edit area from take marker section under mouse.lua
    * bfut_Set time selection to take marker section under mouse.lua

  HOW TO USE:
    1) Hover mouse over item.
    2) Run the script.
  @changelog
    REQUIRES: Reaper v7.67 or later
    + initial version
  @website https://github.com/bfut
  LICENSE:
    Copyright (C) 2026 and later Benjamin Futasz

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
  option = "raz"
}
local function bfut_GetProjectSamplerate()
  if reaper.GetSetProjectInfo(0, "PROJECT_SRATE_USE", -1, false) > 0.0 then
    return true, reaper.GetSetProjectInfo(0, "PROJECT_SRATE", -1, false)
  end
  return reaper.GetAudioDeviceInfo("SRATE")
end
local retv, min_item_len = bfut_GetProjectSamplerate()
if not retv then
  min_item_len = 384000
end
min_item_len = 60 / min_item_len
local SCREEN_X, SCREEN_Y = reaper.GetMousePosition()
local MOUSE_TIME, _ = reaper.GetSet_ArrangeView2(0, false, SCREEN_X, SCREEN_X + 1)
local item, _ = reaper.GetItemFromPoint(SCREEN_X, SCREEN_Y, true)
if not item then
  return
end
local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
if item_len < min_item_len then
  return
end
local item_activetake = reaper.GetActiveTake(item, 0)
if not item_activetake then
  return
end
local track = reaper.GetMediaItemTrack(item)
if not track then
  return
end
local UNDO_DESC
if CONFIG["option"] == "raz" then
  UNDO_DESC = "Create razor edit area from take marker section under mouse"
elseif CONFIG["option"] == "sel" then
  UNDO_DESC = "Set time selection to take marker section under mouse"
else
  return
end
local ORIGINAL_CURSOR_POSITION = reaper.GetCursorPosition()
local VIEW_START, VIEW_END = reaper.GetSet_ArrangeView2(0, false, 0, 0, -1, -1)
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
reaper.SelectAllMediaItems(0, false)
reaper.SetMediaItemSelected(item, true)
reaper.SetOnlyTrackSelected(track)
local timesel_start
local timesel_end
if reaper.GetNumTakeMarkers(item_activetake) > 0 then
  reaper.SetEditCurPos2(0, MOUSE_TIME, false, false)
  reaper.Main_OnCommandEx(42393, 0)
  timesel_start = reaper.GetCursorPosition()
  reaper.Main_OnCommandEx(42394, 0)
  timesel_end = reaper.GetCursorPosition()
  if timesel_start >= MOUSE_TIME then
    timesel_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  end
  if timesel_end <= timesel_start then
    timesel_end = reaper.GetMediaItemInfo_Value(item, "D_POSITION") + item_len
  end
else
  timesel_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  timesel_end = timesel_start + item_len
end
if timesel_end - timesel_start >= min_item_len then
  if CONFIG["option"] == "raz" then
    local p_razoredits = timesel_start .. " " .. timesel_end .. ' ""'
    reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", p_razoredits, true)
  else
    reaper.GetSet_LoopTimeRange2(0, true, false, timesel_start, timesel_end, false)
  end
end
reaper.SetEditCurPos2(0, ORIGINAL_CURSOR_POSITION, false, false)
reaper.GetSet_ArrangeView2(0, true, 0, 0, VIEW_START, VIEW_END)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, UNDO_DESC, -1)