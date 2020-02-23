--[[
  @author bfut
  @version 2.5
  @description bfut_Step sequencer (copy first item on track to grid bar under mouse)
  @about
    Step sequencer for items
    * bfut_Step sequencer (copy first item on track and fill grid bar under mouse)
    * bfut_Step sequencer (copy first item on track to grid bar under mouse).lua
    * bfut_Remove item under mouse cursor (delete).lua

    Copies first item on track under mouse cursor to grid bar under
    mouse cursor. Requires SWS extension.

    Add a source media item at the beginning of your target track.
    Set a time selection, e.g. 16 grid bars. Hit play.
    As you add and remove media items, REAPER's arrange view now behaves like a pattern-based step sequencer.
    Try adjusting the grid divison.

    HOW TO SET UP:
      1) Install the scripts, and SWS.
      2) Toggle on "Options > Trim content behind media items when editing".
      3) Set mouse modifiers (Options > Preferences > Editing Behavior > Mouse Modifiers).
      4) Open Actions > Show action list
      5) Assign keyboard shortcut to each script (e.g. SHIFT+Q, SHIFT+A, and SHIFT+D), respectively.
         Holding a key combination, continuously executes a script.

    HOW TO USE:
      1) There must be at least one item on the track under mouse cursor.
      2) Hover mouse over arrange view.
      3) Run the script.

    REQUIRES: Reaper v6.04 or later, SWS v2.10.0.1 or later
  @changelog
    + native item snap behavior
    + native trim behind items behavior
    + Fix: arrange view scrolling
    + performance improvements
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
  copy_fill_mode = "copy"|"fill"  -- copy item to grid bar or fill grid bar (i.e. don't cut or cut, pasted item after next grid division)
]]
local CONFIG = {
  copy_fill_mode = "copy"
}
if not reaper.APIExists("BR_GetMouseCursorContext_Position") then
  reaper.ReaScriptError("Requires extension, SWS v2.10.0.1 or later.\n")
  return
end
local WINDOW, SEGMENT, DETAILS = reaper.BR_GetMouseCursorContext()
if WINDOW ~= "arrange" or SEGMENT ~= "track" then
  return
end
if DETAILS ~= "empty" and DETAILS ~= "item" then
  return
end
local TRACK = reaper.BR_GetMouseCursorContext_Track()
if not TRACK then
  return
end
local SRC_ITEM = reaper.GetTrackMediaItem(TRACK, 0)
local ORIGINAL_MOUSE_CURSOR_POSITION = reaper.BR_GetMouseCursorContext_Position()
local PREV_GRID_DIVISION = reaper.BR_GetPrevGridDivision(ORIGINAL_MOUSE_CURSOR_POSITION)
local VIEW_START, VIEW_END = reaper.GetSet_ArrangeView2(0, false, 0, 0, -1, -1)
local _item_start
if reaper.GetToggleCommandState(1157) == 1 then
  _item_start = PREV_GRID_DIVISION
else
  _item_start = ORIGINAL_MOUSE_CURSOR_POSITION
end
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
reaper.SetOnlyTrackSelected(TRACK)
reaper.Main_OnCommandEx(40914, 0)
reaper.SelectAllMediaItems(0, false)
if CONFIG["copy_fill_mode"] == "fill" or not SRC_ITEM then
  local loop_start, loop_end = reaper.GetSet_LoopTimeRange2(0, false, false, -1, -1, false)
  reaper.GetSet_LoopTimeRange2(0, true, false, _item_start, _item_start - PREV_GRID_DIVISION + reaper.BR_GetNextGridDivision(ORIGINAL_MOUSE_CURSOR_POSITION), false)
  if SRC_ITEM then
    reaper.SetMediaItemSelected(SRC_ITEM, true)
    reaper.Main_OnCommandEx(41319, 0)
  else
    local original_edit_cursor_position = reaper.GetCursorPosition()
    reaper.Main_OnCommandEx(40142, 0)
    reaper.SetEditCurPos2(0, original_edit_cursor_position, false, false)
  end
  reaper.GetSet_LoopTimeRange2(0, true, false, loop_start, loop_end, false)
else
  local original_edit_cursor_position = reaper.GetCursorPosition()
  reaper.SetEditCurPos2(0, _item_start, false, false)
  reaper.SetMediaItemSelected(SRC_ITEM, true)
  reaper.Main_OnCommandEx(40698, 0)
  reaper.Main_OnCommandEx(40058, 0)
  reaper.SetEditCurPos2(0, original_edit_cursor_position, false, false)
end
reaper.GetSet_ArrangeView2(0, true, 0, 0, VIEW_START, VIEW_END)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "bfut_Step sequencer (copy first item on track to grid bar under mouse)", -1)