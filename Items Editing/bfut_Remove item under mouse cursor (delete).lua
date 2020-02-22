--[[
  @author bfut
  @version 1.1
  @description bfut_Remove item under mouse cursor (delete)
  @about
    HOW TO USE:
      1) Hover mouse over item.
      2) Run the script.
    REQUIRES: Reaper v6.04 or later
  @changelog
    + no longer requires SWS extension
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
local function bfut_GetSelectedItemsGUIDs(count_sel_items)
  local sel_items_takes_guid = {}
  for i = count_sel_items - 1, 0, -1 do
    local take = reaper.GetMediaItemTake(reaper.GetSelectedMediaItem(0, i), 0)
    if take then
      local _, guid = reaper.GetSetMediaItemTakeInfo_String(take, "GUID", "", false)
      sel_items_takes_guid[i + 1] = guid
    else
      sel_items_takes_guid[i + 1] = "-1"
    end
  end
  return sel_items_takes_guid
end
local function bfut_SelectItems(sel_items_takes_guid)
  for _, guid in ipairs(sel_items_takes_guid) do
    local take = reaper.GetMediaItemTakeByGUID(0, guid)
    if take then
      reaper.SetMediaItemSelected(reaper.GetMediaItemTake_Item(take), true)
    end
  end
end
local IS_ITEM_LOCKED = {
  [1.0] = true,
  [3.0] = true
}
if reaper.APIExists("BR_GetMouseCursorContext_Item") then
  reaper.BR_GetMouseCursorContext()
  local item = reaper.BR_GetMouseCursorContext_Item()
  if item and not IS_ITEM_LOCKED[reaper.GetMediaItemInfo_Value(item, "C_LOCK")] then
    reaper.Undo_BeginBlock2(0)
    reaper.DeleteTrackMediaItem(reaper.GetMediaItem_Track(item), item)
    reaper.Undo_EndBlock2(0, "bfut_Remove item under mouse cursor (delete)", -1)
  end
else
  reaper.Undo_BeginBlock2(0)
  reaper.PreventUIRefresh(1)
  local sel_items_takes_guid = bfut_GetSelectedItemsGUIDs(reaper.CountSelectedMediaItems(0))
  reaper.Main_OnCommandEx(40528, 0)
  local item = reaper.GetSelectedMediaItem(0, 0)
  if item and not IS_ITEM_LOCKED[reaper.GetMediaItemInfo_Value(item, "C_LOCK")] then
    reaper.DeleteTrackMediaItem(reaper.GetMediaItem_Track(item), item)
  end
  reaper.SelectAllMediaItems(0, false)
  bfut_SelectItems(sel_items_takes_guid)
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock2(0, "bfut_Remove item under mouse cursor (delete)", -1)
end
reaper.UpdateArrange()
