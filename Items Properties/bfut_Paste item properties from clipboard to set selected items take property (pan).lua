--[[
  @author bfut
  @version 1.2
  @description bfut_Paste item properties from clipboard to set selected items take property (pan)
  @about
    Copy and paste properties
    * bfut_Copy item properties to clipboard.lua
    * bfut_Paste item properties from clipboard to set selected items property (volume).lua
    * bfut_Paste item properties from clipboard to set selected items property (length).lua
    * bfut_Paste item properties from clipboard to set selected items property (snapoffset).lua
    * bfut_Paste item properties from clipboard to set selected items property (fadeinlength).lua
    * bfut_Paste item properties from clipboard to set selected items property (fadeoutlength).lua
    * bfut_Paste item properties from clipboard to set selected items property (fadeinshape).lua
    * bfut_Paste item properties from clipboard to set selected items property (fadeoutshape).lua
    * bfut_Paste item properties from clipboard to set selected items take property (startoffset).lua
    * bfut_Paste item properties from clipboard to set selected items take property (volume).lua
    * bfut_Paste item properties from clipboard to set selected items take property (pan).lua
    * bfut_Paste item properties from clipboard to set selected items take property (playrate).lua
    * bfut_Paste item properties from clipboard to set selected items take property (pitch).lua

    Copies and sets specific property in selected items. Observes item lock status.

    HOW TO USE:
      1) Select media item.
      2) Run script "bfut_Copy item properties to clipboard"
      3) Select other media item(s).
      4) Run one of the scripts "bfut_Paste item properties from clipboard to set selected items ... (...)"

    REQUIRES: Reaper v6.79 or later, SWS v2.12.1 or later
  @changelog
    + improved performance
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
local CONFIG = {
  mode = "take",
  property = "D_PAN",
}
local function bfut_GetPropertiesFromCSV(buf)
  local vals = {}
  local keys = {
    "itemD_VOL",
    "itemD_LENGTH",
    "itemD_SNAPOFFSET",
    "itemD_FADEINLEN",
    "itemD_FADEOUTLEN",
    "itemC_FADEINSHAPE",
    "itemC_FADEOUTSHAPE",
    "takeD_STARTOFFS",
    "takeD_VOL",
    "takeD_PAN",
    "takeD_PLAYRATE",
    "takeD_PITCH",
  }
  i = 1
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
  reaper.ReaScriptError("Requires extension, SWS v2.12.1 or later.\n")
  return
end
local IS_ITEM_LOCKED = {
  [1.0] = true,
  [3.0] = true
}
local buf = reaper.CF_GetClipboard("")
if not buf or not buf:sub(1,4) == "BFI0" or not buf:find("#") then
  return
end
buf = buf:sub(5)
local properties = bfut_GetPropertiesFromCSV(buf)
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
local parmname = CONFIG["property"]
local newvalue = properties[CONFIG["mode"] .. CONFIG["property"]]
if CONFIG["mode"] == "item" then
  for i = 0, COUNT_SEL_ITEMS - 1 do
    item = reaper.GetSelectedMediaItem(0, i)
    if not IS_ITEM_LOCKED[reaper.GetMediaItemInfo_Value(item, "C_LOCK")] then
      reaper.SetMediaItemInfo_Value(item, parmname, newvalue)
    end
  end
else
  for i = 0, COUNT_SEL_ITEMS - 1 do
    item = reaper.GetSelectedMediaItem(0, i)
    if not IS_ITEM_LOCKED[reaper.GetMediaItemInfo_Value(item, "C_LOCK")] then
      local take = reaper.GetActiveTake(item)
      if take then
        reaper.SetMediaItemTakeInfo_Value(take, parmname, newvalue)
      end
    end
  end
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "bfut_Paste item properties from clipboard to set selected items take property (pan).lua", -1)