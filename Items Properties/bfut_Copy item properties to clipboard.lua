--[[
  @author bfut
  @version 1.0
  @description bfut_Copy item properties to clipboard
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
local item = reaper.GetSelectedMediaItem(0, 0)
if item then
  local take = reaper.GetActiveTake(item)
    if take then
      local item_vol = reaper.GetMediaItemInfo_Value(item, "D_VOL")
      local take_vol = reaper.GetMediaItemTakeInfo_Value(take, "D_VOL")
      local pan = reaper.GetMediaItemTakeInfo_Value(take, "D_PAN")
      local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
      local pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
      local buf = string.format("%f#%f#%f#%f#%f", item_vol, take_vol, pan, playrate, pitch)
      if reaper.APIExists("CF_SetClipboard") then
        reaper.CF_SetClipboard(buf)
        reaper.Undo_BeginBlock2(0)
        reaper.Undo_EndBlock2(0, "bfut_Copy item properties to clipboard", -1)
      else
        reaper.ReaScriptError("Requires extension, SWS v2.10.0.1 or later.\n")
      end
  end
end