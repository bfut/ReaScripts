--[[
  @author bfut
  @version 2.6
  @description bfut_Remove item under mouse cursor (delete)
  @about
    Step sequencer for items
    * bfut_Step sequencer (copy first item on track and fill grid bar under mouse)
    * bfut_Step sequencer (copy first item on track to grid bar under mouse).lua
    * bfut_Remove item under mouse cursor (delete).lua

    HOW TO USE:
      1) Hover mouse over item.
      2) Run the script.

    REQUIRES: Reaper v5.99 or later
  @changelog
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
local SCREEN_X, SCREEN_Y = reaper.GetMousePosition()
local item = reaper.GetItemFromPoint(SCREEN_X, SCREEN_Y, true)
if item then
  reaper.Undo_BeginBlock2(0)
  reaper.DeleteTrackMediaItem(reaper.GetMediaItem_Track(item), item)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock2(0, "bfut_Remove item under mouse cursor (delete)", -1)
end