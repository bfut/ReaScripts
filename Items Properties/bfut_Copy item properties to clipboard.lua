--[[
  @author bfut
  @version 1.6
  @description bfut_Copy item properties to clipboard
  @about
    Copy and paste properties
    * bfut_Copy item properties to clipboard.lua
    * bfut_Paste item properties from clipboard to set selected items property (volume).lua
    * bfut_Paste item properties from clipboard to set selected items property (length).lua
    * bfut_Paste item properties from clipboard to set selected items property (snapoffset).lua
    * bfut_Paste item properties from clipboard to set selected items property (fadeinlength).lua
    * bfut_Paste item properties from clipboard to set selected items property (fadeoutlength).lua
    * bfut_Paste item properties from clipboard to set selected items property (fadeincurvature).lua
    * bfut_Paste item properties from clipboard to set selected items property (fadeoutcurvature).lua
    * bfut_Paste item properties from clipboard to set selected items property (autofadeinlength).lua
    * bfut_Paste item properties from clipboard to set selected items property (autofadeoutlength).lua
    * bfut_Paste item properties from clipboard to set selected items property (fadeinshape).lua
    * bfut_Paste item properties from clipboard to set selected items property (fadeoutshape).lua
    * bfut_Paste item properties from clipboard to set selected items property (lowpassfade).lua
    * bfut_Paste item properties from clipboard to set selected items property (activetake).lua
    * bfut_Paste item properties from clipboard to set selected items property (fixedlane).lua
    * bfut_Paste item properties from clipboard to set selected items property (freeitemposition).lua
    * bfut_Paste item properties from clipboard to set selected items take property (startoffset).lua
    * bfut_Paste item properties from clipboard to set selected items take property (volume).lua
    * bfut_Paste item properties from clipboard to set selected items take property (pan).lua
    * bfut_Paste item properties from clipboard to set selected items take property (panlaw).lua
    * bfut_Paste item properties from clipboard to set selected items take property (playrate).lua
    * bfut_Paste item properties from clipboard to set selected items take property (pitch).lua
    * bfut_Paste item properties from clipboard to set selected items take property (preservepitch).lua
    * bfut_Paste item properties from clipboard to set selected items take property (channelmode).lua
    * bfut_Paste item properties from clipboard to set selected items take property (pitchmode).lua
    * bfut_Paste item properties from clipboard to set selected items take property (recordpassid).lua
    * bfut_Paste item properties from clipboard to set selected items take markers.lua
    * bfut_Paste item properties from clipboard to set selected items take stretch markers.lua

    Copies and sets specific property in selected items. Observes item lock status.

    HOW TO USE:
      1) Select media item.
      2) Run script "bfut_Copy item properties to clipboard"
      3) Select other media item(s).
      4) Run one of the scripts "bfut_Paste item properties from clipboard to set selected items ... (...)"
  @changelog
    REQUIRES: Reaper v7.56 or later
    + support copy-/pasting take markers
    + extend support for item take properties, see new scripts (panlaw, preservepitch, channelmode, pitchmode, recordpassid)
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
  local itemD_FADEINDIR = reaper.GetMediaItemInfo_Value(item, "D_FADEINDIR")
  local itemD_FADEOUTDIR = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTDIR")
  local itemD_FADEINLEN_AUTO = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO")
  local itemD_FADEOUTLEN_AUTO = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO")
  local itemC_FADEINSHAPE = reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE")
  local itemC_FADEOUTSHAPE = reaper.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE")
  local itemI_FADELPF = reaper.GetMediaItemInfo_Value(item, "I_FADELPF")
  local itemI_CURTAKE = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")
  local itemF_FREEMODE_Y = reaper.GetMediaItemInfo_Value(item, "F_FREEMODE_Y")
  local itemF_FREEMODE_H = reaper.GetMediaItemInfo_Value(item, "F_FREEMODE_H")
  local itemI_FIXEDLANE = reaper.GetMediaItemInfo_Value(item, "I_FIXEDLANE")
  local takeD_STARTOFFS = 0.0
  local takeD_VOL = 1.0
  local takeD_PAN = 0.0
  local takeD_PANLAW = 0.0
  local takeD_PLAYRATE = 1.0
  local takeD_PITCH = 1.0
  local takeB_PPITCH = 0.0
  local takeI_CHANMODE = 0.0
  local takeI_PITCHMODE = 0.0
  local takeI_RECPASSID = 0.0
  local take = reaper.GetActiveTake(item)
  local num_takestretchmarkers = 0
  local takestretchmarkers = {}
  local num_takemarkers = 0
  local takemarkers = {}
  if take then
    takeD_STARTOFFS = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    takeD_VOL = reaper.GetMediaItemTakeInfo_Value(take, "D_VOL")
    takeD_PAN = reaper.GetMediaItemTakeInfo_Value(take, "D_PAN")
    takeD_PANLAW = reaper.GetMediaItemTakeInfo_Value(take, "D_PANLAW")
    takeD_PLAYRATE = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    takeD_PITCH = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH")
    takeB_PPITCH = reaper.GetMediaItemTakeInfo_Value(take, "B_PPITCH")
    takeI_CHANMODE = reaper.GetMediaItemTakeInfo_Value(take, "I_CHANMODE")
    takeI_PITCHMODE = reaper.GetMediaItemTakeInfo_Value(take, "I_PITCHMODE")
    takeI_RECPASSID = reaper.GetMediaItemTakeInfo_Value(take, "I_RECPASSID")
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
    num_takemarkers = reaper.GetNumTakeMarkers(take)
    if num_takemarkers > 0 then
      for idx = 0, num_takemarkers - 1 do
        local pos, name_, opt_color = reaper.GetTakeMarker(take, idx)
        if pos < 0 then
          num_takemarkers = idx
          break
        end
        name_ = name_:gsub("#", "##")
        takemarkers[#takemarkers + 1] = string.format("%f#%s#%f", pos, name_, opt_color)
      end
    end
  end
  reaper.SetExtState("bfut", "BFI6",
    string.format("BFI6#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#%f#BFS3#%d#%s#BFM1#%d#%s",
      itemD_VOL,
      itemD_LENGTH,
      itemD_SNAPOFFSET,
      itemD_FADEINLEN,
      itemD_FADEOUTLEN,
      itemD_FADEINDIR,
      itemD_FADEOUTDIR,
      itemD_FADEINLEN_AUTO,
      itemD_FADEOUTLEN_AUTO,
      itemC_FADEINSHAPE,
      itemC_FADEOUTSHAPE,
      itemI_FADELPF,
      itemI_CURTAKE,
      itemF_FREEMODE_Y,
      itemF_FREEMODE_H,
      itemI_FIXEDLANE,
      takeD_STARTOFFS,
      takeD_VOL,
      takeD_PAN,
      takeD_PANLAW,
      takeD_PLAYRATE,
      takeD_PITCH,
      takeB_PPITCH,
      takeI_CHANMODE,
      takeI_PITCHMODE,
      takeI_RECPASSID,
      num_takestretchmarkers,
      table.concat(takestretchmarkers, "#"),
      num_takemarkers,
      table.concat(takemarkers, "#")
    ), true)
  reaper.Undo_BeginBlock2(0)
  reaper.Undo_EndBlock2(0, "bfut_Copy item properties to clipboard", -1)
end