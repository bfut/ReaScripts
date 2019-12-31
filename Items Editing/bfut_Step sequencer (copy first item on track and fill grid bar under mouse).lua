--[[
  @author bfut
  @version 2.0
  @description bfut_Step sequencer (copy first item on track and fill grid bar under mouse)
  @about
    Step sequencer for items
    * bfut_Step sequencer (copy first item on track and fill grid bar under mouse)
    * bfut_Step sequencer (copy first item on track to grid bar under mouse).lua
    * bfut_Remove item under mouse cursor (delete).lua

    Copies first item on track under mouse cursor to grid bar under
    mouse cursor. Requires SWS extension.

    Add a source media item at the beginning of your target track.
    Set a time selection, e.g. 4 grid bars on a 1/4 grid division setting.
    Hit play. As you add and remove media items, REAPER's arrange view now behaves like a pattern-based step sequencer.
    Try adjusting the grid settings.

    HOW TO SET UP:
      1) Install the scripts, and SWS.
      2) Open REAPER > Actions > Show action list
      3) Assign keyboard shortcuts to each script (e.g. SHIFT+Q, SHIFT+A, and SHIFT+D), respectively.
      Holding a key combination, continuously executes a script.

    HOW TO USE:
      1) There must be at least one item on the track under mouse cursor.
      2) Hover mouse over arrange view.
      3) Run the script.

    REQUIRES: Reaper v6.00 or later, SWS v2.10.0.1 or later
  @website https://github.com/bfut
  LICENSE:
    Copyright (C) 2019 and later Benjamin Futasz

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
      handle_residual_items =
        "tidy dirty grid"  -- Any item that partially overlaps is cut within current grid, but not deleted (factory default)
        "ignore partial overlaps"  -- Remove items that fit current grid, ignore partial overlaps
        "clear dirty grid"  -- Any item that partially overlaps current grid is removed (not recommended)

      copy_fill_mode = "copy"|"fill"  -- copy item to grid bar or fill grid bar (i.e. don't cut or cut, pasted item after next grid division)
    Note: Script may misbehave if config settings do not match any of the above
]]
local CONFIG = {
  handle_residual_items = "tidy dirty grid"
  ,copy_fill_mode = "fill"
}
local reaper = reaper
local function CopyItemToGridBar(track, src_item)
  if src_item ~= nil then
    -- Select source item
    reaper.SelectAllMediaItems(0, false)
    reaper.SetMediaItemSelected(src_item, true)
    reaper.Main_OnCommandEx(41319, 0)
  else
    reaper.Main_OnCommandEx(40142, 0)
  end
end
local function bfut_SetTimeSelection(timesel_start, timesel_len)
  reaper.Main_OnCommandEx(40635, 0)
  reaper.MoveEditCursor(timesel_start-reaper.GetCursorPosition(0), false)
  reaper.MoveEditCursor(timesel_len, true)
end
for _, function_name in ipairs({"BR_GetMouseCursorContext", "BR_GetMouseCursorContext_Position", "BR_GetMouseCursorContext_Track", "BR_GetNextGridDivision", "BR_GetPrevGridDivision"}) do
  if not reaper.APIExists(function_name) then
    reaper.ReaScriptError("Requires extension, SWS v2.10.0.1 or later.\n")
    return
  end
end
local WINDOW, SEGMENT, DETAILS = reaper.BR_GetMouseCursorContext()
if WINDOW ~= "arrange" or SEGMENT ~= "track" then
  return
end
if DETAILS ~= "empty" and DETAILS ~= "item"  then
  return
end
local TRACK = reaper.BR_GetMouseCursorContext_Track()
if TRACK == nil then
  return
end
local SRC_ITEM = reaper.GetTrackMediaItem(TRACK, 0)
local PLAY_STATE = reaper.GetPlayStateEx(0)
local ORIGINAL_MOUSE_CURSOR_POSITION = reaper.BR_GetMouseCursorContext_Position()
local PREV_GRID_DIVISION = reaper.BR_GetPrevGridDivision(ORIGINAL_MOUSE_CURSOR_POSITION)
local NEXT_GRID_DIVISION = reaper.BR_GetNextGridDivision(ORIGINAL_MOUSE_CURSOR_POSITION)
local ORIGINAL_CURSOR_POSITION = reaper.GetCursorPosition()
reaper.Main_OnCommandEx(40630, 0)
local ORIGINAL_TIMESEL_START = reaper.GetCursorPosition(0)
reaper.Main_OnCommandEx(40631, 0)
local ORIGINAL_TIMESEL_LEN = reaper.GetCursorPosition(0)-ORIGINAL_TIMESEL_START
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
if PLAY_STATE == 1 then
  reaper.CSurf_OnPause()
end
if CONFIG["copy_fill_mode"] == "fill" or SRC_ITEM == nil then
  bfut_SetTimeSelection(PREV_GRID_DIVISION, NEXT_GRID_DIVISION-PREV_GRID_DIVISION)
elseif CONFIG["copy_fill_mode"] == "copy" then
  bfut_SetTimeSelection(PREV_GRID_DIVISION, reaper.GetMediaItemInfo_Value(SRC_ITEM, "D_LENGTH"))
else
  reaper.ReaScriptError("invalid setting CONFIG[copy_fill_mode]\n")
  return
end
reaper.SetOnlyTrackSelected(TRACK)
reaper.Main_OnCommandEx(40914, 0)
reaper.Main_OnCommandEx(reaper.NamedCommandLookup("_BR_FOCUS_ARRANGE_WND"), 0)
reaper.SelectAllMediaItems(0, false)
reaper.Main_OnCommandEx(40718, 0)
if CONFIG["handle_residual_items"] == "tidy dirty grid" then
  reaper.Main_OnCommandEx(41384, 0)  
elseif CONFIG["handle_residual_items"] == "ignore partial overlaps" then
  for i=reaper.CountSelectedMediaItems(0)-1, 0, -1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local item_start_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    if item_start_pos == PREV_GRID_DIVISION and item_start_pos+item_length == NEXT_GRID_DIVISION then
      local item_locked = reaper.GetMediaItemInfo_Value(item, "C_LOCK")
      if item_locked == 0.0 or item_locked == 2.0 then
        reaper.DeleteTrackMediaItem(TRACK, item)
      end
    end
  end
elseif CONFIG["handle_residual_items"] == "clear dirty grid" then
  for i=reaper.CountSelectedMediaItems(0)-1, 0, -1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local item_locked = reaper.GetMediaItemInfo_Value(item, "C_LOCK")
    if item_locked == 0.0 or item_locked == 2.0 then
      reaper.DeleteTrackMediaItem(TRACK, item)
    end
  end
end
CopyItemToGridBar(TRACK, SRC_ITEM)
bfut_SetTimeSelection(ORIGINAL_TIMESEL_START, ORIGINAL_TIMESEL_LEN)
reaper.MoveEditCursor(ORIGINAL_TIMESEL_START-reaper.GetCursorPosition(0), false)
if PLAY_STATE == 1 then
  reaper.CSurf_OnPause()
else
  reaper.CSurf_GoEnd()
end
reaper.MoveEditCursor(ORIGINAL_CURSOR_POSITION-reaper.GetCursorPosition(0), false)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "bfut_Step sequencer (copy first item on track and fill grid bar under mouse)", -1)