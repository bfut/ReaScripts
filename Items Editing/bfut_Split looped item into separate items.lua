--[[
  @author bfut
  @version 1.2
  @description bfut_Split looped item into separate items
  @about
    HOW TO USE:
      1) Select media item(s).
      2) Run the script.
    REQUIRES: Reaper v6.12c or later
  @changelog
    + obey take source start offset
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
local COUNT_SEL_ITEMS = reaper.CountSelectedMediaItems(0)
if COUNT_SEL_ITEMS < 1 then
  return
end
local function bfut_SplitLoopedItemAtLoopPoints(item)
  reaper.SelectAllMediaItems(0, false)
  reaper.SetMediaItemSelected(item, true)
  repeat
    local take = reaper.GetActiveTake(item, 0)
    if take then
      local take_sourcelength, lengthIsQN = reaper.GetMediaSourceLength(reaper.GetMediaItemTake_Source(take))
      local take_startoffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
      if math.abs(take_sourcelength - take_startoffset) < 10^-13 then
        take_startoffset = 0
      end
      if lengthIsQN then
        take_sourcelength = reaper.TimeMap_QNToTime(take_sourcelength)
      end
      item = reaper.SplitMediaItem(
        item,
        reaper.GetMediaItemInfo_Value(item, "D_POSITION")
          + (take_sourcelength - take_startoffset) / reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
      )
    end
  until not item
  return
end
local IS_ITEM_LOCKED = {
  [1.0] = true,
  [3.0] = true
}
local item = {}
for i = 0, COUNT_SEL_ITEMS - 1 do
  item[i] = reaper.GetSelectedMediaItem(0, i)
end
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock2(0)
for i = 0, COUNT_SEL_ITEMS - 1 do
  if not IS_ITEM_LOCKED[reaper.GetMediaItemInfo_Value(item[i], "C_LOCK")] then
    bfut_SplitLoopedItemAtLoopPoints(item[i])
  end
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "bfut_Split looped item into separate items", -1)