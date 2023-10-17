--[[
  @author bfut
  @version 1.4
  @description bfut_Copy item properties to clipboard
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
local item = reaper.GetSelectedMediaItem(0, 0)
if item then
  local itemD_VOL = reaper.GetMediaItemInfo_Value(item, "D_VOL")
  local itemD_LENGTH = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local itemD_SNAPOFFSET = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
  local itemD_FADEINLEN = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
  local itemD_FADEOUTLEN = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
  local itemC_FADEINSHAPE = reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE")
  local itemC_FADEOUTSHAPE = reaper.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE")
  local itemF_FREEMODE_Y = reaper.GetMediaItemInfo_Value(item, "F_FREEMODE_Y")
  local itemF_FREEMODE_H = reaper.GetMediaItemInfo_Value(item, "F_FREEMODE_H")
  local itemI_FIXEDLANE = reaper.GetMediaItemInfo_Value(item, "I_FIXEDLANE")
  local takeD_STARTOFFS = 0.0
  local takeD_VOL = 1.0
  local takeD_PAN = 0.0
  local takeD_PLAYRATE = 1.0
  local takeD_PITCH = 1.0
  local take = reaper.GetActiveTake(item)
  local num_takestretchmarkers = 0
  local takestretchmarkers = {}
  if take then
    takeD_STARTOFFS = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    takeD_VOL = reaper.GetMediaItemTakeInfo_Value(take, "D_VOL")
    takeD_PAN = reaper.GetMediaItemTakeInfo_Value(take, "D_PAN")
    takeD_PLAYRATE = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    takeD_PITCH = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
    num_takestretchmarkers = reaper.GetTakeNumStretchMarkers(take)
    if num_takestretchmarkers > 0 then
      for idx = 0, num_takestretchmarkers - 1 do
        local retval, pos, opt_srcpos = reaper.GetTakeStretchMarker(take, idx)
        if retval < 0 then
          num_takestretchmarkers = idx
          break
        end
        local slope = reaper.GetTakeStretchMarkerSlope(take, idx)
        takestretchmarkers[#takestretchmarkers + 1] = string.format("%f#%f#%f", pos, opt_srcpos, slope)
      end
    end
  end
  reaper.SetExtState("bfut", "BFI4",
    string.format("BFI4#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#BFS3#%d#%s",
      itemD_VOL,
      itemD_LENGTH,
      itemD_SNAPOFFSET,
      itemD_FADEINLEN,
      itemD_FADEOUTLEN,
      itemC_FADEINSHAPE,
      itemC_FADEOUTSHAPE,
      itemF_FREEMODE_Y,
      itemF_FREEMODE_H,
      itemI_FIXEDLANE,
      takeD_STARTOFFS,
      takeD_VOL,
      takeD_PAN,
      takeD_PLAYRATE,
      takeD_PITCH,
      num_takestretchmarkers,
      table.concat(takestretchmarkers, "#")
    ), true)
  reaper.Undo_BeginBlock2(0)
  reaper.Undo_EndBlock2(0, "bfut_Copy item properties to clipboard", -1)
end