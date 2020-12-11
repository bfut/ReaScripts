--[[
  @author bfut
  @version 1.0
  @description bfut_Unselect ungrouped items
  @about
    HOW TO USE:
      1) Select item(s).
      2) Run the script.
    REQUIRES: Reaper v6.16 or later
  @website https://github.com/bfut
  LICENSE:
    Copyright (C) 2020 and later Benjamin Futasz

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
local COUNT_SEL_ITEMS = reaper.CountSelectedMediaItems(0)
if COUNT_SEL_ITEMS < 1 then
  return
end
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
for i = COUNT_SEL_ITEMS - 1, 0, -1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  if math.abs(reaper.GetMediaItemInfo_Value(item, "I_GROUPID")) < 10^-13 then
    reaper.SetMediaItemSelected(item, false)
  end
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "bfut_Unselect ungrouped items", -1)