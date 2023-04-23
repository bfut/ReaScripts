--[[
  @author bfut
  @version 1.0
  @description bfut_Paste item properties from clipboard to set selected items property (pitch)
  @about
    Copy and paste properties
    * bfut_Copy item properties to clipboard.lua
    * bfut_Paste item properties from clipboard to set selected items property (item volume).lua
    * bfut_Paste item properties from clipboard to set selected items property (take volume).lua
    * bfut_Paste item properties from clipboard to set selected items property (pan).lua
    * bfut_Paste item properties from clipboard to set selected items property (pitch).lua
    * bfut_Paste item properties from clipboard to set selected items property (playrate).lua

    Copies and sets specific item properties in selected items.

    HOW TO USE:
      1) Select media item.
      2) Run script "bfut_Copy item properties to clipboard".
      3) Select other media item(s).
      4) Run one of the scripts "bfut_Paste item properties from clipboard to set selected items property".

    REQUIRES: Reaper v6.78 or later, SWS v2.12.1 or later
  @website https://github.com/bfut
  LICENSE:
    Copyright (C) 2023 and later Benjamin Futasz

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
--[[ CONFIG defaults:
  property =
    "item_vol"  -- for item volume
    "D_VOL"  -- for take volume
    "D_PAN"  -- for take pan
    "D_PLAYRATE"  -- for take playrate
    "D_PITCH"  -- for take pitch
]]
local CONFIG = {
  property = "D_PITCH",
}
local function bfut_GetPropertiesFromCSV(buf)
  local vals = {}
  local keys = {"item_vol", "D_VOL", "D_PAN", "D_PLAYRATE", "D_PITCH"}
  local i = 1
  for item in buf:gmatch("[^#]+") do
    vals[keys[i]] = item
    i = i + 1
  end
  return vals
end
local COUNT_SEL_ITEMS = reaper.CountSelectedMediaItems(0)
if COUNT_SEL_ITEMS < 1 then
  return
end
if not reaper.APIExists("CF_GetClipboard") then
  reaper.ReaScriptError("Requires extension, SWS v2.12.0.0 or later.\n")
  return
end
local RPPXML_LOCK = {
  ["1"] = 0,
  ["2"] = 2,
  ["3"] = 2
}
local IS_ITEM_LOCKED = {
    [1.0] = true,
    [3.0] = true
}
local buf = reaper.CF_GetClipboard("")
if not buf or not buf:find("#") then
  return
end
local properties = bfut_GetPropertiesFromCSV(buf)
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
for i = 0, COUNT_SEL_ITEMS - 1 do
  item = reaper.GetSelectedMediaItem(0, i)
  if not IS_ITEM_LOCKED[reaper.GetMediaItemInfo_Value(item, "C_LOCK")] then
    if CONFIG["property"] == "item_vol" then
      reaper.SetMediaItemInfo_Value(item, "D_VOL", properties["item_vol"])
    else
      local take = reaper.GetActiveTake(item)
      if take then
        reaper.SetMediaItemTakeInfo_Value(take, CONFIG["property"], properties[CONFIG["property"]])
      end
    end
  end
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "bfut_Paste item properties from clipboard to set selected items property (pitch).lua", -1)