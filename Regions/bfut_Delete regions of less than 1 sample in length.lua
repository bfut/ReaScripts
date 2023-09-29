--[[
  @author bfut
  @version 1.0
  @description bfut_Delete regions of less than 1 sample in length
  @about
    HOW TO USE:
      1) Run the script.
  @changelog
    REQUIRES: Reaper v6.82 or later
    + initial version
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
  num_samples = 1
}
local retval, NUM_MARKERS, NUM_REGIONS = reaper.CountProjectMarkers(0)
if not retval or NUM_REGIONS < 1 then
  return
end
local function bfut_GetProjectSamplerate()
  if reaper.GetSetProjectInfo(0, "PROJECT_SRATE_USE", -1, false) > 0.0 then
    return true, reaper.GetSetProjectInfo(0, "PROJECT_SRATE", -1, false)
  end
  return reaper.GetAudioDeviceInfo("SRATE")
end
local retv, min_item_len = bfut_GetProjectSamplerate()
if not retv then
  min_item_len = 384000
end
min_item_len = (60 / min_item_len) * CONFIG["num_samples"]
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
for i = NUM_MARKERS + NUM_REGIONS - 1, 0, -1 do
  local _, isregion, pos, rgnend = reaper.EnumProjectMarkers3(0, i)
  if isregion and rgnend - pos < min_item_len then
    reaper.DeleteProjectMarkerByIndex(0, i)
  end
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "bfut_Delete regions of less than 1 sample in length", -1)