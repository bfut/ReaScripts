--[[
  @author bfut
  @version 2.6
  @description bfut_Step sequencer (copy first item on track and fill grid bar under mouse)
  @about
    Step sequencer for items
    * bfut_Step sequencer (copy first item on track and fill grid bar under mouse)
    * bfut_Step sequencer (copy first item on track to grid bar under mouse).lua
    * bfut_Remove item under mouse cursor (delete).lua

    Copies first item on track under mouse cursor to grid bar under mouse cursor.

    HOW TO USE:
      1) There should be at least one item on the track under mouse cursor. (optional)
      2) Hover mouse over track in arrange view.
      3) Run the script.

    HOW TO SET UP:
      1) Install the scripts.
      2) Optionally toggle ON, "Options > Trim content behind media items when editing"
      3) Works well with both, mouse modifiers and keyboard shortcuts.
         Holding a key combination, continuously executes a script.

    POSSIBLE USAGE:
      Add source media item at the beginning of a target track.
      Set a time selection (e.g., 16 grid bars). Hit play.
      As you add and remove media items, REAPER's arrange view now behaves like a pattern-based step sequencer.
      Try adjusting the grid divison.
  @changelog
    REQUIRES: Reaper v7.00 or later
    + add support for item lanes / item position: use item lane / item position under mouse
    + change snap behavior: nearest grid division instead of always previous grid division
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
  copy_fill_mode = "fill"
}
local SCREEN_X, SCREEN_Y = reaper.GetMousePosition()
local TRACK, TRACK_INFO = reaper.GetTrackFromPoint(SCREEN_X, SCREEN_Y)
if not TRACK or TRACK_INFO == 2 then
  return
end
local RETVAL, INFO = reaper.GetThingFromPoint(SCREEN_X, SCREEN_Y)
if RETVAL ~= TRACK or INFO ~= "arrange" then
  return
end
local SRC_ITEM = reaper.GetTrackMediaItem(TRACK, 0)
local MOUSE_TIME = reaper.GetSet_ArrangeView2(0, false, SCREEN_X, SCREEN_X + 1)
reaper.SetEditCurPos2(0, MOUSE_TIME, false, false)
reaper.Main_OnCommandEx(40646, 0)
local PREV_GRID_DIVISION = reaper.GetCursorPosition()
reaper.Main_OnCommandEx(40647, 0)
local NEXT_GRID_DIVISION = reaper.GetCursorPosition()
local VIEW_START, VIEW_END = reaper.GetSet_ArrangeView2(0, false, 0, 0, -1, -1)
local _item_start
if reaper.GetToggleCommandState(1157) == 1 then
  _item_start = PREV_GRID_DIVISION
else
  _item_start = MOUSE_TIME
end
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
reaper.SetOnlyTrackSelected(TRACK)
reaper.Main_OnCommandEx(40914, 0)
reaper.SelectAllMediaItems(0, false)
if CONFIG["copy_fill_mode"] == "fill" or not SRC_ITEM then
  local loop_start, loop_end = reaper.GetSet_LoopTimeRange2(0, false, false, -1, -1, false)
  reaper.GetSet_LoopTimeRange2(0, true, false, _item_start, _item_start - PREV_GRID_DIVISION + NEXT_GRID_DIVISION, false)
  st_trimbehind = reaper.GetToggleCommandState(41117)
  reaper.Main_OnCommandEx(41121, 0)
  if SRC_ITEM then
    reaper.SetMediaItemSelected(SRC_ITEM, true)
    reaper.Main_OnCommandEx(41319, 0)
  else
    reaper.Main_OnCommandEx(40142, 0)
  end
  reaper.Main_OnCommandEx(40699, 0)
  if st_trimbehind == 1 then
    reaper.Main_OnCommandEx(41120,0)
  end
  reaper.Main_OnCommandEx(41221, 0)
  reaper.GetSet_LoopTimeRange2(0, true, false, loop_start, loop_end, false)
else
  reaper.SetEditCurPos2(0, _item_start, false, false)
  reaper.SetMediaItemSelected(SRC_ITEM, true)
  reaper.Main_OnCommandEx(40698, 0)
  reaper.Main_OnCommandEx(41221, 0)
end
reaper.GetSet_ArrangeView2(0, true, 0, 0, VIEW_START, VIEW_END)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "bfut_Step sequencer (copy first item on track and fill grid bar under mouse)", -1)