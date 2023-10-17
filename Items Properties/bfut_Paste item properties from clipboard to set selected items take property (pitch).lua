--[[
  @author bfut
  @version 1.4
  @description bfut_Paste item properties from clipboard to set selected items take property (pitch)
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
    * bfut_Paste item properties from clipboard to set selected items property (fixedlane).lua
    * bfut_Paste item properties from clipboard to set selected items property (freeitemposition).lua
    * bfut_Paste item properties from clipboard to set selected items take property (startoffset).lua
    * bfut_Paste item properties from clipboard to set selected items take property (volume).lua
    * bfut_Paste item properties from clipboard to set selected items take property (pan).lua
    * bfut_Paste item properties from clipboard to set selected items take property (playrate).lua
    * bfut_Paste item properties from clipboard to set selected items take property (pitch).lua
    * bfut_Paste item properties from clipboard to set selected items take stretch markers.lua

    Copies and sets specific property in selected items. Observes item lock status.

    HOW TO USE:
      1) Select media item.
      2) Run script "bfut_Copy item properties to clipboard"
      3) Select other media item(s).
      4) Run one of the scripts "bfut_Paste item properties from clipboard to set selected items ... (...)"
  @changelog
    REQUIRES: Reaper v7.00 or later
    + add support for fixed item lane property, see new script (fixedlane)
    + add support for free item position property, see new script (freeitemposition)
    # this script set version is incompatible with any earlier versions
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
  property1 = "D_PITCH",
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
    "itemF_FREEMODE_Y",
    "itemF_FREEMODE_H",
    "itemI_FIXEDLANE",
    "takeD_STARTOFFS",
    "takeD_VOL",
    "takeD_PAN",
    "takeD_PLAYRATE",
    "takeD_PITCH",
  }
  i = 1
  for item in buf:gmatch("[^#]+") do
    vals[keys[i]] = tonumber(item)
    i = i + 1
  end
  return vals
end
local function bfut_GetStretchMarkersFromCSV(buf)
  local num_vals = tonumber(string.match(buf, "[^#]+", 0))
  local vals
  if num_vals > 0 then
    local cpos = buf:find("#", 2)
    buf = buf:sub(cpos)
    vals = {}
    for item in buf:gmatch("[^#]+") do
      vals[#vals + 1] = tonumber(item)
    end
    if #vals ~= 3*num_vals then
      return 0, nil
    end
  end
  return num_vals, vals
end
local COUNT_SEL_ITEMS = reaper.CountSelectedMediaItems(0)
if COUNT_SEL_ITEMS < 1 then
  return
end
local IS_ITEM_LOCKED = {
  [1.0] = true,
  [3.0] = true
}
if not reaper.HasExtState("bfut", "BFI4") then
  return
end
local buf = reaper.GetExtState("bfut", "BFI4")
if not buf:sub(1,4) == "BFI4" or not buf:find("#") then
  return
end
local cpos = buf:find("#BFS3")
if not cpos then
  return
end
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
if CONFIG["mode"] == "marker" then
  buf = buf:sub(cpos + 5)
  local num_takestretchmarkers, stretchmarkers = bfut_GetStretchMarkersFromCSV(buf)
    for i = 0, COUNT_SEL_ITEMS - 1 do
      item = reaper.GetSelectedMediaItem(0, i)
      if not IS_ITEM_LOCKED[reaper.GetMediaItemInfo_Value(item, "C_LOCK")] then
        local take = reaper.GetActiveTake(item)
        if take then
          reaper.DeleteTakeStretchMarkers(take, 0, reaper.GetTakeNumStretchMarkers(take))
          for i = 0, num_takestretchmarkers - 1 do
            local idx = reaper.SetTakeStretchMarker(take, -1, stretchmarkers[3*i + 1], stretchmarkers[3*i + 2])
          end
        end
      end
    end
else
  buf = buf:sub(5, cpos - 1)
  local properties = bfut_GetPropertiesFromCSV(buf)
  if properties then
    local parmname1 = CONFIG["property1"]
    local newvalue1 = properties[CONFIG["mode"] .. CONFIG["property1"]]
    if CONFIG["mode"] == "item" then
      for i = 0, COUNT_SEL_ITEMS - 1 do
        item = reaper.GetSelectedMediaItem(0, i)
        if not IS_ITEM_LOCKED[reaper.GetMediaItemInfo_Value(item, "C_LOCK")] then
          reaper.SetMediaItemInfo_Value(item, parmname1, newvalue1)
        end
      end
    else
      for i = 0, COUNT_SEL_ITEMS - 1 do
        item = reaper.GetSelectedMediaItem(0, i)
        if not IS_ITEM_LOCKED[reaper.GetMediaItemInfo_Value(item, "C_LOCK")] then
          local take = reaper.GetActiveTake(item)
          if take then
            reaper.SetMediaItemTakeInfo_Value(take, parmname1, newvalue1)
          end
        end
      end
    end
  end
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "bfut_Paste item properties from clipboard to set selected items take property (pitch).lua", -1)