--[[
  @author bfut
  @version 1.0
  @description bfut_Remove item under mouse cursor (delete)
  @about
    HOW TO USE:
      1) Hover mouse over item.
      2) Run the script.
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
local reaper = reaper
for _,function_name in ipairs({"BR_GetMouseCursorContext", "BR_GetMouseCursorContext_Item"}) do
  if not reaper.APIExists(function_name) then
    reaper.ReaScriptError("Requires extension, SWS v2.10.0.1 or later.\n")
    return
  end
end
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
reaper.BR_GetMouseCursorContext()
local item = reaper.BR_GetMouseCursorContext_Item()
if item == nil then
  return
end
local locked = reaper.GetMediaItemInfo_Value(item, "C_LOCK")
if locked ~= 0.0 and locked ~= 2.0 then
  return
end
reaper.DeleteTrackMediaItem(reaper.GetMediaItem_Track(item), item)  
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "bfut_Remove item under mouse cursor (delete)", -1)